#!/usr/bin/env bash
# One-command Path A bring-up on Studio (Chrome check + agent).
# Usage: bash studio/bring-up.sh "go to example.com and summarize the page"
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
TASK="${*:-}"

cd "$ROOT"

if [[ -f .env ]]; then
  # shellcheck disable=SC1091
  set -a && source .env && set +a
fi

export CDP_URL="${CDP_URL:-http://127.0.0.1:9222}"
export MLX_URL="${MLX_URL:-http://127.0.0.1:3211}"

if ! curl -sf "${CDP_URL%/}/json/version" >/dev/null 2>&1; then
  echo "CDP not up. In another terminal run:"
  echo "  bash $ROOT/launch-chrome.sh"
  echo "Then re-run bring-up."
  exit 1
fi

if [[ ! -d .venv ]]; then
  python3 -m venv .venv
  # shellcheck disable=SC1091
  source .venv/bin/activate
  pip install -q -r requirements.txt
else
  # shellcheck disable=SC1091
  source .venv/bin/activate
fi

bash "$ROOT/doctor.sh" || true

if [[ -z "$TASK" ]]; then
  echo
  echo "Usage: bash studio/bring-up.sh \"your browser task\""
  echo "Example: bash studio/bring-up.sh \"open https://example.com and tell me the H1\""
  exit 0
fi

exec python -m agent "$TASK"
