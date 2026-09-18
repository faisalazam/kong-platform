# Shell Test Framework

A lightweight shell-based test framework for validating system behaviour through automated test scenarios.

The framework is intentionally minimal and is built around a small set of composable building blocks:

- Generic operation execution
- Generic assertions
- Test-specific assertion strategies
- A simple test runner

The framework currently executes HTTP requests via `curl`, but its architecture allows the execution mechanism to be
replaced without changing the remainder of the framework.

Potential execution targets include:

- HTTP requests via `curl`
- `aws lambda invoke`
- `docker compose exec`
- `kubectl exec`
- Local CLI execution

---

# Directory Structure

```text
framework/
├── README.md
├── run-tests.sh
└── utils
    ├── assert.sh
    ├── bootstrap.sh
    └── common.sh
```

---

# Architecture Overview

The framework combines the Template Method Pattern and the Strategy Pattern.

`execute_test_case()` defines the fixed execution workflow while each test file supplies its own assertion strategy.

```text
┌─────────────────────────────────────────────────────────────────────┐
│                         Test Framework                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────────────┐      ┌──────────────────┐                     │
│  │   Test File      │      │    Bootstrap     │                     │
│  │     (*.sh)       │      │ (bootstrap.sh)   │                     │
│  │                  │      │                  │                     │
│  │ • Source         │◄─────┤ • Source common  │                     │
│  │   bootstrap.sh   │      │ • Source assert  │                     │
│  │ • Define         │      │                  │                     │
│  │   assertions     │      └──────────────────┘                     │
│  │ • Execute test   │                                               │
│  └────────┬─────────┘                                               │
│           │                                                         │
│           ▼                                                         │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │              execute_test_case()                             │   │
│  ├──────────────────────────────────────────────────────────────┤   │
│  │ 1. Parse arguments                                           │   │
│  │ 2. Execute operation                                         │   │
│  │ 3. Extract status                                            │   │
│  │ 4. Extract body                                              │   │
│  │ 5. Execute assertions                                        │   │
│  │ 6. Print failure response                                    │   │
│  │ 7. Record pass/fail                                          │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                     │
│         ┌─────────────────┐     ┌─────────────────┐                 │
│         │   common.sh     │     │   assert.sh     │                 │
│         ├─────────────────┤     ├─────────────────┤                 │
│         │ • Execution     │     │ • Assertions    │                 │
│         │ • Arg parsing   │     │ • Counters      │                 │
│         │ • Response      │     │ • Failure       │                 │
│         │   extraction    │     │   tracking      │                 │
│         └─────────────────┘     └─────────────────┘                 │
│                                                                     │
│                     ┌─────────────────────┐                         │
│                     │   run-tests.sh      │                         │
│                     ├─────────────────────┤                         │
│                     │ • Discovery         │                         │
│                     │ • Execution         │                         │
│                     │ • Summary           │                         │
│                     └─────────────────────┘                         │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

# Execution Flow

The framework follows a fixed execution flow:

```text
parse arguments
    ↓
execute operation
    ↓
extract response
    ↓
execute assertions
    ↓
record result
```

Tests customize behaviour through assertion functions only.

---

# Framework Components

## bootstrap.sh

Framework entry point.

Every test should begin by sourcing:

```bash
source tests/framework/utils/bootstrap.sh
```

This automatically loads:

```bash
tests/framework/utils/common.sh
tests/framework/utils/assert.sh
```

and provides all framework functionality.

---

## common.sh

Contains generic framework behaviour.

### Named Argument Parsing

```bash
parse_named_args args "$@"
```

Converts:

```bash
status=200
body='{"ok":true}'
```

into:

```bash
args[status]
args[body]
```

### Operation Execution Boundary

```bash
execute_operation()
```

This is the primary framework extension point.

Current implementation:

```bash
curl -s -D - \
  -X "$method" \
  "${TARGET_BASE_URL}${path}"
```

Alternative implementations could execute:

```bash
aws lambda invoke
docker compose exec
kubectl exec
local CLI commands
```

without requiring changes to:

- assertions
- test files
- test runner

### Response Helpers

Extract response components from raw operation output.

```bash
extract_status
extract_body
```

Example:

```text
HTTP/1.1 200 OK

{
  "message": "hello"
}
```

becomes:

```bash
STATUS=200
BODY='{"message":"hello"}'
```

### execute_test_case()

Provides the framework's Template Method implementation.

```text
1. Parse arguments
2. Execute operation
3. Extract status
4. Extract body
5. Execute assertions
6. Print failure response
7. Record pass/fail
```

---

## assert.sh

Contains assertion helpers and test accounting.

### Status Assertions

```bash
assert_status \
  200 \
  "$status" \
  "successful request"
```

Output:

```text
FAIL [404] (successful request -> expected 200)
```

### JSON Assertions

```bash
assert_jq_expr \
  "$body" \
  '.message == "hello"'
```

Output:

```text
FAIL [body] (...)
```

when the expression evaluates to false.

### Automatic Finalization

`assert.sh` installs an EXIT trap:

```bash
trap finalize_assertions EXIT
```

This automatically:

- reports failures
- updates counters
- returns a non-zero exit code when assertions fail

Test files do not require explicit finalization logic.

---

## run-tests.sh

Discovers and executes test files.

### Run Entire Suite

```bash
bash tests/framework/run-tests.sh
```

### List Tests

```bash
bash tests/framework/run-tests.sh --list
```

### Run Matching Tests

```bash
bash tests/framework/run-tests.sh localstack
```

or:

```bash
bash tests/framework/run-tests.sh echo-path
```

The runner:

- discovers matching test files
- executes each file independently
- continues after failures
- produces a consolidated summary
- exits non-zero when failures occur

---

# Writing Tests

Every test follows the same structure:

```bash
#!/usr/bin/env bash

source tests/framework/utils/bootstrap.sh

assert_response() {
  declare -A args
  parse_named_args args "$@"

  local status="${args[status]}"
  local body="${args[body]}"

  assert_status \
    200 \
    "$status" \
    "request succeeds"

  assert_jq_expr \
    "$body" \
    '.message == "hello"' \
    "response contains expected message"
}

execute_test_case \
  method=GET \
  path="/example" \
  assert=assert_response
```

A test is responsible only for defining expectations.

The framework handles:

- execution
- parsing
- reporting
- pass/fail accounting

---

# Design Principles

The framework intentionally prioritizes:

- Simplicity over features
- Shell-native tooling
- Minimal dependencies
- Readable test definitions
- Clear failure output
- Reusable execution workflow
- Easy adaptation to different execution targets

The framework is intentionally small so that new tests can be written with minimal ceremony while keeping generic
execution logic centralized.
