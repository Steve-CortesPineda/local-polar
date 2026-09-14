# Studio half — Path A (primary)

Chrome + CDP + MLX agent loop all run here.

## Commands

```bash
bash launch-chrome.sh          # dedicated Studio agent Chrome
bash doctor.sh                 # CDP + MLX + deps
bash bring-up.sh "task…"       # venv + run agent

# or manually
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp -n .env.example .env
python -m agent "open https://example.com and tell me the title"
```

## Env

See `.env.example`. Defaults assume localhost CDP and `MLX_URL=http://127.0.0.1:3211`.

## Model

Prefer existing AVA stack on this machine:

- OpenAI-compat: `python -m mlx_lm.server --port 3211`
- Or mlx-think on `:3211` if Steve re-enables it (disabled 2026-08-21)

Do not put heavy inference on the MacBook.
