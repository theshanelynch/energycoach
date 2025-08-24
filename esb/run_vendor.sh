#!/usr/bin/env bash
set -euo pipefail

# Resolve this script directory
ESB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Helper to resolve relative paths against ESB_DIR
resolve_path() {
  case "${1:-}" in
    /*) printf "%s" "$1" ;;
    *)  printf "%s/%s" "$ESB_DIR" "$1" ;;
  esac
}

# Load config and secrets
set -a
# .env lives next to this script
source "$(resolve_path ".env")"
set +a

# secrets live at repo root by your design
source "$(resolve_path "../secrets/esb.env")"

# Activate venv that lives next to this script
source "$(resolve_path ".venv/bin/activate")"

# Normalize env paths to absolute
VENDOR_DIR="$(resolve_path "${VENDOR_DIR}")"
WORK_DIR="$(resolve_path "${WORK_DIR:-./work}")"
OUT_DIR="$(resolve_path "${OUT_DIR:-./out}")"
mkdir -p "${WORK_DIR}" "${OUT_DIR}"

SCRIPT="${VENDOR_DIR}/esb-smart-meter-reader.py"
PATCHED="${WORK_DIR}/esb_reader_patched.py"
cp "${SCRIPT}" "${PATCHED}"

# Inject creds and force JSON output as per upstream README
python - <<'PY' "$PATCHED" "$ESB_MPRN" "$ESB_USER" "$ESB_PASS"
import re, sys, pathlib
p, mprn, user, pwd = sys.argv[1:]
s = pathlib.Path(p).read_text(encoding="utf-8")

s = re.sub(r'(?m)^\s*meter_mprn\s*=\s*".*?"\s*$', f'meter_mprn = "{mprn}"', s)
s = re.sub(r'(?m)^\s*esb_user_name\s*=\s*".*?"\s*$', f'esb_user_name = "{user}"', s)
s = re.sub(r'(?m)^\s*esb_password\s*=\s*".*?"\s*$', f'esb_password = "{pwd}"', s)

s = re.sub(r'(?m)^\s*print\(\s*csv_file\s*\)\s*$', r'# print(csv_file)', s)
s = re.sub(r'(?m)^\s*#\s*print\(\s*json_file\s*\)\s*$', r'print(json_file)', s)

pathlib.Path(p).write_text(s, encoding="utf-8")
print("patched")
PY

RAW_JSON="${OUT_DIR}/esb_usage_raw.json"
python "${PATCHED}" > "${RAW_JSON}"
echo "Wrote ${RAW_JSON}"

# Optional publish into Home Assistant www
if [[ -n "${HA_WWW_DIR:-}" ]]; then
  HA_WWW_DIR_ABS="$(resolve_path "${HA_WWW_DIR}")"
  mkdir -p "${HA_WWW_DIR_ABS}"
  cp -f "${RAW_JSON}" "${HA_WWW_DIR_ABS}/esb_usage_raw.json"
  echo "Published to ${HA_WWW_DIR_ABS}/esb_usage_raw.json"
fi
