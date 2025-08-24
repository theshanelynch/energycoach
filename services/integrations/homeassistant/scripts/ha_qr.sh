#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}/../.."
CONFIG_FILE="${PROJECT_ROOT}/homeassistant/docker/config/configuration.yaml"
TOKEN_FILE="${PROJECT_ROOT}/secrets/ha_token.txt"
IMAGE_DIR="${PROJECT_ROOT}/images"
mkdir -p "${IMAGE_DIR}"

if ! command -v qrencode >/dev/null 2>&1; then
  echo "qrencode is not installed. brew install qrencode" >&2
  exit 1
fi

# Try to read internal_url from YAML, else compute from local IP
url=$(grep -E '^[[:space:]]*internal_url:' "$CONFIG_FILE" 2>/dev/null | awk '{print $2}' | tr -d '"')
if [[ -z "${url:-}" ]]; then
  ip="$("${SCRIPT_DIR}/ha_get_ip.sh")"
  url="http://${ip}:8123"
fi

echo "Home Assistant URL: ${url}"

# Warn if HA is not responding
if command -v curl >/dev/null 2>&1; then
    if [[ -f "$TOKEN_FILE" ]]; then
        TOKEN=$(cat "$TOKEN_FILE")
        if ! curl -fsS -H "Authorization: Bearer ${TOKEN}" "${url}/api/" >/dev/null 2>&1; then
            echo "Warning: ${url} did not respond to an authenticated check. The QR will still be shown." >&2
        fi
    else
        if ! curl -fsS "${url}/api/" >/dev/null 2>&1; then
            echo "Warning: ${url} did not respond to a quick check. The QR will still be shown." >&2
        fi
    fi
fi

echo
printf "%s" "${url}" | qrencode -t ANSIUTF8
echo
qrencode -o "${IMAGE_DIR}/ha-url.png" "${url}" >/dev/null 2>&1 || true
echo "Saved ${IMAGE_DIR}/ha-url.png"
