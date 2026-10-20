---
description: issueを1つ、質問で詰めてからPRまで進める。引数はissueの番号。
argument-hint: <issueの番号>
---

# issue #$ARGUMENTS を進める

この手順は、持ち主の手元のPCで、issueごとに新しく起動した`claude`のセッションで回す。1つのセッションでは1つのissueだけを扱う。実績（コスト指数）がセッションごとに数えられるからである（META-05の「実績の出し方」）。

## 1. 始める前に確かめる

次の3つを確かめ、満たしていなければ持ち主に伝えて止まる。

| 確かめること | 確かめ方 |
| --- | --- |
| 作業ツリーに、ほかの作業の変更が残っていない | `git status` |
| コミットにコスト指数が付く | `git config core.hooksPath`が`.githooks`を返す。返さなければ`git config core.hooksPath .githooks`を実行する |
| ほかのissueの作業中でない | 同じフォルダで、ほかのセッションがブランチを切り替えていないか、`git branch --show-current`で見る |

確かめたら、mainを最新にしてブランチを切る。ブランチ名は、主に触るノードのidから取る（META-05の「PRを出すか、mainへ直接出すか」）。

```bash
git switch main && git pull --ff-only
git switch -c <ノードのid>-<英字の短い名前>
```

## 2. 読む

issueは、本文とコメントの両方を読む。コメントには、ほかのissueで決まったことや、持ち主が足した注文が書いてあることがある。

```bash
gh issue view $ARGUMENTS --comments
```

次に、この3つを読む。

- `CLAUDE.md`
- `docs/00-meta/dev-flow.md`（META-05）
- `docs/00-meta/issue-pr-flow.md`（META-07）

issueの「影響しそうなノード」と「着手する条件」を確かめる。着手する条件のissueが閉じていなければ、持ち主に伝えて止まる。閉じているかは`gh issue view <番号>`で見る。

ノードは、全文書を読まずに、近傍だけを読む。

```bash
python -m tools.graph render --format json --focus <ノードのid> --depth 1
```

## 3. 質問で詰める

書き始める前に、issueの「決めること」を質問にして持ち主に聞く。META-05の`/grill`の4つの場面にあたるなら、`/grill`を回して決定木を作ってから聞く。

質問は次の形で、まとめて1回に出す。

- 番号を`Q1`、`Q2`のように振る。持ち主は「Q1は推奨どおり、Q2はB」のように答える
- 各質問に、選択肢と推奨案と、推奨する理由を1〜2文で付ける
- 前提が片付いていない問いは、まだ出さない。答えを受けてから、次の組として出す

答えが出るまで、文書も実装も書き始めない。答えから分からないことは、推測で埋めずに聞き直す。

## 4. 書く

決まったことを、先に文書へ移す（META-07の「決まったことは文書へ移す」）。却下した案も、ADRに書く。そのあと、実装に着手する前に`/lean`を回す。

このプロジェクトでは、次の決まりもある。

| 決まり | 中身 |
| --- | --- |
| 日本語と英語 | 画面の文は、`game/lang/ja.json`と`game/lang/en.json`の両方に足す |
| 字形 | 日本語の画面の文には、`game/fonts/subset-chars.txt`にある漢字だけを使う。無い漢字は表示されない |
| 画面の大きさ | 1280x720に、日本語でも英語でもはみ出さずに収める。転生の画面と体の欄は、すでに上限に近い |
| `G012` | DOM-01・DOM-02・DOM-03・DOM-06・DOM-08は、依存されている数が上限の8に達している。新しいノードの`depends_on`に、この5つを足さない |
| 自動で遊ぶ検査 | `game/ci/playthrough.gd`は、乱数の種を固定している。遊びの長さや順番を変えたら、この検査が通るかを見る |
| 長さ | 遊ぶ時間は、中身（出来事・仕組み・判断）を足して延ばす。待ち時間や必要量を水増しして延ばさない |
| 文章 | `CLAUDE.md`の「日本語の書き方」に沿う |

## 5. 確かめる

文書を触ったら、グラフを検証して、自動生成の部分を作り直す。

```bash
python -m tools.graph check --strict
make all
```

ゲームを触ったら、CI（`.github/workflows/app-check.yml`）と同じ検査を回す。このPCのGodotは、パスが通っていない。

```bash
GODOT=/c/Users/setom/tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe
python game/ci/check_data.py
cd game
"$GODOT" --headless --path . --script res://ci/playthrough.gd
"$GODOT" --headless --path . --script res://ci/part_two.gd
"$GODOT" --headless --path . --script res://ci/away.gd
"$GODOT" --headless --path . --script res://ci/minigame.gd
"$GODOT" --headless --path . --script res://ci/characters.gd
"$GODOT" --headless --path . --script res://ci/layout.gd
cd ..
```

画面を変えたら、持ち主にゲームを起動して見てもらうよう頼む。日本語と英語の両方で見てもらう。

## 6. コミットとPR

`git add -A`を使わない。自分が作ったファイルを名指しで足す。コミットの1行目には、何をしたかと、issueの番号と、関係するノードのidを書く。

```text
第二部の第4章「写し」を作り、第二部を終える（#184、ADR-0078、DOM-34）
```

`prepare-commit-msg`が、`Cost-Index:`の行を足す。手で書かない。

PRの本文は`.github/pull_request_template.md`の節に沿って書き、本文のどこかに`Closes #$ARGUMENTS`の行を入れる。この行が無いと、issueを閉じても実績が記録されない。

```bash
git push -u origin HEAD
gh pr create --title "<コミットの1行目と同じ>" --body-file <本文のファイル>
```

PRのURLを持ち主に伝え、CIを見る。落ちたら直してpushし、通るまで繰り返す。

```bash
gh pr checks --watch
```

## 7. マージ

持ち主が「マージして」と言うまで、マージしない。「CIが通ったらマージしてよい」と言われたときは、CIが通ってからマージする。

```bash
gh pr merge --squash --delete-branch
git switch main && git pull --ff-only
```

マージでissueが閉じたら、閉じたissueに次のコメントを付ける。分類は、着手の遅れ・作業量の見誤り・範囲の変更・待ちの4つから選んで一言を添え、無ければ「なし」と書く（META-05の「見積もりと実績」）。

```bash
gh issue comment $ARGUMENTS --body "日程に響いたこと: <分類と一言>"
```

## 8. 作業の中で見つけたもの

このissueと種類の違う変更は、このPRに入れずにissueにする（META-07）。issueは、このセッションの中で`/new-issue`を呼んで立てる。型・見積もりのコメント・マイルストーン・関係・日程の付け方は、そちらにある。同じセッションで立てると、立てた分の消費が、このPRの次のコミットでこのissueの実績に入る。
