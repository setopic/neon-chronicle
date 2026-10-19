extends Control

## メイン画面。UI はコードで組み立て、言語の切り替えや転生のたびに作り直す。
## 上：3Dの街と状態、左：仕事とスキル、右：体とインプラント、下：ログ。

const City := preload("res://scripts/city.gd")

# 色は見た目の土台（UiStyle）から取る。ADR-0052
const PINK := UiStyle.PINK
const CYAN := UiStyle.CYAN
const DIM := UiStyle.DIM
const DANGER := UiStyle.DANGER
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
var _pay_label: Label  # クレジットの横に、仕事の1回の報酬を短く出す。ADR-0051
var _rest_stats_label: Label
var _job_buttons := {}
var _job_bars := {}  # 仕事のid -> いまの1回の進み具合のバー
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
var _refund_buttons := {}
var _choice_buttons := {}  # 選択肢のid -> ボタン
var _story_closed_life := 0  # 戻った記憶の断片やエンディングの画面を閉じた周の番号。DOM-08


func _ready() -> void:
	theme = UiStyle.make_theme()
	var bg := ColorRect.new()
	bg.color = UiStyle.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	Loc.language_changed.connect(_build)
	Game.life_ended.connect(_build)
	Game.life_started.connect(_build)
	Game.event_changed.connect(_build)
	Game.log_added.connect(_refresh_log)
	Game.job_paid.connect(_show_pay)
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
	_job_bars.clear()
	_skill_rows.clear()
	_implant_buttons.clear()
	_upgrade_buttons.clear()
	_refund_buttons.clear()
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
	# インプラントの列は、ログの横まで下に伸ばす。仕事と体の状態の列の下にログを置き、ログの高さを守る
	var lower := HBoxContainer.new()
	lower.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lower.add_theme_constant_override("separation", 10)
	root.add_child(lower)
	var main_column := VBoxContainer.new()
	main_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_column.size_flags_stretch_ratio = 2.6
	main_column.add_theme_constant_override("separation", 10)
	lower.add_child(main_column)
	# 中身が増えても画面の高さを超えないよう、列ごとにスクロールさせる
	var middle_scroll := _scroll(main_column)
	var middle := HBoxContainer.new()
	middle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle.add_theme_constant_override("separation", 10)
	middle_scroll.add_child(middle)
	middle.add_child(_build_left())
	middle.add_child(_build_right())
	main_column.add_child(_build_log())
	var implants_scroll := _scroll(lower)
	implants_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	implants_scroll.add_child(_build_implants())

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


func _scroll(parent: Control) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)
	return scroll


