src = $(wildcard bin/*.cr) $(wildcard src/*.cr)
output = dist/pk
bin = bin/pk.cr
DIR := ${CURDIR}
output_linux := $(output)-linux-x86_64
output_darwin := $(output)-darwin-x86_64

build: $(output_darwin)

.PHONY: clean
clean:
	rm -f data/*

.PHONY: run
run:
	crystal run bin/pk.cr

.PHONY: play
play:
	crystal play src/pk.cr

$(output_darwin): $(src)
	crystal build --release $(bin) -o $(output_darwin)

$(output_linux): $(src)
	docker run --rm -it -v $(DIR):/app -w /app durosoft/crystal-alpine crystal build $(bin) -o $(output_linux) --release --static

# Credit: https://relativkreativ.at/articles/how-to-compile-a-crystal-project-with-static-linking
.PHONY: linux
linux: $(output_linux)

all: $(output_linux) $(output_darwin)

.PHONY: fmt
fmt:
	crystal tool format
