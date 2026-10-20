"""セッションのコスト指数を、コミットのトレーラーに書く。META-05「見積もりと実績」。

Claudeを通さずに実績を出すための仕組みで、2つの場面で呼ばれる。

  session-start  Claude CodeのSessionStartフック。標準入力のJSONから記録のパスを取り、
                 .git/claude-sessions/<セッションid> に残す。あわせて core.hooksPath を
                 .githooks に向け、コミットのたびに下の trailer が回るようにする
  trailer <file> .githooks/prepare-commit-msg。そのセッションのここまでの消費を
                 「Cost-Index: <値> (session <id>)」としてコミットメッセージに足す。
                 statuslineが残した使用率が新しければ、「Usage:」の行も足す
  statusline     Claude Codeのステータスライン。標準入力のJSONから5時間と週の使用率を取って
                 表示し、.git/claude-sessions/usage.json に残す。ProとMaxのプランで、
                 ステータスラインを描く画面（ターミナルのclaude）のときだけ値が来る

issueが閉じると、project-record.ymlが閉じたPRのコミットからこの行を拾い、
セッションごとの最大値を足してProjectの「実績」に書く。

どちらの場面でも、失敗してもコミットやセッションを止めない。値の無いコミットは、実績に数えられないだけである。
"""

import json
import os
import re
import subprocess
import sys
import time
from datetime import datetime, timedelta, timezone
from pathlib import Path

# token_log.pyと同じ重み（META-05の表）。
MODEL_WEIGHTS = (("opus", 5), ("fable", 5), ("sonnet", 3), ("haiku", 1))
# 内訳の無い記録は、1時間のキャッシュとして数える（META-05）。5分のものはAPIの料金の比で数える。
CACHE_5M_WEIGHT = 1.25
CACHE_1H_WEIGHT = 2
TRAILER = "Cost-Index"
USAGE_TRAILER = "Usage"
# これより古い使用率は、コミットの時点の値とみなさない。ステータスラインは応答のたびに書き直される。
USAGE_MAX_AGE = 600
JST = timezone(timedelta(hours=9))
WINDOWS = (("five_hour", "5h"), ("seven_day", "7d"))


def git(*args):
    return subprocess.run(["git", *args], capture_output=True, text=True, encoding="utf-8").stdout.strip()


def sessions_dir():
    return Path(git("rev-parse", "--git-common-dir")) / "claude-sessions"


def session_start():
    data = json.loads(sys.stdin.buffer.read().decode("utf-8") or "{}")
    session, transcript = data.get("session_id"), data.get("transcript_path")
    if not session or not transcript:
        return
    if git("config", "--get", "core.hooksPath") != ".githooks":
        git("config", "core.hooksPath", ".githooks")
    d = sessions_dir()
    d.mkdir(exist_ok=True)
    (d / session).write_text(transcript, encoding="utf-8", newline="\n")


def current_session():
    """環境変数でセッションが分かればそれを、分からなければ最後に始まったセッションを使う。"""
    d = sessions_dir()
    named = os.environ.get("CLAUDE_CODE_SESSION_ID")
    if named and (d / named).is_file():
        return named, Path((d / named).read_text(encoding="utf-8").strip())
    # 別のフォルダで始めたセッションが、このクローンでコミットしたときは、ここに記録が残っていない。
    # 記録の置き場所から探す。
    if named:
        config = Path(os.environ.get("CLAUDE_CONFIG_DIR") or Path.home() / ".claude")
        found = sorted(config.glob(f"projects/*/{named}.jsonl"))
        if found:
            return named, found[0]
    files = sorted(d.glob("*"), key=lambda p: p.stat().st_mtime) if d.is_dir() else []
    if not files:
        return None, None
    return files[-1].name, Path(files[-1].read_text(encoding="utf-8").strip())


def model_weight(model):
    for key, weight in MODEL_WEIGHTS:
        if key in (model or ""):
            return weight
    return 0  # <synthetic>など、課金されない応答


