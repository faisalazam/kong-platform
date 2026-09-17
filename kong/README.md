# AWS Onboarding APIs - Kong POC

## Overview

A local Kong proof of concept for evaluating AWS Onboarding API integration patterns and migration options.

The PoC evaluates two architectures:

- Kong → API Gateway → Lambda
- Kong → Lambda

using the CMDB and Directory APIs.

The local Kong environment is intentionally configured to mirror the production architecture:

```text
Kong → PostgreSQL → decK
```

Production Kong is database-backed and managed using decK.

---

## POC Architectures Evaluated

### Kong → API Gateway → Lambda

Used by:

1. services/cmdb-api.yml
2. services/directory-api.yml

### Kong → AWS Lambda

Used by:

1. services/cmdb-lambda.yml
2. services/directory-lambda.yml

The direct Lambda approach uses Kong's aws-lambda plugin and bypasses API Gateway entirely.

---

## Directory Structure

```text
kong
├── .config
│   ├── local.deck.yml
│   └── local.env
├── docker-compose.yml
├── README.md
├── scripts
│   ├── sync-kong.sh
│   └── start-kong.sh
└── services
    ├── cmdb-api.yml         # Kong -> API Gateway
    ├── cmdb-lambda.yml      # Kong -> Lambda
    ├── directory-api.yml    # Kong -> API Gateway
    └── directory-lambda.yml # Kong -> Lambda
```

### Source of Truth

Kong configuration is maintained as code.

```text
.config/
services/
```

- .config/local.env contains environment-specific variables.
- .config/local.deck.yml contains decK configuration.
- services/*.yml contains Kong services, routes and plugins.

---

## Prerequisites

### Install Docker

Ensure Docker Desktop is installed and running.

### Install decK

```bash
brew install kong/deck/deck
```

---

## Start Kong

Login to AWS:

```bash
aws login --profile cloud-automation-dev
```

Start kong:

```bash
./scripts/start-kong.sh
```

`start-kong.sh` exports AWS credentials and recreates the Kong container.

Run it again whenever the AWS session expires.

---

## Verify Kong

Check Kong Admin API:

```bash
curl http://localhost:8001
```

Check Kong status:

```bash
curl http://localhost:8001/status
```

For Kong admin GUI, navigate to http://localhost:8002

---

## Validate and Synchronize Configuration

Validates and synchronizes configuration into Kong:

```bash
./scripts/sync-kong.sh
```

Successful output:

```text
INFO: Kong directory: ...
INFO: Environment: local
INFO: Loading environment variables
INFO: Validating Kong configuration
SUCCESS: Kong configuration is valid
INFO: Synchronizing Kong configuration
...
SUCCESS: Kong configuration synchronized
```

### Empty Configuration Handling

If no service definitions exist under:

```text
services/
```

`sync-kong.sh` automatically generates: `services/.generated/empty_kong.yml`. This allows decK validation and Kong startup to
succeed even when no service definitions are present.

---

## Inspect Current Kong Configuration

Export current Kong state:

```bash
deck gateway dump \
  --kong-addr http://localhost:8001
```

Preview planned changes without applying them:

```bash
deck gateway diff \
  --config .config/local.deck.yml \
  services
```

---

## Validation Scenarios

The following commands demonstrate both API Gateway-backed and direct Lambda-backed integrations.

### Directory API via API Gateway

```bash
# Kong → API Gateway → Directory API Lambda
curl -i 'http://localhost:8000/poc/api-gateway/directory/ad/groups?domain=TPGT'
```

### Directory API via Direct Lambda Invocation

```bash
# Kong → Directory API Lambda
curl -i 'http://localhost:8000/poc/lambda/directory/ad/groups?domain=TPGT'
```

### CMDB API via API Gateway

```bash
# Kong → API Gateway → CMDB API Lambda
curl -i 'http://localhost:8000/poc/api-gateway/cmdb/account_category'
```

### CMDB API via Direct Lambda Invocation

```bash
# Kong → CMDB API Lambda
curl -i 'http://localhost:8000/poc/lambda/cmdb/account_category'
```

---

## Kong Admin API Examples

List Services:

```bash
curl http://localhost:8001/services
```

List Routes:

```bash
curl http://localhost:8001/routes
```

List Plugins:

```bash
curl http://localhost:8001/plugins
```

---

## Local Development Workflow

### Add or Update a Service

1. Create or modify a file under:

```text
services/
```

2. Validate and Synchronize:

```bash
./scripts/sync-kong.sh
```

3. Validate using one of the scenarios listed in the "Validation Scenarios" section.

---

## Notes

- Kong configuration is managed as code using decK.
- Local Kong uses PostgreSQL, matching the production architecture.
- API Gateway-backed services and direct Lambda-backed services can coexist within the same Kong instance.
- API Gateway resource policy requirements are documented in the corresponding service definition files.
- AWS credentials used by the aws-lambda plugin are exported when Kong starts via `./scripts/start-kong.sh`.
