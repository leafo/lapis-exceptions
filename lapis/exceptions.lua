local ExceptionRequests
ExceptionRequests = require("lapis.exceptions.models").ExceptionRequests
local protect
protect = function(fn)
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
      end)
    }
    if not (result[1]) then
      pcall(function()
        return ExceptionRequests:create(nil, err, trace)
      end)
      return nil, err, trace
    end
    return unpack(result, 2)
  end
end
return {
  protect = protect
}
