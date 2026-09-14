# local-polar

Local AI **web browser agent**. Studio owns MLX compute + the agent loop. Chrome/CDP is local on Studio by default.

**Not Asteria Polar-like.** Asteria (`~/AVANTI-Local/Projects/asteria/`) is a separate supervisor product. Patterns may be adapted; do not merge this repo into Asteria.

## Architecture (no Tailscale required)

| Path | When | Where Chrome lives | How agent reaches CDP |
|------|------|--------------------|------------------------|
| **A (default)** | Normal use | **Mac Studio** | `CDP_URL=http://127.0.0.1:9222` (same machine) |
| **B (optional)** | Need MacBook logged-in profile | **MacBook** | SSH reverse tunnel → Studio still uses `127.0.0.1:9222` |

MacBook is optional for Path A (SSH/Cursor remote into Studio is enough). Tailscale is **not** a dependency.

```
┌──────────────────────────── Mac Studio ────────────────────────────┐
│  MLX (:3211 mlx-think or mlx_lm.server)                            │
│       ↑                                                            │
│  studio/agent  ←→  CDP http://127.0.0.1:9222  ←→  Chrome (Path A) │
│                         ↑                                          │
│              optional SSH -R from MacBook (Path B)                 │
└────────────────────────────────────────────────────────────────────┘
```

## Quick start — Path A (Studio)

```bash
# On Studio
cd ~/AVANTI-Local/Projects/local-polar

# 1) Agent Chrome (dedicated profile)
bash studio/launch-chrome.sh

# 2) Model endpoint (reuse AVA; do not invent a second stack)
#    If mlx-think is intentionally down, either resurrect it or:
#    python -m mlx_lm.server --port 3211

# 3) Doctor + run
cp -n studio/.env.example studio/.env   # once
bash studio/doctor.sh
bash studio/bring-up.sh "open https://example.com and tell me the H1"
# or:  cd studio && python -m agent "…"
```

## Path B — MacBook sessions via SSH tunnel

```bash
# MacBook terminal 1
bash macbook/launch-chrome.sh
bash macbook/doctor.sh

# MacBook terminal 2 — reverse tunnel (LAN SSH Host `studio`, not Tailscale)
bash macbook/tunnel-to-studio.sh
# equiv: ssh -N -R 127.0.0.1:9222:127.0.0.1:9222 studio

# Studio — same as Path A; CDP still localhost through the tunnel
export CDP_URL=http://127.0.0.1:9222
bash studio/bring-up.sh "check my logged-in site and summarize"
```

Override SSH target: `STUDIO_SSH_HOST=steve-studio.local bash macbook/tunnel-to-studio.sh`

Advanced LAN-direct (no tunnel): bind CDP only to a private LAN address and firewall to Studio — not the default; prefer the SSH `-R` path.

## Env vars

| Var | Default | Meaning |
|-----|---------|---------|
| `CDP_URL` | `http://127.0.0.1:9222` | Chrome DevTools endpoint (Path A and Path B) |
| `MLX_URL` | `http://127.0.0.1:3211` | Model server (mlx-think or OpenAI-compat) |
| `MLX_BACKEND` | `auto` | `auto` \| `openai` \| `mlx_think` |
| `MLX_MODEL` | `local` | Model name for `/v1/chat/completions` |
| `MAX_STEPS` | `20` | Agent loop cap |
| `CDP_PORT` | `9222` | Port for launch/doctor/tunnel scripts |
| `STUDIO_SSH_HOST` | `studio` | SSH Host for Path B tunnel |

## Layout

```
local-polar/
  README.md
  docs/ARCHITECTURE.md
  docs/BRING-UP.md
  macbook/          # Path B only
  studio/           # Path A agent + Studio Chrome
    agent/          # Python MLX + CDP loop
    launch-chrome.sh
    doctor.sh
    bring-up.sh
```

## Hardening notes

- CDP binds **loopback**; scripts use `--remote-allow-origins=http://127.0.0.1:9222` instead of `*`.
- Dedicated Chrome profiles: Studio `~/.chrome-agent-profile-studio`, MacBook `~/.chrome-agent-profile` — never daily Chrome.
- Vortex / vanta-chrome are retired — do not resurrect.
- No secrets in git (`.env` gitignored).

## Status / prerequisites for Steve

- **Studio unreachable from this MacBook session** (SSH to `studio` timed out; Tailscale stopped — and Tailscale is no longer required anyway). Studio half is scaffolded under `studio/` so it runs when Steve is on Studio or LAN SSH works.
- Asteria Polar-like (`polar_like_tick.py`, `docs/POLAR-LIKE.md`) was **not** readable (Studio down). Agent loop is a thin observe→act MVP inspired by the Polar-like *role* (supervisor elsewhere), not a copy of Asteria code.
- mlx-think was deliberately disabled 2026-08-21 — Steve must choose: resurrect `com.avanti.mlx-think` or run `mlx_lm.server`.
- Log into agent Chrome profiles for sites that need auth (Path A on Studio, or Path B on MacBook).
