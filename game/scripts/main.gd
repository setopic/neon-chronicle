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
# 割合で増減させる効果の種類と、その文のキー。並びが画面に出る順になる（DOM-03）
const FX_KEYS := {"income": "ui.fx_income", "xp": "ui.fx_xp", "decay": "ui.fx_decay"}
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
var _body_effects_label: Label
var _effect_total_label: Label
var _request_label: Label
var _challenge_label: Label
var _reputation_label: Label
var _identity_button: Button
var _capacity_label: Label
var _calm_label: Label
var _request_buttons := {}
var _implant_buttons := {}
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
	_request_buttons.clear()
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
	# 仕事やインプラントが増えても画面の高さを超えないよう、中段だけをスクロールさせ、ログの高さを守る
	var middle_scroll := ScrollContainer.new()
	middle_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(middle_scroll)
	var middle := HBoxContainer.new()
	middle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle.add_theme_constant_override("separation", 10)
	middle_scroll.add_child(middle)
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
	header.custom_minimum_size = Vector2(0, 140)
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

	# ボタンは設定と読み物の2段に分ける。1段に並べると、英語では1280の幅に収まらない（ADR-0017）
	var tools := VBoxContainer.new()
	tools.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(tools)
	var settings := HBoxContainer.new()
	settings.alignment = BoxContainer.ALIGNMENT_END
	tools.add_child(settings)
	var language := OptionButton.new()
	for locale in Loc.languages():
		language.add_item(Loc.language_name(locale))
		language.set_item_metadata(language.item_count - 1, locale)
		if locale == Loc.current():
			language.select(language.item_count - 1)
	language.item_selected.connect(func(i): Loc.set_language(language.get_item_metadata(i)))
	settings.add_child(language)
	settings.add_child(_toggle(tr("ui.pause_on_event"), Loc.setting("pause_on_event", false),
		func(on): Loc.set_setting("pause_on_event", on)))
	settings.add_child(_toggle(tr("ui.music"), Sound.music_on(), Sound.set_music))
	settings.add_child(_toggle(tr("ui.sfx"), Sound.sfx_on(), Sound.set_sfx))
	var menu := HBoxContainer.new()
	menu.alignment = BoxContainer.ALIGNMENT_END
	tools.add_child(menu)
	menu.add_child(_button(tr("ui.fragments"), _show_fragments))
	menu.add_child(_button(tr("ui.profiles"), _show_profiles))
	menu.add_child(_button(tr("ui.licenses"), _show_licenses))
	# 押すとやり直しになるので、ほかのボタンから離して右端に置く
	var reset := _button(tr("ui.reset"), _confirm_reset)
	reset.add_theme_color_override("font_color", DANGER)
	menu.add_child(reset)
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
	# 体の種類の効果は転生の画面でしか見えなかったので、周の間も出す。合計は出どころを分けずに1行にする（ADR-0016）
	_body_effects_label = _label(Loc.t("ui.body_effects", {
		"body": GameData.name_of("bodies", Game.body), "quality": Game.body_quality,
		"effects": GameData.desc_of("bodies", Game.body)}) + "\n" + tr("body.%s.trait" % Game.body), DIM, 14)
	_body_effects_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_body_effects_label)
	_effect_total_label = _label("", DIM, 14)
	_effect_total_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_effect_total_label)
	# ジンの依頼は、その周の目標なので、周の状態を出す欄に置く。受けるまでは、並べた依頼ごとにボタンを出す（ADR-0034）
	_request_label = _label("", PINK, 15)
	_request_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_request_label)
	for id in Game.request_offers:
		var button := Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.text = Loc.t("ui.request_offer", {"goal": _request_goal(id),
			"n": roundi(GameData.requests[id].get("bonus", Game.REQUEST_BONUS) * 100.0)})
		button.pressed.connect(Game.accept_request.bind(id))
		box.add_child(button)
		_request_buttons[id] = button
	_challenge_label = _label("", PINK, 15)
	box.add_child(_challenge_label)
	# ひと息つける間は、危ないイベントが起きにくいことを出す（DOM-28）
	_calm_label = _label(tr("ui.calm"), CYAN, 14)
	box.add_child(_calm_label)
	# 評判は周をまたいで残るので、周の状態と並べて出す。0の勢力は出さない（DOM-22）
	_reputation_label = _label("", DIM, 14)
	_reputation_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_reputation_label)

	box.add_child(_section_title(tr("ui.implants")))
	_capacity_label = _label("", DIM, 14)
	box.add_child(_capacity_label)
	for id in GameData.order["implants"]:
		var button := Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.tooltip_text = GameData.desc_of("implants", id)
		button.pressed.connect(_press_implant.bind(id))
		box.add_child(button)
		_implant_buttons[id] = button
	# 偽の身元は闇市場で買う。インプラントと同じくクレジットで買うので、同じ欄に置く（DOM-24）
	_identity_button = Button.new()
	_identity_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_identity_button.pressed.connect(Game.buy_identity)
	box.add_child(_identity_button)

	return box.get_parent().get_parent()


