run_migrations = ->
  m = require "lapis.db.migrations"
  m.run_migrations require("lapis.exceptions.migrations"), "lapis_exceptions"

{ :run_migrations }
