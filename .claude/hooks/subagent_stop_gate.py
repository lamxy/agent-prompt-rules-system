#!/usr/bin/env python3
"""Minimal command hook for SubagentStop.

Behavior:
- Block when required fields are clearly missing.
- Block when output appears to contain long, uncompressed reasoning.
- Approve + warning when external API calls seem > 3 or network timeout is detected.
- Otherwise approve.

This is a heuristic draft designed for low-latency operation.
"""

from __future__ import annotations

import json
import re
import sys
from typing import Iterable


LONG_TEXT_EXEMPT_LINE_THRESHOLD = 30
LONG_TEXT_EXEMPT_ZH_UNIQUE_THRESHOLD = 180


def _contains_any(text: str, keys: Iterable[str]) -> bool:
    return any(k in text for k in keys)


def _emit(payload: dict) -> None:
    # Use compact JSON to stay close to exact-output contract.
    print(json.dumps(payload, ensure_ascii=True, separators=(",", ":")))


def _is_long_text_exempt(raw: str) -> bool:
    """Exempt direct long-form reports from strict field/reasoning blocks.

    Exemption rule:
    - More than 30 lines, OR
    - Equivalent long text size by unique Chinese characters.
    """
    if not raw.strip():
        return False

    line_count = raw.count("\n") + 1
    # Count unique CJK ideographs as the Chinese-content scale signal.
    unique_zh_chars = len(set(re.findall(r"[\u3400-\u4dbf\u4e00-\u9fff]", raw)))

    # "Equivalent scale" for Chinese prose: enough unique Han characters.
    return (
        line_count > LONG_TEXT_EXEMPT_LINE_THRESHOLD
        or unique_zh_chars >= LONG_TEXT_EXEMPT_ZH_UNIQUE_THRESHOLD
    )


def main() -> int:
    try:
        raw = sys.stdin.read() or ""
        t = raw.lower()
        long_text_exempt = _is_long_text_exempt(raw)

        # Required minimal fields (allow close synonyms)
        required = {
            "state": ["state", "status"],
            "delta": ["delta", "change", "updates"],
            "evidence": ["evidence", "proof", "source"],
            "risk": ["risk", "severity"],
            "next": ["next", "next step", "action"],
            "ask": ["ask", "question", "needs confirmation"],
        }
        missing = [name for name, keys in required.items() if not _contains_any(t, keys)]
        if missing and not long_text_exempt:
            _emit({
                "decision": "block",
                "reason": "Subagent output missing minimal required fields: state/delta/evidence/risk/next/ask.",
            })
            return 0

        # Heuristic uncompressed reasoning detector
        reasoning_markers = [
            "step-by-step",
            "chain of thought",
            "reasoning:",
            "let's think",
            "thought process",
        ]
        long_output = len(raw) > 3500 or raw.count("\n") > 80
        if long_output and _contains_any(t, reasoning_markers) and not long_text_exempt:
            _emit({
                "decision": "block",
                "reason": "Subagent output contains uncompressed reasoning; provide a short structured summary.",
            })
            return 0

        warnings = []

        # External API call heuristic
        api_hits = len(re.findall(r"\b(webfetch\(|mcp__|https?://|api call|external api)\b", t))
        if api_hits > 3:
            warnings.append("external API calls > 3")

        # Network timeout heuristic
        timeout_markers = [
            "timeout",
            "timed out",
            "network timeout",
            "etimedout",
            "connection reset",
            "econn",
        ]
        if _contains_any(t, timeout_markers):
            warnings.append("external network timeout detected")

        if warnings:
            _emit({
                "decision": "approve",
                "systemMessage": "[subagent-warning] " + "; ".join(warnings),
            })
            return 0

        _emit({"decision": "approve"})
        return 0
    except Exception:
        # Fail-open for latency and robustness
        _emit({"decision": "approve"})
        return 0


if __name__ == "__main__":
    raise SystemExit(main())
