---
id: IDX-ADR
type: index
title: 決定記録
status: stable
tags: [index]
---

# 決定記録 / ADR（横断）

決定と、その理由と、却下した案を残す。ADRは層のルールの対象外なので、
どの層のノードにも`decides`を張れる。

決定を変えるときは、既存のADRを書き換えず、新しいADRを起こして`supersedes`で繋ぐ。
置き換えられた側は`status: deprecated`にする。番号は4桁のゼロ埋めで振り、欠番を作らない。

## ノード一覧

<!-- graph:children:start -->
- [ADR-0001 設計文書をグラフとして管理する](./adr-0001-graph-driven-docs.md)
- [ADR-0002 素材のライセンスの一覧をゲームの中に置く](./adr-0002-asset-licenses-in-game.md)
- [ADR-0003 物語の文書を既定の種別で書く](./adr-0003-story-docs-default-types.md)
- [ADR-0004 イベントの起き方と結果を決まった量で表す](./adr-0004-event-rules.md)
- [ADR-0005 クロニクルの物語文を仕事と選択と倒れた理由から組み立てる](./adr-0005-chronicle-story.md)
- [ADR-0006 記憶の断片を順に戻し、最後の仕事の選択でエンディングを分ける](./adr-0006-fragments-and-endings.md)
- [ADR-0007 閉じていた時間を、開いたときにまとめて進める](./adr-0007-away-progress.md)
<!-- graph:children:end -->

## 追加するとき

```bash
python -m tools.graph new --type adr --id ADR-0002 --title "..." --slug some-slug
```
