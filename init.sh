#!/usr/bin/env bash

# Copyright 2025 Amazon.com and its affiliates; all rights reserved.
# SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
# Licensed under the Amazon Software License  https://aws.amazon.com/asl/

# This function reads the file that is supplied as the first function argument.
# It then resolves all placeholder values found in that file by
# replacing the ###ENV_VAR_NAME### placeholder with the value of the ENV_VAR_NAME.
# param1: the name of the file that has placeholders to resolve
resolve_placeholders () {

    local filePath="$1"

    local SED_PATTERNS
    local resolvedContent="$(cat "$filePath")"

    # Loop that replaces variable placeholders with values
    local varName
    while read varName
    do
        local envVarValue="${!varName}"

        if [[ "$envVarValue" == "blank" ]]; then
            envVarValue=""
        fi

        SED_PATTERNS="s|###${varName}###|${envVarValue}|g;"

        resolvedContent="$(echo "$resolvedContent" | sed ''"$SED_PATTERNS"'')"

    done <<< "$(IFS=$'\n'; echo -e "${ENV_KEYS[*]}" )"

    echo "$resolvedContent" > "$filePath"
}

echo -e "\nGreetings prototype user! Before you can get started deploying this prototype,"
echo -e "we need to collect some settings values from you...\n"

echo -e "\nThe application name that is used to name cloud resources.
It is best to use a short value in all lowercase with no whitespace to avoid resource name length limits"
read -p "Enter value: " answer
APP_NAME="$answer"

echo -e "\n12 digit AWS account ID to deploy resources to"
read -p "Enter value: " answer
AWS_ACCOUNT_ID="$answer"

echo -e "\nAWS region used as the default for AWS CLI commands
Example: us-east-1"
read -p "Enter value: " answer
AWS_DEFAULT_REGION="$answer"

echo -e "\nThe environment name that is used to name cloud resources.
It is best to use a short value in all lowercase with no whitespace to avoid resource name length limits
Examples: dev, prod, your initials"
read -p "Enter value: " answer
ENV_NAME="$answer"

TF_S3_BACKEND_NAME="${APP_NAME}-${ENV_NAME}-tf-back-end"

echo -e "\nAPI key to access Brave MCP endpoint"
read -p "Enter value: " answer
BRAVE_API_KEY="$answer"

envKeysString="APP_NAME AWS_ACCOUNT_ID AWS_DEFAULT_REGION ENV_NAME TF_S3_BACKEND_NAME BRAVE_API_KEY"
ENV_KEYS=($(echo "$envKeysString"))
templateFilePathsStr="./set-env-vars.sh ./app/layers/psycopg2/python/lib/python3.13/site-packages/psycopg2/.dylibs/libcrypto.3.dylib
./app/layers/psycopg2/python/lib/python3.13/site-packages/psycopg2/.dylibs/libgssapi_krb5.2.2.dylib
./app/layers/psycopg2/python/lib/python3.13/site-packages/psycopg2/.dylibs/libkrb5.3.3.dylib
./app/layers/strands-agents/python/lib/python3.13/site-packages/pydantic/json_schema.py
./app/layers/strands-agents/python/lib/python3.13/site-packages/pydantic/main.py
./iac/roots/app/terraform.tfvars
./iac/roots/app/backend.tf
./iac/bootstrap/parameters.json
./Makefile-4-customer"
templateFilePaths=($(echo "$templateFilePathsStr"))

for templatePath in "${templateFilePaths[@]}"; do

    if [[ $templatePath == *4-customer ]]; then
        templatePath="./Makefile"
    fi

    if [[ -f "$templatePath" ]]; then
        echo -e "\nResolving placeholders in ${templatePath}"
        resolve_placeholders "$templatePath"
    fi
done

echo -e "\nSUCCESS!\n"
