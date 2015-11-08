local run_migrations
run_migrations = function()
  local m = require("lapis.db.migrations")
  return m.run_migrations(require("lapis.exceptions.migrations"), "lapis_exceptions")
end
return {
  run_migrations = run_migrations
}
