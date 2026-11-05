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


# ---- Task 3 ----
def put(base, rel, text):
    path = os.path.join(base, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)
    return path


SCENARIOS_JSON = os.path.join(os.path.dirname(os.path.dirname(TOOL)), "scenarios.json")


class TestInventory(Base):
    def full_project(self):
        put(self.proj, ".claude/skills/db/SKILL.md", "---\nname: db\n---\n")
        put(self.proj, ".claude/agents/sre.md", "agent")
        put(self.proj, ".claude/rules/sub/x.md", "rule")
        put(self.proj, ".mcp.json", json.dumps({"mcpServers": {"a": {"command": "x"}, "b": {"command": "y"}}}))
        put(self.proj, ".claude/settings.json", "{}")
        put(self.proj, "CLAUDE.md", "# CLAUDE.md — 后端开发（Go）\n")

    def test_inventory_kinds_and_hash(self):
        self.full_project()
        items = mse.inventory(self.proj)
        kinds = {}
        for it in items:
            kinds[it["kind"]] = kinds.get(it["kind"], 0) + 1
        self.assertEqual(kinds, {"skill": 1, "agent": 1, "rule": 1, "mcp": 2, "settings": 1, "claude_md": 1})
        self.assertTrue(all(len(it["hash"]) == 12 for it in items))
        rule = next(it for it in items if it["kind"] == "rule")
        self.assertEqual(rule["path"], ".claude/rules/sub/x.md")
        before = rule["hash"]
        put(self.proj, ".claude/rules/sub/x.md", "rule v2")
        after = next(it for it in mse.inventory(self.proj) if it["kind"] == "rule")["hash"]
        self.assertNotEqual(before, after)

    def test_inventory_empty_project(self):
        self.assertEqual(mse.inventory(self.proj), [])

    def scenarios(self):
        with open(SCENARIOS_JSON, encoding="utf-8") as f:
            return json.load(f)

    def test_detect_by_heading(self):
        put(self.proj, "CLAUDE.md", "# CLAUDE.md — 后端开发（Go）\n\nbody\n")
        items = mse.inventory(self.proj)
        self.assertEqual(mse.detect_scenario(self.proj, items, self.scenarios()), "backend-dev")

    def test_detect_by_agents(self):
        for a in ("sre", "devops-automator", "git-workflow-master"):
            put(self.proj, ".claude/agents/%s.md" % a, "x")
        items = mse.inventory(self.proj)
        self.assertEqual(mse.detect_scenario(self.proj, items, self.scenarios()), "dev-ops")

    def test_detect_unknown(self):
        self.assertIsNone(mse.detect_scenario(self.proj, [], self.scenarios()))

    def test_scenarios_json_matches_bundles(self):
        data = self.scenarios()
        self.assertEqual(sorted(data), ["backend-dev", "dev-ops", "frontend-dev", "prd-design"])
        for flag, spec in data.items():
            bundle = os.path.join(REPO, "dot_claude_projects", ".claude-" + flag)
            with open(os.path.join(bundle, "CLAUDE.md"), encoding="utf-8") as f:
                self.assertEqual(spec["claude_md_heading"], f.readline().strip(), flag)
            agents = sorted(n[:-3] for n in os.listdir(os.path.join(bundle, ".claude", "agents")) if n.endswith(".md"))
            self.assertEqual(sorted(spec["agents"]), agents, flag)

    def test_extract_includes_scenario_and_installed(self):
        self.full_project()
        self.write_session("s1", [user("do"), invoke()])
        out = json.loads(self.run_cli("extract").stdout)
        self.assertEqual(out["scenario"], "backend-dev")
        self.assertEqual(len(out["installed"]), 7)


# ---- Task 4 ----
APPEND_OK = ["append", "--task", "建立訂單表", "--status", "done", "--corrections", "1", "--new-requests", "0",
             "--satisfaction", "4", "--sat-source", "estimated", "--basis", "一次糾正後完成", "--include", "yes"]


def log_lines(home):
    path = os.path.join(home, "log.jsonl")
    if not os.path.exists(path):
        return []
    with open(path, encoding="utf-8") as f:
        return [json.loads(l) for l in f if l.strip()]


def seed_log(home, records):
    os.makedirs(home, exist_ok=True)
    with open(os.path.join(home, "log.jsonl"), "a", encoding="utf-8") as f:
        for r in records:
            f.write(json.dumps(r, ensure_ascii=False) + "\n")


