local ExceptionRequests
ExceptionRequests = require("lapis.exceptions.models").ExceptionRequests
return function(app_cls)
  local config = require("lapis.config").get()
  if not (config.track_exceptions) then
    return 
  end
  local old_error_handler = app_cls.__base.handle_error
  app_cls.__base.handle_error = function(self, err, trace, ...)
    pcall(function()
      return ExceptionRequests:create({
        req = self,
        msg = err,
        trace = trace
      })
    end)
    return old_error_handler(self, err, trace, ...)
  end
end
