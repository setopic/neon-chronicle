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
# 使った素材の一覧とライセンスの全文。書き出しに含めるよう export_presets.cfg の include_filter に挙げてある。ADR-0002。
const CREDITS_PATH := "res://credits.txt"
const FONT_LICENSE_PATH := "res://fonts/OFL-NotoSansJP.txt"

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
var _choice_buttons := {}  # 選択肢のid -> ボタン
var _story_closed_life := 0  # 戻った記憶の断片やエンディングの画面を閉じた周の番号。DOM-08


func _ready() -> void:
	theme = _make_theme()
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	Loc.language_changed.connect(_build)
	Game.life_ended.connect(_build)
	Game.life_started.connect(_build)
	Game.event_changed.connect(_build)
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
	_choice_buttons.clear()

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
		var last: Dictionary = Game.chronicle.back() if not Game.chronicle.is_empty() else {}
		var has_story: bool = last.get("ending", "") != "" or not Game.last_fragments.is_empty()
		if has_story and _story_closed_life != Game.life_number:
			_content.add_child(_build_story(last.get("ending", "")))
		else:
			_content.add_child(_build_rebirth())
	elif Game.pending_event != "":
		_content.add_child(_build_event())
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
	var pause := Button.new()
	pause.toggle_mode = true
	pause.text = tr("ui.pause_on_event")
	pause.button_pressed = Loc.setting("pause_on_event", false)
	pause.toggled.connect(func(on): Loc.set_setting("pause_on_event", on))
	tools.add_child(pause)
	tools.add_child(_toggle(tr("ui.music"), Sound.music_on(), Sound.set_music))
	tools.add_child(_toggle(tr("ui.sfx"), Sound.sfx_on(), Sound.set_sfx))
	var reset := Button.new()
	reset.text = tr("ui.reset")
	reset.pressed.connect(_confirm_reset)
	tools.add_child(reset)
	var memories := Button.new()
	memories.text = tr("ui.fragments")
	memories.pressed.connect(_show_fragments)
	tools.add_child(memories)
	var licenses := Button.new()
	licenses.text = tr("ui.licenses")
	licenses.pressed.connect(_show_licenses)
	tools.add_child(licenses)
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

	var last: Dictionary = Game.chronicle.back() if not Game.chronicle.is_empty() else {}
	var box := _panel(tr("ui.rebirth_title_ending" if last.get("ending", "") != "" else "ui.rebirth_title"))
	var panel: Control = box.get_parent().get_parent()
	panel.custom_minimum_size = Vector2(620, 0)
	center.add_child(panel)

	var summary := _label(Game.format_entry({"key": "ui.rebirth_summary", "args": last}), Color.WHITE, 17)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(summary)
	if not last.is_empty():
		var story := _label(Game.story_of(last), CYAN, 17)
		story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(story)
	box.add_child(_label(Loc.t("ui.points_gained", {"n": Game.last_points_gained}), PINK, 20))
	box.add_child(_label(_fragment_progress(), DIM, 14))

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
	box.add_child(_label(Loc.t("ui.chronicle_bonus", {
		"n": Game.chronicle_deeds(), "pct": int(round(Game.deed_bonus() * 100.0)),
	}), PINK, 14))
	# 物語文は1件で2〜3行になるので、全件をスクロールで見せ、最新の記録を下に出しておく
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 140)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for entry in Game.chronicle:
		var story := _label(Loc.t("ui.chronicle_story", {"life": int(entry.get("life", 0)), "story": Game.story_of(entry)}), Color.WHITE, 14)
		story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		list.add_child(story)
		list.add_child(_label(Game.format_entry({"key": "ui.chronicle_stats", "args": entry}), DIM, 12))
	list.resized.connect(func(): scroll.scroll_vertical = int(list.size.y))

	var awaken := Button.new()
	awaken.text = tr("ui.awaken")
	awaken.custom_minimum_size = Vector2(0, 44)
	awaken.add_theme_color_override("font_color", CYAN)
	awaken.pressed.connect(Game.rebirth)
	box.add_child(awaken)
	return dim


