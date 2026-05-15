#!/usr/bin/env python3
"""Minimal command hook for SubagentStop.

Behavior:
- Block when output exceeds size limits (>3000 unique chars OR >50 lines).
  Rationale: oversized output must be saved to file and only a summary+path
  returned to the main agent. Field-format checking is intentionally removed
  to avoid conflicts with commands that use their own fixed output formats
  (e.g. /auditrules).
- Otherwise approve.

This is a size-only gate designed for low-latency, format-agnostic operation.
"""

from __future__ import annotations

import json
import os
import sys
from datetime import datetime


SIZE_BLOCK_UNIQUE_CHARS = 3000
SIZE_BLOCK_LINE_COUNT = 50


def _debug_log(stdin_raw: str, output: dict) -> None:
    """Append a structured debug entry to file specified by SUBAGENT_STOP_DEBUG_LOG.

    Each entry contains a timestamp, the raw stdin received, and the JSON output emitted.
    No-op when the env var is unset or empty.
    """
    log_path = os.getenv("SUBAGENT_STOP_DEBUG_LOG", "")
    if not log_path:
        return
    try:
        ts = datetime.now().strftime("%Y-%m-%dT%H:%M:%S")
        entry = (
            f"\n--- [{ts}] subagent_stop_gate ---\n"
            f"[stdin]\n{stdin_raw}\n"
            f"[output]\n{json.dumps(output, ensure_ascii=False)}\n"
        )
        with open(log_path, "a", encoding="utf-8") as f:
            f.write(entry)
    except Exception:
        pass  # debug logging must never affect main flow


def _emit(payload: dict, stdin_raw: str = "") -> None:
    _debug_log(stdin_raw, payload)
    print(json.dumps(payload, ensure_ascii=True, separators=(",", ":")))


def _normalize_stdin_for_checks(raw: str) -> str:
    """SubagentStop stdin is typically JSON; fallback to raw text if parsing fails."""
    if not raw.strip():
        return ""
    try:
        payload = json.loads(raw)
    except Exception:
        return raw

    if isinstance(payload, dict):
        for key in ("last_assistant_message", "output", "result", "text", "content", "response", "message"):
            v = payload.get(key)
            if isinstance(v, str) and v.strip():
                return v
        return json.dumps(payload, ensure_ascii=False)
    if isinstance(payload, list):
        return json.dumps(payload, ensure_ascii=False)
    return str(payload)


def _placeholder(raw: str) -> bool:
    """Placeholder to satisfy import; kept for structural parity.

    Exemption rule:
    - More than 30 lines, OR
    - Equivalent long text size by unique Chinese characters.
    """
    if not raw.strip():
        return False

    line_count = raw.count("\n") + 1
    return line_count > SIZE_BLOCK_LINE_COUNT  # unused placeholder


def main() -> int:
    try:
        stdin_raw = sys.stdin.read() or ""
        raw = _normalize_stdin_for_checks(stdin_raw)

        # Size gate: block if output exceeds limits.
        # Subagent must save oversized content to a file and return only
        # a short summary + artifact path.
        unique_char_count = len(set(raw))
        line_count = raw.count("\n") + 1

        if unique_char_count > SIZE_BLOCK_UNIQUE_CHARS or line_count > SIZE_BLOCK_LINE_COUNT:
            _emit({
                "decision": "block",
                "reason": (
                    f"Subagent output too large (unique chars={unique_char_count}, lines={line_count}). "
                    "Save full content to a file and return only a short summary + artifact path."
                ),
            }, stdin_raw)
            return 0

        _emit({"decision": "approve"}, stdin_raw)
        return 0
    except Exception:
        # Fail-open for latency and robustness
        _emit({"decision": "approve"})
        return 0


if __name__ == "__main__":
    raise SystemExit(main())
