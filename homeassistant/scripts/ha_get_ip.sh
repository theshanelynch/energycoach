#!/usr/bin/env bash
set -euo pipefail

# Print the best LAN IP for phones. Prefer the Mac interface that owns the default route.
# Fall back to en0, then to the Colima VM address.

mac_ip=""

# Try the interface with the default route
if command -v route >/dev/null 2>&1 && command -v ipconfig >/dev/null 2>&1; then
  iface=$(route -n get default 2>/dev/null | awk '/interface:/{print $2}' || true)
  if [[ -n "${iface:-}" ]]; then
    mac_ip=$(ipconfig getifaddr "$iface" 2>/dev/null || true)
  fi
fi

# Fall back to en0
if [[ -z "${mac_ip:-}" ]]; then
  mac_ip=$(ipconfig getifaddr en0 2>/dev/null || true)
fi

# Fall back to Colima VM address
if [[ -z "${mac_ip:-}" ]]; then
  if ! command -v jq >/dev/null 2>&1; then
    echo "Missing jq and no LAN IP found. Install jq or connect to Wi Fi." >&2
    exit 1
  fi
  mac_ip=$(colima status --json | jq -r '.ip_address // .address')
fi

if [[ -z "${mac_ip:-}" || "${mac_ip}" == "null" ]]; then
  echo "Could not determine a LAN or Colima IP" >&2
  exit 1
fi

echo "${mac_ip}"
