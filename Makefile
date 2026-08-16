.PHONY: render-configs gen-configs

ENV_FILE := compose-bridge/.env
TEMPLATE_FILES := $(shell find compose-bridge/configs -type f -name '*.tpl' | sort)
OUTPUT_FILES := $(patsubst %.tpl,%,$(TEMPLATE_FILES))

SHELL := /bin/bash

check-env:
	@test -f "$(ENV_FILE)" || { echo "Missing env file: $(ENV_FILE)"; exit 1; }

gen-configs: check-env $(OUTPUT_FILES)

%: %.tpl
	@mkdir -p $(dir $@)
	@echo "Generating $< -> $@"
	@set -a; . "$(ENV_FILE)"; set +a; envsubst < "$<" > "$@"

all: gen-configs
