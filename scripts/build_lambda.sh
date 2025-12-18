#!/bin/bash
# Script to build Lambda deployment package

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Building Lambda deployment package..."

if [ -f lambda_function.py ]; then
    zip -q lambda_function.zip lambda_function.py
    echo "✓ lambda_function.zip created successfully in $SCRIPT_DIR"
    ls -lh lambda_function.zip
else
    echo "✗ Error: lambda_function.py not found in $SCRIPT_DIR"
    exit 1
fi

