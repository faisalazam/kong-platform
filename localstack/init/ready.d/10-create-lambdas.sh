#!/bin/bash
set -euxo pipefail

REGION="ap-southeast-2"
ENDPOINT="http://localhost:4566"

# --------------------------------------------------------------------------------------
# LocalStack multi-account strategy:
#
# We explicitly set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY per command.
#
# In LocalStack, AWS_ACCESS_KEY_ID acts as the ACCOUNT IDENTIFIER (not just a credential),
# enabling multi-account isolation. Each unique value represents a separate account.
#
# IMPORTANT:
# - Do NOT use AWS profiles (e.g. --profile localstack) here.
# - Profiles will override these environment variables and break multi-account behavior.
#
# Therefore:
#   AWS_ACCESS_KEY_ID == account_id
#
# Reference:
# https://docs.localstack.cloud/aws/capabilities/config/multi-account-setups/
# --------------------------------------------------------------------------------------
AUTOMATION_ACCOUNT_ID="179857410264"
AUTOMATION_ACCOUNT_ACCESS_KEY="test"

LAMBDA_DIR="/etc/localstack/tests/lambdas"

PYTHON_RUNTIME="python3.12"
LAMBDA_HANDLER="lambda_function.lambda_handler"
LAMBDA_ROLE_ARN="arn:aws:iam::${AUTOMATION_ACCOUNT_ID}:role/lambda-role"

aws_localstack() {
  AWS_ACCESS_KEY_ID="${AUTOMATION_ACCOUNT_ID}" \
  AWS_SECRET_ACCESS_KEY="${AUTOMATION_ACCOUNT_ACCESS_KEY}" \
  aws \
    --region "${REGION}" \
    --endpoint-url "${ENDPOINT}" \
    "$@"
}

create_lambda_from_file() {
  local SOURCE_FILE="$1"

  local FUNCTION_NAME
  FUNCTION_NAME="$(basename "$SOURCE_FILE" .py)"

  local WORK_DIR="/tmp/${FUNCTION_NAME}"

  echo "[INIT] Creating Lambda: ${FUNCTION_NAME}"

  rm -rf "${WORK_DIR}"
  mkdir -p "${WORK_DIR}"

  cp "${SOURCE_FILE}" \
     "${WORK_DIR}/lambda_function.py"

  (
    cd "${WORK_DIR}"

    zip -q function.zip lambda_function.py

    aws_localstack \
      lambda create-function \
      --function-name "${FUNCTION_NAME}" \
      --runtime "${PYTHON_RUNTIME}" \
      --handler "${LAMBDA_HANDLER}" \
      --role "${LAMBDA_ROLE_ARN}" \
      --zip-file fileb://function.zip
  )

  echo "[INIT] Created: ${FUNCTION_NAME}"
}

find "${LAMBDA_DIR}" \
  -type f \
  -name '*.py' \
  | sort \
  | while read -r lambda_file; do
      create_lambda_from_file "${lambda_file}"
    done

echo "[INIT] Lambda inventory"

aws_localstack lambda list-functions
