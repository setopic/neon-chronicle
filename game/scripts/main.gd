extends Control

## メイン画面。UI はコードで組み立て、言語の切り替えや転生のたびに作り直す。
## 上：3Dの街と状態、左：仕事とスキル、右：体とインプラント、下：ログ。

const City := preload("res://scripts/city.gd")

const PINK := Color(1.0, 0.25, 0.75)
const CYAN := Color(0.2, 0.95, 1.0)
const DIM := Color(0.6, 0.6, 0.75)
const DANGER := Color(1.0, 0.3, 0.3)
const BG := Color(0.03, 0.02, 0.07)
const PANEL_BG := Color(0.07, 0.05, 0.13, 0.94)
const REFRESH_INTERVAL := 0.1

var _content: Control
var _refresh_timer := 0.0
# 毎回更新する部品
var _stats_label: Label
var _job_buttons := {}
var _skill_rows := {}  # id -> {label, bar}
var _durability_bar: ProgressBar
var _body_label: Label
var _implant_buttons := {}
var _points_label: Label
var _rebirth_points_label: Label
var _log_label: RichTextLabel
var _upgrade_buttons := {}


func _ready() -> void:
	theme = _make_theme()
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	Loc.language_changed.connect(_build)
	Game.life_ended.connect(_build)
	Game.life_started.connect(_build)
	Game.log_added.connect(_refresh_log)
	_build()


func _process(delta: float) -> void:
	_refresh_timer += delta
	if _refresh_timer >= REFRESH_INTERVAL:
		_refresh_timer = 0.0
		_refresh()


# --- 組み立て ---

func _build() -> void:
	if _content:
		_content.queue_free()
	_job_buttons.clear()
	_skill_rows.clear()
	_implant_buttons.clear()
	_upgrade_buttons.clear()

	_content = Control.new()
	_content.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_content)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	_content.add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	root.add_child(_build_header())
	var middle := HBoxContainer.new()
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle.add_theme_constant_override("separation", 10)
	root.add_child(middle)
	middle.add_child(_build_left())
	middle.add_child(_build_right())
	root.add_child(_build_log())

	if not Game.alive:
		_content.add_child(_build_rebirth())
	_refresh()
	_refresh_log()


func _build_header() -> Control:
	var header := Control.new()
	header.custom_minimum_size = Vector2(0, 200)
	var city := City.new()
	city.set_anchors_preset(Control.PRESET_FULL_RECT)
	header.add_child(city)

	var overlay := MarginContainer.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		overlay.add_theme_constant_override("margin_" + side, 14)
	header.add_child(overlay)
	var row := HBoxContainer.new()
	overlay.add_child(row)

	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(titles)
	titles.add_child(_label(tr("ui.title"), PINK, 36))
	_stats_label = _label("", CYAN, 20)
	titles.add_child(_stats_label)

	var tools := HBoxContainer.new()
	tools.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(tools)
	var language := OptionButton.new()
	for locale in Loc.languages():
		language.add_item(Loc.language_name(locale))
		language.set_item_metadata(language.item_count - 1, locale)
		if locale == Loc.current():
			language.select(language.item_count - 1)
	language.item_selected.connect(func(i): Loc.set_language(language.get_item_metadata(i)))
	tools.add_child(language)
	var reset := Button.new()
	reset.text = tr("ui.reset")
	reset.pressed.connect(_confirm_reset)
	tools.add_child(reset)
	return header


func _build_left() -> Control:
	var box := _panel(tr("ui.jobs"))
	for id in GameData.order["jobs"]:
		var button := Button.new()
		button.toggle_mode = true
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.tooltip_text = GameData.desc_of("jobs", id)
		button.pressed.connect(Game.set_job.bind(id))
		box.add_child(button)
		_job_buttons[id] = button

	box.add_child(_section_title(tr("ui.skills")))
	for id in GameData.order["skills"]:
		var row := HBoxContainer.new()
		var label := _label("", Color.WHITE, 16)
		label.custom_minimum_size = Vector2(170, 0)
		label.tooltip_text = GameData.desc_of("skills", id)
		label.mouse_filter = Control.MOUSE_FILTER_PASS
		row.add_child(label)
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.custom_minimum_size = Vector2(0, 10)
		row.add_child(bar)
		box.add_child(row)
		_skill_rows[id] = {"label": label, "bar": bar}
	return box.get_parent().get_parent()