func _build_header() -> Control:
	var header := Control.new()
	header.custom_minimum_size = Vector2(0, 140)
	var city := City.new()
	city.set_anchors_preset(Control.PRESET_FULL_RECT)
	header.add_child(city)
	var scanlines := UiStyle.Scanlines.new()
	scanlines.set_anchors_preset(Control.PRESET_FULL_RECT)
	header.add_child(scanlines)
	# 帯の下の縁に線を引き、街と下の欄を分ける
	var edge := ColorRect.new()
	edge.color = Color(UiStyle.CYAN, 0.6)
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	edge.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	edge.offset_top = -2
	header.add_child(edge)

	var overlay := MarginContainer.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		overlay.add_theme_constant_override("margin_" + side, 14)
	header.add_child(overlay)
	var row := HBoxContainer.new()
	overlay.add_child(row)

	# 題と状態は、街の上に重ねた板に載せて、街の明かりに紛れないようにする
	var plate := PanelContainer.new()
	plate.theme_type_variation = "HudPlate"
	plate.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	plate.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(plate)
	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", 0)
	plate.add_child(titles)
	var title := _label(tr("ui.title"), PINK, UiStyle.SIZE_TITLE)
	title.add_theme_font_override("font", UiStyle.title_font())
	titles.add_child(title)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 0)
	titles.add_child(stats)
	_stats_label = _label("", CYAN, UiStyle.SIZE_STAT)
	stats.add_child(_stats_label)
	_pay_label = _label("", PINK, UiStyle.SIZE_STAT)
	_pay_label.modulate.a = 0.0
	# 幅を先に取っておき、報酬が出るたびに後ろの稼ぎと記憶ポイントが動かないようにする
	_pay_label.custom_minimum_size = Vector2(80, 0)
	stats.add_child(_pay_label)
	_rest_stats_label = _label("", CYAN, UiStyle.SIZE_STAT)
	stats.add_child(_rest_stats_label)

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
	UiStyle.add_hover(language)
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
	# 仕事の列は高さに余りがあるので、狭くして折り返させ、体の状態の列に幅を回す
	box.get_parent().get_parent().size_flags_stretch_ratio = 0.6
	box.add_theme_constant_override("separation", 3)
	for id in GameData.order["jobs"]:
		var button := Button.new()
		button.toggle_mode = true
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		# 中段は3つの列に分けたので、必要な条件のような長い文は列の幅で折り返す
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.theme_type_variation = "CompactButton"
		button.tooltip_text = GameData.desc_of("jobs", id)
		button.pressed.connect(Game.set_job.bind(id))
		UiStyle.add_hover(button)
		box.add_child(button)
		_job_buttons[id] = button
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 6)
		box.add_child(bar)
		_job_bars[id] = bar

	box.add_child(_section_title(tr("ui.skills")))
	for id in GameData.order["skills"]:
		var row := HBoxContainer.new()
		var label := _label("", UiStyle.TEXT, UiStyle.SIZE_BODY)
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
	# 周の始まりには依頼のボタン・縛り・評判が並ぶので、行の間を詰めて列の高さに収める
	box.add_theme_constant_override("separation", 3)
	_durability_bar = ProgressBar.new()
	_durability_bar.max_value = Game.MAX_DURABILITY
	_durability_bar.show_percentage = false
	_durability_bar.custom_minimum_size = Vector2(0, 16)
	box.add_child(_durability_bar)
	_body_label = _label("", DIM, UiStyle.SIZE_TEXT)
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_body_label)
	# 体の種類の効果は転生の画面でしか見えなかったので、周の間も出す。合計は出どころを分けずに1行にする（ADR-0016）
	_body_effects_label = _label(Loc.t("ui.body_effects", {
		"body": GameData.name_of("bodies", Game.body), "quality": Game.body_quality,
		"effects": GameData.desc_of("bodies", Game.body)}) + "\n" + tr("body.%s.trait" % Game.body), DIM, UiStyle.SIZE_SMALL)
	_body_effects_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_body_effects_label)
	_effect_total_label = _label("", DIM, UiStyle.SIZE_SMALL)
	_effect_total_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_effect_total_label)
	# ジンの依頼は、その周の目標なので、周の状態を出す欄に置く。受けるまでは、並べた依頼ごとにボタンを出す（ADR-0034）
	_request_label = _label("", PINK, UiStyle.SIZE_TEXT)
	_request_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_request_label)
	for id in Game.request_offers:
		var button := Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.theme_type_variation = "CompactButton"
		button.text = Loc.t("ui.request_offer", {"goal": _request_goal(id),
			"n": roundi(GameData.requests[id].get("bonus", Game.REQUEST_BONUS) * 100.0)})
		button.pressed.connect(Game.accept_request.bind(id))
		UiStyle.add_hover(button)
		box.add_child(button)
		_request_buttons[id] = button
	_challenge_label = _label("", PINK, UiStyle.SIZE_TEXT)
	box.add_child(_challenge_label)
	# ひと息つける間は、危ないイベントが起きにくいことを出す（DOM-28）
	_calm_label = _label(tr("ui.calm"), CYAN, UiStyle.SIZE_SMALL)
	box.add_child(_calm_label)
	# 評判は周をまたいで残るので、周の状態と並べて出す。0の勢力は出さない（DOM-22）
	_reputation_label = _label("", DIM, UiStyle.SIZE_SMALL)
	_reputation_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_reputation_label)
	return box.get_parent().get_parent()


