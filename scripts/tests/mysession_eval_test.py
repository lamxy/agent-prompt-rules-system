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


if __name__ == "__main__":
    unittest.main(verbosity=1)
