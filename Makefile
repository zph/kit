src = $(wildcard bin/*.cr) $(wildcard src/*.cr)
output = dist/kit
bin = bin/kit.cr
DIR := ${CURDIR}
output_linux := $(output)-linux-amd64
output_darwin := $(output)-darwin-amd64
installed := ~/bin_local/kit

.PHONY: build
build: $(output_darwin)

.PHONY: install
install: $(installed)

$(installed): $(output_darwin)
	cp -f $(output_darwin) $(installed) && chmod +x $(installed)

.PHONY: clean
clean:
	rm -f dist/*

.PHONY: run
run:
	crystal run $(bin) -- kit.yaml.example

.PHONY: play
play:
	crystal play src/kit.cr

$(output_darwin): $(src)
	crystal build --release $(bin) -o $(output_darwin)

$(output_linux): $(src)
	docker run --rm -it -v $(DIR):/app -w /app durosoft/crystal-alpine crystal build $(bin) -o $(output_linux) --release --static

# Credit: https://relativkreativ.at/articles/how-to-compile-a-crystal-project-with-static-linking
.PHONY: linux
linux: $(output_linux)

all: $(output_linux) $(output_darwin)

# Credit: https://github.com/c4milo/github-release/blob/master/Makefile
# release: dist
# 	@latest_tag=$$(git describe --tags `git rev-list --tags --max-count=1`); \
# 	comparison="$$latest_tag..HEAD"; \
# 	if [ -z "$$latest_tag" ]; then comparison=""; fi; \
# 	changelog=$$(git log $$comparison --oneline --no-merges); \
# 	github-release c4milo/$(NAME) $(VERSION) "$$(git rev-parse --abbrev-ref HEAD)" "**Changelog**<br/>$$changelog" 'dist/*'; \
# 	git pull
release:
	github-release zph/kit $(shell crystal run bin/kit.cr -- --version) "$(git rev-parse --abbrev-ref HEAD)" "MESSAGE" 'dist/kit-*-amd64'

.PHONY: fmt
fmt:
	crystal tool format
