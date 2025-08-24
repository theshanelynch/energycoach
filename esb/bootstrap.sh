#!/usr/bin/env bash
set -euo pipefail

# Work entirely with absolute paths
ESB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

python3 -m venv "${ESB_DIR}/.venv"
source "${ESB_DIR}/.venv/bin/activate"
python -m pip install --upgrade pip
if [[ -f "${ESB_DIR}/requirements.txt" ]]; then
  python -m pip install -r "${ESB_DIR}/requirements.txt"
fi

# Prepare env files
cp -n "${ESB_DIR}/.env.example" "${ESB_DIR}/.env" 2>/dev/null || true
mkdir -p "${ESB_DIR}/../secrets"
if [[ ! -f "${ESB_DIR}/../secrets/esb.env" ]]; then
  cat > "${ESB_DIR}/../secrets/esb.env" <<'ENV'
ESB_MPRN=YOUR_11_DIGIT_MPRN
ESB_USER=you@example.com
ESB_PASS=your_password
ENV
  chmod 600 "${ESB_DIR}/../secrets/esb.env"
  echo "Wrote secrets at ../secrets esb.env fill it in"
fi

# Load module config
set -a
source "${ESB_DIR}/.env"
set +a

# Clone vendor repo at requested ref
mkdir -p "$(dirname "${VENDOR_DIR}")"
if [[ "${VENDOR_DIR}" == /* ]]; then
  VENDOR_DIR_ABS="${VENDOR_DIR}"
else
  VENDOR_DIR_ABS="${ESB_DIR}/${VENDOR_DIR}"
fi
if [[ ! -d "${VENDOR_DIR_ABS}" ]]; then
  git clone https://github.com/badger707/esb-smart-meter-reading-automation "${VENDOR_DIR_ABS}"
fi
if [[ -n "${VENDOR_REF:-}" ]]; then
  git -C "${VENDOR_DIR_ABS}" fetch --all --tags
  git -C "${VENDOR_DIR_ABS}" checkout "${VENDOR_REF}"
fi

echo "Bootstrap complete activate venv with:"
echo -e "source ${ESB_DIR}/.venv/bin/activate"
