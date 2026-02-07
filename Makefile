# VibeKanban Slash Commands - Release Automation
#
# Usage:
#   make release VERSION=0.4 DATE=2026-03-01    # stamp all commands with new version/date
#   make release VERSION=0.4                     # uses today's date
#   make version                                 # show current version
#   make check                                   # verify all commands have consistent metadata
#   make install                                 # install commands (copy mode)
#   make install-link                            # install commands (symlink mode)
#   make uninstall                               # remove installed commands

SHELL := /bin/bash
COMMANDS_DIR := commands
VERSION_FILE := VERSION
CURRENT_VERSION := $(shell cat $(VERSION_FILE) 2>/dev/null || echo "unknown")
DATE ?= $(shell date +%Y-%m-%d)
COMMAND_FILES := $(wildcard $(COMMANDS_DIR)/*.md)

.PHONY: release version check install install-link uninstall help

help: ## Show this help
	@echo "VibeKanban Slash Commands - Release Automation"
	@echo ""
	@echo "Current version: $(CURRENT_VERSION)"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

version: ## Show current version and date from VERSION file
	@echo "Version: $(CURRENT_VERSION)"
	@echo "Commands: $(words $(COMMAND_FILES)) files in $(COMMANDS_DIR)/"
	@echo ""
	@echo "Per-command versions:"
	@for f in $(COMMAND_FILES); do \
		v=$$(grep -m1 '^version:' "$$f" 2>/dev/null | sed 's/version: *//'); \
		d=$$(grep -m1 '^date:' "$$f" 2>/dev/null | sed 's/date: *//'); \
		name=$$(basename "$$f" .md); \
		printf "  %-20s %s (%s)\n" "$$name" "$${v:-[missing]}" "$${d:-[missing]}"; \
	done

check: ## Verify all commands have consistent version metadata
	@echo "Checking metadata consistency..."
	@errors=0; \
	for f in $(COMMAND_FILES); do \
		name=$$(basename "$$f" .md); \
		v=$$(grep -m1 '^version:' "$$f" 2>/dev/null | sed 's/version: *//'); \
		d=$$(grep -m1 '^date:' "$$f" 2>/dev/null | sed 's/date: *//'); \
		a=$$(grep -m1 '^author:' "$$f" 2>/dev/null | sed 's/author: *//'); \
		r=$$(grep -m1 '^repository:' "$$f" 2>/dev/null | sed 's/repository: *//'); \
		if [ -z "$$v" ]; then echo "  MISSING version: $$name"; errors=$$((errors+1)); fi; \
		if [ -z "$$d" ]; then echo "  MISSING date:    $$name"; errors=$$((errors+1)); fi; \
		if [ -z "$$a" ]; then echo "  MISSING author:  $$name"; errors=$$((errors+1)); fi; \
		if [ -z "$$r" ]; then echo "  MISSING repo:    $$name"; errors=$$((errors+1)); fi; \
		if [ -n "$$v" ] && [ "$$v" != "$(CURRENT_VERSION)" ]; then \
			echo "  MISMATCH version: $$name has '$$v', expected '$(CURRENT_VERSION)'"; \
			errors=$$((errors+1)); \
		fi; \
	done; \
	if [ $$errors -eq 0 ]; then \
		echo "All $(words $(COMMAND_FILES)) commands have consistent metadata (version $(CURRENT_VERSION))"; \
	else \
		echo ""; \
		echo "$$errors issue(s) found."; \
		exit 1; \
	fi

release: ## Stamp all commands with VERSION and DATE (e.g., make release VERSION=0.4)
ifndef VERSION
	$(error VERSION is required. Usage: make release VERSION=0.4 [DATE=2026-03-01])
endif
	@echo "Releasing version $(VERSION) (date: $(DATE))"
	@echo ""
	@echo "$(VERSION)" > $(VERSION_FILE)
	@echo "Updated $(VERSION_FILE) -> $(VERSION)"
	@for f in $(COMMAND_FILES); do \
		name=$$(basename "$$f" .md); \
		sed -i '' 's/^version: .*/version: $(VERSION)/' "$$f"; \
		sed -i '' 's/^date: .*/date: $(DATE)/' "$$f"; \
		echo "  Updated: $$name -> $(VERSION) ($(DATE))"; \
	done
	@echo ""
	@echo "Done. $(words $(COMMAND_FILES)) commands stamped with version $(VERSION)."
	@echo ""
	@echo "Next steps:"
	@echo "  1. Update the Version History table in README.md"
	@echo "  2. Review changes: git diff"
	@echo "  3. Commit: git add -A && git commit -m 'Release $(VERSION)'"
	@echo "  4. Tag: git tag -a v$(VERSION) -m 'Release $(VERSION)'"
	@echo "  5. Push: git push origin main --tags"
	@echo "  6. Re-install: ./install.sh --force"

install: ## Install commands (copy mode)
	@./install.sh --force

install-link: ## Install commands (symlink mode)
	@./install.sh --link --force

uninstall: ## Remove installed commands
	@./install.sh --uninstall
