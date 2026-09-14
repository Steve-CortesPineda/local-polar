#!/usr/bin/env bash
# Start MLX OpenAI-compat server on :3211 inside studio/.venv (no system pip).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

# Prefer a stable Python — Homebrew 3.14 often breaks mlx wheels.
PY=""
for c in python3.12 python3.11 python3.13 python3; do
  if command -v "$c" >/dev/null 2>&1; then
    PY="$c"
    break
  fi
done
if [[ -z "$PY" ]]; then
  echo "No python3 found" >&2
  exit 1
fi

echo "Using: $PY ($("$PY" -V 2>&1))"

if [[ ! -d .venv ]]; then
  "$PY" -m venv .venv
fi
# shellcheck disable=SC1091
source .venv/bin/activate

python -m pip install -q -U pip
python -m pip install -q -r requirements.txt "mlx-lm"

echo "Starting mlx_lm.server on http://127.0.0.1:3211"
exec python -m mlx_lm.server --port 3211
