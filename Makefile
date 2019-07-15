src = $(wildcard bin/*.cr) $(wildcard src/*.cr)
output = dist/kit
bin = bin/kit.cr
DIR := ${CURDIR}
output_linux := $(output)-linux-amd64
output_darwin := $(output)-darwin-amd64
installed := ~/bin_local/kit

build: $(output_darwin)

install: $(installed)

$(installed): $(output_darwin)
	cp -f $(output_darwin) $(installed) && chmod +x $(installed)

clean:
	rm -f dist/*

run:
	crystal run $(bin) -- kit.yaml.example

play:
	crystal play src/kit.cr

$(output_darwin): $(src)
	crystal build --release $(bin) -o $(output_darwin)

$(output_linux): $(src)
	docker run --rm -it -v $(DIR):/app -w /app durosoft/crystal-alpine crystal build $(bin) -o $(output_linux) --release --static

# Credit: https://relativkreativ.at/articles/how-to-compile-a-crystal-project-with-static-linking
linux: $(output_linux)

all: $(output_linux) $(output_darwin)


test:
	bats spec/acceptance.bats && crystal spec

# Credit: https://github.com/c4milo/github-release/blob/master/Makefile
# release: dist
# 	@latest_tag=$$(git describe --tags `git rev-list --tags --max-count=1`); \
# 	comparison="$$latest_tag..HEAD"; \
# 	if [ -z "$$latest_tag" ]; then comparison=""; fi; \
# 	changelog=$$(git log $$comparison --oneline --no-merges); \
# 	github-release c4milo/$(NAME) $(VERSION) "$$(git rev-parse --abbrev-ref HEAD)" "**Changelog**<br/>$$changelog" 'dist/*'; \
# 	git pull
release: all
	@latest_tag=$$(git describe --tags `git rev-list --tags --max-count=1`) && \
	comparison="$$latest_tag..HEAD" && \
	if [ -z "$$latest_tag" ]; then comparison=""; fi && \
	changelog=$$(git log $$comparison --oneline --no-merges) && \
	./data/github-release zph/kit v$(shell crystal run bin/kit.cr -- --version) "$(shell git rev-parse --abbrev-ref HEAD)" "**Changelog**<br/>$$changelog" 'dist/kit-*-amd64' && \
		git pull

fmt:
	crystal tool format

.PHONY: run play linux fmt clean
