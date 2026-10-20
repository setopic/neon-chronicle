extends SceneTree

## 閉じていた時間の分だけ進むかを確かめる。ADR-0007、ADR-0051、ADR-0071。
## セーブの時刻を過去にずらしてロードし、1フレーム分だけ進めて結果を見る。
## セーブは別のファイルに書くので、手元のセーブは消えない。
##
##   godot --headless --path . --script res://ci/away.gd

const SAVE_PATH := "user://away-check.json"

var _game: Node
var _failed := false


func _process(_delta: float) -> bool:
	_game = root.get_node("Game")
	_game.save_path = SAVE_PATH
	_game.set_process(false)

	# 仕事に就いていなければイベントは起きないので、進み方が決まる
	_reopen_after(100.0)
	_expect(absf(_game.age - 100.0) < 0.5, "100秒閉じたら、経過時間が100秒進む（%.2f）" % _game.age)
	_expect(_game.alive, "100秒では周は終わらない")
	_expect(_game.logs.back().get("key") == "log.away", "閉じていた時間がログに残る")

	# 運び屋の1回は5秒。3秒進んだ1回を残して4秒閉じたら、1回分の報酬が入り、2秒進んだ1回が残る（ADR-0051）
	_reopen_after(4.0, {"current_job": "courier", "job_progress": 3.0})
	var pay: float = _game.income_per_sec("courier") * _game.job_length("courier")
	_expect(absf(_game.credits - pay) < 0.01, "閉じている間に終えた1回の報酬が入る（%.2f / %.2f）" % [_game.credits, pay])
	_expect(absf(_game.job_progress - 2.0) < 0.3, "途中の1回は続きから進む（%.2f）" % _game.job_progress)

	# 仕事に就いて閉じていたら、稼いだクレジットがログの1行に出る（ADR-0071）
	_reopen_after(100.0, {"current_job": "courier"})
	var away: Dictionary = _first_log("log.away_gain")
	_expect(not away.is_empty(), "閉じていた間の成果がログに残る")
	_expect(absf(away.get("args", {}).get("earned", 0.0) - _game.life_earned) < 0.01, "ログの稼ぎが、閉じていた間に稼いだクレジットと同じ")

	_reopen_after(30.0 * 24.0 * 3600.0)
	_expect(not _game.alive, "長く閉じていたら、周が終わる")
	_expect(_game.chronicle.size() == 1, "終わった周がクロニクルに残る")
	_expect(_game.life_number == 1, "自動では転生しない")

	_reopen_after(-3600.0)
	_expect(_game.age < 1.0, "時計が戻っても進まない（%.2f）" % _game.age)

	DirAccess.remove_absolute(SAVE_PATH)
	print("NG" if _failed else "OK: 閉じていた時間の分だけ進む")
	quit(1 if _failed else 0)
	return true


## 新しい周を始め、changes をセーブに書き足し、seconds 秒前にセーブしたことにしてロードし、1フレーム進める
func _reopen_after(seconds: float, changes := {}) -> void:
	_game.reset_game()
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	data.merge(changes, true)
	data["saved_at"] = Time.get_unix_time_from_system() - seconds
	FileAccess.open(SAVE_PATH, FileAccess.WRITE).store_string(JSON.stringify(data))
	_game.load_game()
	_game._process(0.016)


func _first_log(key: String) -> Dictionary:
	for entry in _game.logs:
		if entry.get("key") == key:
			return entry
	return {}


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_failed = true
		printerr("NG: ", what)
