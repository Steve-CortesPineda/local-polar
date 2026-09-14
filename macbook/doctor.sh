#!/usr/bin/env bash
# MacBook doctor: Path B Chrome CDP readiness (tunnel is separate).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
PORT="${CDP_PORT:-9222}"
CDP_URL="${CDP_URL:-http://127.0.0.1:${PORT}}"
FAIL=0

ok()  { printf '  OK  %s\n' "$*"; }
bad() { printf '  FAIL %s\n' "$*"; FAIL=1; }
info(){ printf '  ..  %s\n' "$*"; }

echo "local-polar macbook doctor (Path B — optional)"
echo "  CDP_URL=$CDP_URL"

if curl -sf "${CDP_URL%/}/json/version" >/dev/null 2>&1; then
  ok "CDP responding: $(curl -s "${CDP_URL%/}/json/version" | head -c 300)"
else
  bad "CDP not reachable at $CDP_URL"
  info "Start: bash $ROOT/launch-chrome.sh"
fi

if command -v lsof >/dev/null 2>&1; then
  LISTEN="$(lsof -nP -iTCP:"$PORT" -sTCP:LISTEN 2>/dev/null || true)"
  if echo "$LISTEN" | grep -Eq '0\.0\.0\.0|\*:9222|\[::\]'; then
    bad "CDP bound beyond loopback — Path B should stay on 127.0.0.1 + SSH tunnel"
    info "$LISTEN"
  elif [[ -n "$LISTEN" ]]; then
    ok "CDP listen looks loopback-local"
  fi
fi

# SSH alias used by tunnel (LAN / hostname — not Tailscale)
SSH_HOST="${STUDIO_SSH_HOST:-studio}"
if ssh -o BatchMode=yes -o ConnectTimeout=3 "$SSH_HOST" 'echo ok' >/dev/null 2>&1; then
  ok "SSH to $SSH_HOST works (needed for tunnel-to-studio.sh)"
else
  bad "SSH to $SSH_HOST failed — Path B tunnel needs working Host studio (LAN/IP)"
  info "Fix ~/.ssh/config Host studio, or: STUDIO_SSH_HOST=<lan-host> bash tunnel-to-studio.sh"
fi

if [[ "$FAIL" -ne 0 ]]; then
  echo "doctor: FAIL"
  exit 1
fi
echo "doctor: OK (MacBook Path B ready — next: tunnel-to-studio.sh)"
