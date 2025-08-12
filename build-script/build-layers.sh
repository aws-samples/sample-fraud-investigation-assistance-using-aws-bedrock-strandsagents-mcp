#!/bin/bash

# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

PYTHON="/usr/bin/arch -x86_64 /usr/local/bin/python3.13"
TARGET_DIR="python/lib/python3.13/site-packages"

# Get the layers path from command line argument
LAYERS_PATH="$1"
cd "$LAYERS_PATH"

# Iterate over each directory in layers
for layer in */ ; do
    # Remove the trailing slash to get the directory name
    layer=${layer%/}

    echo "Building $layer layer"

    # Navigate into the layer directory
    cd "$layer"

    # Clean up any previous build artifacts
    rm -f layer.zip
    rm -rf package
    rm -rf python # if exists

    # layer for fastmcp
    mkdir -p "$TARGET_DIR"
    # arch -x86_64 python3.13 -m pip install -r requirements.txt -t python/lib/python3.13/site-packages
    $PYTHON -m pip install -r requirements.txt -t "$TARGET_DIR"
    # /usr/bin/arch -x86_64 $ARCH_PYTHON -m pip install -r requirements.txt -t python/lib/python3.13/site-packages
    zip -r9 layer.zip * -x requirements.txt || 7z a -tzip -mx=9 layer.zip * -xr!requirements.txt

    cd ..

    echo "Built $layer successfully."
done

# Move back to the original starting directory
cd ..

echo "Layers build complete."