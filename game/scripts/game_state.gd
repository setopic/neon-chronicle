extends Node

## ゲームの進行状態。DOM-02〜DOM-08、DOM-10〜DOM-14、DOM-21〜DOM-31。1人生の状態と、転生しても残る状態を持ち、セーブとロードも行う。

signal life_ended
signal life_started
signal log_added
signal event_changed
signal job_paid(amount: float)  # 仕事の1回を終えて報酬が入ったとき。ADR-0051
signal minigame_changed  # ミニゲームを始めたとき、終えたとき、やめたとき。ADR-0054

var save_path := "user://save.json"  # 通しの検査（ci/playthrough.gd）が別のファイルに差し替える
const SAVE_VERSION := 1
const SAVE_INTERVAL := 5.0
const STEP := 0.25  # シミュレーションの刻み（秒）
const MAX_CATCHUP := 60.0  # ふつうのフレームで進める最大秒数
const MAX_AWAY := 8.0 * 3600.0  # 閉じていた時間を進める上限（秒）。ADR-0007
const AWAY_GAP := 1.0  # 前のフレームからこれより空いたら、閉じていた（タブが裏にあった）とみなす
const AWAY_LOG := 60.0  # これ以上の時間を進めたら、ログに残す
const BASE_DECAY := 0.4  # 体の種類が基本の劣化を持たないときの基本の劣化（耐久/秒）。何もしなくても約250秒で寿命
const MAX_DURABILITY := 100.0
const LOW_DURABILITY := 25.0
const MAX_LOGS := 50
const EVENT_INTERVAL := 90.0  # 危険度1の仕事で、イベントが起きる平均の間隔（秒）。DOM-06
const TENSION_CALM := 15.0  # 緊張がこれ以上なら、ひと息つける間になる。DOM-28
const TENSION_FADE := 0.1  # 緊張が1秒ごとに下がる量
const CALM_RATE := 0.5  # ひと息つける間の、イベントの起きやすさの倍率
const LATE_RATE := 0.5  # 耐久が0に近づくほど、イベントの起きやすさに足す割合
const DEED_XP := 0.02  # クロニクルに残った選択1種類あたりの経験の増え方。DOM-07
const REQUEST_BONUS := 0.5  # 上乗せの割合を持たない依頼を果たした周に、記憶ポイントへ上乗せする割合。ADR-0034
const POINTS_XP := 2.0  # 記憶ポイントの式で、その周で得た経験の合計を割る値。ADR-0032
const QUALITY_MAX := 5  # 体の質の上限。ADR-0032
const QUALITY_DECAY := 0.15  # 体の質1段階ごとに、基本の劣化を下げる割合
const IDENTITY_COST := 300.0  # 闇市場で偽の身元を買う値段。DOM-24
const REPUTATION_LIMIT := 10  # 評判の上限。下限はこれを負にした値。DOM-22
const QUALITY_CREDITS := 1000.0  # 体の質の式で、前の周で稼いだクレジットを割る値
## ログやクロニクルの引数のうち、id から表示名に変える項目
const NAME_ARGS := {
	"job": "jobs", "skill": "skills", "implant": "implants", "upgrade": "upgrades", "event": "events",
	"fragment": "fragments", "ending": "endings", "body": "bodies", "challenge": "challenges", "faction": "factions",
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
var job_progress := 0.0  # 就いている仕事のいまの1回で、進んだ秒数。ADR-0051
var alive := true
var body := ""  # その周の体の種類のid。DOM-11
var body_quality := 0  # その周の体の質。ADR-0032
var life_xp := 0.0  # その周で得た経験の合計。記憶ポイントの式に入る
var pending_event := ""  # 待っているイベントのid。無いときは空
var last_deed := ""  # 最後に選んだ選択肢（"<イベント>.<選択肢>"）。周を終わらせた選択は入れない
var request_offers: Array = []  # その周に並べたジンの依頼のid。0〜2個。DOM-12
var request := ""  # その周に受けた依頼のid。まだ受けていないときは空
var request_done := false
var challenge := ""  # その周の縛りのid。選ばなかった周は空。DOM-21
var challenge_broken := false
var identity := false  # その周に偽の身元を持っているか。周の終わりに失う。DOM-24
# ミニゲームを遊んでいる間は、周の時間を止める。セーブには残さず、開き直したら放置の仕事に戻る（ADR-0054）
var minigame_active := false
const MINIGAME_BONUS := 1.0  # 成功の度合いが1のとき、1回の報酬に上乗せする割合（ADR-0054）
var tension := 0.0  # その周の緊張。耐久を減らす選択肢を選ぶと上がり、時間とともに下がる。DOM-28
var life_choices := {}  # その周に選んだ選択肢 {イベントのid: 選択肢のid}。DOM-27
var met_characters: Array = []  # その周に人物のイベントが起きた人物。1つの周で進む話は、人物ごとに1段まで。DOM-13

# --- 転生しても残る状態 ---
var life_number := 1
var memory_points := 0
var last_points_gained := 0
var last_request_bonus := 0  # last_points_gained のうち、ジンの依頼の上乗せの分
var last_challenge_bonus := 0  # last_points_gained のうち、縛りの上乗せの分
var next_challenge := ""  # 転生の画面で選んでいる縛り。セーブには書かない
var upgrades := {}
var reputation := {}  # 勢力のidごとの評判。転生しても残る。DOM-22
var last_life_choices := {}  # 1つ前の周に選んだ選択肢。前の周の跡のイベントの条件になる。DOM-27
var chronicle: Array = []  # 終わった周の記録 [{life, body, job, age, earned, points, deed, end, ending}]
var fragments: Array = []  # 戻った記憶の断片のid。DOM-08
var character_choices := {}  # 人物のイベントで選んだ選択肢 {イベントのid: 選択肢のid}。話の進み具合を表す。DOM-13
var last_fragments: Array = []  # 直前の周の終わりに戻った記憶の断片のid
var logs: Array = []  # [{key, args}]。言語を切り替えても訳し直せるようキーで持つ

var _pending := 0.0
var _save_timer := 0.0
var _last_seen := 0.0  # 最後に時間を進めた時刻（Unix時間）。ロードしたときはセーブした時刻


func _ready() -> void:
	_last_seen = Time.get_unix_time_from_system()
	if not load_game():
		_start_life()


func _process(delta: float) -> void:
	# 閉じていた時間とタブが裏にあった時間は、壁の時計で測る。ブラウザでは裏にある間フレームが来ないため（ADR-0007）
	var now := Time.get_unix_time_from_system()
	var gap := maxf(delta, now - _last_seen)
	_last_seen = now
	var away := {}
	if gap > AWAY_GAP:
		away = _advance_away(minf(gap, MAX_AWAY))
	else:
		_pending = minf(_pending + delta, MAX_CATCHUP)
	while _pending >= STEP:
		_pending -= STEP
		_tick(STEP)
	if not away.is_empty():
		_fill_away_log(away)
	_save_timer += delta
	if _save_timer >= SAVE_INTERVAL:
		_save_timer = 0.0
		save_game()


## 閉じていた時間を、開いているときと同じ刻みで進める。周が終わっても自動で転生はしない（ADR-0007）。
## ログに残したときは、その行と進める前の値を返す。閉じていた間の成果は、進め終えてから _fill_away_log で足す（ADR-0071）
func _advance_away(seconds: float) -> Dictionary:
	_pending += seconds
	if not alive or is_paused() or seconds < AWAY_LOG:
		return {}
	# 閉じている間に周が終わったときの行より前に出すため、先に行を置いておく
	_log("log.away", {"age": seconds})
	return {"entry": logs.back(), "earned": life_earned, "points": points_if_ended_now()}


func _fill_away_log(away: Dictionary) -> void:
	var earned: float = life_earned - away["earned"]
	var now := last_points_gained if not alive else points_if_ended_now()
	var points := maxi(0, now - away["points"])
	if earned <= 0.0 and points == 0:
		return
	var entry: Dictionary = away["entry"]
	entry["key"] = "log.away_gain"
	entry["args"].merge({"earned": earned, "points": points})
	log_added.emit()


## 「イベントで止める」の設定で、時間が止まっているか（ADR-0004）
func is_paused() -> bool:
	return minigame_active or (pending_event != "" and Loc.setting("pause_on_event", false))


func _notification(what: int) -> void:
	# ブラウザではタブを閉じる前に保存の機会が来ないことがあるので、離れたときにも保存する
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()


func _tick(dt: float) -> void:
	if not alive or is_paused():
		return
	age += dt
	var danger := 1.0
	if GameData.jobs.has(current_job):
		var job: Dictionary = GameData.jobs[current_job]
		job_time[current_job] = job_time.get(current_job, 0.0) + dt
		job_progress += dt
		var length := job_length(current_job)
		if job_progress >= length:
			job_progress -= length
			_finish_job_round(job, length)
		danger = job.get("danger", 1.0)
		tension = maxf(0.0, tension - TENSION_FADE * dt)
		if pending_event == "" and randf() < danger * dt / EVENT_INTERVAL * event_rate():
			_start_event()
	_check_request()
	var before := durability
	durability -= decay_per_sec(danger) * dt
	if before > LOW_DURABILITY and durability <= LOW_DURABILITY:
		_log("log.durability_low")
	if durability <= 0.0:
		durability = 0.0
		_end_life()


## 仕事の1回を終えたときに、その時点の稼ぎと経験の長さ分をまとめて入れる（ADR-0051）
## mult は、ミニゲームで終えた1回の上乗せ。放置で終えた1回は1（ADR-0054）
func _finish_job_round(job: Dictionary, length: float, mult := 1.0) -> void:
	var pay := income_per_sec(current_job) * length * mult
	credits += pay
	life_earned += pay
	var xp: Dictionary = job.get("xp", {})
	for skill in xp:
		_add_xp(skill, xp[skill] * (xp_mult() + effect("xp_" + skill)) * length * mult)
	job_paid.emit(pay)


## 就いている仕事のミニゲームの種類。ミニゲームの無い仕事は空（ADR-0054）
func minigame_of(job_id: String) -> String:
	return GameData.jobs.get(job_id, {}).get("minigame", "")


func can_play_minigame() -> bool:
	return alive and pending_event == "" and not minigame_active and minigame_of(current_job) != ""


## いまの1回を、ミニゲームで置き換えて始める。遊んでいる間は周の時間が止まる
func start_minigame() -> void:
	if not can_play_minigame():
		return
	minigame_active = true
	minigame_changed.emit()


## ミニゲームを終えた。score は成功の度合い（0〜1）。0でも放置で終えた1回と同じだけ入る
func finish_minigame(score: float) -> void:
	if not minigame_active:
		return
	minigame_active = false
	var length := job_length(current_job)
	# ジンの依頼が数える就いた時間も、放置で終えた1回と同じだけ進める
	job_time[current_job] = job_time.get(current_job, 0.0) + length
	job_progress = 0.0
	_finish_job_round(GameData.jobs[current_job], length, 1.0 + MINIGAME_BONUS * clampf(score, 0.0, 1.0))
	_check_request()
	minigame_changed.emit()


## ミニゲームをやめた。報酬は入らず、いまの1回の進み具合はそのまま残る
func cancel_minigame() -> void:
	if not minigame_active:
		return
	minigame_active = false
	minigame_changed.emit()


func job_length(job_id: String) -> float:
	return GameData.jobs.get(job_id, {}).get("length", 1.0)


# --- 効果の計算 ---

## 体の種類・インプラント・永続強化・スキルの効果を合計する（"income", "xp", "decay", "start_level"）。
## 永続強化だけが持つ効果は "xp_<スキル>", "points", "start_credits", "implant_cost" の4つ（ADR-0033）
func effect(key: String) -> float:
	# 体の種類の効果と、体の元の持ち主から残った特性の効果（DOM-25）
	var total: float = GameData.bodies.get(body, {}).get("effects", {}).get(key, 0.0)
	total += GameData.bodies.get(body, {}).get("trait_effects", {}).get(key, 0.0)
	for id in implants:
		total += GameData.implants.get(id, {}).get("effects", {}).get(key, 0.0)
	for id in upgrades:
		total += upgrades[id] * GameData.upgrades.get(id, {}).get("effects_per_level", {}).get(key, 0.0)
	for id in skill_level:
		var skill: Dictionary = GameData.skills.get(id, {})
		total += skill_level[id] * skill.get("effects_per_level", {}).get(key, 0.0)
		total += milestones(id) * skill.get("effects_per_milestone", {}).get(key, 0.0)
	return total


## スキルが越えた節目の数。節目は milestone_every レベルごとで、上限は無い（DOM-03）
func milestones(skill_id: String) -> int:
	var every: int = int(GameData.skills.get(skill_id, {}).get("milestone_every", 0))
	if every <= 0:
		return 0
	return int(skill_level.get(skill_id, 0)) / every


func xp_mult() -> float:
	return 1.0 + effect("xp") + deed_bonus()


## 基本の劣化は体の種類が持ち、体の質で下がる。効果の合計とは別に掛けるので、劣化の効果が下限に届いていても体の差が残る（ADR-0012、ADR-0032）
func decay_per_sec(danger: float) -> float:
	var base: float = GameData.bodies.get(body, {}).get("decay", BASE_DECAY) * (1.0 - QUALITY_DECAY * body_quality)
	return base * danger * maxf(0.2, 1.0 + effect("decay"))


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
	# 橋の向こうの仕事は、橋を渡れる身元が無いと就けない（DOM-24）
	if job.get("needs_identity", false) and not identity:
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
	if current_job != "":
		break_challenge("job")
	current_job = job_id
	job_progress = 0.0  # 途中の1回の分は入らない（ADR-0051）
	_log("log.job", {"job": job_id})


func xp_to_next(level: int) -> float:
	return 10.0 * pow(1.25, level)


func _add_xp(skill: String, amount: float) -> void:
	if not GameData.skills.has(skill):
		return
	skill_xp[skill] = skill_xp.get(skill, 0.0) + amount
	life_xp += amount
	var level: int = skill_level.get(skill, 0)
	while skill_xp[skill] >= xp_to_next(level):
		skill_xp[skill] -= xp_to_next(level)
		level += 1
		skill_level[skill] = level
		var reached := milestones(skill)
		_log("log.skill_up", {"skill": skill, "level": level})
		if reached > 0 and level % int(GameData.skills[skill]["milestone_every"]) == 0:
			_log("log.skill_milestone", {"skill": skill, "level": level})


# --- インプラントと永続強化 ---

## 組み込んだインプラントを外す。払ったクレジットは戻らない（DOM-26）
func remove_implant(id: String) -> void:
	if not alive or not implants.has(id):
		return
	implants.erase(id)
	_log("log.implant_removed", {"implant": id})


## 闇市場で偽の身元を買う。周の終わりまで持ち、次の周には持ち越さない（DOM-24）
func buy_identity() -> void:
	if not alive or identity or credits < IDENTITY_COST:
		return
	credits -= IDENTITY_COST
	identity = true
	_log("log.identity")


## インプラントの値段は、永続強化で下がっても、もとの半分を下回らない（ADR-0033）
func implant_cost(id: String) -> float:
	return GameData.implants.get(id, {}).get("cost", 0.0) * maxf(0.5, 1.0 + effect("implant_cost"))


## いまの体の容量。容量を持たない体の種類（MODで足したものなど）は、上限を設けない（DOM-26）
func capacity() -> int:
	return int(GameData.bodies.get(body, {}).get("capacity", 99))


## 組み込んでいるインプラントの大きさの合計
func implant_load() -> int:
	var total := 0
	for id in implants:
		total += int(GameData.implants.get(id, {}).get("size", 1))
	return total


## 体の容量に収まるか。容量を超えるインプラントは組み込めない（DOM-26）
func implant_fits(id: String) -> bool:
	return implant_load() + int(GameData.implants.get(id, {}).get("size", 1)) <= capacity()


func buy_implant(id: String) -> void:
	var cost := implant_cost(id)
	if not alive or implants.has(id) or credits < cost or not implant_fits(id):
		return
	credits -= cost
	implants.append(id)
	_log("log.implant", {"implant": id})
	break_challenge("implant")


func upgrade_cost(id: String) -> int:
	var data: Dictionary = GameData.upgrades.get(id, {})
	return int(data.get("cost", 1) * pow(data.get("cost_growth", 2.0), upgrades.get(id, 0)))


func upgrade_maxed(id: String) -> bool:
	return upgrades.get(id, 0) >= GameData.upgrades.get(id, {}).get("max_level", 99)


## 同じ排他の組で、すでにレベルを持っている別の永続強化のid。無ければ空。組の選択は取り直せない（ADR-0033）
func upgrade_taken_in_group(id: String) -> String:
	var group: String = GameData.upgrades.get(id, {}).get("group", "")
	if group == "":
		return ""
	for other in upgrades:
		if other != id and upgrades[other] > 0 and GameData.upgrades.get(other, {}).get("group", "") == group:
			return other
	return ""


## その永続強化にこれまで払った記憶ポイント。選び直すときに、この分を戻す（DOM-31）
func upgrade_spent(id: String) -> int:
	var data: Dictionary = GameData.upgrades.get(id, {})
	var spent := 0
	for level in upgrades.get(id, 0):
		spent += int(data.get("cost", 1) * pow(data.get("cost_growth", 2.0), level))
	return spent


## 排他の組の永続強化を選び直す。払った記憶ポイントをすべて戻し、レベルを0にする（DOM-31）
func refund_upgrade(id: String) -> void:
	if GameData.upgrades.get(id, {}).get("group", "") == "" or upgrades.get(id, 0) <= 0:
		return
	var spent := upgrade_spent(id)
	memory_points += spent
	upgrades.erase(id)
	_log("log.upgrade_refund", {"upgrade": id, "points": spent})


## 話を選び直せるか。どれか1つのエンディングに一度でもたどり着いてから選び直せる（DOM-31、ADR-0050）
func can_rewind_story() -> bool:
	return not endings_reached().is_empty()


## 話を、from_event の段から選び直せるようにする。その段と、それより後の段の選択を話の進み具合から消す。
## 消した段は、次からまた起きうる。評判や経験など、選んだときに得たものはそのまま残す（DOM-31）
func rewind_story(line: String, from_event: String) -> void:
	if not can_rewind_story():
		return
	var stages := []
	for id in GameData.order["events"]:
		if story_line(GameData.events[id]) == line:
			stages.append(id)
	var at := stages.find(from_event)
	if at < 0 or not character_choices.has(from_event):
		return
	for i in range(at, stages.size()):
		character_choices.erase(stages[i])
	_log("log.rewind", {"event": from_event})


func can_buy_upgrade(id: String) -> bool:
	return not upgrade_maxed(id) and memory_points >= upgrade_cost(id) and upgrade_taken_in_group(id) == ""


func buy_upgrade(id: String) -> void:
	if not can_buy_upgrade(id):
		return
	memory_points -= upgrade_cost(id)
	upgrades[id] = upgrades.get(id, 0) + 1
	_log("log.upgrade", {"upgrade": id, "level": upgrades[id]})


# --- イベント ---

func _start_event() -> void:
	var candidates := []
	for id in GameData.order["events"]:
		if GameData.events[id].get("jobs", []).has(current_job) and _can_start(id):
			candidates.append(id)
	if candidates.is_empty():
		return
	# ひと息つける間は、耐久を減らす選択肢の無い穏やかなイベントから選ぶ。穏やかなものが無ければ、そのまま選ぶ（DOM-28）
	if is_calm():
		var calm := candidates.filter(func(id): return is_gentle(id))
		if not calm.is_empty():
			candidates = calm
	pending_event = candidates.pick_random()
	var character := story_line(GameData.events[pending_event])
	if character != "":
		met_characters.append(character)
	_log("log.event", {"event": pending_event})
	event_changed.emit()


## 緊張が高く、ひと息つける間か（DOM-28）
func is_calm() -> bool:
	return tension >= TENSION_CALM


## 耐久を減らす選択肢を持たない、穏やかなイベントか
func is_gentle(event_id: String) -> bool:
	for c in GameData.events.get(event_id, {}).get("choices", []):
		if c.get("durability", 0.0) < 0.0:
			return false
	return true


## イベントの起きやすさの倍率。耐久が0に近づくほど上がり、ひと息つける間は下がる（DOM-28）
func event_rate() -> float:
	var rate := 1.0 + LATE_RATE * (1.0 - durability / MAX_DURABILITY)
	return rate * (CALM_RATE if is_calm() else 1.0)


## 人物のイベントと勢力の話のイベントは、その話の次の段だけが、その周にまだ話が進んでいないときに起きる（DOM-13、DOM-23）
func _can_start(event_id: String) -> bool:
	var event: Dictionary = GameData.events[event_id]
	# 前の周の跡のイベントは、1つ前の周にその選択肢を選んだときだけ起きる（DOM-27）
	var trace: String = event.get("requires_trace", "")
	if trace != "":
		var parts := trace.split(".")
		if parts.size() != 2 or last_life_choices.get(parts[0], "") != parts[1]:
			return false
	var character := story_line(event)
	if character == "":
		return true
	if met_characters.has(character) or next_character_event(character) != event_id:
		return false
	# 元の持ち主の話は、その持ち主の部品で組み立てた体で目覚めた周にだけ起きる（DOM-25）
	if event.get("body", "") != "" and event["body"] != body:
		return false
	return event.get("fragment", "") == "" or fragments.has(event["fragment"])


## その話の、まだ起きていない最初のイベント。data に並んだ順が話の順である。話が終わっていれば空
func next_character_event(character: String) -> String:
	for id in GameData.order["events"]:
		if story_line(GameData.events[id]) == character and not character_choices.has(id):
			return id
	return ""


## イベントが段の1つになっている話。人物のイベントは人物のid、勢力の話のイベントは話のid。どちらでもなければ空。
## 人物と勢力の話は、1周に1段までという進み方が同じなので、同じ仕組みで進める（DOM-23）
func story_line(event: Dictionary) -> String:
	return event.get("character", event.get("story", ""))


## 待っているイベントの説明。前の段で選んだ選択肢ごとに文を書き分けたイベントは、その文を使う（DOM-13）
func event_desc(event_id: String) -> String:
	var by: String = GameData.events.get(event_id, {}).get("desc_by", "")
	if by == "":
		return GameData.desc_of("events", event_id)
	return tr("event.%s.desc.%s" % [event_id, character_choices.get(by, "")])


## 待っているイベントの選択肢。前の選択の条件と話の条件を満たさない選択肢は、選び直せないので出さない（DOM-13、DOM-08）
func event_choices() -> Array:
	return GameData.events.get(pending_event, {}).get("choices", []).filter(func(c):
		return _story_met(c.get("requires_choice", "")) and _story_met(c.get("requires_story", "")))


## 「イベントのid.選択肢のid」の条件を、話の進み具合が満たしているか。条件が空なら満たしている
func _story_met(after: String) -> bool:
	if after == "":
		return true
	var parts := after.split(".")
	return parts.size() == 2 and character_choices.get(parts[0], "") == parts[1]


## 待っているイベントに、選ぶ条件があって、いま選べる選択肢があるか
func _has_open_conditioned_choice() -> bool:
	for c in event_choices():
		if has_condition(c) and choice_open(c):
			return true
	return false


## 選ぶ条件（スキルのレベルか評判）を持つ選択肢か
func has_condition(choice: Dictionary) -> bool:
	return not choice.get("requires", {}).is_empty() or not choice.get("requires_reputation", {}).is_empty()


## 選ぶ条件を満たしていて、いま選べる選択肢か。評判の条件は、その値以上（DOM-22）
func choice_open(choice: Dictionary) -> bool:
	if not meets(choice.get("requires", {})):
		return false
	var needs: Dictionary = choice.get("requires_reputation", {})
	for id in needs:
		if reputation.get(id, 0) < needs[id]:
			return false
	return true


## 評判を変える。上限と下限で止める（DOM-22）
func change_reputation(changes: Dictionary) -> void:
	for id in changes:
		if GameData.factions.has(id):
			reputation[id] = clampi(reputation.get(id, 0) + int(changes[id]), -REPUTATION_LIMIT, REPUTATION_LIMIT)


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
	if choice.is_empty() or not choice_open(choice):
		return
	# 選ぶ条件のある選択肢を選べるのに、選ぶ条件の無い選択肢を選んだら、縛りを破ったことになる（DOM-21）
	if not has_condition(choice) and _has_open_conditioned_choice():
		break_challenge("choice")
	var event_id := pending_event
	pending_event = ""
	# 人物のイベントと、資料の出るイベントは、選んだ選択肢を残す（DOM-13、DOM-14）
	if story_line(GameData.events[event_id]) != "" or GameData.events[event_id].get("record", false):
		character_choices[event_id] = choice_id
	life_choices[event_id] = choice_id
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
	change_reputation(choice.get("reputation", {}))
	_check_request()
	var before := durability
	durability = clampf(durability + choice.get("durability", 0.0), 0.0, MAX_DURABILITY)
	if before > LOW_DURABILITY and durability <= LOW_DURABILITY and durability > 0.0:
		_log("log.durability_low")
	var was_calm := is_calm()
	tension += maxf(0.0, -choice.get("durability", 0.0))
	if not was_calm and is_calm():
		_log("log.calm")
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
	# 依頼の上乗せは、この値をもとに _end_life で足す（ADR-0033）
	return maxi(1, int((int(sqrt(life_xp / POINTS_XP)) + levels / 3) * (1.0 + effect("points"))))


## 記憶ポイントの見込み。いま周が終わったら得る記憶ポイントで、依頼と縛りの上乗せを含む（ADR-0071）
func points_if_ended_now() -> int:
	var base := points_for_life()
	return base + request_bonus_for(base) + challenge_bonus_for(base)


func request_bonus_for(base: int) -> int:
	var bonus: float = GameData.requests.get(request, {}).get("bonus", REQUEST_BONUS)
	return maxi(1, roundi(base * bonus)) if request_done else 0


func challenge_bonus_for(base: int) -> int:
	var kept := _kept_challenge()
	return maxi(1, roundi(base * GameData.challenges.get(kept, {}).get("bonus", 0.0))) if kept != "" else 0


## まだ破っていない、その周の縛り。無ければ空
func _kept_challenge() -> String:
	return challenge if challenge != "" and not challenge_broken else ""


# --- 体の質 ---

## 稼いだクレジットは周ごとに大きく変わるので、2倍ごとに1段階上げる（ADR-0032）
static func quality_for(earned: float) -> int:
	if earned < QUALITY_CREDITS:
		return 0
	return clampi(int(floor(log(earned / QUALITY_CREDITS) / log(2.0))), 0, QUALITY_MAX)


## 前の周で稼いだクレジットで決まる体の質。第1周は0
func last_quality() -> int:
	return quality_for(chronicle.back().get("earned", 0.0)) if not chronicle.is_empty() else 0


## 次の周に body_id の体で目覚めたときの体の質。汎用の体だけは、これまでの最高の体の質の半分を下回らない
func next_quality(body_id: String) -> int:
	var quality := last_quality()
	if body_id == first_body():
		var best := 0
		for entry in chronicle:
			best = maxi(best, quality_for(entry.get("earned", 0.0)))
		quality = maxi(quality, best / 2)
	return quality


## 汎用の体のほかは、前の周の体の質が1以上のときだけ選べる
func can_choose_body(body_id: String) -> bool:
	return GameData.bodies.has(body_id) and (body_id == first_body() or last_quality() >= 1)


## fatal_event は周を終わらせたイベントのid、ending はたどり着いたエンディングのid。どちらも無ければ空
func _end_life(fatal_event := "", ending := "") -> void:
	alive = false
	pending_event = ""
	last_life_choices = life_choices.duplicate()
	last_points_gained = points_for_life()
	last_request_bonus = request_bonus_for(last_points_gained)
	var kept := _kept_challenge()
	last_challenge_bonus = challenge_bonus_for(last_points_gained)
	last_points_gained += last_request_bonus + last_challenge_bonus
	memory_points += last_points_gained
	chronicle.append({
		"life": life_number, "body": body, "job": main_job(), "age": age,
		"earned": life_earned, "points": last_points_gained,
		"deed": last_deed, "end": fatal_event, "ending": ending, "challenge": kept,
	})
	_log("log.ending" if ending != "" else "log.death", {"points": last_points_gained})
	_recall_fragments()
	save_game()
	life_ended.emit()


## body_id は次の周の体の種類。転生の画面で選ぶ（DOM-11）
func rebirth(body_id: String) -> void:
	if alive or not can_choose_body(body_id):
		return
	life_number += 1
	_start_life(body_id, next_challenge)
	next_challenge = ""
	save_game()


## 体の種類を指定しないのは第1周だけで、data の最初の体で目覚める
func first_body() -> String:
	return GameData.order["bodies"][0] if not GameData.order["bodies"].is_empty() else ""


## challenge_id はその周の縛り。第1周には縛りが無い（DOM-21）
func _start_life(body_id := "", challenge_id := "") -> void:
	# 依頼は前の周の終わりのスキルのレベルで決めるので、スキルを戻す前に選ぶ。第1周には前の周が無い
	request_offers = pick_requests(skill_level if life_number > 1 else {})
	request = ""
	request_done = false
	met_characters = []
	life_choices = {}
	tension = 0.0
	challenge = challenge_id if GameData.challenges.has(challenge_id) and life_number > 1 else ""
	challenge_broken = false
	identity = false
	implants = implants.filter(func(id): return GameData.implants.get(id, {}).get("persistent", false))
	credits = 0.0
	life_earned = 0.0
	life_xp = 0.0
	durability = MAX_DURABILITY
	age = 0.0
	current_job = ""
	job_progress = 0.0
	pending_event = ""
	last_deed = ""
	job_time = {}
	skill_level = {}
	skill_xp = {}
	alive = true
	body = body_id if body_id != "" else first_body()
	body_quality = next_quality(body)
	credits = effect("start_credits")
	var start_level := int(effect("start_level"))
	for skill in GameData.skills:
		skill_level[skill] = start_level
		skill_xp[skill] = 0.0
	_log("log.awaken_first" if life_number == 1 else "log.awaken", {"life": life_number, "body": body})
	for id in request_offers:
		_log("request.%s.offer" % id, request_args(id))
	if challenge != "":
		_log("log.challenge", {"challenge": challenge})
	life_started.emit()


# --- ジンの依頼 ---

## 示す条件を前の周の終わりのスキルのレベル（levels）が満たす依頼を、周の番号で順に回し、2つまで並べる。
## 2つめは1つめの次の依頼。乱数は使わない（ADR-0034）
func pick_requests(levels: Dictionary) -> Array:
	var candidates := []
	for id in GameData.order["requests"]:
		var requires: Dictionary = GameData.requests[id].get("requires", {})
		if requires.keys().all(func(skill): return levels.get(skill, 0) >= requires[skill]):
			candidates.append(id)
	var offers := []
	for i in mini(2, candidates.size()):
		offers.append(candidates[(life_number - 1 + i) % candidates.size()])
	return offers


## 並べた依頼のうち1つを受ける。受けたあとは周の終わりまで変わらない。進み具合は周の始まりから数える（ADR-0034）
func accept_request(id: String) -> void:
	if not alive or request != "" or not request_offers.has(id):
		return
	request = id
	_log("log.request_accepted")
	_check_request()


## 依頼の中身を、ログと画面の文に差し込む引数にする。時間は分で書くので、秒は60で割る
func request_args(id: String) -> Dictionary:
	var data: Dictionary = GameData.requests.get(id, {})
	if data.has("job"):
		return {"job": data["job"], "min": int(data.get("seconds", 0.0) / 60.0)}
	return {"skill": data.get("skill", ""), "level": int(data.get("level", 0))}


## 依頼の進み具合 [いまの値, 目標]。仕事の依頼は秒、スキルの依頼はレベル
func request_progress() -> Array:
	var data: Dictionary = GameData.requests.get(request, {})
	if data.has("job"):
		return [job_time.get(data["job"], 0.0), float(data.get("seconds", 0.0))]
	return [float(skill_level.get(data.get("skill", ""), 0)), float(data.get("level", 0))]


func _check_request() -> void:
	if request_done or not GameData.requests.has(request):
		return
	var progress := request_progress()
	if progress[0] >= progress[1]:
		request_done = true
		_log("log.request_done")


# --- クロニクル ---

## 記録の物語文。仕事・最後に選んだ選択肢・倒れた理由から組み立てる（DOM-07）。
## 記録には id だけを持たせ、文はいまの言語で毎回組み立てる。#6 より前の記録は deed と end を持たない
func story_of(entry: Dictionary) -> String:
	var job: String = entry.get("job", "")
	var job_part := tr("job.%s.chronicle" % job) if job != "" else tr("chronicle.no_job")
	var end: String = entry.get("end", "")
	# イベントの名前を「〜で倒れた」に差し込むと不自然な文になるので、句をイベントごとに書く（ADR-0011）
	var end_part := tr("event.%s.fall" % end) if end != "" else tr("chronicle.end_decay")
	var ending: String = entry.get("ending", "")
	if ending != "":
		end_part = tr("ending.%s.chronicle" % ending)
	var deed: String = entry.get("deed", "")
	if deed == "":
		return Loc.t("chronicle.story_short", {"job": job_part, "end": end_part}) + _challenge_part(entry)
	return Loc.t("chronicle.story", {"job": job_part, "deed": tr("event.%s.chronicle" % deed), "end": end_part}) + _challenge_part(entry)


## 守った縛りを物語文の後ろに足す句。#82 より前の記録と、縛りの無い周は空（DOM-21）
func _challenge_part(entry: Dictionary) -> String:
	var kept: String = entry.get("challenge", "")
	if not GameData.challenges.has(kept):
		return ""
	return Loc.t("chronicle.challenge", {"challenge": GameData.name_of("challenges", kept)})


# --- 縛り ---

## その周の縛りの守る条件が rule なら、縛りを破ったことにする。破ったら周の終わりまで戻らない（DOM-21）
func break_challenge(rule: String) -> void:
	if challenge == "" or challenge_broken or GameData.challenges.get(challenge, {}).get("rule", "") != rule:
		return
	challenge_broken = true
	_log("log.challenge_broken", {"challenge": challenge})


## クロニクルに残った選択肢の種類。いまのデータに無いもの（外したMODの選択肢）は数えない
## 転生の画面でミオが言う一言のキー。倒れた理由（体の限界かイベントか）と周の番号で変わる（DOM-10）。
## 周の番号は、初めて倒れた周・10周目まで・それより後の3段に分ける
func mio_line_key(entry: Dictionary) -> String:
	var reason := "event" if entry.get("end", "") != "" else "decay"
	var life := int(entry.get("life", 1))
	var stage := 1 if life <= 1 else (2 if life < 10 else 3)
	return "mio.%s.%d" % [reason, stage]


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


## 資料や追記を出してよいか。要る断片が戻り、出るイベントで選択肢を選んでいれば出す。DOM-14
func revealed(entry: Dictionary) -> bool:
	if entry.has("fragment") and not fragments.has(entry["fragment"]):
		return false
	return not entry.has("event") or character_choices.has(entry["event"])


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
	if s >= 3600:
		return "%d:%02d:%02d" % [s / 3600, s / 60 % 60, s % 60]
	return "%d:%02d" % [s / 60, s % 60]


# --- セーブとロード ---

func save_game() -> void:
	var data := {
		"version": SAVE_VERSION, "saved_at": Time.get_unix_time_from_system(),
		"credits": credits, "life_earned": life_earned, "durability": durability, "age": age,
		"current_job": current_job, "skill_xp": skill_xp, "skill_level": skill_level,
		"implants": implants, "job_time": job_time, "job_progress": job_progress, "alive": alive, "body": body, "body_quality": body_quality, "life_xp": life_xp, "pending_event": pending_event,
		"last_deed": last_deed, "request_offers": request_offers, "request": request, "request_done": request_done,
		"challenge": challenge, "challenge_broken": challenge_broken, "identity": identity, "tension": tension, "last_challenge_bonus": last_challenge_bonus, "met_characters": met_characters, "life_number": life_number, "memory_points": memory_points,
		"last_points_gained": last_points_gained, "last_request_bonus": last_request_bonus, "upgrades": upgrades, "reputation": reputation, "life_choices": life_choices, "last_life_choices": last_life_choices,
		"chronicle": chronicle, "fragments": fragments, "last_fragments": last_fragments,
		"character_choices": character_choices, "logs": logs,
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
	# #117 より前のセーブは、仕事の進み具合を持たない。0から始める
	job_progress = float(data.get("job_progress", 0.0))
	alive = data.get("alive", true)
	# #36 より前の体は、どれも効果の無い最初の体だった
	body = data.get("body", first_body())
	body_quality = int(data.get("body_quality", 0))
	life_xp = data.get("life_xp", 0.0)
	pending_event = data.get("pending_event", "")
	if not GameData.events.has(pending_event):
		pending_event = ""
	last_deed = data.get("last_deed", "")
	# #37 より前のセーブの周には、依頼が無い
	request = data.get("request", "")
	if not GameData.requests.has(request):
		request = ""
	request_done = data.get("request_done", false)
	# #81 より前のセーブは、依頼を1つだけ示していた。示した依頼は受けたものとして扱う
	request_offers = data.get("request_offers", [request] if request != "" else []).filter(func(id): return GameData.requests.has(id))
	# #38 より前のセーブには、人物のイベントが無い
	met_characters = data.get("met_characters", [])
	life_number = int(data.get("life_number", 1))
	memory_points = int(data.get("memory_points", 0))
	last_points_gained = int(data.get("last_points_gained", 0))
	last_request_bonus = int(data.get("last_request_bonus", 0))
	# #82 より前のセーブの周には、縛りが無い
	challenge = data.get("challenge", "")
	if not GameData.challenges.has(challenge):
		challenge = ""
	challenge_broken = data.get("challenge_broken", false)
	# #86 より前のセーブの周には、身元が無い。傭兵に就いていたら、身元を持っていたものとして扱う
	identity = data.get("identity", data.get("current_job", "") == "mercenary")
	# #92 より前のセーブの周は、緊張0から始める
	tension = float(data.get("tension", 0.0))
	last_challenge_bonus = int(data.get("last_challenge_bonus", 0))
	upgrades = _int_values(data.get("upgrades", {}))
	# #84 より前のセーブには、評判が無い
	reputation = _int_values(data.get("reputation", {}))
	# #91 より前のセーブには、周ごとの選択が無い。前の周の跡のイベントは、次の周から起きうる
	life_choices = data.get("life_choices", {})
	last_life_choices = data.get("last_life_choices", {})
	chronicle = data.get("chronicle", [])
	for entry in chronicle:
		if not entry.has("body"):
			entry["body"] = first_body()
	fragments = data.get("fragments", [])
	last_fragments = data.get("last_fragments", [])
	character_choices = data.get("character_choices", {})
	logs = data.get("logs", [])
	# 次のフレームで、セーブしてから今までの時間を進める。#9 より前のセーブは時刻を持たない
	_last_seen = data.get("saved_at", Time.get_unix_time_from_system())
	# JSON では整数も小数になるため、ログの Lv などを整数に戻す
	for entry in logs:
		for k in ["level", "life", "points", "min"]:
			if entry.get("args", {}).has(k):
				entry["args"][k] = int(entry["args"][k])
	return true


func reset_game() -> void:
	life_number = 1
	memory_points = 0
	last_points_gained = 0
	last_request_bonus = 0
	last_challenge_bonus = 0
	next_challenge = ""
	upgrades = {}
	reputation = {}
	last_life_choices = {}
	chronicle = []
	fragments = []
	last_fragments = []
	character_choices = {}
	logs = []
	implants = []
	_start_life()
	save_game()


static func _int_values(dict: Dictionary) -> Dictionary:
	var result := {}
	for k in dict:
		result[k] = int(dict[k])
	return result
