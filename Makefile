
test:
	busted

lint: build
	moonc -l lapis

local: build
	luarocks make --local lapis_console-dev-1.rockspec

build:
	moonc lapis
