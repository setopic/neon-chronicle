class_name CityMap
extends Control

## 街の地図。一般的な道路地図の描き方で描く。道路は縁取りした帯、街区は面、水は青、
## 崖は崖の記号、縄張りの境は点線、施設は印と名前で示す。DOM-15、DOM-16。
## 配置はDOM-15の図と同じにする。中枢サーバーは、記憶の断片「中枢サーバー」が戻るまで描かない。

const PINK := Color(1.0, 0.2, 0.7)
const CYAN := Color(0.2, 0.95, 1.0)
const TEXT := Color(0.92, 0.92, 1.0)
const NOTE := Color(0.72, 0.74, 0.86)
const SHADOW := Color(0.04, 0.04, 0.08)
const LOW_BLOCK := Color("232634")
const HIGH_BLOCK := Color("34304d")
const SLOPE := Color("17151f")
const WATER := Color("1d4470")
const SHORE := Color("4f86c0")
const CLIFF_COLOR := Color("c08a5a")
const ROAD_MAIN := Color("8a8fa8")
const ROAD := Color("666a80")
const ALLEY := Color("4c4f62")
const CASING := Color("0d0e15")
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
## 下層街の土地は、この高さから下にある
const LOW_TOP := 244.0
## 縄張りの境目のx座標。縄張りの広さは、社の力関係に合わせる（DOM-15）。
## ヴァルデック義体とモンフォール警備の境は、ヴィラール橋へ下りる通りに沿う
const BORDERS := [280.0, 440.0, 560.0]
## 区画の名前を置く位置（文字列の中心）。名前は map.<id>
const LABELS := {
	"yomi": Vector2(140, 48),
	"waldeck": Vector2(355, 48),
	"montfort": Vector2(500, 48),
	"lindholm": Vector2(670, 48),
	"back_alley": Vector2(205, 272),
	"stalls": Vector2(520, 324),
	"deep": Vector2(375, 410),
	"black_market": Vector2(90, 412),
}
## 名前の下に添え書きを持つ区画。添え書きは map.<id>.note
const NOTED := ["deep", "black_market"]
## 施設の印。名前は map.poi.<id>。印の右に名前を置く
const POIS := {
	"yomi_hq": Vector2(30, 102),
	"power_plant": Vector2(140, 102),
	"substation": Vector2(120, 170),
	"waldeck_hq": Vector2(295, 102),
	"prosthetics_factory": Vector2(295, 128),
	"montfort_hq": Vector2(455, 102),
	"food_plant": Vector2(580, 102),
	"water_plant": Vector2(580, 128),
	"clinic": Vector2(150, 330),
	"market_entrance": Vector2(60, 360),
}
## 中枢サーバーの印。記憶の断片「中枢サーバー」が戻ってから描く
const CORE := Vector2(30, 126)
## 橋のx座標。高台の通りから排水路をまたいで、下層街へ下りる
const BRIDGES := {
	"olsen_bridge": 107.0,
	"villard_bridge": 440.0,
	"hagen_bridge": 672.0,
}
## 道路。[幅の種類, 点の並び]。種類は main（表通り）・road（通り）・alley（路地）
const ROADS := [
	["road", [Vector2(0, 76), Vector2(780, 76)]],
	["main", [Vector2(0, 150), Vector2(780, 150)]],
	["road", [Vector2(107, 20), Vector2(107, 150)]],
	["road", [Vector2(210, 20), Vector2(210, 150)]],
	["road", [Vector2(360, 20), Vector2(360, 150)]],
	["road", [Vector2(672, 20), Vector2(672, 150)]],
	["main", [Vector2(440, 20), Vector2(440, 300)]],
	["main", [Vector2(672, 150), Vector2(672, 300)]],
	["road", [Vector2(107, 150), Vector2(107, 252)]],
	["main", [Vector2(300, 300), Vector2(780, 300)]],
	["alley", [Vector2(107, 252), Vector2(95, 310), Vector2(150, 330), Vector2(300, 300)]],
	["alley", [Vector2(95, 310), Vector2(40, 335), Vector2(60, 360)]],
	["alley", [Vector2(150, 330), Vector2(230, 355), Vector2(260, 390), Vector2(330, 440)]],
	["alley", [Vector2(470, 300), Vector2(450, 360), Vector2(420, 450)]],
	["alley", [Vector2(600, 300), Vector2(560, 380), Vector2(480, 460)]],
	["alley", [Vector2(230, 355), Vector2(330, 360), Vector2(450, 360)]],
	["alley", [Vector2(560, 380), Vector2(700, 400)]],
]
const WIDTHS := {"main": 9.0, "road": 6.0, "alley": 3.0}
const COLORS := {"main": ROAD_MAIN, "road": ROAD, "alley": ALLEY}
## 闇市場は地下にあるので、点線で囲む
const MARKET := Rect2(15, 382, 150, 76)
## 凡例。記号ごとの名前は map.legend.<id>
const LEGEND := Rect2(598, 336, 176, 108)
const LEGEND_ITEMS := ["road", "alley", "water", "cliff", "border", "underground", "poi"]


