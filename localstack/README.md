# LocalStack

## Overview

This repository uses LocalStack to provide a fully local AWS-compatible environment for validating Kong integrations
with AWS Lambda.

LocalStack allows the proof of concept to:

- Provision Lambda functions automatically
- Exercise Kong's `aws-lambda` plugin locally
- Run automated integration tests without AWS dependencies
- Reproduce routing and compatibility scenarios consistently
- Execute the complete CI test suite locally

The local request path is:

```text
Client
  ↓
Kong
  ↓
aws-lambda Plugin
  ↓
LocalStack
  ↓
Lambda
```

---

# Architecture

LocalStack is started by Docker Compose and acts as the local AWS endpoint.

```text
docker-compose
      ↓
  LocalStack
      ↓
 Lambda APIs
      ↓
 Lambda Runtime Containers
```

The Kong aws-lambda plugin invokes Lambda functions through LocalStack instead of AWS.

---

# Directory Structure

```text
localstack/
├── README.md
├── data/
└── init/
    └── ready.d/
        └── 10-create-lambdas.sh
```

## data/

Optional LocalStack persistence directory.

Used when LocalStack persistence is enabled.

Not committed to source control.

## init/

Contains LocalStack initialization hooks.

Files under:

```text
localstack/init/ready.d/
```

are executed automatically when LocalStack finishes startup.

---

# Lambda Provisioning

Lambda provisioning is performed by:

```text
localstack/init/ready.d/10-create-lambdas.sh
```

The script automatically discovers Lambda source files located under:

```text
tests/lambdas/
```

Example:

```text
tests/lambdas/routing/echo-path.py
```

becomes:

```text
echo-path
```

within LocalStack.

Provisioning occurs automatically whenever the LocalStack container starts.

No manual Lambda creation is required.

---

# Lambda Naming Convention

Function names are derived from filenames.

Example:

```text
localstack-smoke-test.py
```

↓

```text
localstack-smoke-test
```

This convention keeps Kong configuration, Lambda implementations, and test scenarios easy to correlate.

---

# LocalStack Multi-Account Configuration

This repository intentionally uses LocalStack's multi-account model.

Within LocalStack:

```text
AWS_ACCESS_KEY_ID
```

acts as the account identifier.

Example:

```text
AWS_ACCESS_KEY_ID=179857410264
```

represents a distinct LocalStack account.

For this reason:

```text
AWS profiles should not be used inside LocalStack initialization scripts.
```

The initialization process sets credentials explicitly when provisioning resources.

---

# Lambda Runtime Containers

LocalStack executes Lambda functions inside runtime containers.

Example container names:

```text
kong-aws-localstack-lambda-echo-path-*
kong-aws-localstack-lambda-event-dump-*
kong-aws-localstack-lambda-chalice-fixed-*
```

These containers are:

- Dynamically created
- Not managed by docker-compose
- Created on first invocation
- Reused by LocalStack where possible

---

# Resetting LocalStack

Over time LocalStack may retain stale references to Lambda runtime containers.

This can occur after:

```text
Container deletion
Repeated test runs
Interrupted executions
Local experimentation
```

Symptoms may include:

```text
Invocation failures
Unexpected timeouts
Hung Lambda executions
```

Remove Lambda runtime containers:

```bash
make cleanup-lambdas
```

Perform a full LocalStack reset:

```bash
make reset-localstack
```

The reset process:

```text
Remove runtime containers
       ↓
Restart LocalStack
       ↓
Recreate runtime state
```

This is the preferred recovery mechanism when Lambda execution behaves unexpectedly.

---

# Health Verification

Verify LocalStack health:

```bash
curl http://localhost:4566/_localstack/health
```

Expected result:

```json
{
  "services": {
    ...
  }
}
```

Verify Lambda inventory:

```bash
godotenv -o -f ./.config/local.env \
aws \
  --endpoint-url http://localhost:4566 \
  lambda list-functions
```

---

# Relationship To Tests

LocalStack is tightly integrated with the automated test suite.

The tests provide:

```text
Lambda source files
Kong test configurations
Integration scenarios
```

See:

```text
tests/README.md
```

for test architecture and scenario documentation.

See:

```text
tests/framework/README.md
```

for framework implementation details.

---

# Design Principles

The LocalStack environment is intended to provide:

- Fast local feedback
- Deterministic test execution
- Reproducible Kong integrations
- Minimal dependency on AWS
- CI-equivalent behaviour

The goal is to validate Kong-to-Lambda behaviour through complete end-to-end execution paths rather than isolated
unit-style checks.
