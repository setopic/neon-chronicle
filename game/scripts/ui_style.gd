class_name UiStyle

## 画面の見た目の土台。色・文字の大きさ・枠・動きを、ここだけで決める。ADR-0052。
## 暗い紺の地に細い線と白い本文を置き、角を斜めに切った枠と走査線を足す。
## 画面はこの値を使って組み立て、その場で色や大きさを決めない。

# 本文と同じフォント（project.godot の gui/theme/custom_font）
const FONT_PATH := "res://fonts/NotoSansJP-Medium-subset.ttf"

# --- 色 ---
const BG := Color(0.02, 0.03, 0.06)
const PANEL_BG := Color(0.035, 0.05, 0.09, 0.94)
const SURFACE := Color(0.06, 0.08, 0.13)  # ボタンなど、押せるものの地
const SURFACE_HOVER := Color(0.09, 0.15, 0.23)
const SURFACE_ON := Color(0.08, 0.22, 0.3)  # 選んでいるもの
const SURFACE_OFF := Color(0.04, 0.05, 0.08)  # 押せないもの
const LINE := Color(0.45, 0.8, 1.0, 0.28)  # 枠の細い線
const TEXT := Color(0.9, 0.94, 1.0)  # 本文
const DIM := Color(0.58, 0.64, 0.75)  # 補足
const CYAN := Color(0.3, 0.9, 1.0)  # 見出しと、選んでいるもの
const PINK := Color(1.0, 0.3, 0.7)  # 題と、入った額のような強調
const DANGER := Color(1.0, 0.32, 0.3)

# --- 文字の大きさ ---
const SIZE_TITLE := 36
const SIZE_STAT := 20
const SIZE_HEADING := 18
const SIZE_BODY := 16
const SIZE_SMALL := 14
const SIZE_TINY := 12

# --- 枠 ---
const CUT := 10  # パネルの左上と右下を斜めに切る長さ
const CUT_SMALL := 6  # ボタンの角を切る長さ

# --- 動き（秒） ---
const FADE := 0.18  # 画面の切り替え
const HOVER := 0.08  # ボタンに乗ったとき
const HOVER_GLOW := Color(1.25, 1.25, 1.3)


## 左上と右下を斜めに切った枠。corner_detail を1にすると、丸ではなく直線で角を切る
static func frame(bg: Color, border: Color, cut := CUT, width := 1) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(width)
	box.corner_detail = 1
	box.corner_radius_top_left = cut
	box.corner_radius_bottom_right = cut
	box.anti_aliasing = false
	return box


