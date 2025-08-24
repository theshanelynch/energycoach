#!/usr/bin/env bash
set -euo pipefail

# This script automates the entire startup process.
# It ensures correct permissions, sets the dynamic internal URL for Home Assistant,
# and then starts all services using Docker Compose.

# Determine the project root directory from the script's location.
# This makes the script runnable from any directory.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}/.."

SCRIPTS_DIR="${PROJECT_ROOT}/homeassistant/scripts"

echo "### 1/5: Setting executable permissions for scripts... ###"
chmod +x "${SCRIPTS_DIR}"/*.sh
echo "Permissions set for scripts in ${SCRIPTS_DIR}"

echo -e "\n### 2/5: Ensuring correct permissions for HA volumes... ###"
HA_DOCKER_DIR="${PROJECT_ROOT}/homeassistant/docker"
chmod 755 "${HA_DOCKER_DIR}/config" "${HA_DOCKER_DIR}/media" "${HA_DOCKER_DIR}/www"

echo -e "\n### 3/5: Setting internal URL for Home Assistant... ###"
"${SCRIPTS_DIR}/ha_set_internal_url.sh"

echo -e "\n### 4/5: Generating QR code for mobile access... ###"
"${SCRIPTS_DIR}/ha_qr.sh"

echo -e "\n### 5/5: Starting services with Docker Compose... ###"
DOCKER_COMPOSE_FILE="${HA_DOCKER_DIR}/docker-compose.yml"
docker-compose -f "${DOCKER_COMPOSE_FILE}" up -d

echo -e "\n🚀 Setup complete! Access Home Assistant at http://localhost:8123"
