#!/usr/bin/env bash
# Studio doctor: Path A readiness (Chrome CDP + MLX endpoint).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
PORT="${CDP_PORT:-9222}"
CDP_URL="${CDP_URL:-http://127.0.0.1:${PORT}}"
MLX_URL="${MLX_URL:-http://127.0.0.1:3211}"
FAIL=0

ok()  { printf '  OK  %s\n' "$*"; }
bad() { printf '  FAIL %s\n' "$*"; FAIL=1; }
info(){ printf '  ..  %s\n' "$*"; }

echo "local-polar studio doctor (Path A)"
echo "  CDP_URL=$CDP_URL"
echo "  MLX_URL=$MLX_URL"

# Chrome / CDP
if curl -sf "${CDP_URL%/}/json/version" >/dev/null 2>&1; then
  VER="$(curl -s "${CDP_URL%/}/json/version" | head -c 300)"
  ok "CDP responding: $VER"
else
  bad "CDP not reachable at $CDP_URL"
  info "Start: bash $ROOT/launch-chrome.sh"
fi

# Ensure we are not advertising a public bind (best-effort)
if command -v lsof >/dev/null 2>&1; then
  LISTEN="$(lsof -nP -iTCP:"$PORT" -sTCP:LISTEN 2>/dev/null || true)"
  if echo "$LISTEN" | grep -q '127.0.0.1\|localhost\|\*:'; then
    if echo "$LISTEN" | grep -Eq '0\.0\.0\.0|\*:9222|\[::\]'; then
      bad "CDP appears bound beyond loopback — prefer 127.0.0.1 only for Path A"
      info "$LISTEN"
    else
      ok "CDP listen looks loopback-local"
    fi
  elif [[ -n "$LISTEN" ]]; then
    info "CDP listeners: $LISTEN"
  fi
fi

# MLX / model
if curl -sf "${MLX_URL%/}/health" >/dev/null 2>&1; then
  ok "MLX health: $(curl -s "${MLX_URL%/}/health" | head -c 200)"
elif curl -sf "${MLX_URL%/}/v1/models" >/dev/null 2>&1; then
  ok "OpenAI-compat models: $(curl -s "${MLX_URL%/}/v1/models" | head -c 200)"
else
  bad "No model endpoint at $MLX_URL (/health or /v1/models)"
  info "Reuse AVA mlx-think (:3211) or: python -m mlx_lm.server --port 3211"
  info "mlx-think was disabled 2026-08-21 — only restart if Steve wants it"
fi

# Python deps (agent)
if [[ -d "$ROOT/.venv" ]]; then
  ok "venv present: $ROOT/.venv"
elif python3 -c 'import playwright, httpx' 2>/dev/null; then
  ok "playwright + httpx importable in current python3"
else
  bad "Agent deps missing (playwright, httpx)"
  info "cd $ROOT && python3 -m venv .venv && . .venv/bin/activate && pip install -r requirements.txt"
fi

if [[ "$FAIL" -ne 0 ]]; then
  echo "doctor: FAIL"
  exit 1
fi
echo "doctor: OK (Path A ready)"
