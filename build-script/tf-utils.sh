#!/bin/bash

# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0


export PATH=$PATH:/usr/local/bin

# Function to get current environment and configuration
get_terraform_state() {
    local dir=$1
    ENV_PATH="${dir}/../environment"
    CURRENT_ENV=$(cat "${ENV_PATH}/.current-environment")
    # echo "Current environment: $CURRENT_ENV"

    APP_NAME=$(jq -r '.APP_NAME' "${ENV_PATH}/environment-constants.json")
    ENV_CONFIG="${ENV_PATH}/.environment-${CURRENT_ENV}.json"
    AWS_ACCOUNT_ID=$(jq -r '.AWS_ACCOUNT_ID' "$ENV_CONFIG")
    AWS_REGION=$(jq -r '.AWS_DEFAULT_REGION' "$ENV_CONFIG")
    TF_S3_BACKEND_NAME=$(jq -r '.TF_S3_BACKEND_NAME' "$ENV_CONFIG")
    
    S3_BUCKET="${TF_S3_BACKEND_NAME}-${AWS_ACCOUNT_ID}-${AWS_REGION}"
    S3_KEY="${CURRENT_ENV}/app/terraform.tfstate"
    # echo "State file at s3://${S3_BUCKET}/${S3_KEY}"

    MESSAGE=$(aws s3 cp "s3://${S3_BUCKET}/${S3_KEY}" "${dir}/tmp/terraform.tfstate")
    echo "${dir}/tmp/terraform.tfstate"
}


# Function to get terraform output
get_tf_output() {
    local state_path=$1
    local output_name=$2

    terraform output -state="$state_path" -raw "$output_name"
}