func _ready() -> void:
	custom_minimum_size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var o := ((size - SIZE) / 2).floor()
	_draw_ground(o)
	_draw_roads(o)
	_draw_bridges(o)
	_draw_borders(o)
	_draw_market(o)
	_draw_labels(o)
	_draw_legend(o)


func _draw_ground(o: Vector2) -> void:
	draw_rect(Rect2(o, SIZE), SLOPE)
	draw_rect(Rect2(o + Vector2(0, LOW_TOP), Vector2(SIZE.x, SIZE.y - LOW_TOP)), LOW_BLOCK)
	var high := PackedVector2Array([o, o + Vector2(SIZE.x, 0)])
	for i in range(CLIFF.size() - 1, -1, -1):
		high.append(o + CLIFF[i])
	draw_colored_polygon(high, HIGH_BLOCK)
	var water := Rect2(o + Vector2(0, CANAL_TOP), Vector2(SIZE.x, CANAL_BOTTOM - CANAL_TOP))
	draw_rect(water, WATER)
	draw_line(water.position, water.position + Vector2(SIZE.x, 0), SHORE, 1)
	draw_line(water.end - Vector2(SIZE.x, 0), water.end, SHORE, 1)
	# 崖の記号。縁の線から、低いほうへ向けて歯を並べる
	draw_polyline(_shift(PackedVector2Array(CLIFF), o), CLIFF_COLOR, 2)
	for i in CLIFF.size() - 1:
		var a: Vector2 = CLIFF[i]
		var b: Vector2 = CLIFF[i + 1]
		var steps := int(a.distance_to(b) / 5)
		for s in steps:
			var p := a.lerp(b, float(s) / steps)
			draw_line(o + p, o + p + Vector2(0, 7), CLIFF_COLOR, 1)


## 道路は、縁取りを先に全部描いてから中身を描く。交差するところで縁取りが道をまたがないようにするため
func _draw_roads(o: Vector2) -> void:
	for road in ROADS:
		draw_polyline(_shift(PackedVector2Array(road[1]), o), CASING, WIDTHS[road[0]] + 3)
	for kind in ["alley", "road", "main"]:
		for road in ROADS:
			if road[0] == kind:
				draw_polyline(_shift(PackedVector2Array(road[1]), o), COLORS[kind], WIDTHS[kind])


## 橋の記号。水と崖をまたぐところだけ、道の両側に線を引き、両端を外へ開く
func _draw_bridges(o: Vector2) -> void:
	var font := get_theme_default_font()
	for id in BRIDGES:
		var x: float = BRIDGES[id]
		var top := _cliff_y(x) - 4
		var bottom := LOW_TOP + 4
		var half := 8.0
		for side in [-1.0, 1.0]:
			var a := o + Vector2(x + side * half, top)
			var b := o + Vector2(x + side * half, bottom)
			draw_line(a, b, TEXT, 2)
			draw_line(a, a + Vector2(side * 5, -5), TEXT, 2)
			draw_line(b, b + Vector2(side * 5, 5), TEXT, 2)
		_text(font, o + Vector2(x + 14, CANAL_TOP - 6), tr("map." + id), 13, TEXT, HORIZONTAL_ALIGNMENT_LEFT)


func _draw_borders(o: Vector2) -> void:
	for b in BORDERS:
		_dashed(o + Vector2(b, 4), o + Vector2(b, _cliff_y(b)), Color(PINK, 0.8), 2)


func _draw_market(o: Vector2) -> void:
	var r := Rect2(o + MARKET.position, MARKET.size)
	draw_rect(r, Color(SHADOW, 0.6))
	_dashed_rect(r, CYAN)


