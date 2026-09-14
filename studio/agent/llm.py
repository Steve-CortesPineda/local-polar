"""LLM backends for local-polar: OpenAI-compat (mlx_lm.server) or AVA mlx-think."""

from __future__ import annotations

import json
import os
import re
from typing import Any

import httpx

SYSTEM_PROMPT = """You are a local browser agent controlling Chrome via CDP.
You receive the current page observation and must reply with ONE JSON object only
(no markdown fences), choosing exactly one action:

{"action":"navigate","url":"https://..."}
{"action":"click","selector":"css selector"}
{"action":"type","selector":"css selector","text":"...","submit":false}
{"action":"scroll","dy":800}
{"action":"wait","ms":1000}
{"action":"extract","note":"what to capture from the page"}
{"action":"done","result":"final answer for the user"}

Rules:
- Prefer simple CSS selectors (a, button, input, [role=button], text-ish).
- Never invent private credentials; stop with done if login is required.
- Prefer extract/done once you have enough to answer.
- Stay on-task; max one action per turn.
"""


class LLMError(RuntimeError):
    pass


def _base() -> str:
    return os.environ.get("MLX_URL", "http://127.0.0.1:3211").rstrip("/")


def _backend() -> str:
    return os.environ.get("MLX_BACKEND", "auto").strip().lower()


def detect_backend(client: httpx.Client | None = None) -> str:
    forced = _backend()
    if forced in {"openai", "mlx_think"}:
        return forced
    own = client is None
    client = client or httpx.Client(timeout=5.0)
    try:
        if client.get(f"{_base()}/v1/models").status_code == 200:
            return "openai"
        if client.get(f"{_base()}/health").status_code == 200:
            return "mlx_think"
    finally:
        if own:
            client.close()
    # Default preference: OpenAI-compat path (better for structured JSON)
    return "openai"


def _parse_json_action(text: str) -> dict[str, Any]:
    text = text.strip()
    if text.startswith("```"):
        text = re.sub(r"^```(?:json)?\s*", "", text)
        text = re.sub(r"\s*```$", "", text)
    try:
        data = json.loads(text)
        if isinstance(data, dict) and "action" in data:
            return data
    except json.JSONDecodeError:
        pass
    m = re.search(r"\{.*\}", text, re.DOTALL)
    if m:
        data = json.loads(m.group(0))
        if isinstance(data, dict) and "action" in data:
            return data
    raise LLMError(f"Model did not return a valid action JSON: {text[:400]}")


def complete_action(observation: str, goal: str, history: list[str]) -> dict[str, Any]:
    """Ask the model for the next browser action."""
    hist = "\n".join(history[-8:]) if history else "(none)"
    user = (
        f"GOAL:\n{goal}\n\n"
        f"RECENT ACTIONS:\n{hist}\n\n"
        f"OBSERVATION:\n{observation}\n\n"
        "Reply with one JSON action object."
    )
    with httpx.Client(timeout=float(os.environ.get("AGENT_TIMEOUT_S", "120"))) as client:
        backend = detect_backend(client)
        if backend == "openai":
            raw = _openai_chat(client, user)
        else:
            raw = _mlx_think(client, user)
    return _parse_json_action(raw)


def _openai_chat(client: httpx.Client, user: str) -> str:
    model = os.environ.get("MLX_MODEL", "local")
    r = client.post(
        f"{_base()}/v1/chat/completions",
        json={
            "model": model,
            "temperature": 0.2,
            "messages": [
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": user},
            ],
        },
    )
    if r.status_code >= 400:
        raise LLMError(f"OpenAI-compat error {r.status_code}: {r.text[:500]}")
    data = r.json()
    try:
        return data["choices"][0]["message"]["content"]
    except (KeyError, IndexError, TypeError) as e:
        raise LLMError(f"Bad OpenAI-compat payload: {data!r}") from e


def _mlx_think(client: httpx.Client, user: str) -> str:
    # AVA mlx-think historically accepts a prompt blob; keep payload flexible.
    prompt = f"{SYSTEM_PROMPT}\n\n{user}"
    payloads = [
        {"prompt": prompt, "max_tokens": 512},
        {"input": prompt, "max_tokens": 512},
        {"text": prompt},
    ]
    last_err = None
    for body in payloads:
        r = client.post(f"{_base()}/think", json=body)
        if r.status_code < 400:
            data = r.json() if r.headers.get("content-type", "").startswith("application/json") else {"text": r.text}
            for key in ("text", "output", "response", "content", "result"):
                if isinstance(data, dict) and isinstance(data.get(key), str):
                    return data[key]
            if isinstance(data, str):
                return data
            return json.dumps(data)
        last_err = f"{r.status_code}: {r.text[:300]}"
    raise LLMError(f"mlx-think /think failed: {last_err}")
