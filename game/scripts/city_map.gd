class_name CityMap
extends Control

## 街の地図。上から見た地形として、高台の企業区画、崖、排水路、低い土地の下層街を描き、
## 建物を小さな四角、通りを線で描く。DOM-15、DOM-16。
## 配置はDOM-15の図と同じにする。中枢サーバーは、記憶の断片「中枢サーバー」が戻るまで描かない。

const PINK := Color(1.0, 0.2, 0.7)
const CYAN := Color(0.2, 0.95, 1.0)
const TEXT := Color(0.9, 0.9, 1.0)
const NOTE := Color(0.7, 0.7, 0.85)
const SHADOW := Color(0.03, 0.02, 0.07)
const HIGH := Color(0.13, 0.08, 0.24)
const LOW := Color(0.06, 0.04, 0.10)
const WATER := Color(0.04, 0.16, 0.26)
const SIZE := Vector2(780, 470)

## 崖の縁。高台はこの線より上にある
const CLIFF := [
	Vector2(0, 186), Vector2(60, 182), Vector2(130, 189), Vector2(210, 180), Vector2(300, 186),
	Vector2(390, 181), Vector2(470, 188), Vector2(560, 180), Vector2(650, 187), Vector2(720, 182),
	Vector2(780, 185),
]
## 排水路の上の岸と下の岸の高さ
const CANAL_TOP := 214.0
const CANAL_BOTTOM := 236.0
## 縄張りの境目のx座標
const BORDERS := [195.0, 390.0, 585.0]
## 区画の名前を置く位置（文字列の中心）。名前は map.<id>、添え書きは map.<id>.note で、改行で行を分ける
const LABELS := {
	"yomi": Vector2(97, 48),
	"waldeck": Vector2(292, 48),
	"montfort": Vector2(487, 48),
	"lindholm": Vector2(682, 48),
	"back_alley": Vector2(200, 272),
	"stalls": Vector2(470, 334),
	"deep": Vector2(375, 410),
	"black_market": Vector2(90, 410),
}
const NOTED := ["yomi", "montfort", "lindholm", "black_market", "deep"]
## 橋のx座標。高台から排水路をまたいで、下層街へ下りる
const BRIDGES := {
	"olsen_bridge": 107.0,
	"villard_bridge": 390.0,
	"hagen_bridge": 672.0,
}
## 下層街の通り。太い線は表通り、細い線は路地
const STREETS := [
	[Vector2(390, 252), Vector2(390, 300)],
	[Vector2(672, 252), Vector2(672, 300)],
	[Vector2(300, 300), Vector2(770, 300)],
]
const ALLEYS := [
	[Vector2(107, 252), Vector2(95, 310), Vector2(150, 330), Vector2(300, 300)],
	[Vector2(95, 310), Vector2(40, 335), Vector2(60, 360)],
	[Vector2(150, 330), Vector2(230, 355), Vector2(260, 390), Vector2(330, 430)],
	[Vector2(470, 300), Vector2(450, 360), Vector2(420, 440)],
	[Vector2(600, 300), Vector2(560, 380), Vector2(480, 455)],
]
## 闇市場は地下にあるので、点線で囲む。入口は裏通りに1つだけある
const MARKET := Rect2(15, 380, 150, 80)
const MARKET_ENTRANCE := Vector2(60, 360)
const CLINIC := Vector2(150, 330)
## 凡例。記号ごとの名前は map.legend.<id>
const LEGEND := Rect2(598, 318, 176, 122)
const LEGEND_ITEMS := ["building", "shack", "street", "alley", "stall", "cliff", "border"]
## 裏通りの添え書き map.back_alley.note は、1行目を診療所の印、2行目を闇市場の入口の印に添える
const MARKERS := [CLINIC, MARKET_ENTRANCE]


func _ready() -> void:
	custom_minimum_size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var o := ((size - SIZE) / 2).floor()
	_draw_ground(o)
	_draw_blocks(o)
	_draw_streets(o)
	_draw_market(o)
	_draw_bridges(o)
	_draw_labels(o)
	_draw_legend(o)


