extends Node

## ゲームの進行状態。1人生の状態と、転生しても残る状態を持ち、セーブとロードも行う。

signal life_ended
signal life_started
signal log_added

const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 1
const SAVE_INTERVAL := 5.0
const STEP := 0.25  # シミュレーションの刻み（秒）
const MAX_CATCHUP := 60.0  # 1フレームで進める最大秒数（タブが裏にあった時用）
const BASE_DECAY := 0.4  # 体の劣化（耐久/秒）。何もしなくても約250秒で寿命
const MAX_DURABILITY := 100.0
const LOW_DURABILITY := 25.0
const MAX_LOGS := 50
## ログやクロニクルの引数のうち、id から表示名に変える項目
const NAME_ARGS := {"job": "jobs", "skill": "skills", "implant": "implants", "upgrade": "upgrades"}

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

# --- 転生しても残る状態 ---
var life_number := 1
var memory_points := 0
var last_points_gained := 0
var upgrades := {}
var chronicle: Array = []  # 過去の人生 [{life, job, age, earned, points}]
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
	return 1.0 + effect("xp")


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
	var requires: Dictionary = GameData.jobs.get(job_id, {}).get("requires", {})
	for skill in requires:
		if skill_level.get(skill, 0) < requires[skill]:
			return false
	return true


func set_job(job_id: String) -> void:
	if not alive or job_id == current_job or not can_take_job(job_id):
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


func _end_life() -> void:
	alive = false
	last_points_gained = points_for_life()
	memory_points += last_points_gained
	chronicle.append({
		"life": life_number, "job": main_job(), "age": age,
		"earned": life_earned, "points": last_points_gained,
	})
	_log("log.death", {"points": last_points_gained})
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
		"implants": implants, "job_time": job_time, "alive": alive,
		"life_number": life_number, "memory_points": memory_points,
		"last_points_gained": last_points_gained, "upgrades": upgrades,
		"chronicle": chronicle, "logs": logs,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
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
	life_number = int(data.get("life_number", 1))
	memory_points = int(data.get("memory_points", 0))
	last_points_gained = int(data.get("last_points_gained", 0))
	upgrades = _int_values(data.get("upgrades", {}))
	chronicle = data.get("chronicle", [])
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
	logs = []
	implants = []
	_start_life()
	save_game()


static func _int_values(dict: Dictionary) -> Dictionary:
	var result := {}
	for k in dict:
		result[k] = int(dict[k])
	return result
