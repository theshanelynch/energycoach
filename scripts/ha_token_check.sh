#!/usr/bin/env bash
set -euo pipefail
BASE_URL="${1:-http://$(ipconfig getifaddr en0 2>/dev/null || echo localhost):8123}"
TOKEN_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/secrets/ha_token.txt"
TOKEN="$(cat "$TOKEN_FILE")"
curl -fsS -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" "$BASE_URL/api/config" | jq .
echo "Token works against $BASE_URL"