func _build_right() -> Control:
	var box := _panel(tr("ui.body"))
	_durability_bar = ProgressBar.new()
	_durability_bar.max_value = Game.MAX_DURABILITY
	_durability_bar.show_percentage = false
	_durability_bar.custom_minimum_size = Vector2(0, 16)
	box.add_child(_durability_bar)
	_body_label = _label("", DIM, 15)
	box.add_child(_body_label)

	box.add_child(_section_title(tr("ui.implants")))
	for id in GameData.order["implants"]:
		var button := Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.tooltip_text = GameData.desc_of("implants", id)
		button.pressed.connect(Game.buy_implant.bind(id))
		box.add_child(button)
		_implant_buttons[id] = button

	_points_label = _label("", PINK, 16)
	box.add_child(_points_label)
	return box.get_parent().get_parent()


func _build_log() -> Control:
	var box := _panel(tr("ui.log"))
	var panel: Control = box.get_parent().get_parent()
	panel.size_flags_horizontal = Control.SIZE_FILL
	panel.custom_minimum_size = Vector2(0, 150)
	_log_label = RichTextLabel.new()
	_log_label.scroll_following = true
	_log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log_label.add_theme_font_size_override("normal_font_size", 15)
	box.add_child(_log_label)
	return panel


func _build_rebirth() -> Control:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.75)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)

	var box := _panel(tr("ui.rebirth_title"))
	var panel: Control = box.get_parent().get_parent()
	panel.custom_minimum_size = Vector2(620, 0)
	center.add_child(panel)

	var last: Dictionary = Game.chronicle.back() if not Game.chronicle.is_empty() else {}
	var summary := _label(Game.format_entry({"key": "ui.rebirth_summary", "args": last}), Color.WHITE, 17)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(summary)
	box.add_child(_label(Loc.t("ui.points_gained", {"n": Game.last_points_gained}), PINK, 20))

	box.add_child(_section_title(tr("ui.upgrades")))
	for id in GameData.order["upgrades"]:
		var button := Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.tooltip_text = GameData.desc_of("upgrades", id)
		button.pressed.connect(Game.buy_upgrade.bind(id))
		box.add_child(button)
		_upgrade_buttons[id] = button
	_rebirth_points_label = _label("", PINK, 16)
	box.add_child(_rebirth_points_label)

	box.add_child(_section_title(tr("ui.chronicle")))
	for entry in Game.chronicle.slice(-5):
		var line := _label(Game.format_entry({"key": "ui.chronicle_entry", "args": entry}), DIM, 14)
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(line)

	var awaken := Button.new()
	awaken.text = tr("ui.awaken")
	awaken.custom_minimum_size = Vector2(0, 44)
	awaken.add_theme_color_override("font_color", CYAN)
	awaken.pressed.connect(Game.rebirth)
	box.add_child(awaken)
	return dim


# --- 更新 ---

func _refresh() -> void:
	if _stats_label == null:
		return
	var income := Game.income_per_sec(Game.current_job)
	_stats_label.text = "%s    %s    %s" % [
		Loc.t("ui.life", {"n": Game.life_number}),
		Loc.t("ui.credits", {"n": Game.format_number(Game.credits)}),
		Loc.t("ui.income", {"n": "%.1f" % income}),
	]
	for id in _job_buttons:
		var button: Button = _job_buttons[id]
		var name := GameData.name_of("jobs", id)
		if Game.can_take_job(id):
			button.text = "%s    %s" % [name, Loc.t("ui.job_income", {"n": "%.1f" % Game.income_per_sec(id)})]
			button.disabled = not Game.alive
		else:
			button.text = "%s    %s" % [name, _requirement_text(id)]
			button.disabled = true
		button.set_pressed_no_signal(id == Game.current_job)
	for id in _skill_rows:
		var level: int = Game.skill_level.get(id, 0)
		_skill_rows[id]["label"].text = "%s  %s" % [GameData.name_of("skills", id), Loc.t("ui.level", {"level": level})]
		var bar: ProgressBar = _skill_rows[id]["bar"]
		bar.max_value = Game.xp_to_next(level)
		bar.value = Game.skill_xp.get(id, 0.0)
	_durability_bar.value = Game.durability
	_durability_bar.modulate = DANGER if Game.durability < Game.LOW_DURABILITY else Color.WHITE
	_body_label.text = "%s    %s    %s" % [
		Loc.t("ui.durability", {"now": int(ceil(Game.durability)), "max": int(Game.MAX_DURABILITY)}),
		Loc.t("ui.age", {"age": Game.format_time(Game.age)}),
		Loc.t("ui.decay", {"n": "%.2f" % Game.current_decay()}),
	]
	for id in _implant_buttons:
		var button: Button = _implant_buttons[id]
		var data: Dictionary = GameData.implants[id]
		var parts := [GameData.name_of("implants", id)]
		if Game.implants.has(id):
			parts.append(tr("ui.implant_owned"))
			button.disabled = true
		else:
			parts.append(Loc.t("ui.cost_credits", {"n": Game.format_number(data.get("cost", 0))}))
			button.disabled = not Game.alive or Game.credits < data.get("cost", 0)
		if data.get("persistent", false):
			parts.append(tr("ui.persistent"))
		button.text = "    ".join(parts)
	for id in _upgrade_buttons:
		var button: Button = _upgrade_buttons[id]
		var level: int = Game.upgrades.get(id, 0)
		var cost := tr("ui.max") if Game.upgrade_maxed(id) else Loc.t("ui.cost_points", {"n": Game.upgrade_cost(id)})
		button.text = "%s  %s    %s    %s" % [
			GameData.name_of("upgrades", id), Loc.t("ui.level", {"level": level}), cost, GameData.desc_of("upgrades", id)]
		button.disabled = Game.upgrade_maxed(id) or Game.memory_points < Game.upgrade_cost(id)
	_points_label.text = Loc.t("ui.memory_points", {"n": Game.memory_points})
	if is_instance_valid(_rebirth_points_label):
		_rebirth_points_label.text = _points_label.text


