#!/usr/bin/env bash
set -euo pipefail

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "Run this script with 'source' so activation affects your current shell:"
  echo "  source scripts/activate_venv.sh"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ACTIVATE_SCRIPT="$ROOT_DIR/.venv/bin/activate"

if [[ ! -f "$ACTIVATE_SCRIPT" ]]; then
  echo "Virtual environment not found at $ROOT_DIR/.venv"
  echo "Run setup first: python3 scripts/dev_setup.py"
  return 1
fi

# shellcheck source=/dev/null
source "$ACTIVATE_SCRIPT"
echo "Virtual environment activated (.venv)."
