"""data と lang のJSONを確かめる。ARCH-01。

CIの app-check.yml から呼ぶ。Godotを使わずに分かる抜けだけを見る。
1. data/*.json と lang/*.json がJSONとして読める
2. どの言語ファイルも、en.json と同じキーを持つ
3. data の各項目に、表示名と説明のキー（<種類>.<id>.name / .desc）がある
4. スクリプトに直接書いたキー（tr("ui.title") など）が en.json にある

ゲームは足りないキーを英語で補うので（loc.gd）、抜けは画面にキーのまま出るまで気づけない。
"""

import json
import re
import sys
from pathlib import Path

GAME = Path(__file__).resolve().parent.parent
BASE_LOCALE = "en"
# game_data.gd の KEY_PREFIX と同じ対応
KEY_PREFIX = {"jobs": "job", "skills": "skill", "implants": "implant", "upgrades": "upgrade"}
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

    for path in sorted((GAME / "data").glob("*.json")):
        data = load(path, errors)
        if not isinstance(data, dict):
            continue
        for kind, prefix in KEY_PREFIX.items():
            for entry in data.get(kind, []):
                for suffix in ("name", "desc"):
                    key = f"{prefix}.{entry.get('id')}.{suffix}"
                    if key not in base:
                        errors.append(f"{path.relative_to(GAME)}: {BASE_LOCALE} にキーが無い: {key}")

    for path in sorted((GAME / "scripts").glob("*.gd")):
        for key in KEY_IN_SCRIPT.findall(path.read_text(encoding="utf-8")):
            if key not in base:
                errors.append(f"{path.relative_to(GAME)}: {BASE_LOCALE} にキーが無い: {key}")

    for error in errors:
        print(error)
    if errors:
        return 1
    print(f"OK: 言語 {len(langs)} 個、キー {len(base)} 個")
    return 0


if __name__ == "__main__":
    sys.exit(main())
