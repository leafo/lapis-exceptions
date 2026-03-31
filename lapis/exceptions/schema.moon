run_migrations = (version) ->
  m = require "lapis.db.migrations"

  migrations = require("lapis.exceptions.migrations")

  if version and not migrations[tonumber version]
    versions = [key for key in pairs migrations]
    table.sort versions
    available_version = versions[#versions]
    error "Expected to migrate to lapis-exceptions version #{version} but it was not found (have #{available_version}). Did you forget to update lapis-exceptions?"

  m.run_migrations migrations, "lapis_exceptions"

{ :run_migrations }
