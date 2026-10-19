"""data と lang のJSONを確かめる。ARCH-01。

CIの app-check.yml から呼ぶ。Godotを使わずに分かる抜けだけを見る。
1. data/*.json と lang/*.json がJSONとして読める
2. どの言語ファイルも、en.json と同じキーを持つ
3. data の各項目に、表示名と説明のキー（<種類>.<id>.name / .desc）がある
4. スクリプトに直接書いたキー（tr("ui.title") など）が en.json にある
5. イベントの各選択肢に、表示名と結果と物語の句のキー（event.<id>.<選択肢>.name / .result / .chronicle）がある
6. どのイベントにも、選ぶ条件の無い選択肢が1つ以上ある（DOM-06）
7. 各仕事に、物語の句のキー（job.<id>.chronicle）がある（DOM-07）
8. エンディングの選択肢は、data にあるエンディングを指す。各エンディングに、物語の句のキー（ending.<id>.chronicle）がある（DOM-08）
   エンディングの選択肢は周を終えるので、最後に選んだ選択肢にならず、選択肢の物語の句は要らない
9. 転生の画面のミオの一言（mio.<倒れた理由>.<段>）が、倒れた理由と段の組すべてにある（DOM-10）。
   キーをスクリプトで組み立てているので、4では見つからない
10. 耐久を減らす選択肢のあるイベントに、倒れたときの句のキー（event.<id>.fall）がある（ADR-0011）
11. 体の種類が1つ以上ある。第1周は data の最初の体で目覚める（DOM-11）
12. ジンの依頼は、仕事かスキルのどちらか一方を持ち、data にある仕事やスキルを指す。
    各依頼に、ジンの台詞のキー（request.<id>.offer）がある（DOM-12）
13. 人物のイベントの前の選択の条件と説明の書き分けは、同じ人物の前の段のイベントを指す。
    説明を書き分けたイベントは、指したイベントの選択肢ごとに説明のキー（event.<id>.desc.<選択肢>）を持つ。
    要る断片は data にある断片を指す（DOM-13）
14. 街と人物の資料の出るイベントと、追記の要る断片・出るイベントは、data にあるものを指す。
    追記は要る断片と出るイベントのどちらか一方を持ち、文のキー（profile.<id>.<追記>）がある（DOM-14）

ゲームは足りないキーを英語で補うので（loc.gd）、抜けは画面にキーのまま出るまで気づけない。
"""

import json
import re
import sys
from pathlib import Path

GAME = Path(__file__).resolve().parent.parent
BASE_LOCALE = "en"
# game_data.gd の KEY_PREFIX と同じ対応。ジンの依頼は表示名と説明を持たないので、12で別に見る
KEY_PREFIX = {
    "jobs": "job", "skills": "skill", "implants": "implant", "upgrades": "upgrade", "events": "event",
    "fragments": "fragment", "endings": "ending", "bodies": "body", "profiles": "profile",
    "challenges": "challenge", "factions": "faction",
}
# game_state.gd の mio_line_key と同じ組
MIO_REASONS = ("decay", "event")
MIO_STAGES = (1, 2, 3)
KEY_IN_SCRIPT = re.compile(r'\b(?:tr|t|_log)\("([a-z_]+\.[a-z0-9_.]+)"')


def load(path, errors):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError) as e:
        errors.append(f"{path.relative_to(GAME)}: JSONとして読めない: {e}")
        return None


