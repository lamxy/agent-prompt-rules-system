"""Tests for dot_claude/skills/mysession-eval/scripts/mysession-eval (run via test-mysession-eval.sh)."""
import importlib.machinery
import importlib.util
import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))
TOOL = os.path.join(REPO, "dot_claude", "skills", "mysession-eval", "scripts", "mysession-eval")


def load_tool():
    loader = importlib.machinery.SourceFileLoader("mse", TOOL)
    spec = importlib.util.spec_from_loader("mse", loader)
    mod = importlib.util.module_from_spec(spec)
    loader.exec_module(mod)
    return mod


mse = load_tool()
SCRIPT = "python3 ~/.claude/skills/mysession-eval/scripts/mysession-eval"
_ts = [0]


def _stamp():
    _ts[0] += 1
    return "2026-11-05T10:%02d:%02d.000Z" % (_ts[0] // 60 % 60, _ts[0] % 60)


# ---- synthetic jsonl entries ----
def user(text):
    return {"type": "user", "timestamp": _stamp(), "message": {"role": "user", "content": text}}


def user_blocks(*texts):
    return {"type": "user", "timestamp": _stamp(),
            "message": {"role": "user", "content": [{"type": "text", "text": t} for t in texts]}}


def meta(text):
    return {"type": "user", "isMeta": True, "timestamp": _stamp(),
            "message": {"role": "user", "content": [{"type": "text", "text": text}]}}


def slash(name, args=""):
    return user("<command-message>%s</command-message>\n<command-name>/%s</command-name>%s"
                % (name, name, ("\n<command-args>%s</command-args>" % args) if args else ""))


def invoke():
    return slash("mysession-eval")


def assistant_text(text="ok", mid=None, usage=None):
    msg = {"role": "assistant", "id": mid or ("m%d" % _ts[0]), "content": [{"type": "text", "text": text}]}
    if usage:
        msg["usage"] = usage
    return {"type": "assistant", "timestamp": _stamp(), "message": msg}


def tool_use(name, inp, tid, mid=None, usage=None):
    msg = {"role": "assistant", "id": mid or ("m-" + tid),
           "content": [{"type": "tool_use", "id": tid, "name": name, "input": inp}]}
    if usage:
        msg["usage"] = usage
    return {"type": "assistant", "timestamp": _stamp(), "message": msg}


def tool_result(tid, content="done", is_error=False):
    block = {"type": "tool_result", "tool_use_id": tid, "content": content}
    if is_error:
        block["is_error"] = True
    return {"type": "user", "timestamp": _stamp(), "message": {"role": "user", "content": [block]}}


def script_call(tid, sub="extract"):
    return tool_use("Bash", {"command": "%s %s" % (SCRIPT, sub)}, tid)


def script_result(tid):
    return tool_result(tid, "{}")


class Base(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.claude = os.path.join(self.tmp, "claude")
        self.home = os.path.join(self.tmp, "home")
        self.proj = os.path.join(self.tmp, "proj")
        os.makedirs(os.path.join(self.claude, "projects", "-enc-proj"))
        os.makedirs(self.proj)

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    def write_session(self, sid, entries):
        path = os.path.join(self.claude, "projects", "-enc-proj", sid + ".jsonl")
        with open(path, "w", encoding="utf-8") as f:
            for e in entries:
                f.write(json.dumps(e, ensure_ascii=False) + "\n")
        return path

    def run_cli(self, *args, sid="s1", env_extra=None):
        env = dict(os.environ)
        env.update({"MSE_CLAUDE_DIR": self.claude, "MSE_HOME": self.home, "MSE_PROJECT_DIR": self.proj,
                    "CLAUDE_PROJECT_DIR": ""})
        if sid is None:
            env.pop("CLAUDE_CODE_SESSION_ID", None)
        else:
            env["CLAUDE_CODE_SESSION_ID"] = sid
        env.update(env_extra or {})
        return subprocess.run([sys.executable, "-I", TOOL] + list(args), env=env,
                              capture_output=True, text=True)


# ---- Task 1 ----
class TestSessionAndBounds(Base):
    def test_find_session_file_missing_raises(self):
        with self.assertRaises(mse.Fail):
            mse.find_session_file("nope", self.claude)
        with self.assertRaises(mse.Fail):
            mse.find_session_file("", self.claude)

    def test_find_session_file_found(self):
        path = self.write_session("abc", [user("hi")])
        self.assertEqual(mse.find_session_file("abc", self.claude), path)

    def test_load_entries_skips_bad_lines(self):
        path = self.write_session("abc", [user("hi")])
        with open(path, "a") as f:
            f.write("not json\n")
        self.assertEqual(len(mse.load_entries(path)), 1)

    def test_bounds_no_previous_invocation(self):
        self.assertEqual(mse.segment_bounds([user("a"), assistant_text(), invoke()]), (0, 2))

    def test_bounds_no_invocation_at_all(self):
        self.assertEqual(mse.segment_bounds([user("a"), assistant_text()]), (0, 2))

    def test_bounds_with_previous_invocation(self):
        es = [user("a"), invoke(), script_call("t1"), script_result("t1"), assistant_text(),
              user("b"), assistant_text(), invoke()]
        self.assertEqual(mse.segment_bounds(es), (4, 7))

    def test_segment_skips_previous_skill_run(self):
        es = [user("a"), invoke(), script_call("t1"), script_result("t1"),
              assistant_text("which score?"), user("4"),
              script_call("t2", "append --task x"), script_result("t2"), assistant_text("recorded"),
              user("next job"), assistant_text(), invoke()]
        self.assertEqual(mse.segment_bounds(es), (8, 11))

    def test_empty_segment(self):
        es = [user("a"), invoke(), script_call("t1"), script_result("t1"), invoke()]
        start, end = mse.segment_bounds(es)
        self.assertEqual(start, end)

    def test_bounds_previous_invocation_without_script(self):
        self.assertEqual(mse.segment_bounds([invoke(), user("b"), invoke()]), (1, 2))

    def test_is_skill_script_call(self):
        self.assertEqual(mse.is_skill_script_call(script_call("t9")), {"t9"})
        self.assertEqual(mse.is_skill_script_call(tool_use("Bash", {"command": "ls"}, "t8")), set())
        self.assertEqual(mse.is_skill_script_call(user("x")), set())

    def test_is_invocation(self):
        self.assertTrue(mse.is_invocation(invoke()))
        self.assertFalse(mse.is_invocation(slash("myplugins")))
        self.assertFalse(mse.is_invocation(meta("<command-name>/mysession-eval</command-name>")))


# ---- Task 2 ----
def nested_rule(path):
    return {"type": "attachment", "timestamp": _stamp(),
            "attachment": {"type": "nested_memory", "path": path,
                           "content": {"path": path, "type": "Project", "content": "rule"}}}


def metrics_of(entries, subagent_dir=None):
    return mse.segment_metrics(entries, 0, len(entries), subagent_dir)


class TestMetrics(Base):
    def test_metrics_skill_slash_and_tool(self):
        es = [tool_use("Skill", {"skill": "db-schema-design"}, "k1"), tool_result("k1"),
              slash("myplugins", "3"), meta("Base directory for this skill: /x/myplugins"),
              slash("clear"), user("hi")]
        self.assertEqual(metrics_of(es)["skills"], {"db-schema-design": 1, "myplugins": 1})

    def test_metrics_agents_mcp_rules(self):
        es = [tool_use("Agent", {"prompt": "x"}, "a1"), tool_result("a1"),
              tool_use("mcp__x__q", {}, "q1"), tool_result("q1"),
              tool_use("mcp__x__q", {}, "q2"), tool_result("q2"),
              nested_rule("/p/.claude/rules/go.md")]
        m = metrics_of(es)
        self.assertEqual(m["agents"], {"general-purpose": 1})
        self.assertEqual(m["mcp"], {"mcp__x__q": 2})
        self.assertEqual(m["rules_loaded"], {"/p/.claude/rules/go.md": 1})

    def test_metrics_denials_and_errors(self):
        es = [tool_use("Read", {}, "d1"),
              tool_result("d1", "File is in a directory that is denied by your permission settings.", True),
              tool_use("Bash", {"command": "rm x"}, "d2"),
              tool_result("d2", "Permission to use Bash with command rm x has been denied.", True),
              tool_use("Bash", {"command": "ls"}, "d3"),
              tool_result("d3", "Claude requested permissions to use Bash, but you haven't granted it yet.", True),
              tool_use("Bash", {"command": "false"}, "e1"), tool_result("e1", "Exit code 1", True),
              tool_use("Bash", {"command": "cat .env"}, "e2"),
              tool_result("e2", "cat: .env: Operation not permitted", True)]
        m = metrics_of(es)
        self.assertEqual(m["denials"]["total"], 3)
        self.assertEqual(m["denials"]["by_kind"], {"deny_rule": 1, "denied": 1, "not_granted": 1})
        self.assertEqual(m["denials"]["by_tool"], {"Read": 1, "Bash": 2})
        self.assertEqual(m["tool_errors"], {"total": 2, "sandbox": 1})

    def test_metrics_interrupt_compact(self):
        es = [user_blocks("[Request interrupted by user for tool use]"),
              {"type": "system", "subtype": "compact_boundary", "timestamp": _stamp()}]
        m = metrics_of(es)
        self.assertEqual(m["interrupts"], 1)
        self.assertEqual(m["compactions"], 1)

    def test_tokens_dedup_by_message_id(self):
        u = {"input_tokens": 1, "cache_creation_input_tokens": 2, "cache_read_input_tokens": 3, "output_tokens": 10}
        es = [assistant_text("a", "same", u), assistant_text("b", "same", u), assistant_text("c", "same", u)]
        self.assertEqual(metrics_of(es)["tokens"], {"input": 1, "cache_creation": 2, "cache_read": 3, "output": 10})

    def test_metrics_exclude_skill_script(self):
        es = [script_call("s1"), tool_result("s1", "Exit code 1", True)]
        self.assertEqual(metrics_of(es)["tool_errors"]["total"], 0)

    def test_subagent_linked_by_tool_use_id(self):
        sub = os.path.join(self.tmp, "subagents")
        os.makedirs(sub)
        with open(os.path.join(sub, "agent-x.meta.json"), "w") as f:
            json.dump({"toolUseId": "a1"}, f)
        with open(os.path.join(sub, "agent-x.jsonl"), "w") as f:
            for e in [tool_use("mcp__y__z", {}, "z1", usage={"output_tokens": 5}), tool_result("z1")]:
                f.write(json.dumps(e) + "\n")
        es = [tool_use("Agent", {"subagent_type": "Explore"}, "a1"), tool_result("a1")]
        m = metrics_of(es, sub)
        self.assertEqual(m["subagents"]["count"], 1)
        self.assertEqual(m["subagents"]["mcp"], {"mcp__y__z": 1})
        self.assertEqual(m["subagents"]["tokens"]["output"], 5)
        self.assertEqual(metrics_of([tool_use("Agent", {}, "other"), tool_result("other")], sub)["subagents"]["count"], 0)

    def test_turns_and_empty(self):
        m = metrics_of([user("a"), assistant_text(), user("b")])
        self.assertEqual(m["turns"], 2)
        self.assertFalse(m["empty"])
        self.assertTrue(mse.segment_metrics([user("a")], 1, 1, None)["empty"])

    def test_user_messages_cleaned(self):
        es = [user("fix it<system-reminder>secret hint</system-reminder>"), slash("foo", "bar"),
              tool_result("t", "tool output"), meta("meta text"),
              user("<local-command-stdout>x</local-command-stdout>")]
        msgs, omitted = mse.user_messages(es, 0, len(es))
        self.assertEqual(msgs, ["fix it", "/foo bar"])
        self.assertEqual(omitted, 0)

    def test_user_messages_capped(self):
        es = [user(("m%03d " % i) + "x" * 1000) for i in range(100)]
        msgs, omitted = mse.user_messages(es, 0, len(es))
        self.assertEqual(len(msgs), 30)
        self.assertTrue(all(len(m) <= 300 for m in msgs))
        self.assertEqual(omitted, 70)
        self.assertTrue(msgs[0].startswith("m000") and msgs[9].startswith("m009") and msgs[10].startswith("m080"))

    def test_extract_cli(self):
        self.write_session("s1", [user("do work"), assistant_text(), invoke()])
        r = self.run_cli("extract")
        self.assertEqual(r.returncode, 0, r.stderr)
        out = json.loads(r.stdout)
        self.assertEqual(out["session_id"], "s1")
        self.assertEqual(out["project"], "proj")
        self.assertEqual(out["segment"]["turns"], 1)
        self.assertEqual(out["user_messages"], ["do work"])

    def test_extract_cli_no_session_env(self):
        r = self.run_cli("extract", sid=None)
        self.assertEqual(r.returncode, 2)
        self.assertIn("CLAUDE_CODE_SESSION_ID", r.stderr)


if __name__ == "__main__":
    unittest.main(verbosity=1)
