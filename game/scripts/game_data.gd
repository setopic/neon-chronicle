extends Node

## data/*.json から仕事・スキル・インプラント・永続強化・イベント・記憶の断片・エンディングを読み込む。DOM-03〜DOM-06、DOM-08。
## 各ファイルは {"jobs": [...], "skills": [...], ...} の形。同じ id の項目は後から読んだもの（MOD）で上書きする。
## 表示名と説明は言語ファイルのキー "<種類>.<id>.name" / "<種類>.<id>.desc" から引く。

const KEY_PREFIX := {
	"jobs": "job", "skills": "skill", "implants": "implant", "upgrades": "upgrade", "events": "event",
	"fragments": "fragment", "endings": "ending",
}

var jobs := {}
var skills := {}
var implants := {}
var upgrades := {}
var events := {}
var fragments := {}
var endings := {}
## 種類ごとの表示順（最初に読んだ順）
var order := {"jobs": [], "skills": [], "implants": [], "upgrades": [], "events": [], "fragments": [], "endings": []}


func _ready() -> void:
	for path in ModPaths.json_files("data"):
		var data: Variant = ModPaths.load_json(path)
		if not data is Dictionary:
			continue
		for kind in KEY_PREFIX:
			for entry in data.get(kind, []):
				_add(kind, entry, path)


func table(kind: String) -> Dictionary:
	return get(kind)


func name_of(kind: String, id: String) -> String:
	return tr("%s.%s.name" % [KEY_PREFIX[kind], id])


func desc_of(kind: String, id: String) -> String:
	return tr("%s.%s.desc" % [KEY_PREFIX[kind], id])


func _add(kind: String, entry: Variant, path: String) -> void:
	if not entry is Dictionary or not entry.has("id"):
		push_warning("Entry without id in %s (%s)" % [path, kind])
		return
	var items := table(kind)
	var id: String = entry["id"]
	if items.has(id):
		items[id].merge(entry, true)
	else:
		items[id] = entry
		order[kind].append(id)
