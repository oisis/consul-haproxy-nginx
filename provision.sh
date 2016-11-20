#!/usr/bin/env bash

tty -s

# Install unzip
sudo apt-get update -qq
sudo apt-get install -qqy unzip mc bc stress

cat >> ~/.bashrc <<"END"
# Coloring of hostname in prompt to keep track of what's what in demos, blue provides a little emphasis but not too much like red
NORMAL="\[\e[0m\]"
BOLD="\[\e[1m\]"
DARKGRAY="\[\e[90m\]"
BLUE="\[\e[34m\]"
PS1="$DARKGRAY\u@$BOLD$BLUE\h$DARKGRAY:\w\$ $NORMAL"
END

# Download consul
CONSUL_VERSION=0.7.1
CONSUL_TEMPLATE_VERSION=0.16.0
curl -s https://releases.hashicorp.com/consul-template/${CONSUL_TEMPLATE_VERSION}/consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip -o consul-template.zip
curl -s https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip -o consul.zip

# Install consul
unzip consul.zip
sudo chmod +x consul
sudo mv consul /usr/bin/consul
rm -f consul.zip

# Install consul-template
unzip consul-template.zip
sudo chmod +x consul-template
sudo mv consul-template /usr/bin/consul-template
rm -f consul-template.zip

#Lets copy config files and run consul:
IP=$(ifconfig eth1 | grep 'inet addr' | awk '{ print substr($2,6) }')
if [[ `hostname` == "web"* ]]; then
    HOSTNAME="web"
else
    HOSTNAME=`hostname`
fi

if [[ `hostname` == "lb"* ]]; then
    HOSTNAME="lb"
else
    HOSTNAME=`hostname`
fi

# Make dir for configuration
mkdir -p /root/consul

# Copy config file to conf dir
cp /vagrant/consul-config/consul-$HOSTNAME.json /root/consul/consul-$HOSTNAME.json
chmod 644 /root/consul/*

# Remove container cAdvisor
/usr/bin/docker rm -f cadvisor

# Copy checks:
mkdir -p /root/consul-checks
cp /vagrant/provision/hc/* /root/consul-checks/
chmod 755 /root/consul-checks/*

# Lets setup IP for web servers before run consul
if [[ `hostname` == "web"* ]]; then
    /bin/sed -i "s/IPADDRESS/$IP/g" /root/consul/consul-web.json
    mkdir -p /root/html
    echo "<h1>$IP $(hostname)</h1>" > /root/html/ip.html
    docker run -d --name web -p 8080:80 --restart unless-stopped \
      -v /root/html/ip.html:/usr/share/nginx/html/ip.html:ro nginx
fi

# Setup LoadBalancer HAProxy
if [[ `hostname` == "lb" ]]; then
  mkdir -p /root/haproxy/
  mkdir -p /root/consul-template
  cp /vagrant/provision/haproxy.ctmpl /root/haproxy/
  cp /vagrant/provision/haproxy.cfg /root/haproxy/
  cp /vagrant/provision/consul-template.hcl /root/consul-template/
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /root/haproxy/haproxy.key \
  -out /root/haproxy/haproxy.crt -subj "/C=PL/ST=Mazowieckie/L=Warszawa/O=COMEORG/OU=IT/CN=172.20.20.11"
  cat /root/haproxy/haproxy.crt /root/haproxy/haproxy.key > /root/haproxy/haproxy.pem
  /usr/bin/consul-template -config /root/consul-template/consul-template.hcl 2>&1 >/dev/null &
  docker run -d --name haproxy -p 80:80 -p 1936:1936 -p 443:443 --restart unless-stopped \
    -v /root/haproxy/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg:ro \
    -v /root/haproxy/haproxy.pem:/usr/local/etc/haproxy/cert.pem:ro haproxy:1.6.9-alpine
  /usr/bin/curl -X PUT -d '4096' http://127.0.0.1:8500/v1/kv/prod/portal/haproxy/maxconn
  /usr/bin/curl -X PUT -d '5s' http://127.0.0.1:8500/v1/kv/prod/portal/haproxy/timeout-connect
  /usr/bin/curl -X PUT -d '50s' http://127.0.0.1:8500/v1/kv/prod/portal/haproxy/timeout-client
  /usr/bin/curl -X PUT -d '50s' http://127.0.0.1:8500/v1/kv/prod/portal/haproxy/timeout-server
  /usr/bin/curl -X PUT -d 'enable' http://127.0.0.1:8500/v1/kv/prod/portal/haproxy/stats
  /usr/bin/curl -X PUT -d '5s' http://127.0.0.1:8500/v1/kv/prod/portal/haproxy/refresh
  /usr/bin/curl -X PUT -d '/' http://127.0.0.1:8500/v1/kv/prod/portal/haproxy/uri
fi

# Setup LoadBalancer Nginx
if [[ `hostname` == "lbn" ]]; then
  mkdir -p /root/nginx/
  mkdir -p /root/consul-template
  cp /vagrant/provision/nginx.ctmpl /root/nginx/
  cp /vagrant/provision/nginx.conf /root/nginx/
  cp /vagrant/provision/consul-template-nginx.hcl /root/consul-template/
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /root/nginx/nginx.key \
    -out /root/nginx/nginx.crt -subj "/C=PL/ST=Mazowieckie/L=Warszawa/O=COMEORG/OU=IT/CN=172.20.20.12"
  /usr/bin/consul-template -config /root/consul-template/consul-template-nginx.hcl 2>&1 >/dev/null &
  docker run -d --name nginx -p 80:80 -p 443:443 --restart unless-stopped \
    -v /root/nginx/nginx.conf:/etc/nginx/conf.d/default.conf:ro -v /root/nginx/nginx.key:/etc/nginx/nginx.key:ro \
    -v /root/nginx/nginx.crt:/etc/nginx/nginx.crt:ro nginx:stable-alpine
fi

# Run consul
/usr/bin/consul agent -config-file /root/consul/consul-$HOSTNAME.json 2>&1 >/dev/null &
