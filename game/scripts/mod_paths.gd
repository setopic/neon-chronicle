class_name ModPaths
extends RefCounted

## ゲーム本体と MOD の読み込み先をまとめる。
## MOD は user://mods/<MOD名>/ に data/ と lang/ を置く。後から読むもの（MOD）が同じ id やキーを上書きする。

const MODS_DIR := "user://mods"


## 読み込み元のルート一覧。先頭がゲーム本体で、MOD は名前順に続く。
static func roots() -> Array[String]:
	var result: Array[String] = ["res://"]
	var dir := DirAccess.open(MODS_DIR)
	if dir == null:
		return result
	var names := Array(dir.get_directories())
	names.sort()
	for mod_name in names:
		result.append("%s/%s/" % [MODS_DIR, mod_name])
	return result


## 全ルートの <subdir>/*.json を読み込み順に返す。
static func json_files(subdir: String) -> Array[String]:
	var files: Array[String] = []
	for root in roots():
		var path := root + subdir
		var dir := DirAccess.open(path)
		if dir == null:
			continue
		var names := Array(dir.get_files())
		names.sort()
		for file_name in names:
			if file_name.ends_with(".json"):
				files.append(path.path_join(file_name))
	return files


static func load_json(path: String) -> Variant:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_warning("Cannot read: " + path)
		return null
	var data: Variant = JSON.parse_string(text)
	if data == null:
		push_error("Invalid JSON: " + path)
	return data
