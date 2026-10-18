# itch.ioのページに入れるもの

[UC-01](../../docs/30-usecases/uc-01-itch-web-release.md)の手順で、itch.ioの編集画面に写す値と文面を置く。ページを直したら、このファイルも同じに直す。

## 基本の欄

| 欄（Edit game） | 値 |
| --- | --- |
| Title | `Neon Chronicle` |
| Project URL | `neon-chronicle` |
| Short description or tagline | `A cyberpunk idle game: work, wear out your body, and wake up in a new one. / サイバーパンクの放置転生ゲーム` |
| Classification | Games |
| Kind of project | HTML |
| Release status | In development |
| Pricing | `$0 or donate`（下の「価格」） |
| Uploads | `neon-chronicle-web.zip`に「This file will be played in the browser」を付ける |
| Embed options | Embed in page、Manually set size `1280 × 720`、Fullscreen buttonを付ける、Mobile friendlyは付けない、Automatically start on page loadは付けない、SharedArrayBuffer supportは付けない |
| Genre | Simulation |
| Tags | `idle`, `incremental`, `cyberpunk`, `prestige`, `neon`, `sci-fi`, `singleplayer`, `short`, `godot`, `japanese` |
| AI generation disclosure | 下の「AIの使用の申告」 |
| Languages | English, Japanese |
| Inputs | Mouse |
| Community | Comments |
| Visibility & access | 準備中はDraft。公開の日にPublic |
| Cover image | `media/itch/cover.png`（630 × 500） |
| Screenshots | `media/screenshots/`の画像（下の「画面写真」） |

SharedArrayBuffer supportを付けないのは、スレッドを使わない書き出しにしているからである（[ARCH-01](../../docs/10-architecture/arch-01-game-overview.md)）。Mobile friendlyを付けないのは、スマートフォンで遊べるかを確かめていないからである。

## 価格

`$0 or donate`にする。無料で遊べて、気に入った人だけが任意で払える。投げ銭を受けるには、itch.ioの「Payout settings」で受け取りの方法（PayPalなど）と税の情報を入れておく。

## AIの使用の申告

itch.ioは、生成AIを使ったかどうかの申告を求めている。コードと文面はClaudeと一緒に書いている。画像・音声は生成AIで作っていない（カバー画像はゲームの画面から作った）。申告の欄の選び方は、作者が決める。

## 画面写真

| ファイル | 写っているもの |
| --- | --- |
| `screenshot-ja.png` | 第1周の途中。ハッカーに就けるようになったところ（日本語） |
| `screenshot-event-ja.png` | 仕事中に起きたイベントと、その選択肢（日本語） |
| `screenshot-memory.png` | 周の終わりに、記憶の断片が戻った画面（日本語） |
| `screenshot-en.png` | 第1周の途中（英語） |
| `screenshot-event-en.png` | イベントと、その選択肢（英語） |

## 説明文（Description）

英語を先に、日本語を後に置く。itch.ioの一覧からは英語で読む人が多いからである。

```text
Neon Chronicle is a cyberpunk idle game about working, wearing out, and starting over.

Pick a job in the back alleys of a neon city. Work earns credits and skill experience, but your body decays every second, and dangerous jobs wear it down faster. When its integrity hits zero, that life is over. The memory points you earned buy permanent upgrades, and you wake up in a new body to begin the next life.

Events break out while you work. Each choice trades credits, integrity, and experience, and the chronicle remembers what you chose. Lives that push your skills far enough bring back fragments of a lost memory. Recover all five, and a path into the corporate core opens, leading to one of two endings.

- Four jobs, from back-alley courier to a breach of the core server
- Events with choices, and a chronicle that tells the story of every life
- Five memory fragments and two endings
- Skills, implants, and permanent upgrades that carry over between lives
- The city keeps going while you are away (up to 8 hours)
- Original music and sound effects (both can be turned off)
- English and Japanese (switch in the top right corner)
- Progress is saved in your browser

Made with Godot 4.7. Font: Noto Sans JP (SIL Open Font License 1.1). Licenses are listed in the game under "Licenses". Full license texts are in the game (Licenses button, top right).

---

ネオン・クロニクルは、働いて、体をすり減らし、新しい体でやり直すサイバーパンクの放置ゲームです。

ネオンの街の路地裏で、仕事を選びます。働くとクレジットとスキルの経験がたまりますが、体は1秒ごとに劣化し、危険な仕事ほど速くすり減ります。耐久が0になると、その人生は終わりです。稼いだ記憶ポイントで永続強化を買い、新しい体で目覚めて次の周を始めます。

働いている間にはイベントが起きます。選んだ選択肢でクレジット・耐久・経験が増減し、その選択はクロニクルに残ります。スキルを十分に伸ばした人生の終わりには、失われた記憶の断片が戻ります。5つすべてがそろうと企業の中枢への道が開け、2つのエンディングのどちらかにたどり着きます。

- 仕事は4つ：路地裏の運び屋から、中枢サーバーへの侵入まで
- 選択肢のあるイベントと、人生ごとの物語を記すクロニクル
- 5つの記憶の断片と、2つのエンディング
- スキル・インプラント・転生しても残る永続強化
- 閉じている間も街の時間は進みます（最大8時間）
- オリジナルの音楽と効果音（それぞれ消せます）
- 日本語と英語（右上で切り替え）
- 進み具合はブラウザに保存されます

Godot 4.7で作りました。フォントはNoto Sans JP（SIL Open Font License 1.1）です。ライセンスは、ゲームの右上の「ライセンス」で読めます。ライセンスの全文は、ゲームの右上の「ライセンス」から見られます。
```

日本語の説明文は遊ぶ人に向けた紹介なので、ゲームの外の文書と違い、です・ます体で書いている。
