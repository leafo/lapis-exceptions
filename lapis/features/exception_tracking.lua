local ExceptionRequests
do
  local _obj_0 = require("lapis.exceptions.models")
  ExceptionRequests = _obj_0.ExceptionRequests
end
local config = require("lapis.config").get()
return function(app_cls)
  if not (config.track_exceptions) then
    return 
  end
  local old_error_handler = app_cls.__base.handle_error
  app_cls.__base.handle_error = function(self, err, trace, ...)
    old_error_handler(self, err, trace, ...)
    return pcall(function()
      return ExceptionRequests:create(self, err, trace)
    end)
  end
end
