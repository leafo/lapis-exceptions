
config = require "lapis.config"

config "test", ->
  postgres {
    database: "lapis_exceptions_test"
  }

import exec from require "lapis.cmd.path"
import use_test_env from require "lapis.spec"

with_query_fn = (q, run) ->
  db = require "lapis.db.postgres"
  old_query = db.set_backend "raw", q
  if not run
    -> db.set_backend "raw", old_query
  else
    with run!
      db.set_backend "raw", old_query

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

describe "lapis.exceptions", ->
  use_test_env!

  describe "with database", ->
    import ExceptionRequests, ExceptionTypes from require "lapis.exceptions.models"

    setup ->
      exec "dropdb -U postgres lapis_exceptions_test &> /dev/null"
      exec "createdb -U postgres lapis_exceptions_test"
      require("lapis.exceptions.schema").run_migrations!

    it "fetches empty exceptions", ->
      assert.same {}, ExceptionRequests\select!

    it "creates a new exception request", ->
      ExceptionRequests\create nil, "There was a problem", "lua:123"
      assert.same 1, ExceptionRequests\count!
      assert.same 1, ExceptionTypes\count!

    it "deletes exception type", ->
      etype = ExceptionTypes\create label: "some error"
      etype\delete!

  describe "normalize label", ->
    it "should normalize label", ->
      import ExceptionTypes from require "lapis.exceptions.models"
      assert.same {
        "./lapis/application.lua:589: what the heck"
        "./lapis/application.lua:589: ./app.lua:235: attempt to index global [STRING] (a nil value)"
        "./app.lua:246: attempt to index global [STRING] (a nil value)"
        "./lapis/nginx/postgres.lua:51: header part is incomplete: select [NUMBER] from hello_world where name = [STRING]"
      }, [ExceptionTypes\normalize_error err for err in *errors]

  describe "protect", ->
    local queries, restore_query

    before_each ->
      queries = {}
      restore_query = with_query_fn (q) ->
        table.insert queries, q

        if q\lower!\match "^insert"
          { {} }
        else
          {}

    after_each ->
      restore_query!

    it "should run a function with no errors", ->
      import protect from require "lapis.exceptions"

      wrapped = protect ->
        "a", 2+4, "no"

      a,b,c = wrapped!

      assert.same "a", a
      assert.same 6, b
      assert.same "no", c


    it "should do something with error function", ->
      import protect from require "lapis.exceptions"

      wrapped = protect ->
        a = 1243
        error "i'm broken"
        true

      res = wrapped!
      assert.falsy res
      assert.same 4, #queries