func _draw_ground(o: Vector2) -> void:
	draw_rect(Rect2(o, SIZE), LOW)
	var high := PackedVector2Array([o, o + Vector2(SIZE.x, 0)])
	for i in range(CLIFF.size() - 1, -1, -1):
		high.append(o + CLIFF[i])
	draw_colored_polygon(high, HIGH)
	# 崖は、縁から下へ向かう短い線を並べて描く
	for i in CLIFF.size() - 1:
		var a: Vector2 = CLIFF[i]
		var b: Vector2 = CLIFF[i + 1]
		var steps := int(a.distance_to(b) / 6)
		for s in steps:
			var p := a.lerp(b, float(s) / steps)
			draw_line(o + p, o + p + Vector2(-2, 12 + (s % 3) * 3), Color(PINK, 0.45), 1)
	draw_polyline(_shift(PackedVector2Array(CLIFF), o), PINK, 2)
	var water := Rect2(o + Vector2(0, CANAL_TOP), Vector2(SIZE.x, CANAL_BOTTOM - CANAL_TOP))
	draw_rect(water, WATER)
	draw_line(water.position, water.position + Vector2(SIZE.x, 0), Color(CYAN, 0.5), 1)
	draw_line(water.end - Vector2(SIZE.x, 0), water.end, Color(CYAN, 0.5), 1)
	for x in range(10, int(SIZE.x), 40):
		var p := o + Vector2(x, (CANAL_TOP + CANAL_BOTTOM) / 2 + (x / 40 % 2) * 4 - 2)
		draw_line(p, p + Vector2(14, 0), Color(CYAN, 0.3), 1)


## 建物の四角。毎回同じ形になるよう、乱数の種を固定する
func _draw_blocks(o: Vector2) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for x in range(6, int(SIZE.x) - 20, 26):
		for y in range(28, 170, 24):
			if BORDERS.any(func(b): return abs(x + 10 - b) < 16):
				continue
			var r := Rect2(o + Vector2(x, y), Vector2(rng.randi_range(14, 20), rng.randi_range(12, 18)))
			if r.end.y - o.y > _cliff_y(x) - 6:
				continue
			draw_rect(r, Color(0.2, 0.13, 0.36))
			draw_rect(r, Color(CYAN, 0.25), false, 1)
	for b in BORDERS:
		_dashed(o + Vector2(b, 24), o + Vector2(b, 176), Color(PINK, 0.6))
	rng.seed = 11
	for i in 260:
		var p := Vector2(rng.randf_range(4, SIZE.x - 12), rng.randf_range(246, SIZE.y - 10))
		if MARKET.grow(4).has_point(p) or LEGEND.grow(4).has_point(p) or _near_street(p):
			continue
		var r := Rect2(o + p, Vector2(rng.randi_range(5, 10), rng.randi_range(4, 8)))
		draw_rect(r, Color(0.16, 0.1, 0.22))
		draw_rect(r, Color(PINK, 0.2), false, 1)


func _draw_streets(o: Vector2) -> void:
	for line in STREETS:
		draw_line(o + line[0], o + line[1], Color(CYAN, 0.7), 4)
	for line in ALLEYS:
		draw_polyline(_shift(PackedVector2Array(line), o), Color(CYAN, 0.45), 2)
	# 屋台通りの屋台
	for x in range(320, 760, 18):
		draw_rect(Rect2(o + Vector2(x, 290), Vector2(7, 5)), Color(1.0, 0.75, 0.3, 0.8))
		draw_rect(Rect2(o + Vector2(x + 9, 305), Vector2(7, 5)), Color(1.0, 0.75, 0.3, 0.8))
	draw_rect(Rect2(o + CLINIC - Vector2(5, 5), Vector2(10, 10)), PINK)
	draw_rect(Rect2(o + MARKET_ENTRANCE - Vector2(4, 4), Vector2(8, 8)), CYAN)


func _draw_market(o: Vector2) -> void:
	var r := Rect2(o + MARKET.position, MARKET.size)
	draw_rect(r, Color(SHADOW, 0.85))
	var c := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.position]
	for i in 4:
		_dashed(c[i], c[i + 1], CYAN)
	_dashed(o + MARKET_ENTRANCE, o + Vector2(MARKET_ENTRANCE.x, MARKET.position.y), CYAN)


func _draw_bridges(o: Vector2) -> void:
	var font := get_theme_default_font()
	for id in BRIDGES:
		var x: float = BRIDGES[id]
		var deck := Rect2(o + Vector2(x - 6, _cliff_y(x) - 10), Vector2(12, 262 - _cliff_y(x)))
		draw_rect(deck, Color(0.25, 0.15, 0.35))
		draw_line(deck.position, Vector2(deck.position.x, deck.end.y), PINK, 2)
		draw_line(Vector2(deck.end.x, deck.position.y), deck.end, PINK, 2)
		_text(font, o + Vector2(x + 12, CANAL_TOP - 6), tr("map." + id), 13, TEXT, HORIZONTAL_ALIGNMENT_LEFT)


