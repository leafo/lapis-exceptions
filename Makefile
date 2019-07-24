
test:
	busted --helper=spec/setup_db.moon

lint: build
	moonc -l lapis

local: build
	luarocks --lua-version=5.1 make --local lapis-exceptions-dev-1.rockspec

build:
	moonc lapis
