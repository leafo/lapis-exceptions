local run_migrations
run_migrations = function(version)
  local m = require("lapis.db.migrations")
  local migrations = require("lapis.exceptions.migrations")
  if version and not migrations[tonumber(version)] then
    local versions
    do
      local _accum_0 = { }
      local _len_0 = 1
      for key in pairs(migrations) do
        _accum_0[_len_0] = key
        _len_0 = _len_0 + 1
      end
      versions = _accum_0
    end
    table.sort(versions)
    local available_version = versions[#versions]
    error("Expected to migrate to lapis-exceptions version " .. tostring(version) .. " but it was not found (have " .. tostring(available_version) .. "). Did you forget to update lapis-exceptions?")
  end
  return m.run_migrations(migrations, "lapis_exceptions")
end
return {
  run_migrations = run_migrations
}
