extends Node

## 音楽と効果音を鳴らす。ADR-0008。
## 音は game/audio/make_sounds.py で作ったもので、外部の素材ではない。
## 音楽と効果音は、設定（user://settings.json の music・sfx）で別々に消せる。
## ブラウザは最初の操作まで音を出させないが、Godotがその操作で音を出せるようにするので、
## 「クリックで開始」の画面は置かず、起動したときから曲を流しておく。

const MUSIC := preload("res://audio/music.wav")
const SOUNDS := {
	"click": preload("res://audio/click.wav"),
	"event": preload("res://audio/event.wav"),
	"fall": preload("res://audio/fall.wav"),
	"rebirth": preload("res://audio/rebirth.wav"),
}
const MUSIC_DB := -10.0
const SFX_DB := -6.0

var _music := AudioStreamPlayer.new()
# 音を出す先が無い（CIのヘッドレス）ときは何も鳴らさない。Dummyのドライバーは終わった再生を片付けないので、
# 鳴らすと終了のときに音が使用中のまま残ったというエラーが出て、CIが落ちる
var _silent := AudioServer.get_driver_name() == "Dummy"
var _sfx := {}  # id -> AudioStreamPlayer。1つにまとめると、別の音を鳴らしたときに前の音が切れる


func _ready() -> void:
	_music.stream = MUSIC
	_music.volume_db = MUSIC_DB
	add_child(_music)
	for id in SOUNDS:
		var player := AudioStreamPlayer.new()
		player.stream = SOUNDS[id]
		player.volume_db = SFX_DB
		add_child(player)
		_sfx[id] = player
	if music_on() and not _silent:
		_music.play()
	# ボタンは画面を作り直すたびに増えるので、木に入ったときに繋ぐ
	get_tree().node_added.connect(_on_node_added)
	Game.event_changed.connect(_on_event_changed)
	Game.life_ended.connect(play.bind("fall"))
	Game.life_started.connect(play.bind("rebirth"))


func music_on() -> bool:
	return Loc.setting("music", true)


func sfx_on() -> bool:
	return Loc.setting("sfx", true)


func set_music(on: bool) -> void:
	Loc.set_setting("music", on)
	if _silent:
		return
	if on and not _music.playing:
		_music.play()
	elif not on:
		_music.stop()


func set_sfx(on: bool) -> void:
	Loc.set_setting("sfx", on)


func play(id: String) -> void:
	if _silent or not sfx_on():
		return
	_sfx[id].play()


# event_changed は選んだときにも出るので、イベントが起きたときだけ鳴らす
func _on_event_changed() -> void:
	if Game.pending_event != "":
		play("event")


func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		node.pressed.connect(play.bind("click"))

