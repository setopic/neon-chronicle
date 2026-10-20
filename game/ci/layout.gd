extends SceneTree

## メインの画面の欄の並びを入れ替えても、1280x720に収まるかを確かめる。ADR-0058。
## 日本語と英語で、入れ替えられる4組のすべての組み合わせを組み立てて、欄が画面の中にあるかを見る。
## 何も入れ替えていなければ既定の並びになることと、入れ替えた並びが設定のファイルに残ることも見る。
## 第二部の画面は体の状態の欄に行が増えるので、第二部でもすべての組み合わせを見る（DOM-34）。
## 設定とセーブは確かめたあとに元へ戻すので、手元の設定とセーブは変わらない。
##
##   godot --headless --path . --script res://ci/layout.gd

const SAVE_PATH := "user://layout-check.json"
const SCREEN := Rect2(0, 0, 1280, 720)
const PANELS := ["ui.jobs", "ui.body", "ui.job_scene", "ui.log", "ui.implants"]

var _loc: Node
var _main: Control
var _settings_file: Variant = null  # 確かめる前の設定のファイルの中身。無ければ null
var _cases: Array = []  # [locale, 入れ替える組の辞書]
var _wait := 0
var _failed := false
var _part_two := false  # 第二部の画面を確かめているか


func _process(_delta: float) -> bool:
	if _main == null:
		var game := root.get_node("Game")
		game.save_path = SAVE_PATH
		game.set_process(false)
		game.reset_game()
		_loc = root.get_node("Loc")
		if FileAccess.file_exists(_loc.SETTINGS_PATH):
			_settings_file = FileAccess.get_file_as_string(_loc.SETTINGS_PATH)
		_add_cases()
		root.size = Vector2i(SCREEN.size)
		_loc._settings.erase("panel_layout")
		_main = load("res://scenes/main.tscn").instantiate()
		root.add_child(_main)
		_wait = 3
		return false
	if _wait > 0:
		_wait -= 1
		return false
	if _cases.is_empty() and not _part_two:
		_part_two = true
		var game := root.get_node("Game")
		game.part = 2
		game._start_part_two()
		_add_cases()
		_next_case()
		return false
	if _cases.is_empty():
		_check_saved()
		_finish()
		return true
	var case: Array = _cases.pop_front()
	_check(case[0], case[1])
	_next_case()
	return false


func _add_cases() -> void:
	for locale in ["ja", "en"]:
		for bits in 16:
			var layout := {}
			for i in _main_swaps().size():
				layout[_main_swaps()[i]] = bits & (1 << i) != 0
			_cases.append([locale, layout])


func _main_swaps() -> Array:
	return load("res://scripts/main.gd").LAYOUT_SWAPS


## 次の組み合わせの並びにして、画面を組み立て直す。言語を変えると画面は作り直される
func _next_case() -> void:
	if _cases.is_empty():
		return
	var case: Array = _cases.front()
	_loc._settings["panel_layout"] = case[1]
	if _loc.current() != case[0]:
		_loc.set_language(case[0])
	else:
		_main._build()
	_wait = 2


var _first := true


func _check(locale: String, layout: Dictionary) -> void:
	if _first:
		# 最初の1回は、設定に並びが無いときの画面を見る
		_first = false
		var rects := _rects()
		_expect(rects["ui.jobs"].position.x < rects["ui.body"].position.x
			and rects["ui.job_scene"].position.x < rects["ui.log"].position.x
			and rects["ui.jobs"].position.y < rects["ui.log"].position.y
			and rects["ui.body"].position.x < rects["ui.implants"].position.x,
			"何も入れ替えていなければ、既定の並びで出る")
		_cases.push_front([locale, {}])
		_next_case()
		return
	var name := "%s%s %s" % ["第二部 " if _part_two else "", locale, layout]
	var rects := _rects()
	var inside := true
	for key in PANELS:
		if not SCREEN.encloses(rects[key]):
			inside = false
			print("     %s: %s" % [key, rects[key]])
	var root_min: Vector2 = _main._content.get_child(0).get_combined_minimum_size()
	# 上の帯の中身は帯に重ねているので、帯の最小の幅に出てこない。題とボタンの行は別に見る
	var header: Control = _main._content.get_child(0).get_child(0).get_child(0)
	var header_row: Control = header.get_child(header.get_child_count() - 1).get_child(0)
	_expect(header_row.get_combined_minimum_size().x <= header_row.size.x,
		"上の帯の題とボタンが帯に収まる（%s、%d / %d）" % [locale, header_row.get_combined_minimum_size().x, header_row.size.x])
	_expect(inside and root_min.x <= SCREEN.size.x and root_min.y <= SCREEN.size.y,
		"1280x720に収まる（%s、最小 %s）" % [name, root_min])
	_expect((rects["ui.body"].position.x < rects["ui.jobs"].position.x) == layout.get("jobs_body", false)
		and (rects["ui.log"].position.x < rects["ui.job_scene"].position.x) == layout.get("scene_log", false)
		and (rects["ui.log"].position.y < rects["ui.jobs"].position.y) == layout.get("rows", false)
		and (rects["ui.implants"].position.x < rects["ui.jobs"].position.x) == layout.get("columns", false),
		"選んだとおりに並ぶ（%s）" % name)


## 欄ごとの、画面に見えている範囲。スクロールの中の欄は、スクロールの枠の範囲を見る
func _rects() -> Dictionary:
	var rects := {}
	for key in PANELS:
		var panel := _find_panel(_main._content, _loc.tr(key))
		var shown: Control = panel
		while shown != null and not shown is ScrollContainer and shown.get_parent() is Control \
				and not shown.get_parent() is BoxContainer:
			shown = shown.get_parent()
		if shown == null or not shown is ScrollContainer:
			shown = panel
		rects[key] = shown.get_global_rect()
	return rects


func _find_panel(node: Node, title: String) -> Control:
	if node is PanelContainer:
		var box := node.get_child(0).get_child(0)
		if box.get_child_count() > 0 and box.get_child(0) is Label and box.get_child(0).text == title:
			return node
	for child in node.get_children():
		var found := _find_panel(child, title)
		if found:
			return found
	return null


## 入れ替えた並びは設定のファイルに残り、既定に戻すと消える
func _check_saved() -> void:
	_main._set_layout_swapped("rows", true)
	var saved: Dictionary = _loc._read_settings()
	_expect(saved.get("panel_layout", {}).get("rows", false) == true, "入れ替えた並びが設定のファイルに残る")
	_loc.set_setting("panel_layout", {})
	_expect(not _loc._read_settings().get("panel_layout", {}).get("rows", false), "既定の並びに戻すと、入れ替えが消える")


func _finish() -> void:
	# 手元の設定を元へ戻す
	if _settings_file == null:
		DirAccess.remove_absolute(_loc.SETTINGS_PATH)
	else:
		var file := FileAccess.open(_loc.SETTINGS_PATH, FileAccess.WRITE)
		file.store_string(_settings_file)
		file.close()
	DirAccess.remove_absolute(SAVE_PATH)
	print("NG" if _failed else "OK: どの並びでも1280x720に収まる")
	quit(1 if _failed else 0)


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_failed = true
	print(("ok   " if ok else "NG   ") + what)