func _draw_labels(o: Vector2) -> void:
	var font := get_theme_default_font()
	_text(font, o + Vector2(8, 18), tr("map.corp_district"), 14, PINK, HORIZONTAL_ALIGNMENT_LEFT)
	_text(font, o + Vector2(SIZE.x - 8, SIZE.y - 10), tr("map.lower_city"), 14, PINK, HORIZONTAL_ALIGNMENT_RIGHT)
	_text(font, o + Vector2(SIZE.x / 2, CANAL_BOTTOM - 6), tr("map.canal"), 12, Color(CYAN, 0.9))
	for id in LABELS:
		var at: Vector2 = o + LABELS[id]
		var lines := PackedStringArray()
		if id in NOTED:
			lines = tr("map.%s.note" % id).split("\n")
		if id == "back_alley":
			var notes := tr("map.back_alley.note").split("\n")
			for i in mini(notes.size(), MARKERS.size()):
				_text(font, o + MARKERS[i] + Vector2(10, 5), notes[i], 13, NOTE, HORIZONTAL_ALIGNMENT_LEFT)
		if id == "yomi" and Game.fragments.has("core"):
			lines.append(tr("map.core"))
		_text(font, at, tr("map." + id), 15, TEXT)
		for i in lines.size():
			_text(font, at + Vector2(0, 20 + i * 18), lines[i], 13, NOTE)


func _draw_legend(o: Vector2) -> void:
	var font := get_theme_default_font()
	var r := Rect2(o + LEGEND.position, LEGEND.size)
	draw_rect(r, Color(SHADOW, 0.9))
	draw_rect(r, Color(CYAN, 0.5), false, 1)
	for i in LEGEND_ITEMS.size():
		var id: String = LEGEND_ITEMS[i]
		var at := r.position + Vector2(10, 16 + i * 15)
		match id:
			"building":
				draw_rect(Rect2(at - Vector2(0, 5), Vector2(14, 10)), Color(0.2, 0.13, 0.36))
				draw_rect(Rect2(at - Vector2(0, 5), Vector2(14, 10)), Color(CYAN, 0.5), false, 1)
			"shack":
				draw_rect(Rect2(at - Vector2(-3, 3), Vector2(8, 6)), Color(0.16, 0.1, 0.22))
				draw_rect(Rect2(at - Vector2(-3, 3), Vector2(8, 6)), Color(PINK, 0.5), false, 1)
			"street":
				draw_line(at, at + Vector2(16, 0), Color(CYAN, 0.7), 4)
			"alley":
				draw_line(at, at + Vector2(16, 0), Color(CYAN, 0.45), 2)
			"stall":
				draw_rect(Rect2(at - Vector2(-4, 3), Vector2(7, 5)), Color(1.0, 0.75, 0.3, 0.8))
			"cliff":
				draw_line(at - Vector2(0, 4), at + Vector2(16, -4), PINK, 2)
				for x in range(2, 16, 5):
					draw_line(at + Vector2(x, -4), at + Vector2(x - 1, 5), Color(PINK, 0.6), 1)
			"border":
				_dashed(at, at + Vector2(16, 0), Color(PINK, 0.8))
		_text(font, at + Vector2(24, 5), tr("map.legend.%s" % id), 12, NOTE, HORIZONTAL_ALIGNMENT_LEFT)


## 建物や線の上でも読めるよう、文字は縁取りしてから描く
func _text(font: Font, at: Vector2, text: String, font_size: int, color: Color, align := HORIZONTAL_ALIGNMENT_CENTER) -> void:
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var pos := at
	if align == HORIZONTAL_ALIGNMENT_CENTER:
		pos.x -= width / 2
	elif align == HORIZONTAL_ALIGNMENT_RIGHT:
		pos.x -= width
	draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 6, SHADOW)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _dashed(a: Vector2, b: Vector2, color: Color) -> void:
	draw_dashed_line(a, b, color, 1, 5)


func _cliff_y(x: float) -> float:
	for i in CLIFF.size() - 1:
		if x <= CLIFF[i + 1].x:
			return lerpf(CLIFF[i].y, CLIFF[i + 1].y, (x - CLIFF[i].x) / (CLIFF[i + 1].x - CLIFF[i].x))
	return CLIFF[-1].y


func _near_street(p: Vector2) -> bool:
	for line in STREETS + ALLEYS:
		for i in line.size() - 1:
			var q := Geometry2D.get_closest_point_to_segment(p, line[i], line[i + 1])
			if p.distance_to(q) < 12:
				return true
	return false


func _shift(points: PackedVector2Array, o: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in points:
		out.append(p + o)
	return out