## 周の終わりに戻った記憶の断片か、たどり着いたエンディングの文。閉じると転生の画面に移る。
## 断片がすべて戻ってから就く仕事でしかエンディングにならないので、両方が同じ周に出ることは無い
func _build_story(ending: String) -> Control:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.9)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)

	var box := _panel(GameData.name_of("endings", ending) if ending != "" else tr("ui.fragment_recalled"))
	var panel: Control = box.get_parent().get_parent()
	panel.custom_minimum_size = Vector2(700, 0)
	center.add_child(panel)
	if ending != "":
		var text := _label(GameData.desc_of("endings", ending), Color.WHITE, 18)
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(text)
		box.add_child(_label(Loc.t("ui.endings_reached", {
			"n": Game.endings_reached().size(), "max": GameData.order["endings"].size(),
		}), PINK, 15))
	for id in Game.last_fragments:
		box.add_child(_label(GameData.name_of("fragments", id), PINK, 20))
		var text := _label(GameData.desc_of("fragments", id), Color.WHITE, 18)
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(text)
	if ending == "":
		box.add_child(_label(_fragment_progress(), DIM, 15))
	var close := Button.new()
	close.text = tr("ui.story_continue")
	close.custom_minimum_size = Vector2(0, 44)
	close.add_theme_color_override("font_color", CYAN)
	close.pressed.connect(func():
		_story_closed_life = Game.life_number
		_build())
	box.add_child(close)
	return dim


## 待っているイベントと選択肢。時間を止めない設定では、選ぶ間も後ろで進行が続く（DOM-06）
func _build_event() -> Control:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)

	var box := _panel(GameData.name_of("events", Game.pending_event))
	var panel: Control = box.get_parent().get_parent()
	panel.custom_minimum_size = Vector2(620, 0)
	center.add_child(panel)
	var text := _label(GameData.desc_of("events", Game.pending_event), Color.WHITE, 17)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(text)
	for choice in Game.event_choices():
		var button := Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(0, 40)
		button.pressed.connect(Game.choose.bind(choice["id"]))
		box.add_child(button)
		_choice_buttons[choice["id"]] = button
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
			button.text = "%s    %s" % [name, _job_requirement_text(id)]
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
	for choice in Game.event_choices():
		var button: Button = _choice_buttons.get(choice["id"])
		if button == null:
			continue
		var parts := [tr("event.%s.%s.name" % [Game.pending_event, choice["id"]])]
		if Game.meets(choice.get("requires", {})):
			parts.append(_choice_effects(choice))
			button.disabled = false
		else:
			parts.append(_requirement_text(choice.get("requires", {})))
			button.disabled = true
		button.text = "    ".join(parts)
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


func _job_requirement_text(job_id: String) -> String:
	var job: Dictionary = GameData.jobs[job_id]
	var text := _requirement_text(job.get("requires", {}))
	if job.get("needs_all_fragments", false) and Game.next_fragment() != "":
		text = "%s %s" % [Loc.t("ui.requires_fragments", {
			"n": Game.fragments.size(), "max": GameData.order["fragments"].size(),
		}), text]
	return text


## 戻った記憶の断片の数と、次の断片の条件
func _fragment_progress() -> String:
	var count := Loc.t("ui.fragment_count", {"n": Game.fragments.size(), "max": GameData.order["fragments"].size()})
	var next := Game.next_fragment()
	if next == "":
		return "%s    %s" % [count, tr("ui.fragments_all")]
	var requires: Dictionary = GameData.fragments[next].get("requires", {})
	var parts := PackedStringArray()
	for skill in requires:
		parts.append(Loc.t("ui.skill_at", {"skill": GameData.name_of("skills", skill), "level": int(requires[skill])}))
	return "%s    %s" % [count, Loc.t("ui.fragment_next", {"requires": " ".join(parts)})]


func _requirement_text(requires: Dictionary) -> String:
	var parts := PackedStringArray()
	for skill in requires:
		parts.append(Loc.t("ui.requires", {"skill": GameData.name_of("skills", skill), "level": int(requires[skill])}))
	return " ".join(parts)


