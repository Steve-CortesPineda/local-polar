"""CLI: python -m agent \"your task\"."""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path


def _load_dotenv() -> None:
    env_path = Path(__file__).resolve().parents[1] / ".env"
    if not env_path.is_file():
        return
    for line in env_path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, v = line.split("=", 1)
        os.environ.setdefault(k.strip(), v.strip())


def main(argv: list[str] | None = None) -> int:
    _load_dotenv()
    p = argparse.ArgumentParser(description="local-polar Studio browser agent")
    p.add_argument("goal", nargs="+", help="Natural-language browser task")
    p.add_argument("--cdp", default=None, help="Override CDP_URL")
    p.add_argument("--mlx", default=None, help="Override MLX_URL")
    args = p.parse_args(argv)

    if args.cdp:
        os.environ["CDP_URL"] = args.cdp
    if args.mlx:
        os.environ["MLX_URL"] = args.mlx

    goal = " ".join(args.goal)
    from .loop import run

    result = run(goal)
    print("\n=== RESULT ===")
    print(result)
    return 0


if __name__ == "__main__":
    sys.exit(main())
