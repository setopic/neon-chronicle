---
id: DOM-01
type: domain
title: 世界観
status: stable
tags: [world]
depends_on: []
related: []
---

# 世界観

## 定義

ゲームの舞台と主人公の設定である。舞台は巨大企業が支配する未来都市で、主人公は意識をデータにされたハッカーである。主人公は体が使えなくなっても、新しい体で目覚める。

## 属性

| 属性 | 型 | 必須 | 説明 |
| --- | --- | --- | --- |
| 舞台 | 都市 | ○ | ネオン・シティ |
| 主人公 | 人物 | ○ | 意識をデータにされたハッカー。名前は決めていない |
| 最終目標 | 文 | ○ | 企業の中枢サーバーにたどり着き、自分の本当の体を取り戻す |

最終目標にたどり着くまでの筋書きとエンディングは、[DOM-08](./dom-08-memory-fragments-and-endings.md)が決めている。

## 不変条件

- [ ] 主人公は1人である。体を乗り換えても、別の人物にはならない
- [ ] 主人公の意識は、体が使えなくなっても消えない

企業が主人公の意識をデータにした経緯は、生き直すたびに少しずつ分かっていく。その分かり方は、DOM-08の記憶の断片が決めている。

主人公が新しい体で目覚める仕組みは[DOM-09](./dom-09-consciousness-copy.md)が、名前のある人物は[DOM-10](./dom-10-characters.md)が決めている。

## 用語

| 用語 | 意味 | 旧称 |
| --- | --- | --- |
| ネオン・シティ | ゲームの舞台になる未来都市。巨大企業が支配している | |
| 企業 | ネオン・シティを支配する巨大企業。主人公の意識をデータにした側で、仕事の依頼主にも、敵にもなる | |
| 主人公 | プレイヤーが動かす人物。意識をデータにされたハッカーで、体を乗り換えながら生き直す | |

---

<!-- graph:auto:start -->

## 関連ドキュメント（自動生成 / 手で編集しない）

このノードを参照しているノード

- (decides) [ADR-0003 物語の文書を既定の種別で書く](../50-adr/adr-0003-story-docs-default-types.md)
- (decides) [ADR-0006 記憶の断片を順に戻し、最後の仕事の選択でエンディングを分ける](../50-adr/adr-0006-fragments-and-endings.md)
- (decides) [ADR-0009 生き直しを闇医者が乗っ取った企業の計画として説明し、4人の人物を置く](../50-adr/adr-0009-world-rationale-and-characters.md)
- (depends_on) [DOM-02 周と体](./dom-02-life-and-body.md)
- (depends_on) [DOM-06 イベントと選択肢](./dom-06-events.md)
- (depends_on) [DOM-08 記憶の断片とエンディング](./dom-08-memory-fragments-and-endings.md)
- (depends_on) [DOM-09 意識の写しと目覚め](./dom-09-consciousness-copy.md)
- (depends_on) [DOM-10 登場人物](./dom-10-characters.md)
- (depends_on) [DOM-14 街と人物の資料](./dom-14-city-and-people-profiles.md)

<!-- graph:auto:end -->
