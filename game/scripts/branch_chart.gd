class_name BranchChart
extends Control

## 分岐図。話（人物・勢力・元の持ち主）の段とエンディングを、選択肢ごとの箱で並べる。DOM-30。
## 1行が1つの話で、段を左から右へ並べる。前の選択の条件と話の条件は、選択肢どうしを線で結ぶ。
## まだ選択肢を選んでいない段は、名前を伏せて「？？？」と描く。選んだ選択肢は色を変える。

const PINK := Color(1.0, 0.2, 0.7)
const CYAN := Color(0.2, 0.95, 1.0)
const TEXT := Color(0.92, 0.92, 1.0)
const DIM := Color(0.55, 0.57, 0.68)
const BOX := Color("232634")
const BOX_EDGE := Color("4c4f62")
const LINE := Color("666a80")
const LABEL_W := 150.0
const BOX_W := 210.0  # 英語でいちばん長い段の名前が、左右の余白を除いた幅に収まる幅
const GAP := 40.0
const TITLE_H := 24.0
const CHOICE_H := 20.0
const ROW_GAP := 18.0
const FONT_SIZE := 13
## エンディングの選択肢を持つイベント。最後の行に置く
const ENDING_EVENT := "core_server"

var _rows: Array = []  # [{label, stages: [event_id]}]
var _choice_pos := {}  # "イベント.選択肢" -> 箱の中の行の位置（線を引く端）


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rows = rows()
	var width := LABEL_W
	var height := 0.0
	for row in _rows:
		width = maxf(width, LABEL_W + row["stages"].size() * (BOX_W + GAP))
		height += _row_height(row) + ROW_GAP
	custom_minimum_size = Vector2(width, height)


## 図の行。話ごとに、data に並んだ順で段を集める。最後にエンディングの行を置く
func rows() -> Array:
	var lines := {}
	var order := []
	for id in GameData.order["events"]:
		var line: String = Game.story_line(GameData.events[id])
		if line == "":
			continue
		if not lines.has(line):
			lines[line] = []
			order.append(line)
		lines[line].append(id)
	var result := []
	for line in order:
		result.append({"label": line_label(line), "stages": lines[line]})
	if GameData.events.has(ENDING_EVENT):
		result.append({"label": tr("chart.endings"), "stages": [ENDING_EVENT]})
	return result


## 話の名前。人物は資料の名前、元の持ち主は体の種類の名前、それ以外は言語ファイルの chart.<話>
func line_label(line: String) -> String:
	if GameData.profiles.has(line):
		return GameData.name_of("profiles", line)
	if line.begins_with("owner_") and GameData.bodies.has(line.trim_prefix("owner_")):
		return Loc.t("chart.owner", {"body": GameData.name_of("bodies", line.trim_prefix("owner_"))})
	return tr("chart." + line)


## 段を見たか。人物や話の段は話の進み具合で、エンディングの行はたどり着いたかで決める
func seen(event_id: String) -> bool:
	if event_id == ENDING_EVENT:
		return not Game.endings_reached().is_empty()
	return Game.character_choices.has(event_id)


## その選択肢を選んだか。エンディングの行は、たどり着いたエンディングで決める
func chosen(event_id: String, choice: Dictionary) -> bool:
	if choice.has("ending"):
		return Game.endings_reached().has(choice["ending"])
	return Game.character_choices.get(event_id, "") == choice.get("id", "")


func _row_height(row: Dictionary) -> float:
	var most := 1
	for id in row["stages"]:
		most = maxi(most, GameData.events[id].get("choices", []).size())
	return TITLE_H + most * CHOICE_H + 8.0


func _draw() -> void:
	var font := get_theme_default_font()
	_choice_pos.clear()
	var y := 0.0
	var links := []  # [[条件の選択肢のキー, 開く選択肢の位置]]
	for row in _rows:
		var h := _row_height(row)
		# 英語の「Former owner of the Prototype body」は1行に収まらないので、名前の欄の幅で折り返す
		draw_multiline_string(font, Vector2(0, y + TITLE_H - 6), row["label"], HORIZONTAL_ALIGNMENT_LEFT, LABEL_W - 8, FONT_SIZE + 1, -1, PINK)
		var x := LABEL_W
		var stages: Array = row["stages"]
		for i in stages.size():
			var id: String = stages[i]
			var rect := Rect2(x, y, BOX_W, h - 8.0)
			draw_rect(rect, BOX)
			draw_rect(rect, BOX_EDGE, false, 1.0)
			var is_seen := seen(id)
			var title := GameData.name_of("events", id) if is_seen else tr("chart.unknown")
			draw_string(font, Vector2(x + 8, y + TITLE_H - 6), title, HORIZONTAL_ALIGNMENT_LEFT, BOX_W - 16, FONT_SIZE, TEXT if is_seen else DIM)
			var choices: Array = GameData.events[id].get("choices", [])
			for j in choices.size():
				var c: Dictionary = choices[j]
				var at := Vector2(x + 8, y + TITLE_H + (j + 1) * CHOICE_H - 6)
				var picked := chosen(id, c)
				var choice_text := tr("event.%s.%s.name" % [id, c.get("id", "")]) if is_seen or picked else tr("chart.unknown")
				if c.has("ending") and (is_seen or picked):
					choice_text = GameData.name_of("endings", c["ending"])
				var mark := "● " if picked else "○ "
				draw_string(font, at, mark + choice_text, HORIZONTAL_ALIGNMENT_LEFT, BOX_W - 16, FONT_SIZE - 1, CYAN if picked else (TEXT if is_seen else DIM))
				_choice_pos["%s.%s" % [id, c.get("id", "")]] = at + Vector2(-6, -4)
				for key in ["requires_choice", "requires_story"]:
					if c.get(key, "") != "":
						links.append([c[key], at + Vector2(-6, -4)])
			if i + 1 < stages.size():
				var mid := y + (h - 8.0) / 2
				draw_line(Vector2(x + BOX_W, mid), Vector2(x + BOX_W + GAP, mid), LINE, 2.0)
			x += BOX_W + GAP
		y += h + ROW_GAP
	# 条件で結ばれた選択肢どうしは、条件の側の右端から、開く側の左端へ線を引く
	for link in links:
		if _choice_pos.has(link[0]):
			var from: Vector2 = _choice_pos[link[0]] + Vector2(BOX_W - 4, 0)
			var to: Vector2 = link[1]
			draw_polyline([from, Vector2(from.x + GAP / 2, from.y), Vector2(from.x + GAP / 2, to.y), to], CYAN.darkened(0.3), 1.5)
