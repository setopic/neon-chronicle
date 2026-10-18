extends SceneTree

## 閉じていた時間の分だけ進むかを確かめる。ADR-0007。
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


## 新しい周を始め、seconds 秒前にセーブしたことにしてロードし、1フレーム進める
func _reopen_after(seconds: float) -> void:
	_game.reset_game()
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	data["saved_at"] = Time.get_unix_time_from_system() - seconds
	FileAccess.open(SAVE_PATH, FileAccess.WRITE).store_string(JSON.stringify(data))
	_game.load_game()
	_game._process(0.016)


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_failed = true
		printerr("NG: ", what)
