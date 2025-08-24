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


echo "Bootstrap complete activate venv with:"
echo "source .venv/bin/activate"
