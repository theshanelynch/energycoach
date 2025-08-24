#!/usr/bin/env bash
set -euo pipefail

# This script restores the most recent Home Assistant backup.

# Determine the project root directory relative to the script's location.
# This makes the script runnable from any working directory.
SCRIPT_DIR="$(dirname "$0")"
PROJECT_ROOT="${SCRIPT_DIR}/.."

BACKUP_DIR="${PROJECT_ROOT}/backups"
HA_DIR="${PROJECT_ROOT}/docker/homeassistant"

echo "Searching for the latest backup in ${BACKUP_DIR}..."

# Find the latest backup file. Using a subshell with nullglob is a safe way
# to handle cases where no files are found.
LATEST_TAR=$( (shopt -s nullglob; ls -1t "${BACKUP_DIR}"/ha-config-*.tar.gz | head -n1) )

if [[ -z "$LATEST_TAR" ]]; then
  echo "Error: No backup file found in ${BACKUP_DIR}" >&2
  exit 1
fi

echo "Found latest backup: $(basename "${LATEST_TAR}")"
read -p "Are you sure you want to restore? This will stop Home Assistant and overwrite current config, media, and www directories. (y/n) " -n 1 -r
echo # move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Restore cancelled."
    exit 1
fi

echo "Stopping Home Assistant container to prevent file conflicts..."
docker stop homeassistant

echo "Restoring from $(basename "${LATEST_TAR}")..."
tar -xzf "${LATEST_TAR}" -C "${HA_DIR}"

echo "Cleaning up any old SQLite lock files..."
rm -f "${HA_DIR}"/config/*.db-wal "${HA_DIR}"/config/*.db-shm

echo "Restore complete. Please restart Home Assistant (e.g., 'docker compose up -d')."
