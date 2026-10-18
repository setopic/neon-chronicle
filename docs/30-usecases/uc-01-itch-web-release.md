---
id: UC-01
type: usecase
title: itch.ioでブラウザ版を公開する
status: draft
tags: [release, web]
depends_on: [ARCH-01]
related: []
---

# itch.ioでブラウザ版を公開する

## 概要

| 項目 | 内容 |
| --- | --- |
| 実行者 | 作者（itch.ioのアカウントの持ち主） |
| きっかけ | ブラウザ版を初めて出すとき。出したあとの更新は、手順の5から行う |
| 完了したときに得られる状態 | itch.ioのページがPublicで、ブラウザから最初の周を遊べ、作品名で検索すると出てくる |
| 影響 | 公開前はDraftなので、誰の目にも触れない。更新のときは、上げ直している間だけ古い版のままになる |

ページに入れる値と説明文は、`media/itch/page.md`にある。

## 事前条件

- [ ] itch.ioのアカウントがあり、メールアドレスを確かめてある
- [ ] Godot 4.7.2と、同じ版の書き出しテンプレート（Web）が入っている
- [ ] `main`の`app-check`が通っている
- [ ] 投げ銭を受け取るための「Payout settings」（受け取りの方法と税の情報）を入れてある
- [ ] GitHubのマイルストーン「物語とイベント」のissueがすべて閉じている（Publicにするのは、それが終わってからと決めた）
- [ ] 公開の日と、公開後数日の告知の段取りを決めてある

## 手順

1. 書き出して、zipにまとめる。

   ```bash
   cd game
   godot --headless --path . --import
   godot --headless --path . --export-release "Web" build/web/index.html
   rm -f neon-chronicle-web.zip
   (cd build/web && zip -r ../../neon-chronicle-web.zip .)
   ```

   zipの直下に`index.html`があることを確かめる。フォルダごと固めると、itch.ioが`index.html`を見つけられない。

2. 手元のブラウザで書き出したものを開き、起動することを確かめる。

   ```bash
   cd game/build/web
   python -m http.server 8000
   ```

   `http://localhost:8000/`を開く。`index.html`をファイルとして直接開くと、ブラウザが読み込みを止めるので起動しない。

3. itch.ioで「Upload new project」を開き、`media/itch/page.md`の「基本の欄」と「説明文」のとおりに入れる。「Visibility & access」は`Draft`のままにして保存する。

4. カバー画像と画面写真を上げ、保存する。

5. zipを上げ、「This file will be played in the browser」を付けて保存する。更新のときは、古いzipを消してから新しいzipを上げる。

6. 編集画面の「View page」から下書きのページを開き、ページの上で第1周を最後まで遊び、「新しい体で目覚める」で第2周が始まることを確かめる。日本語と英語の切り替えも確かめる。

7. 公開の日に、「Visibility & access」を`Public`にして保存する。

8. 作品のページのURLを、決めておいた告知先に出す。

9. 数日たったら、itch.ioの検索で「Neon Chronicle」を引き、出てくるかを確かめる。

## 順序の制約

| 制約 | 理由 |
| --- | --- |
| 3〜6 → 7 | itch.ioの公開日は、最初にPublicにした日で決まり、あとで変わらない。新着に並ぶのはその1回だけなので、ページがそろう前にPublicにしない |
| 7 → 8 | 新着の中で上に来るかは、公開した直後のアクセスと反応で決まる。告知はPublicにしてすぐ出す |
| 4・5の順 | どちらが先でもよい。検索と一覧に載るには、両方がそろっている必要がある |
| 1 → 2 → 5 | 手元で起動しないものを上げない |

## つまずきやすい点

| 症状 | 原因 | 対処 |
| --- | --- | --- |
| ページで「index.html not found」と出る | zipの中でフォルダが1段深い | 手順1のとおり、`build/web`の中で固め直す |
| 画面が真っ黒のまま進まない | 書き出しテンプレートの版がGodotと違う | `--export-release`の出力に版の警告が無いかを見て、同じ版のテンプレートを入れ直す |
| SharedArrayBufferが無いと言われる | スレッドを使う書き出しになっている | `export_presets.cfg`の`variant/thread_support`が`false`であることを確かめる（[ARCH-01](../10-architecture/arch-01-game-overview.md)） |
| Publicにしたのに、新着や検索に出てこない | 初めて出品するアカウントの最初の作品は、審査で数営業日かかることがある | 待つ。その間も、作品のページのURLからは遊べる。ページを消して作り直すと不審な動きとして扱われ、さらに遅れる |
| 進み具合が消えた | セーブはブラウザの保存領域にあり、itch.ioのページの埋め込みの中に保存される | ブラウザの閲覧データを消すと消える。プライベートウィンドウでは残らない |

## 完了の確認

- [ ] itch.ioのページがPublicになっている
- [ ] 公開したページの上で、第1周を最後まで遊び、第2周が始まった
- [ ] itch.ioの検索で「Neon Chronicle」を引くと出てくる

## 切り戻し

ページをPublicからDraftに戻すと、遊べなくなり、一覧からも消える。ただし公開日は最初にPublicにした日のまま変わらず、もう一度Publicにしても新着には並ばない。新着に並ぶ機会は、手順7を過ぎたら戻せない。

上げたzipに不具合があったときは、前の版のzipを上げ直す。前の版のzipは保存していないので、前のコミットから手順1で作り直す。

## 未確認

この手順は、まだ実地で通していない。手順3〜9の欄の名前は、2026-10-17時点のitch.ioの公式の説明と、その調査に基づく。

スマートフォンのブラウザで遊べるかは、確かめていない。

`media/itch/page.md`の説明文は、itch.ioのページの上での見え方を確かめていない。

---

<!-- graph:auto:start -->

## 関連ドキュメント（自動生成 / 手で編集しない）

`depends_on`: この文書が成立するために前提となるノード

- [ARCH-01 ゲームの全体構成](../10-architecture/arch-01-game-overview.md)

<!-- graph:auto:end -->
