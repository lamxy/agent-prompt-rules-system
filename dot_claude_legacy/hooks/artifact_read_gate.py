#!/usr/bin/env python3
"""PreToolUse hook for the Read tool: makes the main agent declare its intent
before reading a subagent artifact.

Artifact paths are files with a text extension under the project's
.claude/artifacts/ or under ~/.claude/artifacts/, matching where
sub-agent-rule-min.md tells subagents to write.

Decision matrix:
  - first Read of an artifact in a session -> deny + intent prompt
  - repeated Read of the same artifact      -> no output (normal permission flow),
    so declaring "process" intent and re-issuing the Read lets it through
  - non-artifact path                       -> no output (normal permission flow)
  - any error                               -> no output (fail open)

The hook never returns permissionDecision "allow": "allow" skips the permission
prompt, which would silently widen access for every Read.
"""

from __future__ import annotations

import hashlib
import json
import os
import sys
import tempfile


ARTIFACT_EXTENSIONS = {".md", ".txt", ".json", ".html", ".csv", ".yaml", ".yml"}
MARKER_DIR = os.path.join(tempfile.gettempdir(), "claude-artifact-read-gate")

INTENT_PROMPT = (
    "ARTIFACT-READ-GATE: 你即将读取子代理 artifact 文件。\n"
    "必须先在本条消息中声明处理意图，再决定是否继续：\n"
    "  • 意图=「转交」（文档/报告/代码等最终产物，用户直接消费）"
    " → 禁止读取，直接告知用户文件路径。\n"
    "  • 意图=「加工」（需要主代理分析/对比/翻译/汇总）"
    " → 允许读取，请对同一文件重新发起 Read（本会话对该文件只拦截一次）。\n"
    "  • 意图不明确 → 默认「转交」，询问用户是否需要进一步加工。\n"
    "本次 Read 已被阻止，请声明意图后再操作。"
)


def _artifact_dirs(cwd: str) -> list[str]:
    return [
        os.path.join(cwd, ".claude", "artifacts"),
        os.path.expanduser("~/.claude/artifacts"),
    ]


def _is_artifact_path(path: str, cwd: str) -> bool:
    if not path:
        return False
    _, ext = os.path.splitext(path)
    if ext.lower() not in ARTIFACT_EXTENSIONS:
        return False
    abs_path = os.path.realpath(os.path.join(cwd, os.path.expanduser(path)))
    for directory in _artifact_dirs(cwd):
        abs_dir = os.path.realpath(directory)
        if abs_path.startswith(abs_dir + os.sep):
            return True
    return False


def _first_read_in_session(session_id: str, path: str, cwd: str) -> bool:
    """Record the read and return True only the first time per session and file."""
    abs_path = os.path.realpath(os.path.join(cwd, os.path.expanduser(path)))
    key = hashlib.sha256(f"{session_id}\0{abs_path}".encode("utf-8")).hexdigest()
    marker = os.path.join(MARKER_DIR, key)
    if os.path.exists(marker):
        return False
    os.makedirs(MARKER_DIR, exist_ok=True)
    with open(marker, "w", encoding="utf-8"):
        pass
    return True


def main() -> int:
    try:
        data = json.loads(sys.stdin.read() or "{}")
        file_path = data.get("tool_input", {}).get("file_path", "")
        cwd = data.get("cwd") or os.getcwd()
        session_id = data.get("session_id", "")

        if _is_artifact_path(file_path, cwd) and _first_read_in_session(session_id, file_path, cwd):
            print(json.dumps({
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "permissionDecision": "deny",
                    "permissionDecisionReason": INTENT_PROMPT,
                },
            }, ensure_ascii=False))
        return 0
    except Exception:
        # Fail open: print nothing so the normal permission flow applies.
        return 0


if __name__ == "__main__":
    raise SystemExit(main())
