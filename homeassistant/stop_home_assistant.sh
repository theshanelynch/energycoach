#!/usr/bin/env bash
set -euo pipefail

# This script gracefully stops and removes the containers defined in the Docker Compose file.

# Determine the project root directory from the script's location.
# This makes the script runnable from any directory.
PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"

echo "### Stopping and removing Home Assistant services... ###"
docker-compose -f "${PROJECT_ROOT}/docker/docker-compose.yml" down

echo "✅ Services stopped successfully."