#!/usr/bin/env python3
"""Minimal command hook for SubagentStop.

Behavior:
- Block when the subagent's final message exceeds size limits
  (>3000 characters OR >150 lines), so oversized output is saved to a file
  and only a summary + path reaches the main agent.
  Field-format checking is intentionally omitted to avoid conflicts with
  commands that use their own fixed output formats (e.g. /auditrules).
- Otherwise print nothing, which lets the subagent stop normally.

SubagentStop block semantics (per the official hooks reference):
  `decision: "block"` keeps the subagent running and delivers `reason` to it as
  its next instruction, so the subagent CAN still write the artifact file.
  `"block"` is the only valid decision value; to allow stopping, omit it.

Loop guard:
  `stop_hook_active` is true when the subagent is already continuing because
  of a stop hook. In that case the hook never blocks again.

Size thresholds:
- Characters (len of the decoded string, so one CJK character counts as one):
  primary gate.
- Line count: secondary gate, 150 to avoid false positives on line-dense
  output such as code listings or JSON arrays.
"""

from __future__ import annotations

import json
import os
import sys
from datetime import datetime


SIZE_BLOCK_TOTAL_CHARS = 3000
SIZE_BLOCK_LINE_COUNT = 150


def _debug_log(stdin_raw: str, output: dict | None) -> None:
    """Append a structured debug entry to the file in SUBAGENT_STOP_DEBUG_LOG.

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


def _final_message(payload: object) -> str:
    """Return the subagent's final message from SubagentStop input."""
    if isinstance(payload, dict):
        message = payload.get("last_assistant_message")
        if isinstance(message, str):
            return message
    return ""


def _exceeds_size_limit(text: str) -> tuple[bool, int, int]:
    """Return (exceeded, total_chars, line_count)."""
    if not text.strip():
        return False, 0, 0
    total_chars = len(text)
    line_count = text.count("\n") + 1
    exceeded = total_chars > SIZE_BLOCK_TOTAL_CHARS or line_count > SIZE_BLOCK_LINE_COUNT
    return exceeded, total_chars, line_count


def main() -> int:
    stdin_raw = ""
    try:
        stdin_raw = sys.stdin.read() or ""
        payload = json.loads(stdin_raw) if stdin_raw.strip() else {}

        if isinstance(payload, dict) and payload.get("stop_hook_active"):
            _debug_log(stdin_raw, None)
            return 0

        exceeded, total_chars, line_count = _exceeds_size_limit(_final_message(payload))
        if not exceeded:
            _debug_log(stdin_raw, None)
            return 0

        output = {
            "decision": "block",
            "reason": (
                f"Your final output is too large ({total_chars} chars, {line_count} lines; "
                f"limits: {SIZE_BLOCK_TOTAL_CHARS} chars, {SIZE_BLOCK_LINE_COUNT} lines). "
                "Write the full content to a file under the project's .claude/artifacts/ directory, "
                "named {task}_{role}_{last 6 chars of a timestamp}.{ext} as sub-agent-rule-min.md requires, "
                "then reply with a summary of at most 10 lines plus the absolute path of that file."
            ),
        }
        _debug_log(stdin_raw, output)
        print(json.dumps(output, ensure_ascii=True, separators=(",", ":")))
        return 0
    except Exception:
        # Fail open: print nothing so the subagent stops normally.
        _debug_log(stdin_raw, None)
        return 0


if __name__ == "__main__":
    raise SystemExit(main())
