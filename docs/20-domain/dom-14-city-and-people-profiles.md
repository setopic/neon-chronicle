---
id: DOM-14
type: domain
title: 街と人物の資料
status: stable
tags: [world, story]
depends_on: [DOM-01, DOM-08, DOM-09, DOM-10, DOM-13, DOM-15, DOM-17, DOM-18, DOM-19, DOM-20]
related: []
implemented_by:
  - game/scripts/game_state.gd
  - game/data/profiles.json
---

# 街と人物の資料

## 定義

資料は、[ネオン・シティ](./dom-01-world.md)・[企業](./dom-01-world.md)・[街の場所](./dom-15-city-places-and-powers.md)・[主人公](./dom-01-world.md)・[登場人物](./dom-10-characters.md)の1つについて、プレイヤーがいつでも読める説明である。最初は、遊んでいればすでに分かることだけを載せる。[記憶の断片](./dom-08-memory-fragments-and-endings.md)が戻ったり、[人物のイベント](./dom-13-character-events.md)や選んだ選択肢を残すイベントが起きたりすると、その資料に追記が加わる。

## 属性

資料の属性は次のとおりである。値は`game/data/profiles.json`にあり、並んだ順が画面に出る順である。

| 属性 | 型 | 必須 | 説明 |
| --- | --- | --- | --- |
| id | 文字列 | ○ | 資料を区別する名前 |
| 出るイベント | イベントのid | | 人物のイベントか、選んだ選択肢を残すイベントのid。そのイベントで選択肢を選ぶまで、資料そのものを出さない。無ければ最初から出る |
| 追記 | 追記の並び | | 並んだ順に、資料の説明の後ろへ加わる |

追記の属性は次のとおりである。

| 属性 | 型 | 必須 | 説明 |
| --- | --- | --- | --- |
| id | 文字列 | ○ | 同じ資料の中で、追記を区別する名前 |
| 要る断片 | 記憶の断片のid | | その断片が戻るまで、追記を出さない |
| 出るイベント | イベントのid | | 人物のイベントか、選んだ選択肢を残すイベントのid。そのイベントで選択肢を選ぶまで、追記を出さない |

追記は、要る断片と出るイベントのどちらか一方を持つ。表示名と文は言語ファイルにあり、データは持たない。

ほかのノードの概念に、次の属性を足す。

| 対象 | 属性 | 型 | 必須 | 説明 |
| --- | --- | --- | --- | --- |
| イベント | 選んだ選択肢を残す | 真偽 | | 真なら、人物のイベントと同じく、選んだ選択肢を[話の進み具合](./dom-13-character-events.md)に残す。資料と追記の出るイベントに使う |

載せる資料は次のとおりである。九条は、まだ名前で画面に出ないので、資料を置かない。

| 資料 | 出るイベント | 追記の要る断片・出るイベント |
| --- | --- | --- |
| ネオン・シティ | | 「計画書」「中枢サーバー」。[被験体の出どころ](./dom-20-test-subjects-origin.md)の追記は「計画書」で出る |
| 街の歴史 | | |
| [橋を架けた技師たち](./dom-17-city-history.md) | 古い銘板 | 「市の図面」のイベント・「変電所」のイベント・断片「中枢サーバー」 |
| 企業 | | |
| リンドホルム食品 | | |
| 企業区画 | | |
| 下層街 | | |
| 闇市場 | | |
| ザンダー・ファミリー | | 屋台通りの対立の3段目 |
| 屋台組合 | | 屋台通りの対立の3段目 |
| [住民の暮らし](./dom-18-resident-classes.md) | | |
| [生まれから死まで](./dom-19-resident-life-course.md) | | |
| [体の元の持ち主たち](./dom-25-body-former-owners.md) | | 元の持ち主ごとの話の2段目 |
| 自分（主人公） | | 「契約書」「名前」「計画書」「中枢サーバー」 |
| ミオ | | 「白い部屋」「計画書」 |
| ジン | | 「名前」 |
| レイ | レイの1段目 | レイの2段目。[被験体の出どころ](./dom-20-test-subjects-origin.md)の追記と、名簿の追記の2つ |

## 不変条件

- [ ] 記憶の断片で明かすことは、その断片が戻るまで、どの資料にも出ない
- [ ] 人物のイベントと、選んだ選択肢を残すイベントで分かることは、そのイベントで選択肢を選ぶまで、どの資料にも出ない
- [ ] 資料は読むだけで、ゲームの状態を変えない

