local ExceptionRequests
ExceptionRequests = require("lapis.exceptions.models").ExceptionRequests
local VERSION = "2.3.0"
local protect
protect = function(fn_or_req, fn)
  local req
  if fn then
    req = fn_or_req
  else
    fn = fn_or_req
  end
  return function(...)
    local err, trace
    local args = {
      ...
    }
    local result = {
      xpcall((function()
        return fn(unpack(args))
      end), function(_err)
        err = _err
        trace = debug.traceback("", 2)
        trace = trace:match("^%s+(.*)")
      end)
    }
    if not (result[1]) then
      pcall(function()
        return ExceptionRequests:create({
          req = req,
          msg = err,
          trace = trace
        })
      end)
      return nil, err, trace
    end
    return unpack(result, 2)
  end
end
local protected_call
protected_call = function(...)
  return protect(...)()
end
return {
  protect = protect,
  protected_call = protected_call,
  VERSION = VERSION
}
