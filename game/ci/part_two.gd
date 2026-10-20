extends "res://ci/playthrough.gd"

## エンディング「本当の体」まで ci/playthrough.gd と同じ手順で遊び、そのまま第二部の章を終えるまで自動で遊ぶ。DOM-34。
## 第二部では、体調が残りわずかになったら休み、戻りきったら仕事に戻る。仕事は、章の目標のスキルのうち
## いちばん低いものを上げる仕事を選ぶ。住まいを借りられるようになったら借り、そのあとは怪我を治せるだけ治す。
## 怪我を治しきったら、クレジットを払って満たす目標を払う。
## 終えたあと、セーブとロード、第一部への行き来で、第二部の状態が残るかも確かめる。
## 章ごとにかかった時間（進めた秒数）を出し、範囲に入らなければ終了コード1で終わる。
## 人が遊んで第1章に約50分という目安を、第一部の検査と同じ比（ゲーム内の36分で人の約1時間）で換算して確かめる（ADR-0075）。
##
##   godot --headless --path . --script res://ci/part_two.gd

const CHAPTER_MIN := 20.0 * 60.0  # 第1章がこれより早く終わったら失敗とする（秒）
const CHAPTER_MAX := 40.0 * 60.0  # 第1章がこれより長くかかったら失敗とする（秒）
const PART_TWO_LIMIT := 6.0 * 3600.0
const REST_BELOW := 15.0  # 体調がこれより下がったら休む

var _part_two_played := 0.0
var _collapses := 0


func _process(_delta: float) -> bool:
	if _game == null:
		_game = root.get_node("Game")
		_data = root.get_node("GameData")
		_game.save_path = SAVE_PATH
		_game.set_process(false)
		seed(SEED)  # 第一部の検査と同じ種で、同じ道筋をたどって第二部に入る
		_game.reset_game()
	while _played < LIMIT and not _game.endings_reached().has("reclaim"):
		_step()
	if not _game.endings_reached().has("reclaim"):
		print("part one did not reach the reclaim ending in %d min" % int(_played / 60.0))
		_finish(1)
		return true
	print("part one: reclaim after %d min, life %d" % [int(_played / 60.0), _game.life_number])
	_game.enter_part_two()
	while _part_two_played < PART_TWO_LIMIT and _game.chapter < 1:
		_step_two()
	var ok: bool = _game.chapter >= 1 and _part_two_played >= CHAPTER_MIN and _part_two_played <= CHAPTER_MAX
	print("part two: chapter 1 %s after %d min, day %d, collapses %d, injury %d, credits %d, skills %s" % [
		"done" if _game.chapter >= 1 else "NOT done", int(_part_two_played / 60.0), _game.day, _collapses,
		int(_game.injury), int(_game.credits), _game.skill_level])
	print("  beats: %s" % str(_game.seen_beats))
	ok = _check_keep() and ok
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	quit(0 if ok else 1)
	return true


func _step_two() -> void:
	if _game.pending_event != "":
		_game.choose(_pick_choice())
	if _game.can_rent_room():
		_game.rent_room()
	elif _game.has_room:
		while _game.can_treat():
			_game.treat()
		if _game.injury <= 0.0:
			for goal in _data.chapters.get(_game.chapter_id(), {}).get("goals", []):
				_game.pay_goal(goal)
	_game.buy_identity()
	for id in _data.order["implants"]:
		_game.buy_implant(id)
	if _game.current_job != "" and _game.durability < REST_BELOW:
		_game.rest()
	elif _game.current_job == "" and _game.durability >= _game.max_condition() - 1.0:
		_game.set_job(_pick_job_two())
	elif _game.current_job != "":
		_game.set_job(_pick_job_two())
	var last: Dictionary = _game.logs.back() if not _game.logs.is_empty() else {}
	_game._tick(_game.STEP)
	if not _game.logs.is_empty() and not is_same(_game.logs.back(), last) and _game.logs.back().get("key", "") == "log.collapse":
		_collapses += 1
	_part_two_played += _game.STEP


## 章の目標のスキルのうち、いちばんレベルの低いものを、いちばん早く上げる仕事
func _pick_job_two() -> String:
	var lacking := ""
	for goal in _data.chapters.get(_game.chapter_id(), {}).get("goals", []):
		var skills: Dictionary = goal.get("skills", {})
		for skill in skills:
			if _game.skill_level.get(skill, 0) < skills[skill] and (lacking == "" or _game.skill_level[skill] < _game.skill_level[lacking]):
				lacking = skill
	var best := ""
	var best_score := -1.0
	for id in _data.order["jobs"]:
		if not _game.can_take_job(id):
			continue
		var score: float = _data.jobs[id].get("xp", {}).get(lacking, 0.0) if lacking != "" else _game.income_per_sec(id)
		if score > best_score:
			best = id
			best_score = score
	return best


## 第二部の状態が、セーブとロードと、第一部の転生の画面への行き来で失われないか。
## クレジットはセーブのJSONで端数が丸まるので、整数にして比べる
func _check_keep() -> bool:
	var before := [_game.day, roundi(_game.credits), _game.skill_level.duplicate(), _game.chapter, _game.has_room]
	_game.save_game()
	_game.load_game()
	var loaded := [_game.day, roundi(_game.credits), _game.skill_level, _game.chapter, _game.has_room]
	_game.leave_part_two()
	var left: bool = _game.part == 1 and not _game.alive and _game.can_enter_part_two()
	_game.save_game()
	_game.load_game()
	_game.enter_part_two()
	var back := [_game.day, roundi(_game.credits), _game.skill_level, _game.chapter, _game.has_room]
	var ok: bool = before == loaded and left and before == back and _game.part == 2 and _game.alive
	print("%s 第二部の状態が、セーブとロードと第一部との行き来で残る %s / %s / %s" % ["ok  " if ok else "NG  ", before, loaded, back])
	return ok
