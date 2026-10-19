---
id: ARCH-01
type: architecture
title: ゲームの全体構成
status: stable
tags: [game]
depends_on: []
related: []
---

# ゲームの全体構成

## 解決したい構造上の問題

ネオン・クロニクルは、まずブラウザ版を無料で出し、あとからPC版でMODを受け付ける。同じ本体を両方に使うため、数値と表示文を外のJSONに出し、MODが同じ形のJSONで上書きできるようにしておく。

## 構成

実装は`game/`にあるGodot 4.7.2のプロジェクトで、言語はGDScriptである。自動読み込み（autoload）は`Loc`・`GameData`・`Game`・`Sound`の4つである。

この表は、`game/project.godot`の自動読み込みと`game/scripts/`のファイルを写したものである。機械は突き合わせないので、スクリプトを足したら手で確かめる。

| 要素 | 責務 | 責務でないこと |
| --- | --- | --- |
| `game/data/*.json` | 仕事・スキル・インプラント・永続強化・イベント・記憶の断片・エンディングの数値を持つ | 表示文を持つこと |
| `game/lang/*.json` | 言語ごとの表示文を、`<種類>.<id>.name`のようなキーで持つ | 数値を持つこと |
| `mod_paths.gd` | 本体とMODの読み込み先をまとめる | ファイルを読むこと |
| `loc.gd`（`Loc`） | 言語ファイルを読み、言語を切り替える。言語と「イベントで止める」「音楽」「効果音」の設定を`user://settings.json`に保存する（[ADR-0045](../50-adr/adr-0045-event-waves.md)、[ADR-0008](../50-adr/adr-0008-audio.md)） | 数値を扱うこと |
| `game_data.gd`（`GameData`） | `data`を読む。同じidは後から読んだものが上書きする | 進行の状態を持つこと |
| `sound.gd`（`Sound`） | 音楽と効果音を鳴らす。「音楽」と「効果音」の設定で消したものは鳴らさない（[ADR-0008](../50-adr/adr-0008-audio.md)） | 進行を変えること |
| `game/audio/` | 音楽と効果音のWAVと、それを合成する`make_sounds.py`を持つ（[ADR-0008](../50-adr/adr-0008-audio.md)） | 外部の素材を持つこと |
| `game_state.gd`（`Game`） | 進行・転生・セーブとロード（`user://save.json`）を受け持つ。セーブはセーブした時刻を持ち、開いたときに閉じていた時間を進める（[ADR-0007](../50-adr/adr-0007-away-progress.md)） | 画面を描くこと |
| `main.gd`・`city.gd` | 画面と、上部の3Dの街を描く。右上の「ライセンス」のボタンで、素材のライセンスを表示する | 進行の計算をすること |
| `game/credits.txt` | 使った外部の素材とそのライセンスの一覧を持つ（[ADR-0002](../50-adr/adr-0002-asset-licenses-in-game.md)） | Godotの第三者の部品を並べること。それは実行中にGodotから取る |

## 境界

本体とMODの境界は、JSONの形である。MODは`user://mods/<MOD名>/data/`と`lang/`に、本体と同じ形のJSONを置く。同じidの項目は値を上書きし、新しいidは追加になる。

## 前提と制約

ブラウザ版は、Compatibility描画と、スレッドを使わないWeb書き出しで動かす。ブラウザ版ではMODのフォルダを読まない。

フォントはNoto Sans JPの部分集合（`game/fonts/subset-chars.txt`）である。外部の素材を足したら、`game/credits.txt`に書き足し、ライセンスの全文を求めるものは書き出しの`include_filter`にも挙げる。この中に無い文字を表示文に使うと表示されないので、そのときは部分集合を作り直す。

どの言語ファイルも`en.json`と同じキーを持ち、`data`の各項目には表示名と説明のキーがある。ゲームは足りないキーを英語で補うので、抜けても画面を見るまで気づけない。そのため、CIの`app-check.yml`がこのキーの対応を確かめる。あわせて、Godotをヘッドレスで起動し、エラーが出ないことも確かめる。さらに、`game/ci/playthrough.gd`が決まった手順で最初から最後まで自動で遊び、エンディングにたどり着くことを確かめる（[ADR-0046](../50-adr/adr-0046-third-ending.md)）。`game/ci/away.gd`は、閉じていた時間の分だけ進むことを確かめる（[ADR-0007](../50-adr/adr-0007-away-progress.md)）。

## 未決事項

なし

---

<!-- graph:auto:start -->

## 関連ドキュメント（自動生成 / 手で編集しない）

このノードを参照しているノード

- (decides) [ADR-0001 設計文書をグラフとして管理する](../50-adr/adr-0001-graph-driven-docs.md)
- (decides) [ADR-0002 素材のライセンスの一覧をゲームの中に置く](../50-adr/adr-0002-asset-licenses-in-game.md)
- (decides) [ADR-0004 イベントの起き方と結果を決まった量で表す](../50-adr/adr-0004-event-rules.md)
- (decides) [ADR-0005 クロニクルの物語文を仕事と選択と倒れた理由から組み立てる](../50-adr/adr-0005-chronicle-story.md)
- (decides) [ADR-0006 記憶の断片を順に戻し、最後の仕事の選択でエンディングを分ける](../50-adr/adr-0006-fragments-and-endings.md)
- (decides) [ADR-0007 閉じていた時間を、開いたときにまとめて進める](../50-adr/adr-0007-away-progress.md)
- (decides) [ADR-0008 音楽と効果音をスクリプトで作り、最初の操作から鳴らす](../50-adr/adr-0008-audio.md)
- (decides) [ADR-0017 画面の右上のボタンとダイアログの見た目をそろえる](../50-adr/adr-0017-header-and-dialog-look.md)
- (depends_on) [UC-01 itch.ioでブラウザ版を公開する](../30-usecases/uc-01-itch-web-release.md)

<!-- graph:auto:end -->