## 選んだときに増減する量。クレジットはいまの稼ぎから計算した額で見せる
func _choice_effects(choice: Dictionary) -> String:
	if choice.has("ending"):
		return tr("ui.effect_ending")
	var parts := PackedStringArray()
	var credits := Game.choice_credits(choice)
	if credits != 0.0:
		parts.append(Loc.t("ui.effect_credits", {"n": _signed(credits)}))
	var durability: float = choice.get("durability", 0.0)
	if durability != 0.0:
		parts.append(Loc.t("ui.effect_durability", {"n": _signed(durability)}))
	var xp: Dictionary = choice.get("xp", {})
	for skill in xp:
		parts.append(Loc.t("ui.effect_xp", {"skill": GameData.name_of("skills", skill), "n": _signed(xp[skill])}))
	return " ".join(parts) if not parts.is_empty() else tr("ui.effect_none")


func _signed(n: float) -> String:
	return ("+" if n >= 0.0 else "-") + Game.format_number(absf(n))


func _confirm_reset() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.dialog_text = tr("ui.reset_confirm")
	dialog.ok_button_text = tr("ui.ok")
	dialog.cancel_button_text = tr("ui.cancel")
	dialog.confirmed.connect(Game.reset_game)
	dialog.visibility_changed.connect(func(): if not dialog.visible: dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered()


## 戻った記憶の断片を、戻った順にすべて読む
func _show_fragments() -> void:
	var lines := PackedStringArray([_fragment_progress(), ""])
	for id in Game.fragments:
		if not GameData.fragments.has(id):
			continue
		lines.append(GameData.name_of("fragments", id))
		lines.append(GameData.desc_of("fragments", id))
		lines.append("")
	var dialog := AcceptDialog.new()
	dialog.title = tr("ui.fragments")
	dialog.ok_button_text = tr("ui.close")
	var text := RichTextLabel.new()
	text.bbcode_enabled = false
	text.custom_minimum_size = Vector2(700, 420)
	text.add_theme_font_size_override("normal_font_size", 16)
	text.text = "\n".join(lines)
	dialog.add_child(text)
	dialog.visibility_changed.connect(func(): if not dialog.visible: dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered()


func _show_licenses() -> void:
	var dialog := AcceptDialog.new()
	dialog.title = tr("ui.licenses")
	dialog.ok_button_text = tr("ui.close")
	var text := RichTextLabel.new()
	text.bbcode_enabled = false
	text.selection_enabled = true
	text.custom_minimum_size = Vector2(900, 520)
	text.add_theme_font_size_override("normal_font_size", 14)
	text.text = license_text()
	dialog.add_child(text)
	dialog.visibility_changed.connect(func(): if not dialog.visible: dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered()


## エンジンとその同梱物のライセンスは、手で写さずに Engine から取る。版を上げても食い違わない。
static func license_text() -> String:
	var parts := PackedStringArray()
	parts.append(FileAccess.get_file_as_string(CREDITS_PATH))
	parts.append("==== Noto Sans JP: SIL Open Font License 1.1 ====\n")
	parts.append(FileAccess.get_file_as_string(FONT_LICENSE_PATH))
	parts.append("==== Godot Engine: MIT License ====\n")
	parts.append(Engine.get_license_text())
	parts.append("==== Third-party components of Godot Engine ====\n")
	for component in Engine.get_copyright_info():
		if component["name"] == "Godot Engine":
			continue
		parts.append(component["name"])
		for part in component["parts"]:
			for line in part["copyright"]:
				parts.append("  Copyright (c) " + line)
			parts.append("  License: " + part["license"])
		parts.append("")
	var licenses := Engine.get_license_info()
	for name in licenses:
		parts.append("==== License: %s ====\n" % name)
		parts.append(licenses[name])
	return "\n".join(parts)


# --- 部品 ---

## 見出しつきのパネルを作り、中身を入れる VBox を返す（パネル本体は VBox の親の親）
func _toggle(text: String, on: bool, changed: Callable) -> Button:
	var button := Button.new()
	button.toggle_mode = true
	button.text = text
	button.button_pressed = on
	button.toggled.connect(changed)
	return button


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