## ライフサイクル

1. 最初の周から、出るイベントを持たない資料が読める
2. 記憶の断片が戻ると、その断片を要る追記が加わる。転生しても消えない
3. 人物のイベントか、選んだ選択肢を残すイベントで選択肢を選ぶと、そのイベントを出るイベントに持つ資料と追記が出る
4. 最初からやり直すと、戻った記憶の断片と[話の進み具合](./dom-13-character-events.md)が無くなるので、資料も最初の状態に戻る

## 用語

| 用語 | 意味 | 旧称 |
| --- | --- | --- |
| 資料 | ネオン・シティ・企業・街の場所・主人公・登場人物の1つについての説明。上のボタン「街と人物」から開く画面で、いつでも読める | |
| 追記 | 記憶の断片が戻るか、人物のイベントが起きると、資料の後ろに加わる文 | |

---

<!-- graph:auto:start -->

## 関連ドキュメント（自動生成 / 手で編集しない）

`depends_on`: この文書が成立するために前提となるノード

- [DOM-01 世界観](./dom-01-world.md)
- [DOM-08 記憶の断片とエンディング](./dom-08-memory-fragments-and-endings.md)
- [DOM-09 意識の写しと目覚め](./dom-09-consciousness-copy.md)
- [DOM-10 登場人物](./dom-10-characters.md)
- [DOM-13 人物のイベント](./dom-13-character-events.md)
- [DOM-15 街の場所と勢力](./dom-15-city-places-and-powers.md)
- [DOM-17 街の歴史](./dom-17-city-history.md)
- [DOM-18 住民の階級と暮らし](./dom-18-resident-classes.md)
- [DOM-19 住民の生まれから死まで](./dom-19-resident-life-course.md)
- [DOM-20 被験体の出どころ](./dom-20-test-subjects-origin.md)

このノードを参照しているノード

- (decides) [ADR-0015 街と人物の資料を上のボタンから開き、記憶の断片が戻るまで追記を伏せる](../50-adr/adr-0015-profiles-revealed-by-fragments.md)
- (decides) [ADR-0018 街を複数の企業が分け合い、場所と住人をイベントと資料に出す](../50-adr/adr-0018-companies-places-and-residents.md)
- (decides) [ADR-0019 衣食住は文だけで書き、食べ物は合成食の企業が握る](../50-adr/adr-0019-food-clothing-housing.md)
- (decides) [ADR-0021 電気はヨミ・システムズ、水はリンドホルム食品が握り、街に公共の交通は置かない](../50-adr/adr-0021-city-infrastructure.md)
- (decides) [ADR-0024 下層街に、ギャングのザンダー一家と住人の屋台組合を置く](../50-adr/adr-0024-lower-city-gang-and-union.md)
- (decides) [ADR-0025 企業の時代より前の街を市とし、市の財政破綻で企業の時代が始まったことにする](../50-adr/adr-0025-city-history-before-corporations.md)
- (decides) [ADR-0027 企業の階級と下層街の稼ぎを決め、身元で橋の行き来を分ける](../50-adr/adr-0027-resident-classes-and-identity.md)
- (decides) [ADR-0028 子どもは親の暮らしの中で育ち、下層街の死者の部品は闇医者が闇市場へ流す](../50-adr/adr-0028-life-course-and-body-parts.md)
- (decides) [ADR-0029 ザンダー一家をザンダー・ファミリーと呼ぶ](../50-adr/adr-0029-zander-family-name.md)
- (decides) [ADR-0030 被験体は借金の契約で集め、使い捨ての体は闇市場の部品で組み立てる](../50-adr/adr-0030-test-subjects-and-bodies.md)
- (decides) [ADR-0031 日本のやくざや的屋に寄った語を、欧米の街でも通じる語に改める](../50-adr/adr-0031-western-terms.md)
- (decides) [ADR-0036 橋を架けた技師たちの記録を、イベントと資料の追記で集める](../50-adr/adr-0036-bridge-engineers-records.md)
- (decides) [ADR-0038 ザンダー・ファミリーと屋台組合の対立を、3段の勢力の話にする](../50-adr/adr-0038-stall-street-feud.md)
- (decides) [ADR-0041 体の元の持ち主の記憶を、体ごとの2段の話にする](../50-adr/adr-0041-former-owner-memories.md)
- (depends_on) [DOM-16 街の地図](./dom-16-city-map.md)

<!-- graph:auto:end -->
