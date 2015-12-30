
test:
	busted --helper=spec/setup_db.moon

lint: build
	moonc -l lapis

local: build
	luarocks make --local lapis-exceptions-dev-1.rockspec

build:
	moonc lapis
