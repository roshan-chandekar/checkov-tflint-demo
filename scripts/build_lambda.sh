#!/bin/bash
# Script to build Lambda deployment package

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Building Lambda deployment package..."

# Check if zip command is available
if ! command -v zip &> /dev/null; then
    echo "✗ Error: zip command not found. Please install zip package."
    echo "  On Ubuntu/Debian: sudo apt-get install -y zip"
    exit 1
fi

# Check if lambda_function.py exists
if [ ! -f lambda_function.py ]; then
    echo "✗ Error: lambda_function.py not found in $SCRIPT_DIR"
    exit 1
fi

# Create the zip file
if zip -q lambda_function.zip lambda_function.py; then
    if [ -f lambda_function.zip ]; then
        echo "✓ lambda_function.zip created successfully in $SCRIPT_DIR"
        ls -lh lambda_function.zip
    else
        echo "✗ Error: zip file was not created"
        exit 1
    fi
else
    echo "✗ Error: Failed to create zip file"
    exit 1
fi

