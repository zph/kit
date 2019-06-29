src = $(wildcard bin/*.cr) $(wildcard src/*.cr)
output = dist/pk
bin = bin/pk.cr

build: $(output)

.PHONY: clean
clean:
	rm -f data/*

.PHONY: run
run:
	crystal run bin/pk.cr

.PHONY: play
play:
	crystal play src/pk.cr

$(output): $(src)
	crystal build --release $(bin) -o $(output)

.PHONY: linux
linux:
	docker run --rm -it -v $((PWD)):/app -w /app durosoft/crystal-alpine crystal build $(bin) -o $(output) --release --static

.PHONY: fmt
fmt:
	crystal tool format
