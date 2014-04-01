
import normalize_error from require "lapis.exceptions.models"

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
  describe "normalize label", ->
    it "should normalize label", ->
      assert.same {
        "./lapis/application.lua:589: what the heck"
        "./lapis/application.lua:589: ./app.lua:235: attempt to index global [STRING] (a nil value)"
        "./app.lua:246: attempt to index global [STRING] (a nil value)"
        "./lapis/nginx/postgres.lua:51: header part is incomplete: select [NUMBER] from hello_world where name = [STRING]"
      }, [normalize_error err for err in *errors]