static func make_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = SIZE_BODY
	t.set_stylebox("panel", "PanelContainer", frame(PANEL_BG, LINE))
	# 上の帯の、街の上に重ねる状態の板。街が透けて見えるよう、地を薄くする
	t.set_type_variation("HudPlate", "PanelContainer")
	var plate := frame(Color(BG, 0.72), Color(CYAN, 0.45))
	plate.set_content_margin_all(10)
	plate.content_margin_left = 16
	plate.content_margin_right = 16
	t.set_stylebox("panel", "HudPlate", plate)

	var normal := frame(SURFACE, Color(CYAN, 0.25), CUT_SMALL)
	normal.set_content_margin_all(8)
	var hover := normal.duplicate()
	hover.bg_color = SURFACE_HOVER
	hover.border_color = Color(CYAN, 0.6)
	# 選んでいるものは、左の縁を太くして示す
	var pressed := normal.duplicate()
	pressed.bg_color = SURFACE_ON
	pressed.border_color = CYAN
	pressed.border_width_left = 3
	var disabled := normal.duplicate()
	disabled.bg_color = SURFACE_OFF
	disabled.border_color = Color(DIM, 0.2)
	for type in ["Button", "OptionButton"]:
		t.set_stylebox("normal", type, normal)
		t.set_stylebox("hover", type, hover)
		t.set_stylebox("pressed", type, pressed)
		t.set_stylebox("hover_pressed", type, pressed)
		t.set_stylebox("disabled", type, disabled)
		t.set_color("font_color", type, TEXT)
		t.set_color("font_hover_color", type, Color.WHITE)
		t.set_color("font_pressed_color", type, CYAN)
		t.set_color("font_hover_pressed_color", type, CYAN)
		t.set_color("font_focus_color", type, TEXT)
		t.set_color("font_disabled_color", type, Color(DIM, 0.75))
	# 転生の画面の永続強化と、仕事・ジンの依頼・インプラントのボタン。数が多いので、上下の余白と文字を詰めて1280x720に収める
	t.set_type_variation("CompactButton", "Button")
	t.set_font_size("font_size", "CompactButton", SIZE_SMALL)
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var compact: StyleBoxFlat = t.get_stylebox(state, "Button").duplicate()
		compact.content_margin_top = 4
		compact.content_margin_bottom = 4
		t.set_stylebox(state, "CompactButton", compact)
	# キーボードで選んでいるボタンの枠。標準の白い枠は、ほかの色から浮く
	var focus := frame(Color.TRANSPARENT, CYAN, CUT_SMALL)
	focus.draw_center = false
	t.set_stylebox("focus", "Button", focus)
	t.set_stylebox("focus", "OptionButton", focus)
	t.set_color("font_color", "Label", TEXT)

	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.08, 0.1, 0.16)
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = CYAN
	t.set_stylebox("background", "ProgressBar", bar_bg)
	t.set_stylebox("fill", "ProgressBar", bar_fill)

	# 記憶・街と人物・ライセンス・最初からの画面も、灰色の標準の見た目ではなくパネルと同じ色にする（ADR-0017）
	var window := frame(Color(0.03, 0.04, 0.08), CYAN)
	window.expand_margin_left = 8
	window.expand_margin_right = 8
	window.expand_margin_bottom = 8
	window.expand_margin_top = 40
	t.set_stylebox("embedded_border", "Window", window)
	var unfocused := window.duplicate()
	unfocused.border_color = LINE
	t.set_stylebox("embedded_unfocused_border", "Window", unfocused)
	t.set_constant("title_height", "Window", 40)
	t.set_font_size("title_font_size", "Window", SIZE_HEADING)
	t.set_color("title_color", "Window", CYAN)
	var dialog := StyleBoxFlat.new()
	dialog.bg_color = Color(0.03, 0.04, 0.08)
	dialog.set_content_margin_all(10)
	t.set_stylebox("panel", "AcceptDialog", dialog)
	# 街と人物の画面の、資料と地図のタブ（ADR-0022）
	var tab := frame(SURFACE, Color(CYAN, 0.25), CUT_SMALL)
	tab.set_content_margin_all(8)
	var tab_selected := tab.duplicate()
	tab_selected.bg_color = SURFACE_ON
	tab_selected.border_color = CYAN
	t.set_stylebox("tab_unselected", "TabContainer", tab)
	t.set_stylebox("tab_hovered", "TabContainer", tab)
	t.set_stylebox("tab_selected", "TabContainer", tab_selected)
	var tab_panel := StyleBoxFlat.new()
	tab_panel.bg_color = Color(0.03, 0.04, 0.08)
	tab_panel.border_color = LINE
	tab_panel.set_border_width_all(1)
	tab_panel.set_content_margin_all(8)
	t.set_stylebox("panel", "TabContainer", tab_panel)
	var popup := StyleBoxFlat.new()
	popup.bg_color = SURFACE
	popup.border_color = Color(CYAN, 0.5)
	popup.set_border_width_all(1)
	popup.set_content_margin_all(6)
	t.set_stylebox("panel", "PopupMenu", popup)
	return t


## 題の文字。字の間を少し空けて、ほかの文と分ける
static func title_font() -> FontVariation:
	var font := FontVariation.new()
	font.base_font = load(FONT_PATH)
	font.spacing_glyph = 2
	return font


## 画面を出すときに、透明から浮かび上がらせる
static func fade_in(item: CanvasItem) -> void:
	item.modulate.a = 0.0
	item.create_tween().tween_property(item, "modulate:a", 1.0, FADE)


## ボタンに乗ったときと、キーボードで選んだときに明るくする
static func add_hover(control: Control) -> void:
	var glow := func(on: bool):
		if control.is_inside_tree():
			control.create_tween().tween_property(control, "self_modulate", HOVER_GLOW if on else Color.WHITE, HOVER)
	control.mouse_entered.connect(glow.bind(true))
	control.mouse_exited.connect(glow.bind(false))
	control.focus_entered.connect(glow.bind(true))
	control.focus_exited.connect(glow.bind(false))


## 横に細い線を引き、走査線のように見せる。上に重ねても押す操作を妨げない
class Scanlines extends Control:
	const GAP := 3
	var color := Color(CYAN, 0.05)

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func _draw() -> void:
		var y := 0
		while y < size.y:
			draw_line(Vector2(0, y), Vector2(size.x, y), color)
			y += GAP
