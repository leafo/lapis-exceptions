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
import exec from require "lapis.cmd.path"
exec "dropdb -U postgres lapis_exceptions_test &> /dev/null"
exec "createdb -U postgres lapis_exceptions_test"
require("lapis.exceptions.schema").run_migrations!
env.pop!
