extends Node

## 言語ファイル（lang/*.json）を読み込み、TranslationServer に登録する。
## 形式: {"locale": "ja", "name": "日本語", "strings": {"キー": "文字列"}}
## MOD の lang/ に同じ locale のファイルを置くと文字列を追加・上書きでき、新しい locale なら言語が増える。
## 言語のほかの設定（イベントで止めるか。ADR-0004。音楽と効果音を鳴らすか。ADR-0008）も、同じ settings.json に保存する。

signal language_changed

const SETTINGS_PATH := "user://settings.json"
const DEFAULT_LOCALE := "en"

var _translations := {}  # locale -> Translation
var _names := {}  # locale -> 言語の表示名
var _settings := {}


func _ready() -> void:
	_settings = _read_settings()
	_load_languages()
	set_language(_saved_or_system_locale())


func setting(key: String, default: Variant) -> Variant:
	return _settings.get(key, default)


func set_setting(key: String, value: Variant) -> void:
	_settings[key] = value
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(_settings))


## 使える言語の locale 一覧
func languages() -> Array:
	var list := _names.keys()
	list.sort()
	return list


func language_name(locale: String) -> String:
	return _names.get(locale, locale)


func current() -> String:
	return TranslationServer.get_locale()


func set_language(locale: String) -> void:
	if not _translations.has(locale):
		locale = DEFAULT_LOCALE
	TranslationServer.set_locale(locale)
	set_setting("locale", locale)
	language_changed.emit()


## 書式つきの翻訳。t("ui.credits", {"n": "10"}) -> "クレジット: 10"
func t(key: String, args := {}) -> String:
	return tr(key).format(args)


func _load_languages() -> void:
	for path in ModPaths.json_files("lang"):
		var data: Variant = ModPaths.load_json(path)
		if not data is Dictionary or not data.has("locale"):
			push_warning("Language file without locale: " + path)
			continue
		var locale: String = data["locale"]
		if not _translations.has(locale):
			var translation := Translation.new()
			translation.locale = locale
			_translations[locale] = translation
			TranslationServer.add_translation(translation)
		if data.has("name"):
			_names[locale] = data["name"]
		var strings: Dictionary = data.get("strings", {})
		for key in strings:
			_translations[locale].add_message(key, strings[key])


func _saved_or_system_locale() -> String:
	if _translations.has(_settings.get("locale", "")):
		return _settings["locale"]
	var system := OS.get_locale_language()
	return system if _translations.has(system) else DEFAULT_LOCALE


func _read_settings() -> Dictionary:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(SETTINGS_PATH))
	return data if data is Dictionary else {}
