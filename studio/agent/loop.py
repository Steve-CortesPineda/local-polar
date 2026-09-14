"""Polar-like agent loop: observe → LLM action → execute → repeat."""

from __future__ import annotations

import os
import traceback
from typing import Callable

from . import browser, llm


def run(goal: str, on_event: Callable[[str], None] | None = None) -> str:
    log = on_event or (lambda s: print(s, flush=True))
    max_steps = int(os.environ.get("MAX_STEPS", "20"))
    session = browser.connect()
    history: list[str] = []
    final = ""

    try:
        log(f"[agent] CDP connected — goal: {goal}")
        for step in range(1, max_steps + 1):
            obs = browser.observe(session.page)
            log(f"[step {step}] observing {session.page.url}")
            try:
                action = llm.complete_action(obs, goal, history)
            except Exception as e:
                log(f"[step {step}] LLM error: {e}")
                final = f"LLM error: {e}"
                break

            log(f"[step {step}] action: {action}")
            try:
                result = browser.run_action(session.page, action)
            except Exception as e:
                result = f"action_error:{e}"
                log(f"[step {step}] {result}\n{traceback.format_exc()}")

            history.append(f"{step}. {action} → {result}")
            if action.get("action") == "done" or result.startswith("done:"):
                final = action.get("result") or result
                break
            if action.get("action") == "extract":
                # Keep going unless model also finished; store extract in history.
                continue
        else:
            final = final or "Reached MAX_STEPS without done."
    finally:
        session.close()

    log(f"[agent] done: {final}")
    return final
