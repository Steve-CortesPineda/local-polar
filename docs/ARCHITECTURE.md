# Architecture

## Product boundary

**local-polar** = browser agent (this repo).  
**Asteria Polar-like** = separate supervisor in `~/AVANTI-Local/Projects/asteria/` (`polar_like_tick.py`, `docs/POLAR-LIKE.md`). Do not merge repos. Optionally adapt tick/observe patterns; local-polar owns the browser-agent product.

## Planes

| Plane | Machine | Responsibility |
|-------|---------|----------------|
| Compute | Mac Studio | MLX inference + agent loop (`studio/agent`) |
| Browser (Path A) | Mac Studio | Dedicated Chrome + CDP `:9222` loopback |
| Browser (Path B) | MacBook | Logged-in Chrome; exposed to Studio via **SSH reverse tunnel** |

## Networking (Tailscale not required)

### Path A — default

Everything on Studio. `CDP_URL=http://127.0.0.1:9222`. No cross-machine CDP. MacBook optional (SSH/Cursor into Studio).

### Path B — optional MacBook sessions

1. MacBook: `macbook/launch-chrome.sh` (CDP on `127.0.0.1:9222` only).
2. MacBook: `macbook/tunnel-to-studio.sh` → `ssh -N -R 127.0.0.1:9222:127.0.0.1:9222 studio`.
3. Studio agent unchanged: still talks to localhost CDP (tunnel endpoint).

SSH Host `studio` should resolve over **LAN / local hostname / IP** (see `~/.ssh/config`). Tailscale IPs are not documented as the default.

### LAN-direct (advanced)

Only if SSH tunnels are undesirable: bind Chrome debugging to a private LAN address and firewall so only Studio can connect. Prefer Path B tunnel; do not use `remote-allow-origins=*`.

## Model stack

Prefer **reuse** of Studio AVA/MLX:

1. **OpenAI-compatible** `mlx_lm.server` on `:3211` → `/v1/chat/completions` (best for JSON actions).
2. **mlx-think** (`~/ava-overlay/sidecar/mlx_think_server.py`, launchd `com.avanti.mlx-think`) → `POST /think`.

`MLX_BACKEND=auto` probes `/v1/models` then `/health`. Note: mlx-think was disabled in the 2026-08-21 daemon sweep — only restart if Steve wants local inference back.

## Agent loop (MVP)

1. Connect Playwright over CDP (do not launch a second Chromium).
2. Observe: URL, title, control inventory, truncated body text.
3. Ask MLX for one JSON action (`navigate|click|type|scroll|wait|extract|done`).
4. Execute; repeat until `done` or `MAX_STEPS`.

Thin by design — not a full product UI.
