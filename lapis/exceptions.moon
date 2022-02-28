
import ExceptionRequests from require "lapis.exceptions.models"

VERSION = "2.2.0"

protect = (fn_or_req, fn) ->
  local req

  if fn
    req = fn_or_req
  else
    fn = fn_or_req

  (...) ->
    local err, trace
    args = {...}
    result = {
      xpcall (-> fn unpack args), (_err) ->
        err = _err
        trace = debug.traceback "", 2
        trace = trace\match "^%s+(.*)"
    }

    unless result[1]
      pcall -> ExceptionRequests\create {
        :req
        msg: err
        :trace
      }

      return nil, err, trace

    unpack result, 2


protected_call = (...) ->
  protect(...)!

{ :protect, :protected_call, :VERSION }
