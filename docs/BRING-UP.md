# Bring-up

## Path A — Studio only (primary)

Prereqs: Mac Studio with Chrome, Python 3.11+, and either mlx-think or `mlx_lm` serving on `:3211`.

```bash
cd ~/AVANTI-Local/Projects/local-polar
cp -n studio/.env.example studio/.env

# Terminal 1 — agent Chrome
bash studio/launch-chrome.sh
# Log into sites as needed (profile: ~/.chrome-agent-profile-studio)

# Terminal 2 — model (pick one)
# A) resurrect AVA mlx-think if Steve wants it
#    launchctl enable gui/$(id -u)/com.avanti.mlx-think
#    launchctl kickstart gui/$(id -u)/com.avanti.mlx-think
# B) or OpenAI-compat:
#    python -m mlx_lm.server --port 3211

# Terminal 2 — doctor + task
bash studio/doctor.sh
bash studio/bring-up.sh "open https://example.com and report the H1 text"
```

`bring-up.sh` creates `studio/.venv`, installs `requirements.txt`, and runs `python -m agent`.

## Path B — MacBook profile → Studio agent

Needs working SSH to Studio **without Tailscale** (LAN Host `studio`).

```bash
# MacBook T1
bash macbook/launch-chrome.sh

# MacBook T2
bash macbook/doctor.sh
bash macbook/tunnel-to-studio.sh

# Studio (same agent as Path A)
export CDP_URL=http://127.0.0.1:9222
bash studio/bring-up.sh "use my logged-in session and summarize the inbox page"
```

If Host `studio` is wrong on this network:

```bash
STUDIO_SSH_HOST=192.168.x.x bash macbook/tunnel-to-studio.sh
```

## Doctor cheat sheet

| Script | Checks |
|--------|--------|
| `studio/doctor.sh` | Local CDP, MLX `/health` or `/v1/models`, Python deps |
| `macbook/doctor.sh` | Local CDP loopback, SSH to Studio |

## Common failures

| Symptom | Fix |
|---------|-----|
| CDP connection refused | Start `*/launch-chrome.sh`; confirm `curl -s http://127.0.0.1:9222/json/version` |
| Playwright Origin / WS reject | Launch scripts set `--remote-allow-origins=http://127.0.0.1:9222` (not `*`) |
| Path B CDP on Studio empty | Tunnel not running; MacBook Chrome must be up first |
| LLM errors | `MLX_URL` down; start mlx server; try `MLX_BACKEND=openai` or `mlx_think` |
| Wrong cookies / logged out | Using wrong profile — Studio vs MacBook agent profiles are separate |
