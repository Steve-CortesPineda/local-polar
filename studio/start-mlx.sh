#!/usr/bin/env bash
# Start MLX OpenAI-compat server on :3211 inside studio/.venv (no system pip).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"
export PATH="/opt/homebrew/bin:$PATH"

# Prefer 3.12 — Homebrew python3 alone may be 3.14 (breaks mlx / mixed venvs).
PY=""
for c in python3.12 python3.11 python3.13 python3; do
  if command -v "$c" >/dev/null 2>&1; then
    PY="$c"
    break
  fi
done
if [[ -z "$PY" ]]; then
  echo "No python3 found. On Studio: brew install python@3.12" >&2
  exit 1
fi

echo "Using: $PY ($("$PY" -V 2>&1))"

# Recreate venv if it points at a different major.minor than PY
need_new=0
if [[ ! -d .venv ]]; then
  need_new=1
else
  vver="$(.venv/bin/python -V 2>&1 || true)"
  pver="$("$PY" -V 2>&1)"
  if [[ "$vver" != "$pver" ]]; then
    echo "Recreating .venv ($vver -> $pver)"
    rm -rf .venv
    need_new=1
  fi
fi

if [[ "$need_new" -eq 1 ]]; then
  "$PY" -m venv .venv
fi
# shellcheck disable=SC1091
source .venv/bin/activate

python -m pip install -q -U pip
python -m pip install -q -r requirements.txt mlx mlx-lm
python -c "import mlx_lm" >/dev/null

MODEL="${MLX_MODEL:-mlx-community/Qwen2.5-7B-Instruct-4bit}"
PORT="${MLX_PORT:-3211}"

echo "Starting mlx_lm server on http://127.0.0.1:${PORT}"
echo "  model: $MODEL"
exec python -m mlx_lm server --model "$MODEL" --host 127.0.0.1 --port "$PORT"
