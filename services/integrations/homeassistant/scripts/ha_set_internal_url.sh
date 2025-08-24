#!/usr/bin/env bash
set -euo pipefail

# This script automatically finds the local network IP and sets it as the
# internal_url in the Home Assistant configuration, then restarts the container.

# This makes the script runnable from any working directory.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}/../.."
CONFIG_FILE="${PROJECT_ROOT}/homeassistant/docker/config/configuration.yaml"

echo "Determining local IP address..."
MAC_IP=$("${SCRIPT_DIR}/ha_get_ip.sh")
echo "Using IP: $MAC_IP"

# Ensure homeassistant: exists in configuration.yaml
if ! grep -q '^homeassistant:' "$CONFIG_FILE"; then
  echo -e "\nhomeassistant:" >> "$CONFIG_FILE"
fi

# Remove any old internal_url lines and clean up the backup file created by sed.
sed -i.bak '/internal_url:/d' "$CONFIG_FILE" && rm -f "${CONFIG_FILE}.bak"

# Insert new internal_url under homeassistant:
awk -v ip="$MAC_IP" '/^homeassistant:/ { print; print "  internal_url: \"http://" ip ":8123\""; next } { print }' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"

echo "Set internal_url to http://$MAC_IP:8123"
