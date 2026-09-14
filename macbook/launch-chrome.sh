#!/usr/bin/env bash
# Path B (optional): MacBook agent Chrome with dedicated profile + CDP on loopback.
# Studio reaches this via SSH reverse tunnel (see tunnel-to-studio.sh) — not Tailscale.
set -euo pipefail

PROFILE="${CHROME_AGENT_PROFILE:-$HOME/.chrome-agent-profile}"
PORT="${CDP_PORT:-9222}"
ORIGIN="http://127.0.0.1:${PORT}"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

mkdir -p "$PROFILE"

if [[ ! -x "$CHROME" ]]; then
  echo "Chrome not found at $CHROME" >&2
  exit 1
fi

if curl -sf "http://127.0.0.1:${PORT}/json/version" >/dev/null 2>&1; then
  echo "CDP already healthy on 127.0.0.1:${PORT}"
  curl -s "http://127.0.0.1:${PORT}/json/version" | head -c 400
  echo
  exit 0
fi

echo "MacBook agent Chrome (Path B — optional sessions)"
echo "  profile: $PROFILE"
echo "  CDP:     ${ORIGIN}"
echo "  next:    bash tunnel-to-studio.sh   # SSH -R to Studio"
echo "  note:    separate from daily Chrome — do NOT use default user-data-dir"

# Loopback only. Prefer specific Origin over remote-allow-origins=* .
# Do not pass --remote-debugging-address=0.0.0.0 unless you intentionally want LAN-direct.
exec "$CHROME" \
  --remote-debugging-port="$PORT" \
  --remote-allow-origins="$ORIGIN" \
  --user-data-dir="$PROFILE" \
  --no-first-run \
  --no-default-browser-check \
  about:blank
