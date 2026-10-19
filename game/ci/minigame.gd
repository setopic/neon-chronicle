extends SceneTree

## ミニゲームで終えた1回の報酬と、放置の仕事と二重に入らないことを確かめる。ADR-0054。
## セーブは別のファイルに書くので、手元のセーブは消えない。
##
##   godot --headless --path . --script res://ci/minigame.gd

const SAVE_PATH := "user://minigame-check.json"

var _game: Node
var _failed := false


func _process(_delta: float) -> bool:
	_game = root.get_node("Game")
	_game.save_path = SAVE_PATH
	_game.set_process(false)
	_game.reset_game()
	_game.current_job = "courier"
	var pay: float = _game.income_per_sec("courier") * _game.job_length("courier")

	# 遊んでいる間は周の時間が止まり、放置の1回は進まない
	_game.job_progress = 3.0
	_game.start_minigame()
	_expect(_game.minigame_active, "運び屋の仕事でミニゲームを始められる")
	for i in 100:
		_game._tick(0.25)
	_expect(_game.credits == 0.0, "遊んでいる間は、放置の1回の報酬が入らない（%.2f）" % _game.credits)
	_expect(absf(_game.job_progress - 3.0) < 0.01, "遊んでいる間は、放置の1回が進まない（%.2f）" % _game.job_progress)

	# 成功の度合いが1なら、1回の報酬に MINIGAME_BONUS の分が上乗せされ、進み具合は0に戻る
	_game.finish_minigame(1.0)
	var full: float = pay * (1.0 + _game.MINIGAME_BONUS)
	_expect(absf(_game.credits - full) < 0.01, "うまく終えると上乗せした報酬が入る（%.2f / %.2f）" % [_game.credits, full])
	_expect(_game.job_progress == 0.0, "ミニゲームで終えた1回の進み具合は0に戻る")
	_game.finish_minigame(1.0)
	_expect(absf(_game.credits - full) < 0.01, "終えたあとに、もう一度報酬は入らない")

	# 度合いが0でも、放置で終えた1回と同じだけ入る
	_game.start_minigame()
	_game.finish_minigame(0.0)
	_expect(absf(_game.credits - full - pay) < 0.01, "度合いが0でも1回分は入る（%.2f）" % (_game.credits - full))

	# やめたら入らず、進み具合はそのまま残る
	var before: float = _game.credits
	_game.job_progress = 2.0
	_game.start_minigame()
	_game.cancel_minigame()
	_expect(_game.credits == before, "やめたら報酬は入らない")
	_expect(absf(_game.job_progress - 2.0) < 0.01, "やめたら進み具合はそのまま残る")
	_expect(not _game.minigame_active, "やめたら放置の仕事に戻る")

	_check_hacking()
	_check_courier()

	DirAccess.remove_absolute(SAVE_PATH)
	print("NG" if _failed else "OK: ミニゲームの報酬は二重に入らない")
	quit(1 if _failed else 0)
	return true


## ハッキングのミニゲームは、作った道をたどればちょうどの回数でそろい、度合いが1になる（ADR-0055）
func _check_hacking() -> void:
	for i in 20:
		var game: HackingGame = Minigame.create("hacking", 0)
		root.add_child(game)
		var scores := []
		game.finished.connect(func(score): scores.append(score))
		for cell in game.path:
			game._pick(cell)
		_expect(scores == [1.0], "ハッキングの表は、作った道でそろう（%s）" % [scores])
		game.free()


## 運び屋のミニゲームは、表を作るときに見つけた手で、レベル0の歩数以内に届けられる（ADR-0056）
func _check_courier() -> void:
	for i in 20:
		var game: CourierGame = Minigame.create("courier", 0)
		root.add_child(game)
		var scores := []
		game.finished.connect(func(score): scores.append(score))
		for key in game.solution:
			game.move(key)
		_expect(scores.size() == 1 and scores[0] >= 0.5, "運び屋の地図は、見つけた手で届けられる（%s）" % [scores])
		game.free()


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_failed = true
		printerr("NG: ", what)
