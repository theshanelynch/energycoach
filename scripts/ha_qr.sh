#!/usr/bin/env bash
set -euo pipefail

# This script reads the internal_url from the Home Assistant configuration
# and displays it as a QR code for easy mobile access.

# Determine the project root directory relative to the script's location.
SCRIPT_DIR="$(dirname "$0")"
PROJECT_ROOT="${SCRIPT_DIR}/.."
CONFIG_FILE="${PROJECT_ROOT}/docker/homeassistant/config/configuration.yaml"
IMAGE_DIR="${PROJECT_ROOT}/images"
OUTFILE="${IMAGE_DIR}/ha-url.png"

# Check for qrencode dependency
if ! command -v qrencode &> /dev/null; then
    echo "Error: 'qrencode' is not installed. Please install it to generate QR codes." >&2
    echo "On macOS, run: brew install qrencode" >&2
    exit 1
fi

# Extract internal_url from the configuration file, removing quotes.
URL=$(grep 'internal_url:' "$CONFIG_FILE" | awk '{print $2}' | tr -d '"')

if [[ -z "$URL" ]]; then
    echo "Error: Could not find internal_url in ${CONFIG_FILE}" >&2
    echo "Please ensure the startup script has been run to set the URL." >&2
    exit 1
fi

# Print the URL
echo "Home Assistant is available at: $URL"

# Display QR code in terminal
echo
echo "Scan this QR code with your phone:"
echo
qrencode -t ANSIUTF8 "$URL"

# Save QR as PNG for convenience
mkdir -p "${IMAGE_DIR}"
qrencode -o "$OUTFILE" "$URL"
echo
echo "QR code saved to $OUTFILE"
