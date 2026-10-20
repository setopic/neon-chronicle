class_name HackingGame
extends Minigame

## ハッカーの仕事のミニゲーム。防壁の符号の表から、縦と横を交互にたどって、決まった並びの符号を選ぶ。ADR-0055。
## 中枢サーバーへの侵入の仕事でも使う（ADR-0054）。ハッキングのレベルが上がるほど、選べる枠が増えて易しくなる。

const CODES := ["1C", "55", "BD", "E9", "7A"]
const GRID := 5
const TARGET := 4  # そろえる並びの長さ
const MIN_SLACK := 1  # レベル0のときに、並びより多く選べる回数
const MAX_SLACK := 4

var _cells := []  # 行ごとの符号
var _target := []
var path := []  # 並びをちょうどの回数でそろえられる升目の道。ci/minigame.gd が使う
var _buffer := []  # 選んだ符号
var _used := {}  # 選んだ升目（Vector2i）
var _matched := 0
var _line_is_row := true  # 次に選ぶのが行の中か（false なら列の中）
var _line := 0
var _buttons := {}  # Vector2i -> Button
var _target_label: Label
var _buffer_label: Label


func _ready() -> void:
	add_theme_constant_override("separation", 8)
	_make_puzzle()
	_target_label = Label.new()
	_target_label.add_theme_font_size_override("font_size", UiStyle.SIZE_HEADING)
	add_child(_target_label)
	_buffer_label = Label.new()
	_buffer_label.add_theme_color_override("font_color", UiStyle.DIM)
	add_child(_buffer_label)
	var grid := GridContainer.new()
	grid.columns = GRID
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	add_child(grid)
	for r in GRID:
		for c in GRID:
			var button := Button.new()
			button.text = _cells[r][c]
			button.custom_minimum_size = Vector2(110, 38)
			button.pressed.connect(_pick.bind(Vector2i(r, c)))
			grid.add_child(button)
			_buttons[Vector2i(r, c)] = button
	_refresh()


## 選べる枠の数。並びの長さに、レベルに応じた余りを足す
func buffer_size() -> int:
	return TARGET + clampi(MIN_SLACK + level / 5, MIN_SLACK, MAX_SLACK)


## 先に解ける道を1つ作って並びの符号を置き、残りの升目を埋める。どの表でも必ずそろえられる
func _make_puzzle() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for r in GRID:
		var row := []
		for c in GRID:
			row.append(CODES[rng.randi() % CODES.size()])
		_cells.append(row)
	var at := Vector2i(0, rng.randi() % GRID)
	path = [at]
	for i in TARGET - 1:
		var next := at
		while path.has(next):
			# 偶数番目の次は同じ列の別の行、奇数番目の次は同じ行の別の列を選ぶ
			next = Vector2i(rng.randi() % GRID, at.y) if i % 2 == 0 else Vector2i(at.x, rng.randi() % GRID)
		path.append(next)
		at = next
	for p in path:
		var code: String = CODES[rng.randi() % CODES.size()]
		_cells[p.x][p.y] = code
		_target.append(code)


func _pick(cell: Vector2i) -> void:
	var code: String = _cells[cell.x][cell.y]
	_buffer.append(code)
	_used[cell] = true
	# 並びの次の符号なら進め、違えば最初からやり直す。違った符号が並びの頭なら1つ目として数える
	if code == _target[_matched]:
		_matched += 1
	else:
		_matched = 1 if code == _target[0] else 0
	_line_is_row = not _line_is_row
	_line = cell.x if _line_is_row else cell.y
	if _matched >= TARGET:
		# そろえたら、余らせた枠の数で度合いを決める。ちょうどの回数なら1、枠を使い切ったら0.5
		var slack := buffer_size() - TARGET
		var extra := _buffer.size() - TARGET
		finished.emit(1.0 - 0.5 * float(extra) / maxf(1.0, slack))
		return
	if _buffer.size() >= buffer_size():
		# 枠が埋まったら失敗で、度合いは0にする。それでも放置で終えた1回と同じだけ入る（ADR-0054）
		finished.emit(0.0)
		return
	_refresh()


func _refresh() -> void:
	var parts := PackedStringArray()
	for i in _target.size():
		parts.append("[%s]" % _target[i] if i < _matched else _target[i])
	_target_label.text = "%s  %s" % [tr("minigame.hacking.target"), "  ".join(parts)]
	# ci/minigame.gd から作るときは自動読み込みの名前（Loc）が使えないので、tr で文を引く
	_buffer_label.text = tr("minigame.hacking.buffer").format({"codes": " ".join(_buffer), "left": buffer_size() - _buffer.size()})
	var focus: Button = null
	for cell in _buttons:
		var button: Button = _buttons[cell]
		var on_line: bool = (cell.x == _line) if _line_is_row else (cell.y == _line)
		button.disabled = _used.has(cell) or not on_line
		if not button.disabled and focus == null:
			focus = button
	if focus != null:
		focus.call_deferred("grab_focus")
