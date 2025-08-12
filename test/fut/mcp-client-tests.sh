#!/bin/bash

# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0


# Exit script on any error
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
BUILD_DIR="${SCRIPT_DIR}/../../build-script"
source "${BUILD_DIR}/tf-utils.sh"
source "${SCRIPT_DIR}/lambda-utils.sh"

STATE_PATH="$(get_terraform_state $BUILD_DIR)"

CLIENT_FUNCTION_NAME=$(get_tf_output $STATE_PATH "strands_agent_function_name")
echo "Client function name: $CLIENT_FUNCTION_NAME"
if [ -z "$CLIENT_FUNCTION_NAME" ]; then
    echo "Error: Client function name not found in Terraform output."
    exit 1
fi

REGION=$(get_tf_output $STATE_PATH "region")
echo "Region: $REGION"
if [ -z "$REGION" ]; then
    echo "Error: Unable to retrieve region from Terraform output."
    exit 1
fi

run_client_function_test_cases "$SCRIPT_DIR" "$CLIENT_FUNCTION_NAME" "$REGION" mcp-test-cases.json
# run_client_function_test_cases "$SCRIPT_DIR" "$MERCHANT_FUCNTION_NAME" "$REGION" merchant-test-cases.json
# run_client_function_test_cases "$SCRIPT_DIR" "$TRANSACTION_FUCNTION_NAME" "$REGION" transaction-test-cases.json

print_test_summary

# Clean up
rm -f ./tmp/lambda-response.json