func _build_log() -> Control:
	var box := _panel(tr("ui.log"))
	var panel: Control = box.get_parent().get_parent()
	panel.size_flags_horizontal = Control.SIZE_FILL
	panel.custom_minimum_size = Vector2(0, 180)
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
	# 画面が低いと「新しい体で目覚める」が下にはみ出すので、パネルごと縦にスクロールできるようにする
	var outer := ScrollContainer.new()
	outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dim.add_child(outer)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(center)

	var last: Dictionary = Game.chronicle.back() if not Game.chronicle.is_empty() else {}
	var box := _panel(tr("ui.rebirth_title_ending" if last.get("ending", "") != "" else "ui.rebirth_title"))
	var panel: Control = box.get_parent().get_parent()
	# 体の種類のボタンを横に4つ並べるため、ほかのパネルより広くする
	panel.custom_minimum_size = Vector2(880, 0)
	center.add_child(panel)

	var summary := _label(Game.format_entry({"key": "ui.rebirth_summary", "args": last}), Color.WHITE, 17)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(summary)
	if not last.is_empty():
		var story := _label(Game.story_of(last), CYAN, 17)
		story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(story)
		# エンディングのあとは物語が終わっているので、診療所の場面を出さない
		if last.get("ending", "") == "":
			var mio := _label(tr(Game.mio_line_key(last)), Color.WHITE, 16)
			mio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			box.add_child(mio)
	var gained := Loc.t("ui.points_gained", {"n": Game.last_points_gained})
	if Game.last_request_bonus > 0:
		gained += Loc.t("ui.request_bonus", {"n": Game.last_request_bonus})
	if Game.last_challenge_bonus > 0:
		gained += Loc.t("ui.challenge_bonus", {"n": Game.last_challenge_bonus})
	box.add_child(_label(gained, PINK, 20))
	box.add_child(_label(_fragment_progress(), DIM, 14))

	# 説明は見出しと同じ行に置き、画面の高さに収める
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 14)
	box.add_child(heading)
	heading.add_child(_section_title(tr("ui.upgrades")))
	var note := _label(tr("ui.upgrades_note"), DIM, 14)
	note.size_flags_vertical = Control.SIZE_SHRINK_END
	heading.add_child(note)
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
	scroll.custom_minimum_size = Vector2(0, 70)
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

	# 体の種類ごとに目覚めるボタンを置く。選ぶことと目覚めることを1回の操作にして、画面の高さを増やさない（ADR-0012）
	# 縛りは目覚める前に選ぶので、体の種類のボタンの上に置く。選んだものは目覚めるボタンを押したときに使う（DOM-21）
	if not GameData.order["challenges"].is_empty():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		box.add_child(row)
		row.add_child(_label(tr("ui.challenge_choice"), DIM, 14))
		var picker := OptionButton.new()
		picker.add_item(tr("ui.challenge_none"))
		for id in GameData.order["challenges"]:
			picker.add_item(Loc.t("ui.challenge_option", {"challenge": GameData.name_of("challenges", id),
				"desc": GameData.desc_of("challenges", id),
				"n": roundi(GameData.challenges[id].get("bonus", 0.0) * 100.0)}))
		picker.select(GameData.order["challenges"].find(Game.next_challenge) + 1)
		picker.item_selected.connect(_pick_challenge)
		row.add_child(picker)
	box.add_child(_label(tr("ui.body_choice"), DIM, 14))
	var bodies := GridContainer.new()
	bodies.columns = 4
	bodies.add_theme_constant_override("h_separation", 8)
	bodies.add_theme_constant_override("v_separation", 8)
	box.add_child(bodies)
	for id in GameData.order["bodies"]:
		var awaken := Button.new()
		# 体の質は、目覚める前に分かるようにボタンに出す（ADR-0032）
		var quality := Game.next_quality(id)
		var quality_text := Loc.t("ui.body_quality", {"quality": quality, "pct": roundi(Game.QUALITY_DECAY * quality * 100.0)}) \
			if Game.can_choose_body(id) else Loc.t("ui.body_locked", {"n": Game.format_number(Game.QUALITY_CREDITS * 2.0)})
		# 元の持ち主から残った特性も、目覚める前に分かるように添える（DOM-25）
		awaken.text = "%s\n%s\n%s\n%s" % [
			Loc.t("ui.awaken", {"body": GameData.name_of("bodies", id)}), quality_text,
			GameData.desc_of("bodies", id) + "  " + Loc.t("ui.capacity_short", {"max": int(GameData.bodies[id].get("capacity", 99))}),
			tr("body.%s.trait" % id)]
		awaken.disabled = not Game.can_choose_body(id)
		awaken.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		awaken.add_theme_color_override("font_color", CYAN)
		awaken.pressed.connect(Game.rebirth.bind(id))
		bodies.add_child(awaken)
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
	var text := _label(Game.event_desc(Game.pending_event), Color.WHITE, 17)
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
	_stats_label.text = "%s    %s    %s    %s" % [
		Loc.t("ui.life", {"n": Game.life_number}),
		Loc.t("ui.credits", {"n": Game.format_number(Game.credits)}),
		Loc.t("ui.income", {"n": "%.1f" % income}),
		# 体の欄に効果の行を足した分、記憶ポイントは周の状態と並べて上に出す（ADR-0016）
		Loc.t("ui.memory_points", {"n": Game.memory_points}),
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
	_effect_total_label.text = Loc.t("ui.effect_total", {"effects": _effects_text({
		"income": Game.effect("income"),
		"xp": Game.xp_mult() - 1.0,
		# 劣化の効果には下限があるので、実際に掛かっている割合を出す（DOM-03）
		"decay": maxf(0.2, 1.0 + Game.effect("decay")) - 1.0,
	}, true)})
	_request_label.text = _request_text()
	_request_label.visible = _request_label.text != ""
	_calm_label.visible = Game.alive and Game.is_calm()
	_reputation_label.text = _reputation_text()
	_reputation_label.visible = _reputation_label.text != ""
	_challenge_label.visible = Game.challenge != ""
	if Game.challenge != "":
		_challenge_label.text = Loc.t("ui.challenge", {"challenge": GameData.name_of("challenges", Game.challenge),
			"state": tr("ui.challenge_broken" if Game.challenge_broken else "ui.challenge_keeping")})
	for id in _request_buttons:
		_request_buttons[id].visible = Game.alive and Game.request == ""
	if is_instance_valid(_capacity_label):
		_capacity_label.text = Loc.t("ui.capacity", {"load": Game.implant_load(), "max": Game.capacity()})
	if is_instance_valid(_identity_button):
		_identity_button.text = tr("ui.identity_owned") if Game.identity else Loc.t("ui.identity_buy", {"n": Game.format_number(Game.IDENTITY_COST)})
		_identity_button.disabled = Game.identity or not Game.alive or Game.credits < Game.IDENTITY_COST
	for id in _implant_buttons:
		var button: Button = _implant_buttons[id]
		var data: Dictionary = GameData.implants[id]
		# ツールチップは指で触ると見られないので、効果をボタンの文に出す（ADR-0016）
		var parts := [GameData.name_of("implants", id), _effects_text(data.get("effects", {})),
			Loc.t("ui.implant_size", {"n": int(data.get("size", 1))})]
		if Game.implants.has(id):
			# 組み込んだインプラントは、押すと外せる。外しても払ったクレジットは戻らない（DOM-26）
			parts.append(tr("ui.implant_owned"))
			button.disabled = not Game.alive
		else:
			parts.append(Loc.t("ui.cost_credits", {"n": Game.format_number(Game.implant_cost(id))}))
			if not Game.implant_fits(id):
				parts.append(tr("ui.implant_no_room"))
			button.disabled = not Game.alive or Game.credits < Game.implant_cost(id) or not Game.implant_fits(id)
		if data.get("persistent", false):
			parts.append(tr("ui.persistent"))
		button.text = "    ".join(parts)
	for id in _upgrade_buttons:
		var button: Button = _upgrade_buttons[id]
		var level: int = Game.upgrades.get(id, 0)
		var cost := tr("ui.max") if Game.upgrade_maxed(id) else Loc.t("ui.cost_points", {"n": Game.upgrade_cost(id)})
		button.text = "%s  %s    %s    %s%s" % [
			GameData.name_of("upgrades", id), Loc.t("ui.level", {"level": level}), cost, GameData.desc_of("upgrades", id), _upgrade_group_text(id)]
		button.disabled = not Game.can_buy_upgrade(id)
	for choice in Game.event_choices():
		var button: Button = _choice_buttons.get(choice["id"])
		if button == null:
			continue
		var parts := [tr("event.%s.%s.name" % [Game.pending_event, choice["id"]])]
		if Game.choice_open(choice):
			parts.append(_choice_effects(choice))
			button.disabled = false
		else:
			parts.append(_requirement_text(choice.get("requires", {}), _reputation_items(choice.get("requires_reputation", {}))))
			button.disabled = true
		button.text = "    ".join(parts)
	if is_instance_valid(_rebirth_points_label):
		_rebirth_points_label.text = Loc.t("ui.memory_points", {"n": Game.memory_points})


func _refresh_log() -> void:
	if _log_label == null:
		return
	var lines := PackedStringArray()
	for entry in Game.logs.slice(-30):
		lines.append(Game.format_entry(entry))
	_log_label.text = "\n".join(lines)


func _job_requirement_text(job_id: String) -> String:
	var job: Dictionary = GameData.jobs[job_id]
	var items := PackedStringArray()
	if job.get("needs_all_fragments", false) and Game.next_fragment() != "":
		items.append(Loc.t("ui.requires_fragments", {
			"n": Game.fragments.size(), "max": GameData.order["fragments"].size(),
		}))
	if job.get("needs_identity", false) and not Game.identity:
		items.append(tr("ui.requires_identity"))
	return _requirement_text(job.get("requires", {}), items)


## 依頼の中身（「運び屋として2分働く」）
func _request_goal(id: String) -> String:
	var args := Game.request_args(id)
	return Loc.t("request.job" if args.has("job") else "request.skill", {
		"job": GameData.name_of("jobs", args.get("job", "")),
		"skill": GameData.name_of("skills", args.get("skill", "")),
		"min": args.get("min", 0), "level": args.get("level", 0),
	})


## 受けたジンの依頼の中身と進み具合。まだ受けていない周は空
func _request_text() -> String:
	if Game.request == "":
		return ""
	var args := Game.request_args(Game.request)
	var goal := _request_goal(Game.request)
	var progress := tr("ui.request_done")
	if not Game.request_done:
		var p := Game.request_progress()
		progress = "%s / %s" % ([Game.format_time(p[0]), Game.format_time(p[1])] if args.has("job") else [
			Loc.t("ui.level", {"level": int(p[0])}), Loc.t("ui.level", {"level": int(p[1])})])
	return Loc.t("ui.request", {"goal": goal, "progress": progress})


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


## 「必要」を1つだけ付けて、条件を「、」でつなぐ。items は先に並べる条件
func _requirement_text(requires: Dictionary, items := PackedStringArray()) -> String:
	for skill in requires:
		items.append(Loc.t("ui.skill_at", {"skill": GameData.name_of("skills", skill), "level": int(requires[skill])}))
	return Loc.t("ui.requires", {"items": tr("ui.list_sep").join(items)}) if not items.is_empty() else ""


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
	var changes: Dictionary = choice.get("reputation", {})
	for id in changes:
		parts.append(Loc.t("ui.effect_reputation", {"faction": GameData.name_of("factions", id), "n": _signed(changes[id])}))
	return " ".join(parts) if not parts.is_empty() else tr("ui.effect_none")


## 効果を「稼ぎ +50%、経験 +10%」の形にする。説明の文ではなくdataから作るので、MODで足したインプラントにも出る
func _effects_text(effects: Dictionary, keep_zero := false) -> String:
	var parts := []
	for key in FX_KEYS:
		var n: float = effects.get(key, 0.0)
		if keep_zero or not is_zero_approx(n):
			parts.append(Loc.t(FX_KEYS[key], {"n": _signed(round(n * 100.0))}))
	var start_level: float = effects.get("start_level", 0.0)
	if not is_zero_approx(start_level):
		parts.append(Loc.t("ui.fx_start_level", {"n": _signed(start_level)}))
	return tr("ui.list_sep").join(parts) if not parts.is_empty() else tr("ui.fx_none")


## 排他の組の相手を添える。相手を取ったあとは、取ったものの名前を出す（ADR-0033）
func _upgrade_group_text(id: String) -> String:
	var taken: String = Game.upgrade_taken_in_group(id)
	if taken != "":
		return "    " + Loc.t("ui.upgrade_taken", {"name": GameData.name_of("upgrades", taken)})
	var group: String = GameData.upgrades[id].get("group", "")
	if group == "":
		return ""
	var names := []
	for other in GameData.order["upgrades"]:
		if other != id and GameData.upgrades[other].get("group", "") == group:
			names.append(GameData.name_of("upgrades", other))
	return "    " + Loc.t("ui.upgrade_group", {"names": tr("ui.list_sep").join(names)})


## インプラントのボタン。組み込んでいなければ買い、組み込んでいれば外す
func _press_implant(id: String) -> void:
	if Game.implants.has(id):
		Game.remove_implant(id)
	else:
		Game.buy_implant(id)


## 評判の条件（{勢力のid: 値}）を、選ぶ条件の文に並べる項目にする
func _reputation_items(needs: Dictionary) -> PackedStringArray:
	var items := PackedStringArray()
	for id in needs:
		items.append(Loc.t("ui.reputation_at", {"faction": GameData.name_of("factions", id), "n": int(needs[id])}))
	return items


## 0でない評判を、勢力の並んだ順に1行にする。どれも0なら空
func _reputation_text() -> String:
	var items := PackedStringArray()
	for id in GameData.order["factions"]:
		var n: int = Game.reputation.get(id, 0)
		if n != 0:
			items.append(Loc.t("ui.reputation_item", {"faction": GameData.name_of("factions", id), "n": _signed(n)}))
	return Loc.t("ui.reputation", {"items": tr("ui.list_sep").join(items)}) if not items.is_empty() else ""


## 縛りを選ぶ欄の i 番目。0は縛りなし
func _pick_challenge(i: int) -> void:
	Game.next_challenge = GameData.order["challenges"][i - 1] if i > 0 else ""


func _signed(n: float) -> String:
	return ("+" if n >= 0.0 else "-") + Game.format_number(absf(n))


func _confirm_reset() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = tr("ui.reset")
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
	_show_text(tr("ui.fragments"), "\n".join(lines), Vector2(700, 420), 16)


## 街と人物の資料を読む。追記は、要る断片が戻るか出るイベントが起きるまで伏せる（DOM-14）
func _show_profiles() -> void:
	var lines := PackedStringArray()
	for id in GameData.order["profiles"]:
		var profile: Dictionary = GameData.profiles[id]
		if not Game.revealed(profile):
			continue
		var paragraphs := PackedStringArray([GameData.desc_of("profiles", id)])
		for note in profile.get("notes", []):
			if note is Dictionary and Game.revealed(note):
				paragraphs.append(tr("profile.%s.%s" % [id, note.get("id", "")]))
		lines.append(GameData.name_of("profiles", id))
		lines.append("\n".join(paragraphs))
		lines.append("")
	# 地図は資料と同じ画面に、タブで分けて置く。上のボタンをこれ以上増やすと、英語では1280の幅に収まらない（ADR-0022）
	var tabs := TabContainer.new()
	tabs.add_child(_text_body("\n".join(lines), CityMap.SIZE, 16))
	tabs.add_child(CityMap.new())
	tabs.set_tab_title(0, tr("ui.profile_text"))
	tabs.set_tab_title(1, tr("ui.map"))
	_show_dialog(tr("ui.profiles"), tabs)


func _show_licenses() -> void:
	_show_text(tr("ui.licenses"), license_text(), Vector2(900, 520), 14)


func _show_text(title: String, body: String, min_size: Vector2, font_size: int) -> void:
	_show_dialog(title, _text_body(body, min_size, font_size))


func _text_body(body: String, min_size: Vector2, font_size: int) -> RichTextLabel:
	var text := RichTextLabel.new()
	text.bbcode_enabled = false
	text.selection_enabled = true
	text.custom_minimum_size = min_size
	text.add_theme_font_size_override("normal_font_size", font_size)
	text.text = body
	return text


func _show_dialog(title: String, content: Control) -> void:
	var dialog := AcceptDialog.new()
	dialog.title = title
	dialog.ok_button_text = tr("ui.close")
	dialog.add_child(content)
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

func _button(text: String, pressed: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(pressed)
	return button


func _toggle(text: String, on: bool, changed: Callable) -> Button:
	var button := Button.new()
	button.toggle_mode = true
	button.text = text
	button.button_pressed = on
	button.toggled.connect(changed)
	return button


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
	# キーボードで選んでいるボタンの枠。標準の白い枠は、ほかの色から浮く
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.border_color = CYAN
	focus.set_border_width_all(1)
	focus.set_corner_radius_all(4)
	t.set_stylebox("focus", "Button", focus)
	t.set_stylebox("focus", "OptionButton", focus)

	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.1, 0.08, 0.16)
	bar_bg.set_corner_radius_all(3)
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = CYAN
	bar_fill.set_corner_radius_all(3)
	t.set_stylebox("background", "ProgressBar", bar_bg)
	t.set_stylebox("fill", "ProgressBar", bar_fill)

	# 記憶・街と人物・ライセンス・最初からの画面も、灰色の標準の見た目ではなくパネルと同じ色にする（ADR-0017）
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color(0.05, 0.03, 0.1)
	frame.border_color = CYAN
	frame.set_border_width_all(1)
	frame.set_corner_radius_all(6)
	frame.expand_margin_left = 8
	frame.expand_margin_right = 8
	frame.expand_margin_bottom = 8
	frame.expand_margin_top = 40
	t.set_stylebox("embedded_border", "Window", frame)
	var unfocused := frame.duplicate()
	unfocused.border_color = Color(CYAN, 0.35)
	t.set_stylebox("embedded_unfocused_border", "Window", unfocused)
	t.set_constant("title_height", "Window", 40)
	t.set_font_size("title_font_size", "Window", 18)
	t.set_color("title_color", "Window", CYAN)
	var dialog := StyleBoxFlat.new()
	dialog.bg_color = Color(0.05, 0.03, 0.1)
	dialog.set_content_margin_all(10)
	t.set_stylebox("panel", "AcceptDialog", dialog)
	# 街と人物の画面の、資料と地図のタブ（ADR-0022）
	var tab := StyleBoxFlat.new()
	tab.bg_color = Color(0.12, 0.08, 0.2)
	tab.border_color = Color(PINK, 0.5)
	tab.set_border_width_all(1)
	tab.set_corner_radius_all(4)
	tab.set_content_margin_all(8)
	var tab_selected := tab.duplicate()
	tab_selected.bg_color = Color(0.35, 0.08, 0.3)
	tab_selected.border_color = PINK
	t.set_stylebox("tab_unselected", "TabContainer", tab)
	t.set_stylebox("tab_hovered", "TabContainer", tab)
	t.set_stylebox("tab_selected", "TabContainer", tab_selected)
	var tab_panel := StyleBoxFlat.new()
	tab_panel.bg_color = Color(0.05, 0.03, 0.1)
	tab_panel.border_color = Color(CYAN, 0.35)
	tab_panel.set_border_width_all(1)
	tab_panel.set_content_margin_all(8)
	t.set_stylebox("panel", "TabContainer", tab_panel)
	var popup := StyleBoxFlat.new()
	popup.bg_color = Color(0.07, 0.05, 0.13)
	popup.border_color = Color(PINK, 0.5)
	popup.set_border_width_all(1)
	popup.set_content_margin_all(6)
	t.set_stylebox("panel", "PopupMenu", popup)
	return t
