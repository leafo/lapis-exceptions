package = "lapis-exceptions"
version = "dev-1"

source = {
  url = "git://github.com/leafo/lapis-exceptions.git"
}

description = {
  summary = "Track Lapis exceptions to database and email when they happen",
  license = "MIT",
  maintainer = "Leaf Corcoran <leafot@gmail.com>",
}

dependencies = {
  "lua == 5.1",
  "lapis",
  "date",
}

build = {
  type = "builtin",
  modules = {
    ["lapis.exceptions"] = "lapis/exceptions.lua",
    ["lapis.exceptions.email"] = "lapis/exceptions/email.lua",
    ["lapis.exceptions.flow"] = "lapis/exceptions/flow.lua",
    ["lapis.exceptions.migrations"] = "lapis/exceptions/migrations.lua",
    ["lapis.exceptions.model"] = "lapis/exceptions/model.lua",
    ["lapis.exceptions.models"] = "lapis/exceptions/models.lua",
    ["lapis.exceptions.models.exception_requests"] = "lapis/exceptions/models/exception_requests.lua",
    ["lapis.exceptions.models.exception_types"] = "lapis/exceptions/models/exception_types.lua",
    ["lapis.exceptions.schema"] = "lapis/exceptions/schema.lua",
    ["lapis.features.exception_tracking"] = "lapis/features/exception_tracking.lua",
  }
}

