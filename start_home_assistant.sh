#!/usr/bin/env bash
set -euo pipefail

# This script automates the entire startup process.
# It ensures correct permissions, sets the dynamic internal URL for Home Assistant,
# and then starts all services using Docker Compose.

# Determine the project root directory from the script's location.
# This makes the script runnable from any directory.
PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"

echo "### 1/3: Ensuring correct permissions for HA volumes... ###"
chmod 755 "${PROJECT_ROOT}/docker/homeassistant/config" "${PROJECT_ROOT}/docker/homeassistant/media" "${PROJECT_ROOT}/docker/homeassistant/www"

echo -e "\n### 2/4: Setting internal URL for Home Assistant... ###"
"${PROJECT_ROOT}/scripts/ha_set_internal_url.sh"

echo -e "\n### 3/4: Generating QR code for mobile access... ###"
"${PROJECT_ROOT}/scripts/ha_qr.sh"

echo -e "\n### 4/4: Starting services with Docker Compose... ###"
docker-compose -f "${PROJECT_ROOT}/docker/homeassistant/docker-compose.yml" up -d

echo -e "\n🚀 Setup complete! Access Home Assistant at http://localhost:8123"
