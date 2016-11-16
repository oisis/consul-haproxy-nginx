// Description:
// https://github.com/hashicorp/consul-template
consul = "127.0.0.1:8500"
reload_signal = "SIGHUP"
dump_signal = "SIGQUIT"
kill_signal = "SIGINT"
retry = "10s"
max_stale = "10m"
log_level = "warn"
template {
  source = "/root/haproxy/haproxy.ctmpl"
  destination = "/root/haproxy/haproxy.cfg"
  command = "docker restart haproxy"
//  command = "docker kill -s HUP haproxy"
}