class TestAppend(Base):
    def setUp(self):
        super().setUp()
        put(self.proj, "CLAUDE.md", "# CLAUDE.md — 后端开发（Go）\n")
        self.write_session("s1", [user("do SECRETMARK work"), assistant_text(), invoke()])

    def test_append_writes_one_line(self):
        self.assertEqual(self.run_cli(*APPEND_OK).returncode, 0)
        r = self.run_cli(*APPEND_OK)
        self.assertEqual(r.returncode, 0, r.stderr)
        lines = log_lines(self.home)
        self.assertEqual(len(lines), 2)
        rec = lines[0]
        self.assertEqual(rec["schema"], 1)
        self.assertIs(rec["include"], True)
        self.assertEqual(rec["scenario"], "backend-dev")
        self.assertEqual(rec["task"], "建立訂單表")
        self.assertEqual((rec["corrections"], rec["new_requests"], rec["satisfaction"]), (1, 0, 4))
        self.assertEqual(rec["satisfaction_source"], "estimated")
        self.assertEqual(rec["metrics"]["turns"], 1)
        self.assertEqual(rec["session_id"], "s1")

    def test_append_record_has_no_user_text(self):
        self.run_cli(*APPEND_OK)
        with open(os.path.join(self.home, "log.jsonl"), encoding="utf-8") as f:
            self.assertNotIn("SECRETMARK", f.read())

    def test_append_validation(self):
        bad_sat = list(APPEND_OK)
        bad_sat[bad_sat.index("--satisfaction") + 1] = "6"
        r = self.run_cli(*bad_sat)
        self.assertEqual(r.returncode, 2)
        self.assertIn("超出範圍", r.stderr)
        no_reason = list(APPEND_OK)
        no_reason[no_reason.index("--include") + 1] = "no"
        r = self.run_cli(*no_reason)
        self.assertEqual(r.returncode, 2)
        self.assertIn("--exclude-reason", r.stderr)
        self.assertEqual(log_lines(self.home), [])

    def test_append_empty_segment_refused(self):
        self.write_session("s2", [user("a"), invoke(), script_call("t1"), script_result("t1"), invoke()])
        r = self.run_cli(*APPEND_OK, sid="s2")
        self.assertEqual(r.returncode, 2)
        self.assertIn("沒有新活動", r.stderr)
        self.assertEqual(log_lines(self.home), [])

    def test_append_summary_counter(self):
        seed_log(self.home, [{"schema": 1, "scenario": "backend-dev", "include": True, "project": "proj",
                              "task": "t%d" % i} for i in range(8)])
        out9 = self.run_cli(*APPEND_OK).stdout
        self.assertIn("已累積 9 筆", out9)
        self.assertNotIn("可覆盤", out9)
        out10 = self.run_cli(*APPEND_OK).stdout
        self.assertIn("已累積 10 筆", out10)
        self.assertIn("可覆盤", out10)

    def test_append_unknown_scenario(self):
        os.remove(os.path.join(self.proj, "CLAUDE.md"))
        self.run_cli(*APPEND_OK)
        self.assertEqual(log_lines(self.home)[0]["scenario"], "unknown")

    def test_append_missed_list(self):
        self.run_cli(*(APPEND_OK + ["--missed", "a,b"]))
        self.run_cli(*APPEND_OK)
        lines = log_lines(self.home)
        self.assertEqual(lines[0]["missed"], ["a", "b"])
        self.assertEqual(lines[1]["missed"], [])

    def test_extract_recent_tasks(self):
        seed_log(self.home, [{"schema": 1, "project": "proj", "task": "t%02d" % i} for i in range(12)]
                 + [{"schema": 1, "project": "other", "task": "foreign"}])
        out = json.loads(self.run_cli("extract").stdout)
        self.assertEqual(len(out["recent_tasks"]), 10)
        self.assertEqual(out["recent_tasks"][0], "t11")
        self.assertNotIn("foreign", out["recent_tasks"])


# ---- Task 5 ----
_rec_n = [0]