## インプラントと偽の身元。体の状態の欄に積むと中段が画面の高さを超えるので、3つ目の列に分ける
func _build_implants() -> Control:
	var box := _panel(tr("ui.implants"))
	box.get_parent().get_parent().size_flags_vertical = Control.SIZE_EXPAND_FILL
	_capacity_label = _label("", DIM, UiStyle.SIZE_SMALL)
	box.add_child(_capacity_label)
	for id in GameData.order["implants"]:
		var button := Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.tooltip_text = GameData.desc_of("implants", id)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.theme_type_variation = "CompactButton"
		button.pressed.connect(_press_implant.bind(id))
		UiStyle.add_hover(button)
		box.add_child(button)
		_implant_buttons[id] = button
	# 偽の身元は闇市場で買う。インプラントと同じくクレジットで買うので、同じ欄に置く（DOM-24）
	_identity_button = Button.new()
	_identity_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_identity_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_identity_button.theme_type_variation = "CompactButton"
	_identity_button.pressed.connect(Game.buy_identity)
	UiStyle.add_hover(_identity_button)
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
	_log_label.add_theme_font_size_override("normal_font_size", UiStyle.SIZE_TEXT)
	_log_label.add_theme_color_override("default_color", UiStyle.TEXT)
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
	# 1280x720に収めるため、画面の幅いっぱいに広げて左右の列に分ける。
	# 左は周の結果と永続強化、右は年代記と体の選択で、上下の段で左右の幅をそろえる
	panel.custom_minimum_size = Vector2(1240, 0)
	center.add_child(panel)
	var top := _rebirth_columns(box)
	var intro: VBoxContainer = top[0]
	var history: VBoxContainer = top[1]
	var bottom := _rebirth_columns(box)
	var left: VBoxContainer = bottom[0]
	var right: VBoxContainer = bottom[1]

	var summary := _label(Game.format_entry({"key": "ui.rebirth_summary", "args": last}), Color.WHITE, 17)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.add_child(summary)
	if not last.is_empty():
		var story := _label(Game.story_of(last), CYAN, 17)
		story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		intro.add_child(story)
		# エンディングのあとは物語が終わっているので、診療所の場面を出さない
		if last.get("ending", "") == "":
			var mio := _label(tr(Game.mio_line_key(last)), Color.WHITE, 16)
			mio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			intro.add_child(mio)
	var gained := Loc.t("ui.points_gained", {"n": Game.last_points_gained})
	if Game.last_request_bonus > 0:
		gained += Loc.t("ui.request_bonus", {"n": Game.last_request_bonus})
	if Game.last_challenge_bonus > 0:
		gained += Loc.t("ui.challenge_bonus", {"n": Game.last_challenge_bonus})
	intro.add_child(_label(gained, PINK, 20))
	intro.add_child(_label(_fragment_progress(), DIM, 14))

	# 説明は見出しと同じ行に置き、画面の高さに収める
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 14)
	left.add_child(heading)
	heading.add_child(_section_title(tr("ui.upgrades")))
	var note := _label(tr("ui.upgrades_note"), DIM, 14)
	note.size_flags_vertical = Control.SIZE_SHRINK_END
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.add_child(note)
	# 残りの記憶ポイントも見出しの行に置き、ボタンの列の下に行を足さない
	_rebirth_points_label = _label("", PINK, 16)
	_rebirth_points_label.size_flags_vertical = Control.SIZE_SHRINK_END
	heading.add_child(_rebirth_points_label)
	for id in GameData.order["upgrades"]:
		var button := Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.tooltip_text = GameData.desc_of("upgrades", id)
		# 列の幅に収まらない説明は折り返す。折り返さないと、最も長い行がパネルの幅を決める
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.theme_type_variation = "CompactButton"
		button.pressed.connect(Game.buy_upgrade.bind(id))
		left.add_child(button)
		_upgrade_buttons[id] = button
	# 排他の組の永続強化は、払った記憶ポイントを戻して選び直せる。レベルを持つものにだけ出す（DOM-31）
	for id in GameData.order["upgrades"]:
		if GameData.upgrades[id].get("group", "") == "":
			continue
		var refund := Button.new()
		refund.alignment = HORIZONTAL_ALIGNMENT_LEFT
		refund.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		refund.theme_type_variation = "CompactButton"
		refund.pressed.connect(Game.refund_upgrade.bind(id))
		left.add_child(refund)
		_refund_buttons[id] = refund

	history.add_child(_section_title(tr("ui.chronicle")))
	history.add_child(_label(Loc.t("ui.chronicle_bonus", {
		"n": Game.chronicle_deeds(), "pct": int(round(Game.deed_bonus() * 100.0)),
	}), PINK, 14))
	# 物語文は1件で2〜3行になるので、全件をスクロールで見せ、最新の記録を下に出しておく
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 70)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	history.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for entry in Game.chronicle:
		var story := _label(Loc.t("ui.chronicle_story", {"life": int(entry.get("life", 0)), "story": Game.story_of(entry)}), Color.WHITE, 14)
		story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		list.add_child(story)
		var stats := _label(Game.format_entry({"key": "ui.chronicle_stats", "args": entry}), DIM, 12)
		stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		list.add_child(stats)
	list.resized.connect(func(): scroll.scroll_vertical = int(list.size.y))

	# 体の種類ごとに目覚めるボタンを置く。選ぶことと目覚めることを1回の操作にして、画面の高さを増やさない（ADR-0012）
	# 縛りは目覚める前に選ぶので、体の種類のボタンの上に置く。選んだものは目覚めるボタンを押したときに使う（DOM-21）
	if not GameData.order["challenges"].is_empty():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		right.add_child(row)
		row.add_child(_label(tr("ui.challenge_choice"), DIM, 14))
		var picker := OptionButton.new()
		picker.add_item(tr("ui.challenge_none"))
		for id in GameData.order["challenges"]:
			picker.add_item(Loc.t("ui.challenge_option", {"challenge": GameData.name_of("challenges", id),
				"desc": GameData.desc_of("challenges", id),
				"n": roundi(GameData.challenges[id].get("bonus", 0.0) * 100.0)}))
		# 縛りの説明は長いので、いちばん長い項目の幅に合わせず、列の幅で切る
		picker.fit_to_longest_item = false
		picker.clip_text = true
		picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		picker.select(GameData.order["challenges"].find(Game.next_challenge) + 1)
		picker.item_selected.connect(_pick_challenge)
		row.add_child(picker)
	var body_choice := _label(tr("ui.body_choice"), DIM, 14)
	body_choice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(body_choice)
	var bodies := GridContainer.new()
	bodies.columns = 2
	bodies.add_theme_constant_override("h_separation", 8)
	bodies.add_theme_constant_override("v_separation", 8)
	right.add_child(bodies)
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
		awaken.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		awaken.add_theme_font_size_override("font_size", 14)
		awaken.disabled = not Game.can_choose_body(id)
		awaken.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		awaken.add_theme_color_override("font_color", CYAN)
		awaken.pressed.connect(Game.rebirth.bind(id))
		bodies.add_child(awaken)
	return dim


