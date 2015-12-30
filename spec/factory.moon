models = require "lapis.exceptions.models"

random_string = (length) ->
  string.char unpack [math.random 65, 90 for i=1,length ]

ExceptionRequests = (opts={}) ->
  opts.msg or= "Some error #{random_string 10}"
  opts.trace or= "Some random traceback\n#{random_string 10}"
  assert models.ExceptionRequests\create opts

ExceptionTypes = (opts) ->
  error "not yet"

{:ExceptionRequests, :ExceptionTypes}
