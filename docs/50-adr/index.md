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
- [ADR-0008 音楽と効果音をスクリプトで作り、最初の操作から鳴らす](./adr-0008-audio.md)
- [ADR-0009 生き直しを闇医者が乗っ取った企業の計画として説明し、4人の人物を置く](./adr-0009-world-rationale-and-characters.md)
- [ADR-0010 ミオの一言を転生の画面に出し、人物を目覚めと断片の文に入れる](./adr-0010-characters-in-screen-text.md)
- [ADR-0011 倒れた理由の句をイベントごとに書く](./adr-0011-fall-phrase-per-event.md)
- [ADR-0012 転生のときに4種類の体から1つを選ぶ](./adr-0012-choose-body-on-rebirth.md)
- [ADR-0013 周の始まりにジンの依頼を1つ示し、果たせば記憶ポイントを上乗せする](./adr-0013-jin-requests.md)
- [ADR-0014 人物のイベントを1周に1段ずつ進め、前の段の選択で文と選択肢を変える](./adr-0014-character-events-across-lives.md)
- [ADR-0015 街と人物の資料を上のボタンから開き、記憶の断片が戻るまで追記を伏せる](./adr-0015-profiles-revealed-by-fragments.md)
- [ADR-0016 インプラントと体の種類の効果を画面の文に出す](./adr-0016-show-effects-on-screen.md)
- [ADR-0017 画面の右上のボタンとダイアログの見た目をそろえる](./adr-0017-header-and-dialog-look.md)
- [ADR-0018 街を複数の企業が分け合い、場所と住人をイベントと資料に出す](./adr-0018-companies-places-and-residents.md)
- [ADR-0019 衣食住は文だけで書き、食べ物は合成食の企業が握る](./adr-0019-food-clothing-housing.md)
- [ADR-0020 街を区画と3本の橋で分け、地図は設計文書の図に残す](./adr-0020-city-districts-and-map.md)
- [ADR-0021 電気はヨミ・システムズ、水はリンドホルム食品が握り、街に公共の交通は置かない](./adr-0021-city-infrastructure.md)
- [ADR-0022 街の地図を「街と人物」の画面にタブで出し、中枢サーバーは断片が戻るまで伏せる](./adr-0022-city-map-in-game.md)
<!-- graph:children:end -->

## 追加するとき

```bash
python -m tools.graph new --type adr --id ADR-0002 --title "..." --slug some-slug
```
