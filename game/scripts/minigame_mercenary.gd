class_name MercenaryGame
extends Minigame

## 傭兵の仕事のミニゲーム。並んだ窓に敵が順に顔を出すので、撃ち返される前に、その窓を狙って撃つ。ADR-0057。
## 格闘のレベルが上がるほど、敵が顔を出している時間が長くなって易しくなる。

const SLOTS := 4
const TARGETS := 8
const GAP := 0.5  # 敵が引っ込んでから、次の敵が顔を出すまで（秒）
const BASE_WINDOW := 1.2  # レベル0のときに、敵が顔を出している時間（秒）
const WINDOW_PER_LEVEL := 0.05
const MAX_WINDOW := 2.2
const MISFIRE := 0.05  # 誰もいない窓を撃つたびに、度合いから引く量

var active := -1  # 敵が顔を出している窓。いなければ -1。ci/minigame.gd が使う
var _left := GAP  # 次の切り替えまでの時間
var _spawned := 0
var _hits := 0
var _missed := 0
var _misfires := 0
var _done := false
var _slots := []
var _status: Label
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	add_theme_constant_override("separation", 8)
	_status = Label.new()
	_status.add_theme_color_override("font_color", UiStyle.DIM)
	add_child(_status)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	add_child(row)
	for i in SLOTS:
		var button := Button.new()
		button.text = str(i + 1)
		button.custom_minimum_size = Vector2(130, 120)
		button.pressed.connect(shoot.bind(i))
		button.draw.connect(_draw_slot.bind(i))
		row.add_child(button)
		_slots.append(button)
	_slots[0].call_deferred("grab_focus")
	_refresh()


## 敵が顔を出している時間。レベルに応じて長くする
func window() -> float:
	return minf(BASE_WINDOW + WINDOW_PER_LEVEL * level, MAX_WINDOW)


func _process(delta: float) -> void:
	advance(delta)


## 時間を進める。敵が顔を出している時間が切れたら撃たれ、間が空いたら次の敵が顔を出す
func advance(delta: float) -> void:
	if _done:
		return
	_left -= delta
	if _left > 0.0:
		for slot in _slots:
			slot.queue_redraw()
		return
	if active >= 0:
		_missed += 1
		active = -1
		_left = GAP
		_check_end()
	elif _spawned < TARGETS:
		active = _rng.randi() % SLOTS
		_spawned += 1
		_left = window()
	_refresh()


func shoot(slot: int) -> void:
	if _done:
		return
	if slot == active:
		_hits += 1
		active = -1
		_left = GAP
		_check_end()
	else:
		_misfires += 1
	_refresh()


func _check_end() -> void:
	if _spawned >= TARGETS and active < 0:
		_done = true
		finished.emit(clampf(float(_hits) / TARGETS - MISFIRE * _misfires, 0.0, 1.0))


func _unhandled_input(event: InputEvent) -> void:
	# 数字のキーで、その番号の窓を撃つ
	if event is InputEventKey and event.pressed and not event.echo:
		var n: int = event.keycode - KEY_1
		if n >= 0 and n < SLOTS:
			shoot(n)
			get_viewport().set_input_as_handled()


func _refresh() -> void:
	if _status != null:
		_status.text = tr("minigame.mercenary.status").format({"hits": _hits, "max": TARGETS, "missed": _missed})
	for slot in _slots:
		slot.queue_redraw()


func _draw_slot(i: int) -> void:
	var button: Button = _slots[i]
	if i != active:
		return
	var area := button.size
	# 敵の影と、撃ち返されるまでの残りの時間の棒
	button.draw_rect(Rect2(area.x * 0.5 - 14, area.y * 0.2, 28, area.y * 0.5), UiStyle.DANGER)
	button.draw_circle(Vector2(area.x * 0.5, area.y * 0.18), 12, UiStyle.DANGER)
	button.draw_rect(Rect2(8, area.y - 12, (area.x - 16) * clampf(_left / window(), 0.0, 1.0), 4), UiStyle.PINK)
