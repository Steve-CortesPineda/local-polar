#!/usr/bin/env bash
# Path B: SSH reverse tunnel — MacBook Chrome CDP → Studio localhost:9222.
# No Tailscale. Uses existing SSH Host (default: studio = LAN/IP from ~/.ssh/config).
#
# On Studio, agent keeps CDP_URL=http://127.0.0.1:9222
set -euo pipefail

PORT="${CDP_PORT:-9222}"
SSH_HOST="${STUDIO_SSH_HOST:-studio}"
LOCAL_CDP="127.0.0.1:${PORT}"

if ! curl -sf "http://${LOCAL_CDP}/json/version" >/dev/null 2>&1; then
  echo "MacBook CDP not up on ${LOCAL_CDP}" >&2
  echo "Run: bash $(dirname "$0")/launch-chrome.sh" >&2
  exit 1
fi

echo "Tunneling MacBook CDP → ${SSH_HOST}:127.0.0.1:${PORT}"
echo "  local:  http://${LOCAL_CDP}"
echo "  remote: Studio agent uses CDP_URL=http://127.0.0.1:${PORT}"
echo "  leave this terminal open (ssh -N)"
echo

# -R: Studio:9222 → this MacBook's Chrome
# GatewayPorts not required when binding remote to loopback (default).
exec ssh -N -o ExitOnForwardFailure=yes -R "127.0.0.1:${PORT}:${LOCAL_CDP}" "$SSH_HOST"
