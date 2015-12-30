
import ExceptionRequests from require "lapis.exceptions.models"

(app_cls) ->
  config = require("lapis.config").get!
  return unless config.track_exceptions

  old_error_handler = app_cls.__base.handle_error
  app_cls.__base.handle_error = (err, trace, ...) =>
    old_error_handler @, err, trace, ...
    pcall ->
      ExceptionRequests\create {
        req: @
        msg: err
        :trace
      }

