# MacBook half — Path B (optional)

Use only when the agent needs **this laptop’s** logged-in Chrome profile.  
Default product path is **Studio Path A** (`../studio/`).

## Commands

```bash
bash launch-chrome.sh          # CDP on 127.0.0.1:9222, dedicated profile
bash doctor.sh                 # CDP + SSH-to-studio check
bash tunnel-to-studio.sh       # ssh -N -R … studio  (leave open)
```

On Studio, keep `CDP_URL=http://127.0.0.1:9222` — the reverse tunnel makes MacBook Chrome appear local.

## Notes

- Profile: `~/.chrome-agent-profile` (not daily Chrome).
- No Tailscale. SSH Host defaults to `studio` (LAN/IP in `~/.ssh/config`).
- Override: `STUDIO_SSH_HOST=… bash tunnel-to-studio.sh`
- CDP stays on loopback; do not expose `:9222` to the internet.
