package = "lapis_console"
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
  "lapis"
}

build = {
  type = "builtin",
  modules = {
  }
}

