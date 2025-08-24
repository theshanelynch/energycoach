#!/usr/bin/env bash
set -euo pipefail

# This script determines the correct local IP address for Home Assistant.
# It prioritizes the Mac's LAN IP and falls back to the Colima VM IP.
# Informational messages are sent to stderr, and the final IP is sent to stdout.

# Get Mac LAN IP (Wi-Fi on en0)
MAC_IP=$(ipconfig getifaddr en0 || true)

# Fallback to Colima's VM IP if MAC_IP is empty
if [[ -z "$MAC_IP" ]]; then
  echo "No LAN IP found on en0, trying Colima..." >&2
  MAC_IP=$(colima status --json | jq -r '.ip_address // .address')
fi

if [[ -z "$MAC_IP" || "$MAC_IP" == "null" ]]; then
  echo "Error: Could not determine a valid LAN or Colima IP." >&2
  exit 1
fi

echo "$MAC_IP"