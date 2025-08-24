# esb/publish_only.sh
#!/usr/bin/env bash
set -euo pipefail

# Resolve this script folder
ESB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Helper to resolve relative paths against ESB_DIR
resolve_path() {
  case "${1:-}" in
    /*) printf "%s" "$1" ;;
    *)  printf "%s/%s" "$ESB_DIR" "$1" ;;
  esac
}

# Load module config
set -a
source "$(resolve_path ".env")"
set +a

# Absolute paths for output and HA www
OUT_DIR_ABS="$(resolve_path "${OUT_DIR:-./out}")"
HA_WWW_DIR_ABS="$(resolve_path "${HA_WWW_DIR:-../homeassistant/www}")"

# Pick the source file to publish
# Priority: explicit arg, then normalized, then raw
SRC="${1:-}"
if [[ -z "$SRC" ]]; then
  if [[ -f "${OUT_DIR_ABS}/esb_usage_30min.json" ]]; then
    SRC="${OUT_DIR_ABS}/esb_usage_30min.json"
  elif [[ -f "${OUT_DIR_ABS}/esb_usage_raw.json" ]]; then
    SRC="${OUT_DIR_ABS}/esb_usage_raw.json"
  else
    echo "No ESB JSON found in ${OUT_DIR_ABS}"
    exit 1
  fi
fi
case "$SRC" in
  /*) ;;  # already absolute
  *)  SRC="$(resolve_path "$SRC")" ;;
esac

# Publish
mkdir -p "$HA_WWW_DIR_ABS"
cp -f "$SRC" "$HA_WWW_DIR_ABS/$(basename "$SRC")"
echo "Published $(basename "$SRC") to $HA_WWW_DIR_ABS"

# Print a URL for convenience if we can detect your LAN IP
if command -v ipconfig >/dev/null 2>&1; then
  IP="$(ipconfig getifaddr en0 2>/dev/null || true)"
  if [[ -n "$IP" ]]; then
    echo "Open http://$IP:8123/local/$(basename "$SRC")"
  fi
fi
