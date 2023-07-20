
test::
	busted --helper=spec/setup_db.moon -o utfTerminal

tags::
	moon-tags --lapis $$(git ls-files lapis/) > $@

annotate::
	LAPIS_ENVIRONMENT=test lapis annotate --preload-module=spec.setup_db lapis/exceptions/models/*.moon

lint: build
	moonc -l lapis

local: build
	luarocks --lua-version=5.1 make --local lapis-exceptions-dev-1.rockspec

build:
	moonc lapis