def main():
    errors = []

    langs = {}
    for path in sorted((GAME / "lang").glob("*.json")):
        data = load(path, errors)
        if data is None:
            continue
        if not isinstance(data, dict) or not isinstance(data.get("strings"), dict) or "locale" not in data:
            errors.append(f"{path.relative_to(GAME)}: locale と strings が無い")
            continue
        langs[data["locale"]] = set(data["strings"])

    base = langs.get(BASE_LOCALE)
    if base is None:
        errors.append(f"lang/{BASE_LOCALE}.json が無いか読めない")
        base = set()
    for locale, keys in sorted(langs.items()):
        for key in sorted(base - keys):
            errors.append(f"{locale}: キーが無い: {key}")
        for key in sorted(keys - base):
            errors.append(f"{locale}: {BASE_LOCALE} に無いキーがある: {key}")

    datas = {}
    for path in sorted((GAME / "data").glob("*.json")):
        data = load(path, errors)
        if isinstance(data, dict):
            datas[path] = data
    endings = {e.get("id") for data in datas.values() for e in data.get("endings", [])}
    jobs = {e.get("id") for data in datas.values() for e in data.get("jobs", [])}
    skills = {e.get("id") for data in datas.values() for e in data.get("skills", [])}
    fragments = {e.get("id") for data in datas.values() for e in data.get("fragments", [])}
    events = {e.get("id"): e for data in datas.values() for e in data.get("events", [])}
    if not any(data.get("bodies") for data in datas.values()):
        errors.append("data に体の種類（bodies）が1つも無い")

    for path, data in datas.items():
        for kind, prefix in KEY_PREFIX.items():
            for entry in data.get(kind, []):
                for suffix in ("name", "desc"):
                    key = f"{prefix}.{entry.get('id')}.{suffix}"
                    if key not in base:
                        errors.append(f"{path.relative_to(GAME)}: {BASE_LOCALE} にキーが無い: {key}")
        for job in data.get("jobs", []):
            key = f"job.{job.get('id')}.chronicle"
            if key not in base:
                errors.append(f"{path.relative_to(GAME)}: {BASE_LOCALE} にキーが無い: {key}")
            # 1回の長さが無いと、報酬が1秒ごとに入ってしまう（ADR-0051）
            if not job.get("length", 0) > 0:
                errors.append(f"{path.relative_to(GAME)}: 1回の長さ（length）が無い: job.{job.get('id')}")
            # ミニゲームの遊び方の説明が無いと、始めたときに何をすればよいか分からない（ADR-0054）
            kind = job.get("minigame", "")
            if kind and f"minigame.{kind}.help" not in base:
                errors.append(f"{path.relative_to(GAME)}: {BASE_LOCALE} にキーが無い: minigame.{kind}.help")
        for event in data.get("events", []):
            choices = event.get("choices", [])
            if not any(not c.get("requires") and not c.get("requires_choice") for c in choices):
                errors.append(f"{path.relative_to(GAME)}: 選ぶ条件の無い選択肢が無い: event.{event.get('id')}")
            if any(c.get("durability", 0) < 0 for c in choices):
                key = f"event.{event.get('id')}.fall"
                if key not in base:
                    errors.append(f"{path.relative_to(GAME)}: {BASE_LOCALE} にキーが無い: {key}")
            for choice in choices:
                if "ending" in choice and choice["ending"] not in endings:
                    errors.append(f"{path.relative_to(GAME)}: 無いエンディングを指している: event.{event.get('id')}.{choice.get('id')}")
                suffixes = ("name", "result") if "ending" in choice else ("name", "result", "chronicle")
                for suffix in suffixes:
                    key = f"event.{event.get('id')}.{choice.get('id')}.{suffix}"
                    if key not in base:
                        errors.append(f"{path.relative_to(GAME)}: {BASE_LOCALE} にキーが無い: {key}")

        seen = []
        for event in data.get("events", []):
            where = f"{path.relative_to(GAME)}: event.{event.get('id')}"
            # 人物のイベントと勢力の話のイベントは、同じ形で段を進める（DOM-13、DOM-23）
            character = event.get("character", event.get("story"))
            earlier = {e.get("id") for e in seen if character and e.get("character", e.get("story")) == character}
            seen.append(event)
            if "fragment" in event and event["fragment"] not in fragments:
                errors.append(f"{where}: 無い断片を指している: {event['fragment']}")
            by = event.get("desc_by")
            if by is not None:
                if by not in earlier:
                    errors.append(f"{where}: 同じ人物の前の段ではないイベントで説明を書き分けている: {by}")
                for c in events.get(by, {}).get("choices", []):
                    key = f"event.{event.get('id')}.desc.{c.get('id')}"
                    if key not in base:
                        errors.append(f"{path.relative_to(GAME)}: {BASE_LOCALE} にキーが無い: {key}")
            trace = event.get("requires_trace")
            if trace is not None:
                parts = trace.split(".")
                if len(parts) != 2 or parts[0] not in events or not any(c.get("id") == parts[1] for c in events[parts[0]].get("choices", [])):
                    errors.append(f"{where}: 前の周の跡の条件が、無い選択肢を指している: {trace}")
            for choice in event.get("choices", []):
                story = choice.get("requires_story")
                if story is not None:
                    parts = story.split(".")
                    if len(parts) != 2 or parts[0] not in events or not any(c.get("id") == parts[1] for c in events[parts[0]].get("choices", [])):
                        errors.append(f"{where}.{choice.get('id')}: 話の条件が、無い選択肢を指している: {story}")
            for choice in event.get("choices", []):
                after = choice.get("requires_choice")
                if after is None:
                    continue
                parts = after.split(".")
                if len(parts) != 2 or parts[0] not in earlier or not any(c.get("id") == parts[1] for c in events[parts[0]].get("choices", [])):
                    errors.append(f"{where}.{choice.get('id')}: 同じ人物の前の段の選択肢を指していない: {after}")

        for req in data.get("requests", []):
            where = f"{path.relative_to(GAME)}: request.{req.get('id')}"
            if ("job" in req) == ("skill" in req):
                errors.append(f"{where}: 仕事とスキルのどちらか一方だけを持たない")
            if "job" in req and req["job"] not in jobs:
                errors.append(f"{where}: 無い仕事を指している: {req['job']}")
            if "skill" in req and req["skill"] not in skills:
                errors.append(f"{where}: 無いスキルを指している: {req['skill']}")
            key = f"request.{req.get('id')}.offer"
            if key not in base:
                errors.append(f"{path.relative_to(GAME)}: {BASE_LOCALE} にキーが無い: {key}")

        for profile in data.get("profiles", []):
            where = f"{path.relative_to(GAME)}: profile.{profile.get('id')}"
            if "event" in profile and profile["event"] not in events:
                errors.append(f"{where}: 無いイベントを指している: {profile['event']}")
            for note in profile.get("notes", []):
                note_where = f"{where}.{note.get('id')}"
                if note.get("id") in ("name", "desc"):
                    errors.append(f"{note_where}: 表示名と説明のキーと重なる")
                if ("fragment" in note) == ("event" in note):
                    errors.append(f"{note_where}: 要る断片と出るイベントのどちらか一方だけを持たない")
                if "fragment" in note and note["fragment"] not in fragments:
                    errors.append(f"{note_where}: 無い断片を指している: {note['fragment']}")
                if "event" in note and note["event"] not in events:
                    errors.append(f"{note_where}: 無いイベントを指している: {note['event']}")
                key = f"profile.{profile.get('id')}.{note.get('id')}"
                if key not in base:
                    errors.append(f"{path.relative_to(GAME)}: {BASE_LOCALE} にキーが無い: {key}")

        for ending in data.get("endings", []):
            key = f"ending.{ending.get('id')}.chronicle"
            if key not in base:
                errors.append(f"{path.relative_to(GAME)}: {BASE_LOCALE} にキーが無い: {key}")

    for path in sorted((GAME / "scripts").glob("*.gd")):
        for key in KEY_IN_SCRIPT.findall(path.read_text(encoding="utf-8")):
            if key not in base:
                errors.append(f"{path.relative_to(GAME)}: {BASE_LOCALE} にキーが無い: {key}")

    for reason in MIO_REASONS:
        for stage in MIO_STAGES:
            if f"mio.{reason}.{stage}" not in base:
                errors.append(f"{BASE_LOCALE} にキーが無い: mio.{reason}.{stage}")

    for error in errors:
        print(error)
    if errors:
        return 1
    print(f"OK: 言語 {len(langs)} 個、キー {len(base)} 個")
    return 0


if __name__ == "__main__":
    sys.exit(main())
