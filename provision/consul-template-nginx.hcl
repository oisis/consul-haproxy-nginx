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
  source = "/root/nginx/nginx.ctmpl"
  destination = "/root/nginx/nginx.conf"
  command = "docker restart nginx"
}
