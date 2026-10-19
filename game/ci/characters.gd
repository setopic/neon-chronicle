extends SceneTree

## 人物のイベントが周をまたいで決まった順に進むかを確かめる。DOM-13。
## イベントは乱数で起きるので、待っているイベントを捨てながら起こし直して、出てくるイベントを見る。
## セーブは別のファイルに書くので、手元のセーブは消えない。
##
##   godot --headless --path . --script res://ci/characters.gd

const SAVE_PATH := "user://characters-check.json"
const TRIES := 300  # 起こし直す回数。候補は多くて3つなので、出るはずのイベントはまず出る

var _game: Node
var _failed := false


func _process(_delta: float) -> bool:
	_game = root.get_node("Game")
	_game.save_path = SAVE_PATH
	_game.set_process(false)
	_game.reset_game()

	_game.current_job = "hacker"
	_expect(_roll("rei") == "rei_1", "最初は、レイの1段目が起きる")
	_game.choose("refuse")
	_expect(_roll("rei") == "", "同じ周では、レイの話は1段しか進まない")

	_next_life("hacker")
	_expect(_roll("rei") == "rei_2", "次の周に、レイの2段目が起きる")
	_expect(_game.event_desc("rei_2") == TranslationServer.translate("event.rei_2.desc.refuse"), "2段目の説明が、1段目の選択で変わる")
	_game.skill_level["hacking"] = 6
	_game.choose("help")

	_next_life("hacker")
	_expect(_roll("rei") == "rei_3", "その次の周に、レイの3段目が起きる")
	_expect(_choice_ids().has("promise"), "2段目で手を貸したら、約束する選択肢が出る")

	_game.save_game()
	_game.character_choices = {}
	_game.load_game()
	_expect(_game.character_choices.get("rei_2") == "help", "話の進み具合がセーブに残る")

	_game.reset_game()
	_expect(_game.next_character_event("rei") == "rei_1", "最初からやり直すと、話の進み具合も最初に戻る")
	_game.character_choices = {"rei_1": "listen", "rei_2": "decline"}
	_game.current_job = "hacker"
	_expect(_roll("rei") == "rei_3", "進み具合のとおりの段から起きる")
	_expect(not _choice_ids().has("promise"), "2段目で断ったら、約束する選択肢は出ない")

	_next_life("courier")
	_game.character_choices = {"jin_1": "heed", "jin_2": "rescue"}
	_expect(_roll("jin") == "", "記憶の断片「名前」が戻るまで、ジンの3段目は起きない")
	_game.fragments = ["white_room", "contract", "name"]
	_expect(_roll("jin") == "jin_3", "記憶の断片「名前」が戻ったら、ジンの3段目が起きる")

	DirAccess.remove_absolute(SAVE_PATH)
	print("NG" if _failed else "OK: 人物のイベントが周をまたいで決まった順に進む")
	quit(1 if _failed else 0)
	return true


## イベントを起こし直して、その人物のイベントが出たらそのidを返す。出なければ空
func _roll(character: String) -> String:
	for i in TRIES:
		_game.pending_event = ""
		_game._start_event()
		var id: String = _game.pending_event
		if id != "" and root.get_node("GameData").events[id].get("character", "") == character:
			return id
	_game.pending_event = ""
	return ""


func _choice_ids() -> Array:
	return _game.event_choices().map(func(c): return c["id"])


func _next_life(job: String) -> void:
	_game._end_life()
	_game.rebirth(_game.first_body())
	_game.current_job = job


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_failed = true
		printerr("NG: ", what)
