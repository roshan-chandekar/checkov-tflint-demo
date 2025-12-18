#!/bin/bash
# Helper script to run Checkov using Docker container
# Usage: ./scripts/run-checkov-docker.sh [checkov-args]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

docker exec -i -w /workspace checkov checkov "$@"

