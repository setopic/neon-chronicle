class_name JobScene
extends Control

## 就いている仕事の様子を、線と点で描く。いまの1回の進み具合に合わせて動き、報酬が入ると光る。ADR-0053。
## 絵は外部の素材を使わず、ここで描く。色は UiStyle から取る。

const PAY_TIME := 0.9  # 報酬が入ったときに光って、額が浮かぶ長さ（秒）

var _time := 0.0
var _pay_left := 0.0
var _pay_text := ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	Game.job_paid.connect(_on_paid)


func _process(delta: float) -> void:
	_time += delta
	_pay_left = maxf(0.0, _pay_left - delta)
	queue_redraw()


func _on_paid(amount: float) -> void:
	_pay_left = PAY_TIME
	_pay_text = "+" + Game.format_number(amount)


## いまの1回の進み具合（0〜1）
func progress() -> float:
	var length := Game.job_length(Game.current_job)
	return clampf(Game.job_progress / length, 0.0, 1.0) if length > 0.0 else 0.0


func _draw() -> void:
	var font := get_theme_default_font()
	match Game.current_job if Game.alive else "":
		"courier": _draw_courier(progress())
		"hacker": _draw_hacker(progress())
		"mercenary": _draw_mercenary(progress())
		"core_breach": _draw_core(progress())
		_:
			draw_string(font, Vector2(0, size.y * 0.5), tr("ui.job_scene_idle"),
				HORIZONTAL_ALIGNMENT_CENTER, size.x, UiStyle.SIZE_SMALL, UiStyle.DIM)
			return
	if _pay_left > 0.0:
		var k := _pay_left / PAY_TIME
		draw_rect(Rect2(Vector2.ZERO, size), Color(UiStyle.PINK, 0.25 * k))
		draw_string(font, Vector2(0, size.y * 0.35 + 24.0 * k), _pay_text,
			HORIZONTAL_ALIGNMENT_CENTER, size.x, UiStyle.SIZE_STAT, Color(UiStyle.PINK, k))


## 運び屋：街の道を、荷が出発点から届け先へ進む
func _draw_courier(t: float) -> void:
	var points := PackedVector2Array()
	for p in [Vector2(0.06, 0.8), Vector2(0.3, 0.8), Vector2(0.3, 0.35), Vector2(0.62, 0.35),
			Vector2(0.62, 0.65), Vector2(0.94, 0.65), Vector2(0.94, 0.2)]:
		points.append(p * size)
	draw_polyline(points, UiStyle.LINE, 3.0)
	draw_rect(Rect2(points[0] - Vector2(5, 5), Vector2(10, 10)), UiStyle.DIM)
	draw_rect(Rect2(points[-1] - Vector2(6, 6), Vector2(12, 12)), UiStyle.CYAN, false, 2.0)
	var at := _along(points, t)
	var done := PackedVector2Array(points.slice(0, at["index"] + 1))
	done.append(at["point"])
	if done.size() >= 2:
		draw_polyline(done, Color(UiStyle.CYAN, 0.8), 3.0)
	var pulse := 5.0 + 1.5 * sin(_time * 10.0)
	draw_circle(at["point"], pulse, UiStyle.PINK)


## 線の上で、長さの割合 t の位置と、その手前の点の番号を返す
func _along(points: PackedVector2Array, t: float) -> Dictionary:
	var total := 0.0
	for i in points.size() - 1:
		total += points[i].distance_to(points[i + 1])
	var left := total * t
	for i in points.size() - 1:
		var step := points[i].distance_to(points[i + 1])
		if left <= step:
			return {"index": i, "point": points[i].lerp(points[i + 1], left / step if step > 0.0 else 0.0)}
		left -= step
	return {"index": points.size() - 2, "point": points[-1]}


## ハッカー：防壁のセルを順に開けていく。開けたセルは水色になり、いま開けているセルが点滅する
func _draw_hacker(t: float) -> void:
	var cols := 10
	var rows := 4
	var gap := 4.0
	var cell := Vector2((size.x - gap * (cols + 1)) / cols, (size.y - gap * (rows + 1)) / rows)
	var opened := int(t * cols * rows)
	for i in cols * rows:
		var rect := Rect2(Vector2(gap + (i % cols) * (cell.x + gap), gap + floori(i / float(cols)) * (cell.y + gap)), cell)
		if i < opened:
			draw_rect(rect, Color(UiStyle.CYAN, 0.55))
		elif i == opened:
			draw_rect(rect, Color(UiStyle.PINK, 0.4 + 0.4 * absf(sin(_time * 12.0))))
		else:
			draw_rect(rect, UiStyle.LINE, false, 1.0)
	var scan := fmod(_time * 0.8, 1.0) * size.y
	draw_line(Vector2(0, scan), Vector2(size.x, scan), Color(UiStyle.CYAN, 0.35), 2.0)


## 傭兵：地面を進みながら、前の敵を撃って倒していく
func _draw_mercenary(t: float) -> void:
	var ground := size.y * 0.78
	draw_line(Vector2(0, ground), Vector2(size.x, ground), UiStyle.LINE, 2.0)
	var x := lerpf(size.x * 0.06, size.x * 0.9, t)
	var enemies := [0.3, 0.52, 0.74, 0.94]
	var target := -1.0
	for e in enemies:
		var ex: float = size.x * e
		if ex < x + size.x * 0.12:
			# 倒した敵は、地面に伏せた形で残す
			draw_rect(Rect2(ex - 9, ground - 5, 18, 5), Color(UiStyle.DANGER, 0.35))
		else:
			draw_rect(Rect2(ex - 5, ground - 26, 10, 26), UiStyle.DANGER)
			if target < 0.0:
				target = ex
	draw_rect(Rect2(x - 6, ground - 28, 12, 28), UiStyle.CYAN)
	if target >= 0.0 and fmod(_time, 0.5) < 0.12:
		draw_line(Vector2(x + 8, ground - 20), Vector2(target - 6, ground - 18), UiStyle.PINK, 2.0)


## 中枢サーバーへの侵入：中枢を囲む防壁の輪を、外から1つずつ破って進む
func _draw_core(t: float) -> void:
	var center := size * 0.5
	var rings := 5
	var outer := minf(size.x, size.y) * 0.46
	var broken := int(t * rings)
	for i in rings:
		var radius := outer * (1.0 - float(i) / rings)
		var color := Color(UiStyle.DIM, 0.25) if i < broken else (UiStyle.PINK if i == broken else Color(UiStyle.CYAN, 0.6))
		draw_arc(center, radius, _time * (0.6 + 0.2 * i) * (1.0 if i % 2 == 0 else -1.0), \
			_time * (0.6 + 0.2 * i) * (1.0 if i % 2 == 0 else -1.0) + TAU * 0.8, 48, color, 2.0)
	draw_circle(center, outer * 0.12, UiStyle.PINK if t > 0.95 else UiStyle.CYAN)
	var probe := center + Vector2.RIGHT.rotated(_time * 2.0) * outer * (1.0 - t * 0.9)
	draw_circle(probe, 4.0, Color.WHITE)
