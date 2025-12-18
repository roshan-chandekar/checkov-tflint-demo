#!/bin/bash
# Helper script to run TFLint using Docker container
# Usage: ./scripts/run-tflint-docker.sh [tflint-args]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

docker exec -i -w /workspace tflint tflint "$@"

