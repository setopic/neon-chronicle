# ネオン・クロニクル（最小版）

Godot 4.7.2 / GDScript。ブラウザ向けに Compatibility 描画とスレッドなしの Web 書き出しを使っています。

## 遊び方
仕事を選ぶとクレジットとスキル経験がたまります。体の耐久は時間と仕事の危険度で減り、0 になると人生が終わります。
得た記憶ポイントで永続強化を買い、新しい体で目覚めると次の周が始まります。1周はおよそ4〜7分です。
仕事中にはイベントが起き、選んだ選択肢でクレジット・耐久・経験が増減します。右上の「イベントで止める」を入れると、選ぶまで時間が止まります。
周の終わりのスキルのレベルが条件を満たすと、記憶の断片が順に戻ります。5つすべて戻ると「中枢サーバーへの侵入」に就けるようになり、そこで起きるイベントの選択でエンディング（2つ）にたどり着きます。戻った断片は右上の「記憶」で読み返せます（DOM-08）。

## フォルダ構成
| 場所 | 中身 |
|---|---|
| `data/*.json` | 仕事・スキル・インプラント・永続強化・イベント・記憶の断片とエンディング（`story.json`）・体の種類（`bodies.json`）の数値。表示文はここに書かない |
| `lang/*.json` | 言語ファイル（`ja.json`, `en.json`）。`<種類>.<id>.name` / `.desc` などのキーで文を持つ |
| `scripts/mod_paths.gd` | 本体と MOD の読み込み先をまとめる |
| `scripts/loc.gd` | 言語ファイルの読み込みと言語の切り替え。設定（言語、イベントで止めるか、音楽と効果音を鳴らすか）の保存 |
| `scripts/game_data.gd` | data の読み込み（同じ id は後から読んだものが上書き） |
| `scripts/game_state.gd` | 進行・転生・セーブとロード（`user://save.json`） |
| `scripts/main.gd` / `city.gd` | 画面と上部の3Dの街 |
| `scripts/sound.gd` | 音楽と効果音を鳴らす |
| `audio/` | 音楽と効果音の WAV と、それを合成する `make_sounds.py` |

## 言語と MOD
- 最初の起動ではブラウザ（OS）の言語が日本語なら日本語、それ以外は英語。右上で切り替えると次回も覚えています。
- 言語を増やすには `lang/<locale>.json` を `{"locale": "fr", "name": "Français", "strings": {...}}` の形で置くだけです。足りないキーは英語で表示されます。
- MOD は `user://mods/<MOD名>/data/` と `lang/` に JSON を置くと読み込まれます。同じ id の項目は値を上書き、新しい id は追加、同じ locale の言語ファイルは文の上書き・追加になります（PC版向け。ブラウザ版では MOD フォルダを使いません）。
- 新しい仕事を足すときは、`data` に項目を、各言語ファイルに `job.<id>.name` と `job.<id>.desc` を足します。
- 新しいイベントを足すときは、`data/events.json` と同じ形で項目を置き、各言語ファイルに `event.<id>.name`・`event.<id>.desc` と、選択肢ごとの `event.<id>.<選択肢>.name`・`event.<id>.<選択肢>.result` を足します（DOM-06）。

## ライセンス
使った外部の素材とそのライセンスは `credits.txt` に並べています。ゲームの右上の「ライセンス」のボタンで、この一覧と、OFL・Godot（第三者の部品を含む）のライセンスの全文を表示します。外部の素材を足したら、`credits.txt` に書き足してください。全文を添える必要があるものは、`export_presets.cfg` の `include_filter` にも足します（ADR-0002）。

## フォント
Noto Sans JP（SIL Open Font License 1.1、`fonts/OFL-NotoSansJP.txt`）を太さ500に固定し、ASCII・かな・JIS第1水準漢字などに絞って軽くしています（`fonts/subset-chars.txt`）。
第2水準の漢字など、この中にない文字を使うと表示されないので、そのときはサブセットを作り直します。

## 書き出し
```bash
godot --headless --path . --export-release "Web" build/web/index.html
rm -f neon-chronicle-web.zip
(cd build/web && zip -r ../../neon-chronicle-web.zip .)
```

できた `neon-chronicle-web.zip` は itch.io に HTML ゲームとしてそのままアップロードできます。itch.io での公開の手順は `docs/30-usecases/uc-01-itch-web-release.md`（UC-01）にあります。

## 検査
`python ci/check_data.py` で、言語ファイルのキーの抜けと JSON の書き損じを確かめます。CI（`.github/workflows/app-check.yml`）はこれに加えて、Godot をヘッドレスで起動してエラーが出ないかを見ます。
`godot --headless --path . --script res://ci/playthrough.gd` は、決まった手順で最初から最後まで早送りで遊び、エンディングにたどり着くかを確かめます。遊んだ時間と各周の物語文を出します。セーブは別のファイルに書くので、手元のセーブは消えません。
`godot --headless --path . --script res://ci/away.gd` は、セーブの時刻をずらしてロードし、閉じていた時間の分だけ進むかを確かめます。

## 音
音楽と効果音は外部の素材ではなく、`python audio/make_sounds.py` で合成した WAV です。音を変えるときはこのスクリプトを直して回し直します。曲は繰り返して流すので、`audio/music.wav.import` の `edit/loop_mode=2` を外さないでください。右上の「音楽」と「効果音」で別々に消せます。ブラウザでは、最初にクリックかキー入力をしたときから聞こえます（ADR-0008）。
