extends SceneTree

## 最初から最後まで自動で遊び、エンディングにたどり着くかを確かめる。DOM-08。
## プレイヤーが画面で見られる情報だけで動く。次の記憶の断片の条件にあるスキルを上げ、
## 条件がそろったら稼ぎの多い仕事に就く。永続強化とインプラントは買えるものから買う。
## 転生するときは、説明に書いてある効果を見て、経験がいちばん増える体を選ぶ。
## ジンの依頼は狙わない。果たした依頼の数だけを出す（ADR-0013）。
## 人物のイベントも狙わない。エンディングまでに選んだ選択肢を出す（DOM-13）。
## 遊んだ時間（進めた秒数）を出し、制限時間までにたどり着かなければ終了コード1で終わる。
## セーブは別のファイルに書くので、手元のセーブは消えない。
##
##   godot --headless --path . --script res://ci/playthrough.gd

const LIMIT := 3.0 * 3600.0  # これより長くかかったら失敗とする（秒）
const SAVE_PATH := "user://playthrough.json"

var _game: Node
var _data: Node  # --script では自動読み込みの名前が使えないので、ノードを取って使う
var _played := 0.0
var _requests_done := 0


func _process(_delta: float) -> bool:
	if _game == null:
		_game = root.get_node("Game")
		_data = root.get_node("GameData")
		_game.save_path = SAVE_PATH
		_game.set_process(false)
		_game.reset_game()
	while _played < LIMIT:
		_step()
		if not _game.endings_reached().is_empty():
			_finish(0)
			return true
	_finish(1)
	return true


func _step() -> void:
	if not _game.alive:
		if _game.request_done:
			_requests_done += 1
		_buy_upgrades()
		_game.rebirth(_pick_body())
		return
	if _game.pending_event != "":
		_game.choose(_pick_choice())
	_game.set_job(_pick_job())
	for id in _data.order["implants"]:
		_game.buy_implant(id)
	_game._tick(_game.STEP)
	_played += _game.STEP


## 次の断片の条件に届いていないスキルがあれば、それをいちばん早く上げる仕事。無ければ稼ぎがいちばん多い仕事
func _pick_job() -> String:
	var lacking := ""
	var next: String = _game.next_fragment()
	if next != "":
		var requires: Dictionary = _data.fragments[next].get("requires", {})
		for skill in requires:
			if _game.skill_level.get(skill, 0) < requires[skill]:
				lacking = skill
				break
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


## 選べる選択肢のうち、本当の体に戻るエンディング、なければ選ぶ条件のあるもの（見返りが大きい）を選ぶ
func _pick_choice() -> String:
	var pick := ""
	for choice in _game.event_choices():
		if not _game.meets(choice.get("requires", {})):
			continue
		if choice.get("ending", "") == "reclaim":
			return choice["id"]
		if pick == "" or not choice.get("requires", {}).is_empty():
			pick = choice["id"]
	return pick


func _pick_body() -> String:
	var best := ""
	var best_xp := -INF
	for id in _data.order["bodies"]:
		if not _game.can_choose_body(id):
			continue
		var xp: float = _data.bodies[id].get("effects", {}).get("xp", 0.0)
		if xp > best_xp:
			best = id
			best_xp = xp
	return best


func _buy_upgrades() -> void:
	var bought := true
	while bought:
		bought = false
		for id in _data.order["upgrades"]:
			if _game.can_buy_upgrade(id):
				_game.buy_upgrade(id)
				bought = true


func _finish(code: int) -> void:
	print("played %d min, life %d, fragments %d / %d, endings %s, requests done %d" % [
		int(_played / 60.0), _game.life_number, _game.fragments.size(),
		_data.order["fragments"].size(), _game.endings_reached(), _requests_done])
	print("  character events: %s" % _game.character_choices)
	for entry in _game.chronicle:
		print("  life %d (%s): %s" % [int(entry["life"]), entry.get("body", ""), _game.story_of(entry)])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	quit(code)
