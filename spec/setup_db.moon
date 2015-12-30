config = require "lapis.config"

config "test", ->
  postgres {
    database: "lapis_exceptions_test"
  }

env = require "lapis.environment"
env.push "test"
require("spec.helpers").create_db!
env.pop!
