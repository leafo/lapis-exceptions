import mock_request from require "lapis.spec.request"
import Application from require "lapis"

assert = require "luassert"

create_db = ->
  import exec from require "lapis.cmd.path"
  exec "dropdb -U postgres lapis_exceptions_test &> /dev/null"
  exec "createdb -U postgres lapis_exceptions_test"
  require("lapis.exceptions.schema").run_migrations!

class TestApp extends Application
  @get: (path, get={}) =>
    status, res = mock_request @, path, {
      :get
      expect: "json"
    }

    assert.same 200, status
    res


{ :TestApp, :create_db }
