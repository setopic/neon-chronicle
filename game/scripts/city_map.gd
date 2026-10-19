class_name CityMap
extends Control

## 街の地図。区画を箱、橋を小さな箱、行き来できるところを線で描く。DOM-15、DOM-16。
## 配置はDOM-15の図と同じにする。中枢サーバーは、記憶の断片「中枢サーバー」が戻るまで描かない。

const PINK := Color(1.0, 0.2, 0.7)
const CYAN := Color(0.2, 0.95, 1.0)
const TEXT := Color(0.9, 0.9, 1.0)
const NOTE := Color(0.65, 0.65, 0.8)
const SIZE := Vector2(780, 470)

## 区画を高台と低い土地でまとめる枠。名前は map.<id>
const GROUPS := {
	"corp_district": Rect2(10, 10, 760, 170),
	"lower_city": Rect2(10, 250, 760, 215),
}
## 区画。名前は map.<id>
const AREAS := {
	"yomi": Rect2(20, 40, 175, 130),
	"waldeck": Rect2(205, 40, 175, 130),
	"montfort": Rect2(395, 40, 175, 130),
	"lindholm": Rect2(585, 40, 175, 130),
	"back_alley": Rect2(20, 280, 250, 80),
	"stalls": Rect2(330, 280, 430, 80),
	"black_market": Rect2(20, 385, 150, 70),
	"deep": Rect2(200, 385, 270, 70),
}
## 添え書きを持つ区画。添え書きは map.<id>.note で、改行で行を分ける
const NOTED := ["yomi", "montfort", "lindholm", "back_alley", "black_market", "deep"]
const BRIDGES := {
	"north_bridge": Vector2(107, 215),
	"middle_bridge": Vector2(387, 215),
	"south_bridge": Vector2(672, 215),
}
const LINES := [
	[Vector2(107, 170), Vector2(107, 280)],
	[Vector2(292, 170), Vector2(387, 201)],
	[Vector2(482, 170), Vector2(387, 201)],
	[Vector2(387, 229), Vector2(387, 280)],
	[Vector2(672, 170), Vector2(672, 280)],
	[Vector2(270, 320), Vector2(330, 320)],
	[Vector2(95, 360), Vector2(95, 385)],
	[Vector2(235, 360), Vector2(235, 385)],
	[Vector2(400, 360), Vector2(400, 385)],
]


func _ready() -> void:
	custom_minimum_size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var font := get_theme_default_font()
	var origin := ((size - SIZE) / 2).floor()
	for line in LINES:
		draw_line(origin + line[0], origin + line[1], Color(CYAN, 0.6), 2)
	for id in GROUPS:
		var rect: Rect2 = GROUPS[id]
		rect.position += origin
		draw_rect(rect, Color(PINK, 0.5), false, 1)
		draw_string(font, rect.position + Vector2(8, 20), tr("map." + id), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, PINK)
	for id in AREAS:
		var rect: Rect2 = AREAS[id]
		rect.position += origin
		draw_rect(rect, Color(0.08, 0.05, 0.15))
		draw_rect(rect, CYAN, false, 1)
		var lines := PackedStringArray()
		if id in NOTED:
			lines = tr("map.%s.note" % id).split("\n")
		if id == "yomi" and Game.fragments.has("core"):
			lines.append(tr("map.core"))
		draw_string(font, rect.position + Vector2(0, 24), tr("map." + id), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 15, TEXT)
		for i in lines.size():
			draw_string(font, rect.position + Vector2(0, 46 + i * 19), lines[i], HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 13, NOTE)
	for id in BRIDGES:
		var rect := Rect2(origin + BRIDGES[id] - Vector2(50, 14), Vector2(100, 28))
		draw_rect(rect, Color(0.08, 0.05, 0.15))
		draw_rect(rect, PINK, false, 1)
		draw_string(font, rect.position + Vector2(0, 20), tr("map." + id), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 13, TEXT)
