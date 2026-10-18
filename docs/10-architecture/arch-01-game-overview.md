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

実装は`game/`にあるGodot 4.7.2のプロジェクトで、言語はGDScriptである。自動読み込み（autoload）は`Loc`・`GameData`・`Game`の3つである。

この表は、`game/project.godot`の自動読み込みと`game/scripts/`のファイルを写したものである。機械は突き合わせないので、スクリプトを足したら手で確かめる。

| 要素 | 責務 | 責務でないこと |
| --- | --- | --- |
| `game/data/*.json` | 仕事・スキル・インプラント・永続強化の数値を持つ | 表示文を持つこと |
| `game/lang/*.json` | 言語ごとの表示文を、`<種類>.<id>.name`のようなキーで持つ | 数値を持つこと |
| `mod_paths.gd` | 本体とMODの読み込み先をまとめる | ファイルを読むこと |
| `loc.gd`（`Loc`） | 言語ファイルを読み、言語の切り替えと保存をする | 数値を扱うこと |
| `game_data.gd`（`GameData`） | `data`を読む。同じidは後から読んだものが上書きする | 進行の状態を持つこと |
| `game_state.gd`（`Game`） | 進行・転生・セーブとロード（`user://save.json`）を受け持つ | 画面を描くこと |
| `main.gd`・`city.gd` | 画面と、上部の3Dの街を描く | 進行の計算をすること |

## 境界

本体とMODの境界は、JSONの形である。MODは`user://mods/<MOD名>/data/`と`lang/`に、本体と同じ形のJSONを置く。同じidの項目は値を上書きし、新しいidは追加になる。

## 前提と制約

ブラウザ版は、Compatibility描画と、スレッドを使わないWeb書き出しで動かす。ブラウザ版ではMODのフォルダを読まない。

フォントはNoto Sans JPの部分集合（`game/fonts/subset-chars.txt`）である。この中に無い文字を表示文に使うと表示されないので、そのときは部分集合を作り直す。

どの言語ファイルも`en.json`と同じキーを持ち、`data`の各項目には表示名と説明のキーがある。ゲームは足りないキーを英語で補うので、抜けても画面を見るまで気づけない。そのため、CIの`app-check.yml`がこのキーの対応を確かめる。あわせて、Godotをヘッドレスで起動し、エラーが出ないことも確かめる。

## 未決事項

イベントと選択肢、クロニクルの物語文、ストーリー、音楽と効果音、オフライン中の進行は、まだ入っていない。

---

<!-- graph:auto:start -->

## 関連ドキュメント（自動生成 / 手で編集しない）

このノードを参照しているノード

- (decides) [ADR-0001 設計文書をグラフとして管理する](../50-adr/adr-0001-graph-driven-docs.md)
- (depends_on) [UC-01 itch.ioでブラウザ版を公開する](../30-usecases/uc-01-itch-web-release.md)

<!-- graph:auto:end -->