## 転生の画面の1段。左右の列を返す。永続強化の説明が1行に収まるよう、左の列を広く取る
func _rebirth_columns(box: VBoxContainer) -> Array:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	box.add_child(row)
	var columns := []
	for ratio in [1.4, 1.0]:
		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.size_flags_stretch_ratio = ratio
		column.add_theme_constant_override("separation", 4)
		row.add_child(column)
		columns.append(column)
	return columns


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
	_stats_label.text = "%s    %s" % [
		Loc.t("ui.life", {"n": Game.life_number}),
		Loc.t("ui.credits", {"n": Game.format_number(Game.credits)}),
	]
	_rest_stats_label.text = "    %s    %s" % [
		Loc.t("ui.income", {"n": "%.1f" % income}),
		# 体の欄に効果の行を足した分、記憶ポイントは周の状態と並べて上に出す（ADR-0016）
		Loc.t("ui.memory_points", {"n": Game.memory_points}),
	]
	for id in _job_buttons:
		var button: Button = _job_buttons[id]
		var name := GameData.name_of("jobs", id)
		if Game.can_take_job(id):
			button.text = "%s  %s" % [name, Loc.t("ui.job_income", {"n": "%.1f" % Game.income_per_sec(id)})]
			button.disabled = not Game.alive
		else:
			button.text = "%s  %s" % [name, _job_requirement_text(id)]
			button.disabled = true
		button.set_pressed_no_signal(id == Game.current_job)
		var bar: ProgressBar = _job_bars[id]
		bar.visible = id == Game.current_job
		bar.max_value = Game.job_length(id)
		bar.value = Game.job_progress
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
		button.text = "  ".join(parts)
	for id in _upgrade_buttons:
		var button: Button = _upgrade_buttons[id]
		var level: int = Game.upgrades.get(id, 0)
		var cost := tr("ui.max") if Game.upgrade_maxed(id) else Loc.t("ui.cost_points", {"n": Game.upgrade_cost(id)})
		button.text = "%s  %s  %s  %s%s" % [
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
	for id in _refund_buttons:
		var refund: Button = _refund_buttons[id]
		refund.visible = Game.upgrades.get(id, 0) > 0
		refund.text = Loc.t("ui.upgrade_refund", {"upgrade": GameData.name_of("upgrades", id), "n": Game.upgrade_spent(id)})
	if is_instance_valid(_rebirth_points_label):
		_rebirth_points_label.text = Loc.t("ui.memory_points", {"n": Game.memory_points})


func _refresh_log() -> void:
	if _log_label == null:
		return
	var lines := PackedStringArray()
	for entry in Game.logs.slice(-30):
		lines.append(Game.format_entry(entry))
	_log_label.text = "\n".join(lines)


## 仕事の1回の報酬を、クレジットの横に出して消す。1回ごとのログは残さない（ADR-0051）
func _show_pay(amount: float) -> void:
	if not is_instance_valid(_pay_label):
		return
	_pay_label.text = " +" + Game.format_number(amount)
	_pay_label.modulate.a = 1.0
	var tween := _pay_label.create_tween()
	tween.tween_interval(0.6)
	tween.tween_property(_pay_label, "modulate:a", 0.0, 0.9)


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
		return "  " + Loc.t("ui.upgrade_taken", {"name": GameData.name_of("upgrades", taken)})
	var group: String = GameData.upgrades[id].get("group", "")
	if group == "":
		return ""
	var names := []
	for other in GameData.order["upgrades"]:
		if other != id and GameData.upgrades[other].get("group", "") == group:
			names.append(GameData.name_of("upgrades", other))
	return "  " + Loc.t("ui.upgrade_group", {"names": tr("ui.list_sep").join(names)})


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
func _show_profiles(tab := 0) -> void:
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
	tabs.add_child(_chart_tab())
	tabs.set_tab_title(0, tr("ui.profile_text"))
	tabs.set_tab_title(1, tr("ui.map"))
	tabs.set_tab_title(2, tr("ui.chart"))
	tabs.current_tab = tab
	_show_dialog(tr("ui.profiles"), tabs)


## 分岐図のタブ。図の下に、選んだ段ごとに「ここから選び直す」ボタンを並べる（DOM-30、DOM-31）
func _chart_tab() -> Control:
	var box := VBoxContainer.new()
	# 分岐図は話とエンディングが増えると画面に収まらないので、スクロールの中に置く
	var chart_scroll := ScrollContainer.new()
	chart_scroll.custom_minimum_size = CityMap.SIZE - Vector2(0, 110)
	var chart := BranchChart.new()
	chart_scroll.add_child(chart)
	box.add_child(chart_scroll)
	# 最初のエンディングまでは選び直せないので、ボタンを出さずに案内だけを出す（DOM-31、ADR-0050）
	if not Game.can_rewind_story():
		box.add_child(_label(tr("ui.rewind_locked"), DIM, 13))
		return box
	box.add_child(_label(tr("ui.rewind_note"), DIM, 13))
	var flow := HFlowContainer.new()
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(CityMap.SIZE.x, 80)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(flow)
	box.add_child(scroll)
	for row in chart.rows():
		for id in row["stages"]:
			if not Game.character_choices.has(id):
				continue
			var button := Button.new()
			button.text = Loc.t("ui.rewind", {"line": row["label"], "event": GameData.name_of("events", id)})
			button.pressed.connect(_rewind.bind(Game.story_line(GameData.events[id]), id, box))
			flow.add_child(button)
	return box


## 話を選び直したら、分岐図を開き直して、消えた選択を図から外す
func _rewind(line: String, event_id: String, content: Control) -> void:
	Game.rewind_story(line, event_id)
	var dialog := content.get_parent()
	while dialog != null and not dialog is AcceptDialog:
		dialog = dialog.get_parent()
	if dialog != null:
		dialog.hide()
	_show_profiles(2)


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
	UiStyle.add_hover(button)
	return button


func _toggle(text: String, on: bool, changed: Callable) -> Button:
	var button := Button.new()
	button.toggle_mode = true
	button.text = text
	button.button_pressed = on
	button.toggled.connect(changed)
	UiStyle.add_hover(button)
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
	var heading := _section_title(title)
	# 見出しの下に細い線を引き、中身と分ける。行を足すと欄の高さが増えるので、見出しの枠の下の縁で引く
	var rule := StyleBoxFlat.new()
	rule.draw_center = false
	rule.border_color = UiStyle.LINE
	rule.border_width_bottom = 1
	rule.content_margin_bottom = 2
	heading.add_theme_stylebox_override("normal", rule)
	box.add_child(heading)
	return box


func _section_title(text: String) -> Label:
	return _label(text, CYAN, UiStyle.SIZE_HEADING)


func _label(text: String, color: Color, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)
	return label
