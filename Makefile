
test:
	busted

lint: build
	moonc -l lapis

local: build
	luarocks make --local lapis_exceptions-dev-1.rockspec

build:
	moonc lapis
