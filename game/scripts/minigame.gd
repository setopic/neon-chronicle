class_name Minigame
extends VBoxContainer

## 仕事のミニゲームの共通の形。遊び方の説明と遊ぶ部分を持ち、終えたら成功の度合い（0〜1）を知らせる。ADR-0054。
## どの種類も、マウスだけでも、キーボードだけでも遊べるようにする。

signal finished(score: float)

var level := 0  # 仕事の主なスキルのレベル。種類ごとに難しさを変えるのに使う


## jobs.json の minigame の値から、その種類のミニゲームを作る。知らない種類は null
static func create(kind: String, skill_level: int) -> Minigame:
	var game: Minigame = null
	match kind:
		"hacking": game = HackingGame.new()
		"courier": game = CourierGame.new()
		"mercenary": game = MercenaryGame.new()
	if game != null:
		game.level = skill_level
	return game
