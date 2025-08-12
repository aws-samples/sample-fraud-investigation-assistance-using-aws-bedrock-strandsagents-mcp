#!/bin/bash

# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0


# Root directory for lambda functions
LAMBDAS_PATH="$1"
cd "$LAMBDAS_PATH"
mkdir packages

# Iterate over each directory in business_logic
for lambda in */ ; do
    # Remove the trailing slash to get the directory name
    lambda="${lambda%/}"
    if [ "$lambda" == "packages" ] || [ "$lambda" == "helpers" ]; then
        continue
    fi
    echo "Building ${lambda} lambda"
    
    rm -f "packages/${lambda}.zip"

    cd "$lambda"
    zip -r9 "../packages/${lambda}.zip" . || 7z a -tzip -mx=9 "../packages/${lambda}.zip" .

    HELPERS_FILE="../helpers/helpers.py"
    # Add the helpers file to the zip
    if [ -f "$HELPERS_FILE" ]; then
       echo "Helpers found"
        zip -j "../packages/${lambda}.zip" "$HELPERS_FILE" || 7z a -tzip -mx=9 "../packages/${lambda}.zip" "$HELPERS_FILE"
    else
        echo "Warning: Helpers file ${HELPERS_FILE} not found. Skipping."
    fi

    cd ..

    echo "Built ${lambda} successfully."
done

# Move back to the original starting directory
cd ..

echo "Lambda build complete."

# Root directory for lambda container functions
cd container

# Iterate over each directory in business_logic
for lambda in */ ; do
    # Remove the trailing slash to get the directory name
    echo "Copying helpers to ${lambda} lambda"

    HELPERS_FILE="../python/helpers/helpers.py"
    # Add the helpers file to the folder
    if [ -f "$HELPERS_FILE" ]; then
       echo "Helpers found"
       cp "$HELPERS_FILE" "${lambda}"
    else
        echo "Warning: Helpers file ${HELPERS_FILE} not found. Skipping."
    fi

    echo "Copied helpers to ${lambda} successfully."
done

# Move back to the original starting directory
cd ..

echo "Container lambda files ready."
