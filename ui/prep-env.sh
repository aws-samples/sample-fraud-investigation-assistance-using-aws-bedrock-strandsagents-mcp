#!/bin/bash

# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0


# Exit script on any error
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
BUILD_DIR="${SCRIPT_DIR}/../build-script"
source "${BUILD_DIR}/tf-utils.sh"

STATE_PATH="$(get_terraform_state "$BUILD_DIR")"

AGENT_ID="$(get_tf_output "$STATE_PATH" "agent_id")"
echo "Agent ID: $AGENT_ID"
if [ -z "$AGENT_ID" ]; then
    echo "Error: Agent ID not found in Terraform output."
    exit 1
fi


AGENT_ALIAS_ID=$(get_tf_output "$STATE_PATH" "agent_alias_id")
echo "Agent alias ID: $AGENT_ALIAS_ID"
if [ -z "$AGENT_ALIAS_ID" ]; then
    echo "Error: Agent alias not found in Terraform output."
    exit 1
fi

# Create or update .env file in SCRIPT_DIR
ENV_FILE="${SCRIPT_DIR}/.env"
echo "BEDROCK_AGENT_ID=${AGENT_ID}" > "$ENV_FILE"
echo "BEDROCK_AGENT_ALIAS_ID=${AGENT_ALIAS_ID}" >> "$ENV_FILE"

echo ".env file created/updated in ${SCRIPT_DIR}"