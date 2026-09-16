# AWS Onboarding API CMDB - Kong POC

## Overview

A local Kong proof of concept for evaluating the migration of CMDB APIs away from API Gateway.

The local Kong environment is intentionally configured to mirror the production architecture:

```text
Kong → PostgreSQL → decK
```

Production Kong is database-backed and managed using decK.

---

## Directory Structure

```text
kong
├── docker-compose.yml
├── services
│   ├── cmdb-api.yml       # Kong -> API Gateway
│   └── directory-api.yml  # Kong -> API Gateway
├── plugins
├── scripts
│   └── run.sh
└── README.md
```

### Source of Truth

Configuration is maintained in:

```text
services/*.yml
plugins/*.yml
```

### Generated Artifact

Generates an `services/.generated/empty_kong.yml` only if `services` folder is empty so that kong can start up fine:

```bash
./scripts/build.sh
```

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

Start PostgreSQL and Kong:

```bash
docker compose up -d
```

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

## Build Configuration

Generate and validate the Kong manifest:

```bash
./scripts/build.sh
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

---

## Synchronize Configuration

Build and synchronize configuration into Kong:

```bash
./scripts/deploy.sh
```

Equivalent manual command:

```bash
deck gateway sync \
  --kong-addr http://localhost:8001 \
  generated/kong.yml
```

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
  --kong-addr http://localhost:8001 \
  generated/kong.yml
```

---

## Test Route

Current route:

```bash
curl http://localhost:8000/account_category
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

2. Build and validate:

```bash
./scripts/build.sh
```

3. Apply changes:

```bash
./scripts/deploy.sh
```

4. Test through Kong:

```bash
curl http://localhost:8000/<route>
```

---

## Notes

- Kong configuration is managed as code.
- The generated `generated/kong.yml` file is an implementation artifact and should not be edited manually.
- decK is used to synchronize configuration into Kong.
- Local development mirrors the production Kong architecture as closely as possible.


_format_version: "3.0"

## PoC note:

The upstream API Gateway is protected by resource policies and is not
publicly callable by default.

To test Kong → API Gateway routing, resource policies may need to be
temporarily updated to allow invocation of specific API resources.

Depending on the target API:
  - Method Authorization may need to be set to NONE
  - API Gateway resource policies may need to allow the required paths
  - The API must be redeployed after applying policy changes

Example endpoints used during development:
  - GET /ad/groups (directory-api)
  - GET /account_category (cmdb-api)

Policy requirements are API-specific and should be tailored to the
resources being exposed through Kong.