def cost_index(transcript):
    # サブエージェントの記録は、本体の記録の横の <セッションid>/subagents/ に置かれる。
    files = [transcript, *sorted(transcript.with_suffix("").glob("subagents/*.jsonl"))]
    seen, total = set(), 0.0
    for f in files:
        if not f.is_file():
            continue
        for line in f.read_text(encoding="utf-8", errors="replace").splitlines():
            try:
                message = json.loads(line).get("message")
            except (ValueError, AttributeError):
                continue
            if not isinstance(message, dict) or not message.get("usage"):
                continue
            # 1つの応答は、内容のブロックごとに同じ使用量を持って何行にも分かれて記録される。
            if message.get("id") in seen:
                continue
            seen.add(message.get("id"))
            u = message["usage"]
            split = u.get("cache_creation") or {}
            c5m = split.get("ephemeral_5m_input_tokens") or 0
            c1h = split.get("ephemeral_1h_input_tokens") if split else u.get("cache_creation_input_tokens")
            total += model_weight(message.get("model")) * (
                (u.get("input_tokens") or 0)
                + c5m * CACHE_5M_WEIGHT
                + (c1h or 0) * CACHE_1H_WEIGHT
                + (u.get("cache_read_input_tokens") or 0) * 0.1
                + (u.get("output_tokens") or 0) * 5
            )
    return round(total / 1000)


def statusline():
    data = json.loads(sys.stdin.buffer.read().decode("utf-8") or "{}")
    limits = data.get("rate_limits") or {}
    shown = [(label, limits[key]) for key, label in WINDOWS if isinstance(limits.get(key), dict)]
    if not shown:
        return
    print("  ".join(f"{label} {w.get('used_percentage', 0):g}%" for label, w in shown))
    d = sessions_dir()
    d.mkdir(exist_ok=True)
    (d / "usage.json").write_text(
        json.dumps({"at": time.time(), "rate_limits": limits}), encoding="utf-8", newline="\n"
    )


def usage_line():
    """「5h 23% (resets 2026-10-19T14:00+09:00), 7d 41% (resets ...)」。新しい記録が無ければNone。"""
    path = sessions_dir() / "usage.json"
    if not path.is_file():
        return None
    saved = json.loads(path.read_text(encoding="utf-8"))
    if time.time() - saved.get("at", 0) > USAGE_MAX_AGE:
        return None
    parts = []
    for key, label in WINDOWS:
        w = saved["rate_limits"].get(key)
        if isinstance(w, dict) and w.get("used_percentage") is not None:
            resets = datetime.fromtimestamp(w["resets_at"], JST).strftime("%Y-%m-%dT%H:%M+09:00")
            parts.append(f"{label} {w['used_percentage']:g}% (resets {resets})")
    return ", ".join(parts) or None


def trailer(message_file):
    session, transcript = current_session()
    if not session:
        return
    value = cost_index(transcript)
    if not value:
        return
    path = Path(message_file)
    # amendのときは書き直す
    text = re.sub(rf"^({TRAILER}|{USAGE_TRAILER}): .*\n?", "", path.read_text(encoding="utf-8"), flags=re.M)
    lines = [f"{TRAILER}: {value} (session {session})"]
    usage = usage_line()
    if usage:
        lines.append(f"{USAGE_TRAILER}: {usage}")
    out = subprocess.run(
        ["git", "interpret-trailers", *[a for line in lines for a in ("--trailer", line)]],
        input=text, capture_output=True, text=True, encoding="utf-8",
    )
    if out.returncode == 0:
        path.write_text(out.stdout, encoding="utf-8", newline="\n")


if __name__ == "__main__":
    try:
        if sys.argv[1:2] == ["session-start"]:
            session_start()
        elif sys.argv[1:2] == ["trailer"] and len(sys.argv) > 2:
            trailer(sys.argv[2])
        elif sys.argv[1:2] == ["statusline"]:
            statusline()
    except Exception as e:  # 実績のためにコミットを止めない
        print(f"cost_index: {e}", file=sys.stderr)
