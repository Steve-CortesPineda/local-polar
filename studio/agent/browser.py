"""Thin CDP browser plane via Playwright connect_over_cdp."""

from __future__ import annotations

import os
from dataclasses import dataclass
from typing import Any

from playwright.sync_api import Browser, Page, Playwright, sync_playwright


@dataclass
class BrowserSession:
    playwright: Playwright
    browser: Browser
    page: Page

    def close(self) -> None:
        # Do not kill the user's Chrome — only disconnect.
        try:
            self.browser.close()
        finally:
            self.playwright.stop()


def connect(cdp_url: str | None = None) -> BrowserSession:
    url = (cdp_url or os.environ.get("CDP_URL") or "http://127.0.0.1:9222").rstrip("/")
    pw = sync_playwright().start()
    browser = pw.chromium.connect_over_cdp(url)
    if browser.contexts and browser.contexts[0].pages:
        page = browser.contexts[0].pages[0]
    elif browser.contexts:
        page = browser.contexts[0].new_page()
    else:
        ctx = browser.new_context()
        page = ctx.new_page()
    return BrowserSession(playwright=pw, browser=browser, page=page)


def observe(page: Page, max_chars: int = 6000) -> str:
    title = page.title()
    url = page.url
    try:
        body = page.inner_text("body")
    except Exception:
        body = ""
    body = " ".join(body.split())
    if len(body) > max_chars:
        body = body[: max_chars - 20] + " …[truncated]"

    # Lightweight interactive inventory for click/type targets
    try:
        controls = page.evaluate(
            """() => {
              const pick = (sel, n) => Array.from(document.querySelectorAll(sel))
                .slice(0, n)
                .map(el => {
                  const tag = el.tagName.toLowerCase();
                  const id = el.id ? `#${el.id}` : '';
                  const name = el.getAttribute('name') ? `[name="${el.getAttribute('name')}"]` : '';
                  const type = el.getAttribute('type') ? `[type="${el.getAttribute('type')}"]` : '';
                  const text = (el.innerText || el.value || el.getAttribute('aria-label') || '').trim().slice(0, 60);
                  return `${tag}${id}${name}${type}${text ? ' :: ' + text : ''}`;
                });
              return {
                links: pick('a[href]', 12),
                buttons: pick('button, [role=button], input[type=submit]', 12),
                inputs: pick('input, textarea, select', 12),
              };
            }"""
        )
    except Exception as e:
        controls = {"error": str(e)}

    return (
        f"url: {url}\n"
        f"title: {title}\n"
        f"controls: {controls}\n"
        f"body: {body}"
    )


def run_action(page: Page, action: dict[str, Any]) -> str:
    name = action.get("action")
    if name == "navigate":
        url = action["url"]
        page.goto(url, wait_until="domcontentloaded")
        return f"navigated:{url}"
    if name == "click":
        sel = action["selector"]
        page.click(sel, timeout=10_000)
        return f"clicked:{sel}"
    if name == "type":
        sel = action["selector"]
        text = action.get("text", "")
        page.fill(sel, text)
        if action.get("submit"):
            page.press(sel, "Enter")
        return f"typed:{sel}"
    if name == "scroll":
        dy = int(action.get("dy", 800))
        page.mouse.wheel(0, dy)
        return f"scrolled:{dy}"
    if name == "wait":
        ms = int(action.get("ms", 1000))
        page.wait_for_timeout(ms)
        return f"waited:{ms}"
    if name == "extract":
        note = action.get("note", "")
        snap = observe(page, max_chars=4000)
        return f"extract:{note}\n{snap}"
    if name == "done":
        return f"done:{action.get('result', '')}"
    return f"unknown_action:{name}"
