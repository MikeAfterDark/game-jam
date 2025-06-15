#!/bin/bash

DIRECTORY=$1

if [ ! -d "$DIRECTORY" ]; then
    echo "Directory '$DIRECTORY' doesn't exist."
    exit 1
fi

# 2. Build, use folder/build for config
echo "Building project: $DIRECTORY"

# 3. Upload, Check for itch upload config
