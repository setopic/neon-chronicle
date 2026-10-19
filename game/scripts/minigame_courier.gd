class_name CourierGame
extends Minigame

## 運び屋の仕事のミニゲーム。街の升目を1歩ずつ進み、縦に行き来する追っ手をかわして届け先へ荷を運ぶ。ADR-0056。
## 1歩ごとに追っ手も1歩動く。交渉のレベルが上がるほど、使える歩数に余りが増えて易しくなる。

const COLS := 8
const ROWS := 5
const PATROL_COLS := [2, 4, 6]  # 追っ手が行き来する列
const MIN_SLACK := 3  # レベル0のときに、いちばん短い歩数より多く歩ける数
const MAX_SLACK := 7
const CELL := Vector2(60, 46)
const MOVES := {"up": Vector2i(0, -1), "down": Vector2i(0, 1), "left": Vector2i(-1, 0), "right": Vector2i(1, 0), "wait": Vector2i.ZERO}
const MOVE_TEXT := {"up": "minigame.courier.up", "down": "minigame.courier.down", "left": "minigame.courier.left",
	"right": "minigame.courier.right", "wait": "minigame.courier.wait"}

var goal := Vector2i.ZERO
var start := Vector2i(0, 2)
var solution := []  # レベル0の歩数で届く手の並び。表を作るときに確かめる。ci/minigame.gd が使う
var _player := Vector2i.ZERO
var _patrols := []  # [{"pos": Vector2i, "dir": 1 か -1}]
var _steps := 0
var _map: Control
var _status: Label
var _done := false


func _ready() -> void:
	add_theme_constant_override("separation", 8)
	_make_map()
	_status = Label.new()
	_status.add_theme_color_override("font_color", UiStyle.DIM)
	add_child(_status)
	_map = Control.new()
	_map.custom_minimum_size = Vector2(COLS, ROWS) * CELL
	_map.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_map.draw.connect(_draw_map)
	_map.gui_input.connect(_click_map)
	add_child(_map)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(row)
	for key in MOVES:
		var button := Button.new()
		button.text = tr(MOVE_TEXT[key])
		button.custom_minimum_size = Vector2(80, 36)
		# 矢印のキーで歩けるよう、ボタンにはキーボードの選択を渡さない
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(move.bind(key))
		row.add_child(button)
	_refresh()


## 使える歩数。いちばん短い歩数に、レベルに応じた余りを足す
func step_limit(for_level := -1) -> int:
	var lv := level if for_level < 0 else for_level
	return shortest() + clampi(MIN_SLACK + lv / 5, MIN_SLACK, MAX_SLACK)


## 追っ手がいないときの、いちばん短い歩数
func shortest() -> int:
	return absi(goal.x - start.x) + absi(goal.y - start.y)


## 届け先と追っ手の位置を決め、レベル0の歩数で届く手があるかを確かめる。無ければ作り直す
func _make_map() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	while true:
		goal = Vector2i(COLS - 1, rng.randi() % ROWS)
		_patrols = []
		for x in PATROL_COLS:
			_patrols.append({"pos": Vector2i(x, rng.randi() % ROWS), "dir": 1 if rng.randf() < 0.5 else -1})
		solution = _solve(step_limit(0))
		if not solution.is_empty():
			break
	_player = start


## 1歩進めたあとの状態を返す。追っ手に捕まったら caught を立てる。表を確かめるときにも、遊ぶときにも使う
static func _step(player: Vector2i, patrols: Array, key: String) -> Dictionary:
	var next: Vector2i = player + MOVES[key]
	next = Vector2i(clampi(next.x, 0, COLS - 1), clampi(next.y, 0, ROWS - 1))
	var moved := []
	var caught := false
	for p in patrols:
		var dir: int = p["dir"]
		if p["pos"].y + dir < 0 or p["pos"].y + dir >= ROWS:
			dir = -dir
		var pos: Vector2i = p["pos"] + Vector2i(0, dir)
		# 同じ升目に入ったときと、すれ違ったときに捕まる
		if pos == next or (pos == player and p["pos"] == next):
			caught = true
		moved.append({"pos": pos, "dir": dir})
	return {"player": next, "patrols": moved, "caught": caught}


## limit 歩以内に届く手の並びを、幅優先で探す。無ければ空
func _solve(limit: int) -> Array:
	var queue := [{"player": start, "patrols": _patrols, "keys": []}]
	var seen := {}
	while not queue.is_empty():
		var s: Dictionary = queue.pop_front()
		if s["player"] == goal:
			return s["keys"]
		if s["keys"].size() >= limit:
			continue
		for key in MOVES:
			var n := _step(s["player"], s["patrols"], key)
			if n["caught"]:
				continue
			var id := "%s/%s" % [n["player"], n["patrols"]]
			if seen.has(id):
				continue
			seen[id] = true
			queue.append({"player": n["player"], "patrols": n["patrols"], "keys": s["keys"] + [key]})
	return []


func move(key: String) -> void:
	if _done:
		return
	var n := _step(_player, _patrols, key)
	_player = n["player"]
	_patrols = n["patrols"]
	_steps += 1
	if n["caught"]:
		# 捕まったら失敗で、度合いは0にする。それでも放置で終えた1回と同じだけ入る（ADR-0054）
		_finish(0.0)
	elif _player == goal:
		# 届けたら、余りの歩数をどれだけ使ったかで度合いを決める。いちばん短い歩数なら1、余りを使い切ったら0.5
		var slack := step_limit() - shortest()
		_finish(1.0 - 0.5 * float(_steps - shortest()) / maxf(1.0, slack))
	elif _steps >= step_limit():
		_finish(0.0)
	_refresh()


func _finish(score: float) -> void:
	_done = true
	finished.emit(clampf(score, 0.0, 1.0))


func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var keys := {KEY_UP: "up", KEY_W: "up", KEY_DOWN: "down", KEY_S: "down", KEY_LEFT: "left", KEY_A: "left",
		KEY_RIGHT: "right", KEY_D: "right", KEY_SPACE: "wait"}
	if keys.has(event.keycode):
		move(keys[event.keycode])
		get_viewport().set_input_as_handled()


## 隣の升目を押すと、そちらへ1歩進む。自分の升目を押すと待つ
func _click_map(event: InputEvent) -> void:
	if not event is InputEventMouseButton or not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return
	var cell := Vector2i((event.position / CELL).floor())
	for key in MOVES:
		if _player + MOVES[key] == cell:
			move(key)
			return


func _refresh() -> void:
	if _status != null:
		_status.text = tr("minigame.courier.steps").format({"left": step_limit() - _steps})
	if _map != null:
		_map.queue_redraw()


func _draw_map() -> void:
	for x in COLS:
		for y in ROWS:
			_map.draw_rect(Rect2(Vector2(x, y) * CELL + Vector2(2, 2), CELL - Vector2(4, 4)), UiStyle.SURFACE)
	_map.draw_rect(Rect2(Vector2(goal) * CELL + Vector2(8, 8), CELL - Vector2(16, 16)), UiStyle.CYAN, false, 2.0)
	for p in _patrols:
		var center: Vector2 = (Vector2(p["pos"]) + Vector2(0.5, 0.5)) * CELL
		_map.draw_circle(center, 12, UiStyle.DANGER)
		# 次に動く向きを、小さな印で見せる
		_map.draw_circle(center + Vector2(0, 18 * p["dir"]), 3, Color(UiStyle.DANGER, 0.6))
	_map.draw_circle((Vector2(_player) + Vector2(0.5, 0.5)) * CELL, 12, UiStyle.PINK)
