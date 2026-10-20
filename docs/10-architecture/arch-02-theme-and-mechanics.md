---
id: ARCH-02
type: architecture
title: 主題と仕組みの対応
status: stable
tags: [game, story]
depends_on: []
related: []
---

# 主題と仕組みの対応

## 解決したい構造上の問題

本作の主題は「使い捨て」で、警告として描く（[ADR-0070](../50-adr/adr-0070-theme-disposable.md)）。仕組みを足すときや直すときに、主題に合うかをこの文書の表と照らして決める。

主題は2つの側から伝える。1つは、企業が人を使い捨てにする街である。もう1つは、遊ぶ人も体を使い捨てにして強くなることで、遊ぶ人に企業と同じことをしていると気づかせる。どのエンディングでも、企業は倒れずに残る。

## 構成

この表は、ドメインのノードと突き合わせる手段が無い。ARCH-02は`depends_on`を持たないので、`G015`が一度も挙げない。仕組みを足したら、ここを手で確かめること。

| 仕組み | ノード | 主題とのかかわり |
| --- | --- | --- |
| 被験体の出どころ | [DOM-20](../20-domain/dom-20-test-subjects-origin.md) | 企業が借金を買い取り、人を被験体にする。意識を読み込む体は、下層街の死者から取り出した部品の寄せ集めである |
| 意識の写し | [DOM-09](../20-domain/dom-09-consciousness-copy.md) | 企業は抜き取った意識を使い捨ての体に入れて汚れ仕事をさせ、体が倒れたら写しを新しい体へ読み込み直す。主人公の写しは廃棄した写しとして記録されている |
| 住民の階級と身元 | [DOM-18](../20-domain/dom-18-resident-classes.md) | 社員や私兵は、解雇されると社の身元を消され、社宅を出される |
| 住民の生まれから死まで | [DOM-19](../20-domain/dom-19-resident-life-course.md) | 社が貸したインプラントは、死んだあとに回収される |
| 街の歴史 | [DOM-17](../20-domain/dom-17-city-history.md) | 市が破綻し、発電所や浄水場が企業に売られた |
| 周と体 | [DOM-02](../20-domain/dom-02-life-and-body.md) | 遊ぶ人の体は、耐久が尽きると使えなくなる |
| 仕事 | [DOM-03](../20-domain/dom-03-jobs-and-skills.md) | 遊ぶ人は、体の耐久を減らしながらクレジットを稼ぐ |
| 転生と永続強化 | [DOM-05](../20-domain/dom-05-rebirth.md) | 遊ぶ人は、体が倒れるたびに記憶ポイントを得て強くなる |
| 体の種類 | [DOM-11](../20-domain/dom-11-body-types.md) | 遊ぶ人は、次に使い捨てる体を選ぶ |
| 体の元の持ち主 | [DOM-25](../20-domain/dom-25-body-former-owners.md) | 遊ぶ人は、死者の神経の型が残した特性を力として使う |
| インプラントと体の容量 | [DOM-04](../20-domain/dom-04-implants.md)・[DOM-26](../20-domain/dom-26-body-capacity.md) | 体に組み込んだインプラントは、外しても代金が戻らない |
| 前の周の跡 | [DOM-27](../20-domain/dom-27-traces-of-last-life.md) | 体は使い捨てでも、街の人は前の周の主人公のしたことに反応する |
| 登場人物と人物のイベント | [DOM-10](../20-domain/dom-10-characters.md)・[DOM-13](../20-domain/dom-13-character-events.md) | 体が毎周替わることを、人間関係として感じさせる |
| クロニクルの物語 | [DOM-07](../20-domain/dom-07-chronicle-story.md) | 使い終えた体の1周を、物語文として残す |
| エンディング | [DOM-08](../20-domain/dom-08-memory-fragments-and-endings.md)・[DOM-29](../20-domain/dom-29-day-of-waking.md) | 被験体を全員目覚めさせても、企業は残る |

次の仕組みは、主題と関わらない。主題に合うかを照らさずに足してよい。

| 仕組み | ノード |
| --- | --- |
| イベントと選択肢、イベントの波 | [DOM-06](../20-domain/dom-06-events.md)・[DOM-28](../20-domain/dom-28-event-waves.md) |
| 地図と分岐図 | [DOM-16](../20-domain/dom-16-city-map.md)・[DOM-30](../20-domain/dom-30-branch-chart.md) |
| 縛りの周と話の選び直し | [DOM-21](../20-domain/dom-21-challenges.md)・[DOM-31](../20-domain/dom-31-choosing-again.md) |

## 境界

主題と照らすのは、遊ぶ人が触れる仕組みと物語である。画面の構成やMODの境界のような技術の構成（[ARCH-01](./arch-01-game-overview.md)）は照らさない。

## 前提と制約

企業を倒す結末を足すと、警告として描く方針が成り立たなくなる。そのときは、新しいADRで決め直す。

## 未決事項

なし

---

<!-- graph:auto:start -->

## 関連ドキュメント（自動生成 / 手で編集しない）

このノードを参照しているノード

- (decides) [ADR-0070 本作の主題を「使い捨て」とし、警告として描く](../50-adr/adr-0070-theme-disposable.md)

<!-- graph:auto:end -->
