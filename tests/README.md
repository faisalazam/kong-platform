# Tests

This directory contains the test assets used to validate Kong-to-Lambda integrations running through the AWS Lambda
plugin.

The tests are designed to verify behaviour from the perspective of an API consumer by making requests through the Kong
proxy and validating the resulting responses.

The test suite covers:

- Kong route behaviour
- AWS Lambda plugin integration
- Event payload compatibility
- Request path forwarding
- LocalStack integration
- Regressions discovered during experimentation and proof-of-concept work

For details about the reusable shell testing framework itself, see:

**./framework/README.md**

---

# Directory Structure

```text
tests/
├── README.md
├── framework/
├── scenarios/
├── kong/
└── lambdas/
```

The test suite is intentionally split into distinct layers.

---

# Architecture

Each test scenario consists of three related components:

```text
Scenario
    ↓
Kong Configuration
    ↓
Lambda Implementation
```

Example:

```text
tests/scenarios/routing/echo-path.sh
            ↓
tests/kong/routing/echo-path.yml
            ↓
tests/lambdas/routing/echo-path.py
```

The scenario validates behaviour.

The Kong configuration defines the route and plugin configuration being tested.

The Lambda implementation acts as the target system receiving requests from Kong.

---

# Running Tests

Run the full test suite:

```bash
make test
```

or:

```bash
bash tests/framework/run-tests.sh
```

List available tests:

```bash
bash tests/framework/run-tests.sh --list
```

Run matching tests:

```bash
bash tests/framework/run-tests.sh localstack
```

```bash
bash tests/framework/run-tests.sh compatibility
```

```bash
bash tests/framework/run-tests.sh echo-path
```

---

# Adding A New Test Scenario

A new scenario typically requires three files.

Example:

```text
tests/scenarios/example/my-test.sh
tests/kong/example/my-test.yml
tests/lambdas/example/my-test.py
```

## Step 1

Create the Lambda implementation.

Example:

```python
def lambda_handler(event, context):
    return {
        "statusCode": 200,
        "body": "hello"
    }
```

## Step 2

Create the Kong configuration.

Configure:

- route
- aws-lambda plugin
- Lambda function name

Example:

```text
/poc/my-test
```

↓

```text
my-test Lambda
```

## Step 3

Create the test scenario.

The scenario should:

- invoke the route through Kong
- validate the response
- assert the expected behaviour

Example:

```bash
execute_test_case \
  method=GET \
  path="/poc/my-test" \
  assert=assert_response
```

---

# Design Philosophy

The tests validate externally observable behaviour rather than internal implementation details.

The preferred testing approach is:

```text
Request
    ↓
Kong Route
    ↓
AWS Lambda Plugin
    ↓
Lambda
    ↓
Response
```

rather than directly invoking Lambdas or asserting Kong configuration state.

This keeps tests focused on the behaviour experienced by API consumers and helps detect integration issues that may not
be visible when validating components in isolation.

---

# Notes

- Scenario files contain behavioural expectations.
- Kong files contain test-specific route and plugin configuration.
- Lambda files contain the executable test fixtures.
- The framework directory contains reusable testing infrastructure and can be adapted for other repositories if
  required.
- Test scenarios are intentionally lightweight and focus on validating a single behaviour wherever possible.
