## Setup Consul to manage web servers(Nginx) with LoadBalancer(HAProxy)

### Requirements:
- Vagrant 1.8.*
- VirtualBox 5.*

### Check available hosts on vagrant:
```vagrant status```

### Run on Vagrnat:
```vagrant up <HOSTNAME>```

example:
```vagrant up lb```

### Create K/V for HAProxy with curl
```/usr/bin/curl -X PUT -d '4096' http://127.0.0.1:8500/v1/kv/prod/portal/haproxy/maxconn```

```/usr/bin/curl -X PUT -d '5s' http://127.0.0.1:8500/v1/kv/prod/portal/haproxy/timeout-connect```

```/usr/bin/curl -X PUT -d '50s' http://127.0.0.1:8500/v1/kv/prod/portal/haproxy/timeout-client```

```/usr/bin/curl -X PUT -d '50s' http://127.0.0.1:8500/v1/kv/prod/portal/haproxy/timeout-server```

```/usr/bin/curl -X PUT -d 'enable' http://127.0.0.1:8500/v1/kv/prod/portal/haproxy/stats```

```/usr/bin/curl -X PUT -d '5s' http://127.0.0.1:8500/v1/kv/prod/portal/haproxy/refresh```

```/usr/bin/curl -X PUT -d '/' http://127.0.0.1:8500/v1/kv/prod/portal/haproxy/uri```
