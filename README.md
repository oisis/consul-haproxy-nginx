## Setup Consul to manage web servers(Nginx) with LoadBalancers(HAProxy/Nginx)

### Requirements:
- Vagrant 1.8.*
- VirtualBox 5.*

### Check available hosts on vagrant:
```vagrant status```

### Run on Vagrnat:
```vagrant up <HOSTNAME>```

example:
```vagrant up lb```

### Consul UI access:
```http://172.20.20.31:8500```

### Access to services with HAProxy loadbalancer:

* Stats:
```http://172.20.20.11:1936```

* HTTP acccess to services:
```http://172.20.20.11/ip.html```

* HTTPS access to backend services:
```https://172.20.20.11/ip.html```

### Access to services with Nginx loadbalancer:

* HTTP acccess to services:
```http://172.20.20.12/ip.html```

* HTTPS access to backend services:
```https://172.20.20.12/ip.html```
