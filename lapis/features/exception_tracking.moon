
import ExceptionRequests from require "lapis.exceptions.models"
config = require("lapis.config").get!

(app_cls) ->
  return unless config.track_exceptions

  old_error_handler = app_cls.__base.handle_error
  app_cls.__base.handle_error = (err, trace, ...) =>
    old_error_handler @, err, trace, ...
    pcall -> ExceptionRequests\create @, err, trace

