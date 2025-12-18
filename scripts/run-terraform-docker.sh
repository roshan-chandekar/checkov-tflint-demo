#!/bin/bash
# Helper script to run Terraform using Docker container
# Usage: ./scripts/run-terraform-docker.sh [terraform-args]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

docker exec -i -w /workspace terraform terraform "$@"

