SHELL := /bin/sh

.DEFAULT_GOAL := help

.PHONY: help check fmt eval-gamma build-gamma apply-gamma bootstrap-apply-gamma check-karabiner-edn install-pre-commit-hook

help: ## Show available repo commands.
	@awk 'BEGIN {FS = ":.*## "; printf "Available targets:\n"} /^[a-zA-Z0-9_-]+:.*## / {printf "  %-24s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

check: ## Validate flake outputs.
	./scripts/check

fmt: ## Format Nix files with the configured flake formatter.
	./scripts/fmt

eval-gamma: ## Evaluate the gamma Darwin system output.
	./scripts/eval-gamma

build-gamma: ## Build the gamma Darwin system closure without applying it.
	./scripts/build-gamma

apply-gamma: ## Apply the gamma Darwin configuration using the installed darwin-rebuild.
	./scripts/apply-gamma

bootstrap-apply-gamma: ## Apply gamma during first bootstrap through pinned nix-darwin.
	./scripts/bootstrap-apply-gamma

check-karabiner-edn: ## Compare Goku output from config/karabiner.edn with tracked Karabiner JSON.
	./scripts/check-karabiner-edn

install-pre-commit-hook: ## Configure this clone to use repository Git hooks.
	./scripts/install-pre-commit-hook