def rec(task="t", session="s", sat=4, include=True, installed=None, skills=None, rules=None,
        missed=None, corrections=0, scenario="backend-dev", source="estimated"):
    _rec_n[0] += 1
    n = _rec_n[0]
    return {"schema": 1, "recorded_at": "2026-11-05T%02d:%02d:%02dZ" % (n // 3600 % 24, n // 60 % 60, n % 60),
            "session_id": session, "project": "proj", "scenario": scenario,
            "installed": installed or [], "task": task, "status": "done",
            "corrections": corrections, "new_requests": 0, "satisfaction": sat,
            "satisfaction_source": source, "include": include, "missed": missed or [],
            "metrics": {"skills": skills or {}, "agents": {}, "mcp": {}, "rules_loaded": rules or {},
                        "denials": {"total": 0, "by_kind": {}, "by_tool": {}},
                        "tool_errors": {"total": 0, "sandbox": 0},
                        "tokens": {"input": 0, "cache_creation": 0, "cache_read": 0, "output": 100}}}


def skill_item(name, h="aaaaaaaaaaaa"):
    return {"kind": "skill", "name": name, "path": ".claude/skills/%s/SKILL.md" % name, "hash": h}


def find_item(summary, name, h=None, scenario="backend-dev"):
    return [it for it in summary["scenarios"][scenario]["items"]
            if it["name"] == name and (h is None or it["hash"] == h)]


class TestSummarize(Base):
    def test_summarize_thresholds(self):
        db = skill_item("db")
        recs = [rec(installed=[db], skills={"db": 1} if i < 3 else {}) for i in range(9)]
        s = mse.summarize(recs)["scenarios"]["backend-dev"]
        self.assertFalse(s["scenario_eligible"])
        self.assertEqual(s["scenario_missing"], 1)
        it = find_item({"scenarios": {"backend-dev": s}}, "db")[0]
        self.assertEqual((it["records_installed"], it["records_used"], it["uses"]), (9, 3, 3))
        self.assertTrue(it["item_eligible"])

    def test_config_versions_split(self):
        a, b = skill_item("db", "aaaaaaaaaaaa"), skill_item("db", "bbbbbbbbbbbb")
        recs = [rec(installed=[a]), rec(installed=[a]), rec(installed=[b]), rec(installed=[b])]
        s = mse.summarize(recs)
        items = find_item(s, "db")
        self.assertEqual(len(items), 2)
        self.assertEqual(sorted(it["records_installed"] for it in items), [2, 2])
        self.assertFalse(any(it["item_eligible"] for it in items))

    def test_summarize_excluded_records(self):
        recs = [rec(sat=4), rec(sat=1, include=False)]
        s = mse.summarize(recs)["scenarios"]["backend-dev"]
        self.assertEqual((s["records_total"], s["records_included"]), (2, 1))
        self.assertEqual(s["satisfaction"]["dist"]["1"], 0)
        self.assertEqual(s["satisfaction"]["dist"]["4"], 1)

    def test_summarize_task_merge(self):
        s = mse.summarize([rec(task="訂單", session="s1"), rec(task="訂單", session="s2")])
        tasks = s["scenarios"]["backend-dev"]["tasks"]
        self.assertEqual(len(tasks), 1)
        self.assertEqual((tasks[0]["records"], tasks[0]["sessions"]), (2, 2))

    def test_summarize_rule_matched_by_path(self):
        r = {"kind": "rule", "name": "go/style.md", "path": ".claude/rules/go/style.md", "hash": "cccccccccccc"}
        s = mse.summarize([rec(installed=[r], rules={"/abs/proj/.claude/rules/go/style.md": 2})])
        self.assertEqual(find_item(s, "go/style.md")[0]["uses"], 2)

    def test_summarize_missed_counted(self):
        db = skill_item("db-schema-design")
        s = mse.summarize([rec(installed=[db], missed=["db-schema-design"]) for _ in range(2)])
        self.assertEqual(find_item(s, "db-schema-design")[0]["missed"], 2)

    def test_summarize_used_not_installed(self):
        s = mse.summarize([rec(skills={"superpowers:brainstorming": 2})])
        self.assertIn({"kind": "skill", "name": "superpowers:brainstorming", "uses": 2},
                      s["scenarios"]["backend-dev"]["used_not_installed"])

    def test_interventions_trend(self):
        s = mse.summarize([rec(corrections=c) for c in (4, 2, 1, 1)])["scenarios"]["backend-dev"]
        self.assertEqual(s["interventions_trend"], {"n": 4, "first_half_avg": 3.0, "second_half_avg": 1.0})
        small = mse.summarize([rec(corrections=1)])["scenarios"]["backend-dev"]["interventions_trend"]
        self.assertIsNone(small["first_half_avg"])

    def test_summarize_scenario_filter(self):
        s = mse.summarize([rec(), rec(scenario="dev-ops")], scenario="dev-ops")
        self.assertEqual(list(s["scenarios"]), ["dev-ops"])

    def test_summarize_skips_bad_lines(self):
        seed_log(self.home, [rec()])
        with open(os.path.join(self.home, "log.jsonl"), "a") as f:
            f.write("{broken\n")
        r = self.run_cli("summarize")
        self.assertEqual(r.returncode, 0, r.stderr)
        out = json.loads(r.stdout)
        self.assertEqual(out["bad_lines"], 1)
        self.assertEqual(out["scenarios"]["backend-dev"]["records_total"], 1)

    def test_summarize_no_log(self):
        r = self.run_cli("summarize")
        self.assertEqual(r.returncode, 2)
        self.assertIn("尚無記錄", r.stderr)


if __name__ == "__main__":
    unittest.main(verbosity=1)
