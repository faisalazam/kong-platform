# Kong Platform - AWS Onboarding APIs

## Overview

A local Kong proof of concept for evaluating AWS Onboarding API integration patterns and migration options.

## Goal

This proof of concept evaluates whether Kong can invoke AWS Lambda functions directly using the aws-lambda plugin,
eliminating the API Gateway dependency while preserving routing, observability, and policy management capabilities.

The PoC compares:

- Kong → API Gateway → Lambda
- Kong → Lambda

for both the CMDB and Directory APIs.

The local Kong environment is intentionally configured to mirror the production architecture:

```text
Kong → PostgreSQL → decK
```

The production Kong platform is database-backed and managed using decK.

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
.
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

Kong configuration is managed declaratively using decK.

The synchronization process:

1. Loads environment variables from `.config/local.env`
2. Validates Kong configuration
3. Computes differences against the running Kong instance
4. Applies configuration changes to Kong

```bash
./scripts/sync-kong.sh

#OR

ENVIRONMENT=dev ./scripts/sync-kong.sh
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

`sync-kong.sh` automatically generates: `services/.generated/empty_kong.yml`. This allows decK validation and Kong
startup to succeed even when no service definitions are present.

---

## Inspect Current Kong Configuration

Export current Kong state:

```bash
deck \
  --config .config/local.deck.yml \
  gateway dump
```

Preview planned changes without applying them:

```bash
deck \
  --config .config/local.deck.yml \
  gateway diff \
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

### Service Lifecycle

All Kong services, routes, and plugins are managed as code.

Each service definition should be maintained in its own YAML file under:

```text
services/
```

Changes should always be validated and synchronized using:

```bash
./scripts/sync-kong.sh
```

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

## Troubleshooting

### AWS Lambda Invocation Fails After AWS Credentials Expire

**Symptoms**

```text
failed to sign request:
failed to get credentials:
none of the providers succeeded,
no credentials available
```

or

```text
HTTP/1.1 500 Internal Server Error
```

**Cause**

The `aws-lambda` plugin requires valid AWS credentials to sign Lambda invocation requests. Once the AWS session expires, Kong can no longer invoke Lambda functions.

**Resolution**

Re-export AWS credentials and restart Kong:

```bash
./scripts/start-kong.sh
```

If the AWS login session has also expired:

```bash
aws login --profile cloud-automation-dev

./scripts/start-kong.sh
```

---

### API Gateway Returns "Missing Authentication Token"

**Symptoms**

```json
{
  "message": "Missing Authentication Token"
}
```

**Cause**

The request path forwarded to API Gateway does not match a configured API resource.

This can occur when:

- `strip_path` is incorrectly configured
- the API Gateway resource does not exist
- the API Gateway stage was not redeployed after resource changes

**Resolution**

Verify:

- route configuration in Kong
- API Gateway resource path
- API Gateway deployment status

API-specific requirements are documented in:

```text
services/cmdb-api.yml
services/directory-api.yml
```

---

### Chalice Lambda Fails When Invoked Through Kong

**Symptoms**

```text
KeyError: 'stageVariables'
```

or

```text
KeyError: 'resource'
```

**Cause**

Kong OSS 3.9.3 with:

```yaml
awsgateway_compatible: true
```

generates an API-Gateway-like event but not a fully compatible API Gateway REST API (AWS_PROXY) event.

Compared to a native API Gateway invocation:

- `stageVariables` is omitted
- `resource` is omitted
- `requestContext` differs
- body encoding behaviour differs

Chalice 1.32.0 expects certain API Gateway REST API fields to be present and can fail when they are missing.

**Resolution**

Normalize the incoming event before passing it to Chalice:

```python
def normalize_kong_event(event):
    event.setdefault("stageVariables", None)
    event.setdefault("resource", event.get("path"))

    return event


def lambda_handler(event, context):
    return app(
        normalize_kong_event(event),
        context,
    )
```

Update the Lambda runtime handler to use:

```python
lambda_handler
```

instead of the default Chalice handler.

Also update:

```text
Configuration → Runtime settings → Handler
```

to point to:

```text
lambda_handler
```

if it is not already configured.

**Notes**

Native API Gateway provides:

```json
{
  "stageVariables": null,
  "resource": "/resource/path"
}
```

Kong OSS 3.9.3 does not include these fields, even when:

```yaml
awsgateway_compatible: true
```

The normalization layer restores compatibility with Chalice applications.

---

### Kong → Lambda Routes Fail After Adding PoC Prefixes

**Symptoms**

```text
Unexpected route errors
```

or

```json
{
  "message": "Missing Authentication Token"
}
```

after introducing PoC-specific route prefixes.

**Cause**

The Lambda expects the original application path:

```text
/ad/groups
/account_category
```

but may receive:

```text
/poc/lambda/directory/ad/groups
```

if route prefixes are not stripped before invocation.

**Resolution**

Use:

```yaml
strip_path: true
```

when introducing PoC route prefixes.

Example:

```yaml
paths:
  - /poc/lambda/directory

strip_path: true
```

This transforms:

```text
/poc/lambda/directory/ad/groups → ad/groups
```

before invoking the Lambda function.

---

## Notes

- Kong configuration is managed as code using decK.
- Local Kong uses PostgreSQL, matching the production architecture.
- API Gateway-backed services and direct Lambda-backed services can coexist within the same Kong instance.
- API Gateway resource policy requirements are documented in the corresponding service definition files.
- AWS credentials used by the aws-lambda plugin are exported when Kong starts via `./scripts/start-kong.sh`.
