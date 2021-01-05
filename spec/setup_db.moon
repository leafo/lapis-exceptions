config = require "lapis.config"

config "test", ->
  track_exceptions true
  logging false -- hide query logs

  postgres {
    database: "lapis_exceptions_test"

    host: os.getenv "PGHOST"
    user: os.getenv "PGUSER"
    password: os.getenv "PGPASSWORD"
  }

env = require "lapis.environment"
env.push "test"
require("spec.helpers").create_db!
env.pop!
