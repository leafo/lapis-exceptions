import use_test_env from require "lapis.spec"
import truncate_tables from require "lapis.spec.db"

errors = {
[[./lapis/application.lua:589: what the heck
stack traceback:
	[builtin#19]: at 0x7f20cb4c80d0]]

[[./lapis/application.lua:589: ./app.lua:235: attempt to index global 'x' (a nil value)
stack traceback:
	./app.lua: in function <./app.lua:234>]]

[[./app.lua:246: attempt to index global 'a' (a nil value)]]


[[./lapis/nginx/postgres.lua:51: header part is incomplete: select 123 from hello_world where name = 'yeah']]
}

import ExceptionRequests, ExceptionTypes from require "lapis.exceptions.models"

describe "lapis.exceptions", ->
  use_test_env!

  describe "normalize label", ->
    it "should normalize label", ->
      assert.same {
        "./lapis/application.lua:589: what the heck"
        "./lapis/application.lua:589: ./app.lua:235: attempt to index global [STRING] (a nil value)"
        "./app.lua:246: attempt to index global [STRING] (a nil value)"
        "./lapis/nginx/postgres.lua:51: header part is incomplete: select [NUMBER] from hello_world where name = [STRING]"
      }, [ExceptionTypes\normalize_error err for err in *errors]

  describe "feature", ->
    lapis = require "lapis"
    import mock_request from require "lapis.spec.request"

    before_each ->
      truncate_tables ExceptionRequests, ExceptionTypes

    it "installs app feature", ->
      class App extends lapis.Application
        @enable "exception_tracking"

        "/throw-error": =>
          error "this is broken"

      mock_request App, "/throw-error", {
        allow_error: true
      }

      assert.same 1, ExceptionRequests\count!
      assert.same 1, ExceptionTypes\count!

      req = unpack ExceptionRequests\select!
      assert.truthy req.msg\find("this is broken") > 0


  describe "protect", ->
    before_each ->
      truncate_tables ExceptionRequests, ExceptionTypes

    it "should run a function with no errors", ->
      import protect from require "lapis.exceptions"

      wrapped = protect ->
        "a", 2+4, "no"

      a,b,c = wrapped!

      assert.same "a", a
      assert.same 6, b
      assert.same "no", c

      assert.same 0, ExceptionRequests\count!
      assert.same 0, ExceptionTypes\count!

    it "should do something with error function", ->
      import protect from require "lapis.exceptions"

      wrapped = protect ->
        a = 1243
        error "i'm broken"
        true

      res = wrapped!
      assert.falsy res

      assert.same 1, ExceptionRequests\count!
      assert.same 1, ExceptionTypes\count!

      req = unpack ExceptionRequests\select!
      assert.truthy req.msg\find("i'm broken") > 0
