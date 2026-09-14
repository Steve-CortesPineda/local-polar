#!/usr/bin/env bash
# Path A: Studio-local agent Chrome + CDP on loopback only.
# No Tailscale. Do not bind to 0.0.0.0.
set -euo pipefail

PROFILE="${CHROME_AGENT_PROFILE:-$HOME/.chrome-agent-profile-studio}"
PORT="${CDP_PORT:-9222}"
ORIGIN="http://127.0.0.1:${PORT}"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

mkdir -p "$PROFILE"

if [[ ! -x "$CHROME" ]]; then
  echo "Chrome not found at $CHROME" >&2
  exit 1
fi

# Fail fast if something else already owns the port.
if curl -sf "http://127.0.0.1:${PORT}/json/version" >/dev/null 2>&1; then
  echo "CDP already healthy on 127.0.0.1:${PORT}"
  curl -s "http://127.0.0.1:${PORT}/json/version" | head -c 400
  echo
  exit 0
fi

echo "Studio agent Chrome (Path A)"
echo "  profile: $PROFILE"
echo "  CDP:     ${ORIGIN}"
echo "  bind:    loopback only (no LAN / no Tailscale)"
echo "  note:    separate from daily Chrome — do NOT use default user-data-dir"

exec "$CHROME" \
  --remote-debugging-port="$PORT" \
  --remote-allow-origins="$ORIGIN" \
  --user-data-dir="$PROFILE" \
  --no-first-run \
  --no-default-browser-check \
  about:blank
