extends SceneTree

## 分岐図が組み立てられ、見た段と選んだ選択肢を見分けられるかを確かめる。DOM-30。
## 画面を開かずに、分岐図の部品だけを作って木に入れ、数フレーム描かせる。
## セーブは別のファイルに書くので、手元のセーブは消えない。
##
##   godot --headless --path . --script res://ci/chart.gd

const SAVE_PATH := "user://chart-check.json"

var _game: Node
var _chart: Control
var _frames := 0
var _failed := false


func _process(_delta: float) -> bool:
	if _game == null:
		_game = root.get_node("Game")
		_game.save_path = SAVE_PATH
		_game.set_process(false)
		_game.reset_game()
		_game.character_choices = {"rei_1": "listen", "rei_2": "help"}
		_chart = load("res://scripts/branch_chart.gd").new()
		root.add_child(_chart)
		return false
	_frames += 1
	if _frames < 3:
		return false
	var rows: Array = _chart.rows()
	var labels := rows.map(func(r): return r["label"])
	_expect(rows.size() >= 8, "話とエンディングの行がある（%d行）" % rows.size())
	_expect(rows.back()["stages"] == ["core_server"], "最後の行はエンディング")
	_expect(_chart.seen("rei_2") and not _chart.seen("rei_3"), "選んだ段だけを見たことにする")
	_expect(_chart.chosen("rei_2", {"id": "help"}), "選んだ選択肢を見分ける")
	_expect(not _chart.seen("core_server"), "エンディングにたどり着くまで、結末の行は伏せる")
	_expect(_chart.custom_minimum_size.x > 0.0 and _chart.custom_minimum_size.y > 0.0, "図の大きさが決まる")
	# 話を選び直すと、その段から後の選択だけが消える（DOM-31）
	# エンディングにたどり着く前は選び直せない（ADR-0050）
	_game.rewind_story("rei", "rei_2")
	_expect(_game.character_choices.has("rei_2"), "エンディングにたどり着く前は、選び直せない")
	_game.chronicle = [{"ending": "reclaim"}]
	_game.rewind_story("rei", "rei_2")
	_expect(_game.character_choices.has("rei_1") and not _game.character_choices.has("rei_2"), "選び直した段から後の選択だけが消える")
	# 排他の組の永続強化は、払った記憶ポイントをすべて戻して選び直せる
	_game.memory_points = 0
	_game.upgrades = {"focus_hacking": 2}
	_game.refund_upgrade("focus_hacking")
	_expect(_game.memory_points == 9 and _game.upgrade_taken_in_group("focus_combat") == "", "組の永続強化を選び直すと、払った記憶ポイントが戻る（%d）" % _game.memory_points)
	print(labels)
	DirAccess.remove_absolute(SAVE_PATH)
	print("NG" if _failed else "OK: 分岐図を組み立てられる")
	quit(1 if _failed else 0)
	return true


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_failed = true
	print(("ok   " if ok else "NG   ") + what)
