extends Node

## ゲームの進行状態。DOM-02〜DOM-08。1人生の状態と、転生しても残る状態を持ち、セーブとロードも行う。

signal life_ended
signal life_started
signal log_added
signal event_changed

var save_path := "user://save.json"  # 通しの検査（ci/playthrough.gd）が別のファイルに差し替える
const SAVE_VERSION := 1
const SAVE_INTERVAL := 5.0
const STEP := 0.25  # シミュレーションの刻み（秒）
const MAX_CATCHUP := 60.0  # 1フレームで進める最大秒数（タブが裏にあった時用）
const BASE_DECAY := 0.4  # 体の劣化（耐久/秒）。何もしなくても約250秒で寿命
const MAX_DURABILITY := 100.0
const LOW_DURABILITY := 25.0
const MAX_LOGS := 50
const EVENT_INTERVAL := 90.0  # 危険度1の仕事で、イベントが起きる平均の間隔（秒）。DOM-06
const DEED_XP := 0.02  # クロニクルに残った選択1種類あたりの経験の増え方。DOM-07
## ログやクロニクルの引数のうち、id から表示名に変える項目
const NAME_ARGS := {
	"job": "jobs", "skill": "skills", "implant": "implants", "upgrade": "upgrades", "event": "events",
	"fragment": "fragments", "ending": "endings",
}

# --- 1人生の状態 ---
var credits := 0.0
var life_earned := 0.0
var durability := MAX_DURABILITY
var age := 0.0
var current_job := ""
var skill_xp := {}
var skill_level := {}
var implants: Array = []
var job_time := {}
var alive := true
var pending_event := ""  # 待っているイベントのid。無いときは空
var last_deed := ""  # 最後に選んだ選択肢（"<イベント>.<選択肢>"）。周を終わらせた選択は入れない

# --- 転生しても残る状態 ---
var life_number := 1
var memory_points := 0
var last_points_gained := 0
var upgrades := {}
var chronicle: Array = []  # 終わった周の記録 [{life, job, age, earned, points, deed, end, ending}]
var fragments: Array = []  # 戻った記憶の断片のid。DOM-08
var last_fragments: Array = []  # 直前の周の終わりに戻った記憶の断片のid
var logs: Array = []  # [{key, args}]。言語を切り替えても訳し直せるようキーで持つ

var _pending := 0.0
var _save_timer := 0.0


func _ready() -> void:
	if not load_game():
		_start_life()


func _process(delta: float) -> void:
	_pending = minf(_pending + delta, MAX_CATCHUP)
	while _pending >= STEP:
		_pending -= STEP
		_tick(STEP)
	_save_timer += delta
	if _save_timer >= SAVE_INTERVAL:
		_save_timer = 0.0
		save_game()


func _tick(dt: float) -> void:
	if not alive:
		return
	if pending_event != "" and Loc.setting("pause_on_event", false):
		return
	age += dt
	var danger := 1.0
	if GameData.jobs.has(current_job):
		var job: Dictionary = GameData.jobs[current_job]
		var income := income_per_sec(current_job) * dt
		credits += income
		life_earned += income
		job_time[current_job] = job_time.get(current_job, 0.0) + dt
		var xp: Dictionary = job.get("xp", {})
		for skill in xp:
			_add_xp(skill, xp[skill] * xp_mult() * dt)
		danger = job.get("danger", 1.0)
		if pending_event == "" and randf() < danger * dt / EVENT_INTERVAL:
			_start_event()
	var before := durability
	durability -= decay_per_sec(danger) * dt
	if before > LOW_DURABILITY and durability <= LOW_DURABILITY:
		_log("log.durability_low")
	if durability <= 0.0:
		durability = 0.0
		_end_life()


# --- 効果の計算 ---

## インプラント・永続強化・スキルの効果を合計する（"income", "xp", "decay", "start_level"）
func effect(key: String) -> float:
	var total := 0.0
	for id in implants:
		total += GameData.implants.get(id, {}).get("effects", {}).get(key, 0.0)
	for id in upgrades:
		total += upgrades[id] * GameData.upgrades.get(id, {}).get("effects_per_level", {}).get(key, 0.0)
	for id in skill_level:
		total += skill_level[id] * GameData.skills.get(id, {}).get("effects_per_level", {}).get(key, 0.0)
	return total


