#!/usr/bin/env bash
set -euo pipefail

# Determine the project root directory relative to the script's location.
# This makes the script runnable from any working directory.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}/../.."

TS=$(date +"%Y%m%d-%H%M%S")
BACKUP_DIR="${PROJECT_ROOT}/homeassistant/backups"
HA_DIR="${PROJECT_ROOT}/homeassistant/docker"
BACKUP_FILE="${BACKUP_DIR}/ha-config-${TS}.tar.gz"

mkdir -p "${BACKUP_DIR}"
docker exec homeassistant sh -c "sync || true"

tar \
  --exclude='config/home-assistant.log*' \
  --exclude='config/*.db-shm' \
  --exclude='config/*.db-wal' \
  -czf "${BACKUP_FILE}" \
  -C "${HA_DIR}" config media www
echo "Backup written to ${BACKUP_FILE}"
