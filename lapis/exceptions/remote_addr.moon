-- TODO: there should be a way to configure how we authorize x-forwarded-for

->
  return unless ngx
  ip = ngx.var.remote_addr
  if ip == "127.0.0.1"
    ngx.var.http_x_forwarded_for or ip
  else
    ip