func _refresh_log() -> void:
	if _log_label == null:
		return
	var lines := PackedStringArray()
	for entry in Game.logs.slice(-30):
		lines.append(Game.format_entry(entry))
	_log_label.text = "\n".join(lines)


func _requirement_text(job_id: String) -> String:
	var parts := PackedStringArray()
	var requires: Dictionary = GameData.jobs[job_id].get("requires", {})
	for skill in requires:
		parts.append(Loc.t("ui.requires", {"skill": GameData.name_of("skills", skill), "level": int(requires[skill])}))
	return " ".join(parts)


func _confirm_reset() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.dialog_text = tr("ui.reset_confirm")
	dialog.ok_button_text = tr("ui.ok")
	dialog.cancel_button_text = tr("ui.cancel")
	dialog.confirmed.connect(Game.reset_game)
	dialog.visibility_changed.connect(func(): if not dialog.visible: dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered()


# --- 部品 ---

## 見出しつきのパネルを作り、中身を入れる VBox を返す（パネル本体は VBox の親の親）
func _panel(title: String) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)
	box.add_child(_section_title(title))
	return box


func _section_title(text: String) -> Label:
	return _label(text, CYAN, 18)


func _label(text: String, color: Color, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _make_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 16
	var panel := StyleBoxFlat.new()
	panel.bg_color = PANEL_BG
	panel.border_color = Color(CYAN, 0.35)
	panel.set_border_width_all(1)
	panel.set_corner_radius_all(6)
	t.set_stylebox("panel", "PanelContainer", panel)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.12, 0.08, 0.2)
	normal.border_color = Color(PINK, 0.5)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(4)
	normal.set_content_margin_all(8)
	var hover := normal.duplicate()
	hover.bg_color = Color(0.2, 0.1, 0.3)
	var pressed := normal.duplicate()
	pressed.bg_color = Color(0.35, 0.08, 0.3)
	pressed.border_color = PINK
	var disabled := normal.duplicate()
	disabled.bg_color = Color(0.08, 0.07, 0.11)
	disabled.border_color = Color(0.3, 0.3, 0.4, 0.4)
	for type in ["Button", "OptionButton"]:
		t.set_stylebox("normal", type, normal)
		t.set_stylebox("hover", type, hover)
		t.set_stylebox("pressed", type, pressed)
		t.set_stylebox("hover_pressed", type, pressed)
		t.set_stylebox("disabled", type, disabled)
	t.set_color("font_disabled_color", "Button", Color(0.5, 0.5, 0.6))

	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.1, 0.08, 0.16)
	bar_bg.set_corner_radius_all(3)
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = CYAN
	bar_fill.set_corner_radius_all(3)
	t.set_stylebox("background", "ProgressBar", bar_bg)
	t.set_stylebox("fill", "ProgressBar", bar_fill)
	return t
