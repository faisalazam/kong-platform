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
    logs \
    ci-logs \
    cleanup-lambdas \
    reset-localstack

help:
	@echo "Targets:"
	@echo "  up                Start docker-compose services"
	@echo "  down              Shutdown docker-compose services and volumes"
	@echo "  init              Initialize Kong"
	@echo "  sync              Validate Kong configuration and optionally sync"
	@echo "  test              Run test suite"
	@echo "  list-tests        List available tests"
	@echo "  logs              Follow docker-compose logs"
	@echo "  ci-logs           Print docker-compose logs for CI debugging"
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

logs:
	godotenv -o -f $(ENV_FILE) docker compose logs -f --tail=200

ci-logs:
	@echo "---- Docker Compose Logs ----"
	godotenv -o -f $(ENV_FILE) docker compose logs --no-color --tail=500
	@echo "---- End Docker Compose Logs ----"