func xp_mult() -> float:
	return 1.0 + effect("xp") + deed_bonus()


func decay_per_sec(danger: float) -> float:
	return BASE_DECAY * danger * maxf(0.2, 1.0 + effect("decay"))


func current_decay() -> float:
	return decay_per_sec(GameData.jobs.get(current_job, {}).get("danger", 1.0))


func income_per_sec(job_id: String) -> float:
	var job: Dictionary = GameData.jobs.get(job_id, {})
	if job.is_empty():
		return 0.0
	var level: int = skill_level.get(job.get("skill", ""), 0)
	return job.get("income", 0.0) * (1.0 + job.get("skill_bonus", 0.1) * level) * (1.0 + effect("income"))


# --- 仕事とスキル ---

func can_take_job(job_id: String) -> bool:
	var job: Dictionary = GameData.jobs.get(job_id, {})
	if job.get("needs_all_fragments", false) and next_fragment() != "":
		return false
	return meets(job.get("requires", {}))


## スキルのレベルが、就く条件や選ぶ条件（{スキルのid: レベル}）を満たしているか
func meets(requires: Dictionary) -> bool:
	for skill in requires:
		if skill_level.get(skill, 0) < requires[skill]:
			return false
	return true


func set_job(job_id: String) -> void:
	if not alive or pending_event != "" or job_id == current_job or not can_take_job(job_id):
		return
	current_job = job_id
	_log("log.job", {"job": job_id})


func xp_to_next(level: int) -> float:
	return 10.0 * pow(1.25, level)


func _add_xp(skill: String, amount: float) -> void:
	if not GameData.skills.has(skill):
		return
	skill_xp[skill] = skill_xp.get(skill, 0.0) + amount
	var level: int = skill_level.get(skill, 0)
	while skill_xp[skill] >= xp_to_next(level):
		skill_xp[skill] -= xp_to_next(level)
		level += 1
		skill_level[skill] = level
		_log("log.skill_up", {"skill": skill, "level": level})


# --- インプラントと永続強化 ---

func buy_implant(id: String) -> void:
	var cost: float = GameData.implants.get(id, {}).get("cost", 0.0)
	if not alive or implants.has(id) or credits < cost:
		return
	credits -= cost
	implants.append(id)
	_log("log.implant", {"implant": id})


func upgrade_cost(id: String) -> int:
	var data: Dictionary = GameData.upgrades.get(id, {})
	return int(data.get("cost", 1) * pow(data.get("cost_growth", 2.0), upgrades.get(id, 0)))


func upgrade_maxed(id: String) -> bool:
	return upgrades.get(id, 0) >= GameData.upgrades.get(id, {}).get("max_level", 99)


func buy_upgrade(id: String) -> void:
	if upgrade_maxed(id) or memory_points < upgrade_cost(id):
		return
	memory_points -= upgrade_cost(id)
	upgrades[id] = upgrades.get(id, 0) + 1
	_log("log.upgrade", {"upgrade": id, "level": upgrades[id]})


# --- イベント ---

func _start_event() -> void:
	var candidates := []
	for id in GameData.order["events"]:
		if GameData.events[id].get("jobs", []).has(current_job):
			candidates.append(id)
	if candidates.is_empty():
		return
	pending_event = candidates.pick_random()
	_log("log.event", {"event": pending_event})
	event_changed.emit()


func event_choices() -> Array:
	return GameData.events.get(pending_event, {}).get("choices", [])


## 選択肢のクレジットの増減。いまの稼ぎの何秒分かで書いてある
func choice_credits(choice: Dictionary) -> float:
	return income_per_sec(current_job) * choice.get("credits", 0.0)


