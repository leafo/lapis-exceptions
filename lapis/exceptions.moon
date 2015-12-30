
import ExceptionRequests from require "lapis.exceptions.models"

protect = (fn) ->
  (...) ->
    local err, trace
    args = {...}
    result = {
      xpcall (-> fn unpack args), (_err) ->
        err = _err
        trace = debug.traceback "", 2
    }

    unless result[1]
      pcall -> ExceptionRequests\create {
        msg: err
        :trace
      }

      return nil, err, trace

    unpack result, 2

{ :protect }
