ENVIRONMENT ?= local
ENV_FILE := .config/$(ENVIRONMENT).env

.PHONY: \
    help \
    up \
    down \
    init \
    sync \
    test \
    list-tests \
    cleanup-lambdas \
    reset-localstack

help:
	@echo "Targets:"
	@echo "  up                Start docker-compose services"
	@echo "  down              Shutdown docker-compose services and volumes"
	@echo "  init              Initialize Kong and sync configuration"
	@echo "  sync              Validate Kong configuration and optionally sync"
	@echo "  test              Run test suite"
	@echo "  list-tests        List available tests"
	@echo "  cleanup-lambdas   Remove LocalStack Lambda runtime containers"
	@echo "  reset-localstack  Reset LocalStack runtime state"

up:
	godotenv -o -f $(ENV_FILE) docker compose up -d
	$(MAKE) init ENVIRONMENT=$(ENVIRONMENT)
	$(MAKE) sync ENVIRONMENT=$(ENVIRONMENT)

down:
	$(MAKE) cleanup-lambdas
	godotenv -o -f $(ENV_FILE) docker compose down -v

init:
	godotenv -o -f $(ENV_FILE) \
		./scripts/init-kong.sh

sync:
	godotenv -o -f $(ENV_FILE) \
		./scripts/sync-kong.sh

test:
	godotenv -o -f $(ENV_FILE) \
		./tests/run-tests.sh

list-tests:
	./tests/run-tests.sh --list

cleanup-lambdas:
	./scripts/cleanup-lambdas.sh

reset-localstack:
	godotenv -o -f $(ENV_FILE) \
		./scripts/reset-localstack.sh