func choose(choice_id: String) -> void:
	if not alive:
		return
	var choice := {}
	for c in event_choices():
		if c.get("id") == choice_id:
			choice = c
	if choice.is_empty() or not meets(choice.get("requires", {})):
		return
	var event_id := pending_event
	pending_event = ""
	_log("event.%s.%s.result" % [event_id, choice_id])
	# エンディングの選択肢は、ほかの結果を持たず、その場で周を終える（DOM-08）
	if choice.has("ending"):
		event_changed.emit()
		_end_life("", choice["ending"])
		return
	var deed := "%s.%s" % [event_id, choice_id]
	var gain := choice_credits(choice)
	credits = maxf(0.0, credits + gain)
	if gain > 0.0:
		life_earned += gain
	var xp: Dictionary = choice.get("xp", {})
	for skill in xp:
		_add_xp(skill, maxf(0.0, xp[skill]))
	var before := durability
	durability = clampf(durability + choice.get("durability", 0.0), 0.0, MAX_DURABILITY)
	if before > LOW_DURABILITY and durability <= LOW_DURABILITY and durability > 0.0:
		_log("log.durability_low")
	event_changed.emit()
	if durability <= 0.0:
		_end_life(event_id)
	else:
		last_deed = deed


# --- 人生の終わりと転生 ---

func main_job() -> String:
	var best := ""
	for id in job_time:
		if best == "" or job_time[id] > job_time[best]:
			best = id
	return best


func points_for_life() -> int:
	var levels := 0
	for skill in skill_level:
		levels += skill_level[skill]
	return maxi(1, int(sqrt(life_earned / 50.0)) + levels / 3)


## fatal_event は周を終わらせたイベントのid、ending はたどり着いたエンディングのid。どちらも無ければ空
func _end_life(fatal_event := "", ending := "") -> void:
	alive = false
	pending_event = ""
	last_points_gained = points_for_life()
	memory_points += last_points_gained
	chronicle.append({
		"life": life_number, "job": main_job(), "age": age,
		"earned": life_earned, "points": last_points_gained,
		"deed": last_deed, "end": fatal_event, "ending": ending,
	})
	_log("log.ending" if ending != "" else "log.death", {"points": last_points_gained})
	_recall_fragments()
	save_game()
	life_ended.emit()


func rebirth() -> void:
	if alive:
		return
	life_number += 1
	_start_life()
	save_game()


func _start_life() -> void:
	implants = implants.filter(func(id): return GameData.implants.get(id, {}).get("persistent", false))
	credits = 0.0
	life_earned = 0.0
	durability = MAX_DURABILITY
	age = 0.0
	current_job = ""
	pending_event = ""
	last_deed = ""
	job_time = {}
	skill_level = {}
	skill_xp = {}
	alive = true
	var start_level := int(effect("start_level"))
	for skill in GameData.skills:
		skill_level[skill] = start_level
		skill_xp[skill] = 0.0
	_log("log.awaken", {"life": life_number})
	life_started.emit()


# --- クロニクル ---

## 記録の物語文。仕事・最後に選んだ選択肢・倒れた理由から組み立てる（DOM-07）。
## 記録には id だけを持たせ、文はいまの言語で毎回組み立てる。#6 より前の記録は deed と end を持たない
func story_of(entry: Dictionary) -> String:
	var job: String = entry.get("job", "")
	var job_part := tr("job.%s.chronicle" % job) if job != "" else tr("chronicle.no_job")
	var end: String = entry.get("end", "")
	var end_part := Loc.t("chronicle.end_event", {"event": GameData.name_of("events", end)}) if end != "" else tr("chronicle.end_decay")
	var ending: String = entry.get("ending", "")
	if ending != "":
		end_part = tr("ending.%s.chronicle" % ending)
	var deed: String = entry.get("deed", "")
	if deed == "":
		return Loc.t("chronicle.story_short", {"job": job_part, "end": end_part})
	return Loc.t("chronicle.story", {"job": job_part, "deed": tr("event.%s.chronicle" % deed), "end": end_part})


## クロニクルに残った選択肢の種類。いまのデータに無いもの（外したMODの選択肢）は数えない
func chronicle_deeds() -> int:
	var seen := {}
	for entry in chronicle:
		var deed: String = entry.get("deed", "")
		var parts := deed.split(".")
		if parts.size() != 2:
			continue
		for c in GameData.events.get(parts[0], {}).get("choices", []):
			if c.get("id") == parts[1]:
				seen[deed] = true
	return seen.size()


func deed_bonus() -> float:
	return DEED_XP * chronicle_deeds()


# --- 記憶の断片とエンディング ---

## 次に戻る記憶の断片のid。すべて戻っていれば空。断片は data に並んだ順に戻る
func next_fragment() -> String:
	for id in GameData.order["fragments"]:
		if not fragments.has(id):
			return id
	return ""


