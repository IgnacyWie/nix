SHELL := /bin/sh

.DEFAULT_GOAL := help

.PHONY: help check fmt eval-gamma build-gamma eval-eta build-eta apply-gamma apply-eta apply-eta-remote bootstrap-apply-gamma homebrew-cleanup-preview check-karabiner-edn install-pre-commit-hook collect-eta-docker-orbstack-inventory

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

eval-eta: ## Evaluate the eta Darwin system output.
	./scripts/eval-eta

build-eta: ## Build the eta Darwin system closure without applying it.
	./scripts/build-eta

apply-gamma: ## Apply the gamma Darwin configuration using the installed darwin-rebuild.
	./scripts/apply-gamma

apply-eta: ## Apply the eta Darwin configuration using the installed darwin-rebuild.
	./scripts/apply-eta

apply-eta-remote: ## SSH to eta and apply the eta Darwin configuration from ~/nix.
	./scripts/apply-eta-remote

bootstrap-apply-gamma: ## Apply gamma during first bootstrap through pinned nix-darwin.
	./scripts/bootstrap-apply-gamma

homebrew-cleanup-preview: ## Preview zap cleanup from the evaluated gamma Brewfile.
	./scripts/homebrew-cleanup-preview

check-karabiner-edn: ## Compare Goku output from config/karabiner.edn with tracked Karabiner JSON.
	./scripts/check-karabiner-edn

install-pre-commit-hook: ## Configure this clone to use repository Git hooks.
	./scripts/install-pre-commit-hook

collect-eta-docker-orbstack-inventory: ## Collect raw local Docker/OrbStack inventory from eta without committing it.
	./scripts/collect-eta-docker-orbstack-inventory
