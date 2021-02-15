return function()
  if not (ngx) then
    return 
  end
  local ip = ngx.var.remote_addr
  if ip == "127.0.0.1" then
    return ngx.var.http_x_forwarded_for or ip
  else
    return ip
  end
end