## 周の終わりのスキルのレベルで、次の断片の条件を満たしていれば戻す。続けて満たしていれば、いくつでも戻る
func _recall_fragments() -> void:
	last_fragments = []
	var id := next_fragment()
	while id != "" and meets(GameData.fragments[id].get("requires", {})):
		fragments.append(id)
		last_fragments.append(id)
		_log("log.fragment", {"fragment": id})
		id = next_fragment()


## たどり着いたエンディングのid（クロニクルに残った順、重複なし）
func endings_reached() -> Array:
	var seen := []
	for entry in chronicle:
		var ending: String = entry.get("ending", "")
		if ending != "" and not seen.has(ending):
			seen.append(ending)
	return seen


# --- ログ ---

func _log(key: String, args := {}) -> void:
	logs.append({"key": key, "args": args})
	if logs.size() > MAX_LOGS:
		logs.pop_front()
	log_added.emit()


## {key, args} を今の言語の文にする。id は表示名に、数値は読みやすい形に変える
func format_entry(entry: Dictionary) -> String:
	var args: Dictionary = entry.get("args", {}).duplicate()
	for k in args:
		if NAME_ARGS.has(k):
			args[k] = GameData.name_of(NAME_ARGS[k], args[k]) if args[k] != "" else tr("ui.no_job")
		elif k == "age":
			args[k] = format_time(args[k])
		elif args[k] is float:
			args[k] = format_number(args[k])
	return tr(entry["key"]).format(args)


static func format_number(n: float) -> String:
	const UNITS := ["", "K", "M", "B", "T"]
	var i := 0
	while absf(n) >= 1000.0 and i < UNITS.size() - 1:
		n /= 1000.0
		i += 1
	return str(int(n)) if i == 0 else "%.1f%s" % [n, UNITS[i]]


static func format_time(seconds: float) -> String:
	var s := int(seconds)
	return "%d:%02d" % [s / 60, s % 60]


# --- セーブとロード ---

func save_game() -> void:
	var data := {
		"version": SAVE_VERSION,
		"credits": credits, "life_earned": life_earned, "durability": durability, "age": age,
		"current_job": current_job, "skill_xp": skill_xp, "skill_level": skill_level,
		"implants": implants, "job_time": job_time, "alive": alive, "pending_event": pending_event,
		"last_deed": last_deed, "life_number": life_number, "memory_points": memory_points,
		"last_points_gained": last_points_gained, "upgrades": upgrades,
		"chronicle": chronicle, "fragments": fragments, "last_fragments": last_fragments, "logs": logs,
	}
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))


func load_game() -> bool:
	if not FileAccess.file_exists(save_path):
		return false
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if not data is Dictionary:
		return false
	credits = data.get("credits", 0.0)
	life_earned = data.get("life_earned", 0.0)
	durability = data.get("durability", MAX_DURABILITY)
	age = data.get("age", 0.0)
	current_job = data.get("current_job", "")
	skill_xp = data.get("skill_xp", {})
	skill_level = _int_values(data.get("skill_level", {}))
	implants = data.get("implants", [])
	job_time = data.get("job_time", {})
	alive = data.get("alive", true)
	pending_event = data.get("pending_event", "")
	if not GameData.events.has(pending_event):
		pending_event = ""
	last_deed = data.get("last_deed", "")
	life_number = int(data.get("life_number", 1))
	memory_points = int(data.get("memory_points", 0))
	last_points_gained = int(data.get("last_points_gained", 0))
	upgrades = _int_values(data.get("upgrades", {}))
	chronicle = data.get("chronicle", [])
	fragments = data.get("fragments", [])
	last_fragments = data.get("last_fragments", [])
	logs = data.get("logs", [])
	# JSON では整数も小数になるため、ログの Lv などを整数に戻す
	for entry in logs:
		for k in ["level", "life", "points"]:
			if entry.get("args", {}).has(k):
				entry["args"][k] = int(entry["args"][k])
	return true


func reset_game() -> void:
	life_number = 1
	memory_points = 0
	last_points_gained = 0
	upgrades = {}
	chronicle = []
	fragments = []
	last_fragments = []
	logs = []
	implants = []
	_start_life()
	save_game()


static func _int_values(dict: Dictionary) -> Dictionary:
	var result := {}
	for k in dict:
		result[k] = int(dict[k])
	return result
