class_name Minigame
extends VBoxContainer

## 仕事のミニゲームの共通の形。遊び方の説明と遊ぶ部分を持ち、終えたら成功の度合い（0〜1）を知らせる。ADR-0054。
## どの種類も、マウスだけでも、キーボードだけでも遊べるようにする。

signal finished(score: float)

var level := 0  # 仕事の主なスキルのレベル。種類ごとに難しさを変えるのに使う


## jobs.json の minigame の値から、その種類のミニゲームを作る。知らない種類は null
static func create(kind: String, skill_level: int) -> Minigame:
	var game: Minigame = null
	match kind:
		"timing": game = TimingGame.new()
	if game != null:
		game.level = skill_level
	return game


## 動く印を、中央の枠の中で止める。3回止めて、枠の中心からのずれで度合いを決める。
## 各仕事のミニゲームができるまでの、仮のもの
class TimingGame extends Minigame:
	const TRIES := 3
	const SPEED := 0.9  # 1秒に進む、棒の長さに対する割合
	var _bar: Control
	var _pos := 0.0
	var _dir := 1.0
	var _scores := []

	func _ready() -> void:
		add_theme_constant_override("separation", 10)
		_bar = Control.new()
		_bar.custom_minimum_size = Vector2(0, 48)
		_bar.draw.connect(_draw_bar)
		add_child(_bar)
		var stop := Button.new()
		stop.text = tr("minigame.timing.stop")
		stop.custom_minimum_size = Vector2(0, 44)
		stop.pressed.connect(_stop)
		add_child(stop)
		stop.call_deferred("grab_focus")

	func _process(delta: float) -> void:
		_pos += _dir * SPEED * delta
		if _pos > 1.0 or _pos < 0.0:
			_dir = -_dir
			_pos = clampf(_pos, 0.0, 1.0)
		_bar.queue_redraw()

	func _stop() -> void:
		_scores.append(clampf(1.0 - absf(_pos - 0.5) / 0.5, 0.0, 1.0))
		if _scores.size() >= TRIES:
			var total := 0.0
			for s in _scores:
				total += s
			finished.emit(total / TRIES)

	func _draw_bar() -> void:
		var area := _bar.size
		_bar.draw_rect(Rect2(Vector2.ZERO, area), UiStyle.SURFACE)
		_bar.draw_rect(Rect2(Vector2(area.x * 0.42, 0), Vector2(area.x * 0.16, area.y)), Color(UiStyle.CYAN, 0.3))
		_bar.draw_rect(Rect2(Vector2(area.x * _pos - 3, 0), Vector2(6, area.y)), UiStyle.PINK)
		for i in _scores.size():
			_bar.draw_circle(Vector2(12 + i * 18, 10), 5, UiStyle.CYAN)