func _draw_labels(o: Vector2) -> void:
	var font := get_theme_default_font()
	_text(font, o + Vector2(8, 18), tr("map.corp_district"), 14, PINK, HORIZONTAL_ALIGNMENT_LEFT)
	_text(font, o + Vector2(SIZE.x - 8, SIZE.y - 10), tr("map.lower_city"), 14, PINK, HORIZONTAL_ALIGNMENT_RIGHT)
	_text(font, o + Vector2(SIZE.x / 2, CANAL_BOTTOM - 6), tr("map.canal"), 12, SHORE.lightened(0.4))
	for id in POIS:
		_poi(font, o + POIS[id], tr("map.poi.%s" % id))
	if Game.fragments.has("core"):
		_poi(font, o + CORE, tr("map.core"))
	for id in LABELS:
		var at: Vector2 = o + LABELS[id]
		_text(font, at, tr("map." + id), 15, TEXT)
		if id in NOTED:
			_text(font, at + Vector2(0, 19), tr("map.%s.note" % id), 13, NOTE)


func _poi(font: Font, at: Vector2, text: String) -> void:
	draw_circle(at, 5, CASING)
	draw_circle(at, 4, CYAN)
	draw_circle(at, 1.5, CASING)
	_text(font, at + Vector2(9, 5), text, 13, NOTE, HORIZONTAL_ALIGNMENT_LEFT)


func _draw_legend(o: Vector2) -> void:
	var font := get_theme_default_font()
	var r := Rect2(o + LEGEND.position, LEGEND.size)
	draw_rect(r, Color(SHADOW, 0.92))
	draw_rect(r, Color(NOTE, 0.5), false, 1)
	for i in LEGEND_ITEMS.size():
		var id: String = LEGEND_ITEMS[i]
		var at := r.position + Vector2(10, 14 + i * 13.5)
		var end := at + Vector2(18, 0)
		match id:
			"road":
				draw_line(at, end, CASING, WIDTHS["main"] - 1)
				draw_line(at, end, ROAD_MAIN, WIDTHS["main"] - 4)
			"alley":
				draw_line(at, end, CASING, WIDTHS["alley"] + 2)
				draw_line(at, end, ALLEY, WIDTHS["alley"])
			"water":
				draw_rect(Rect2(at - Vector2(0, 4), Vector2(18, 8)), WATER)
			"cliff":
				draw_line(at - Vector2(0, 3), end - Vector2(0, 3), CLIFF_COLOR, 2)
				for x in range(1, 18, 4):
					draw_line(at + Vector2(x, -3), at + Vector2(x, 3), CLIFF_COLOR, 1)
			"border":
				_dashed(at, end, Color(PINK, 0.8), 2)
			"underground":
				_dashed_rect(Rect2(at - Vector2(0, 4), Vector2(18, 8)), CYAN)
			"poi":
				draw_circle(at + Vector2(9, 0), 4, CYAN)
				draw_circle(at + Vector2(9, 0), 1.5, CASING)
		_text(font, at + Vector2(26, 5), tr("map.legend.%s" % id), 12, NOTE, HORIZONTAL_ALIGNMENT_LEFT)


## 道路や記号の上でも読めるよう、文字は縁取りしてから描く
func _text(font: Font, at: Vector2, text: String, font_size: int, color: Color, align := HORIZONTAL_ALIGNMENT_CENTER) -> void:
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var pos := at
	if align == HORIZONTAL_ALIGNMENT_CENTER:
		pos.x -= width / 2
	elif align == HORIZONTAL_ALIGNMENT_RIGHT:
		pos.x -= width
	draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 6, SHADOW)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _dashed(a: Vector2, b: Vector2, color: Color, width := 1.0) -> void:
	draw_dashed_line(a, b, color, width, 5)


func _dashed_rect(r: Rect2, color: Color) -> void:
	var c := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.position]
	for i in 4:
		_dashed(c[i], c[i + 1], color)


func _cliff_y(x: float) -> float:
	for i in CLIFF.size() - 1:
		if x <= CLIFF[i + 1].x:
			return lerpf(CLIFF[i].y, CLIFF[i + 1].y, (x - CLIFF[i].x) / (CLIFF[i + 1].x - CLIFF[i].x))
	return CLIFF[-1].y


func _shift(points: PackedVector2Array, o: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in points:
		out.append(p + o)
	return out
