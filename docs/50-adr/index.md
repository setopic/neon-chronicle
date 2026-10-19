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
- [ADR-0023 橋に人名を付け、地図を地形の分かる描き方にする](./adr-0023-bridge-names-and-terrain-map.md)
- [ADR-0024 下層街に、ギャングのザンダー一家と住人の屋台組合を置く](./adr-0024-lower-city-gang-and-union.md)
- [ADR-0025 企業の時代より前の街を市とし、市の財政破綻で企業の時代が始まったことにする](./adr-0025-city-history-before-corporations.md)
- [ADR-0026 屋台組合が、台帳でみかじめを割り振り、外から来た人に住む場所を割り振る](./adr-0026-union-ledger-and-housing.md)
- [ADR-0027 企業の階級と下層街の稼ぎを決め、身元で橋の行き来を分ける](./adr-0027-resident-classes-and-identity.md)
- [ADR-0028 子どもは親の暮らしの中で育ち、下層街の死者の部品は闇医者が闇市場へ流す](./adr-0028-life-course-and-body-parts.md)
- [ADR-0029 ザンダー一家をザンダー・ファミリーと呼ぶ](./adr-0029-zander-family-name.md)
- [ADR-0030 被験体は借金の契約で集め、使い捨ての体は闇市場の部品で組み立てる](./adr-0030-test-subjects-and-bodies.md)
- [ADR-0031 日本のやくざや的屋に寄った語を、欧米の街でも通じる語に改める](./adr-0031-western-terms.md)
- [ADR-0032 体の質を前の周の稼ぎで決め、記憶ポイントを経験から出す](./adr-0032-body-quality-and-memory-software.md)
- [ADR-0033 永続強化を増やし、どちらか一方しか取れない組を作る](./adr-0033-upgrade-groups.md)
- [ADR-0034 ジンの依頼を2つ並べ、受けるものを選ばせる](./adr-0034-choose-jin-request.md)
- [ADR-0035 転生のときに縛りを1つ選び、守り通せば記憶ポイントを上乗せする](./adr-0035-challenges.md)
- [ADR-0036 橋を架けた技師たちの記録を、イベントと資料の追記で集める](./adr-0036-bridge-engineers-records.md)
- [ADR-0037 4つの勢力に評判を持たせ、周をまたいで残す](./adr-0037-faction-reputation.md)
- [ADR-0038 ザンダー・ファミリーと屋台組合の対立を、3段の勢力の話にする](./adr-0038-stall-street-feud.md)
- [ADR-0039 仕事に区画を持たせ、傭兵の仕事には偽の身元を要る](./adr-0039-job-districts-and-identity.md)
- [ADR-0040 体の種類ごとに元の持ち主を1人決め、その特性を持たせる](./adr-0040-body-former-owners.md)
- [ADR-0041 体の元の持ち主の記憶を、体ごとの2段の話にする](./adr-0041-former-owner-memories.md)
- [ADR-0042 体の種類ごとに容量を持たせ、インプラントを外せるようにする](./adr-0042-body-capacity.md)
- [ADR-0043 ミオにも3段の人物のイベントを持たせる](./adr-0043-mio-character-events.md)
- [ADR-0044 1つ前の周の選択を、次の周の跡のイベントに出す](./adr-0044-traces-of-last-life.md)
- [ADR-0045 イベントの起きやすさに、緊張と耐久で波を付ける](./adr-0045-event-waves.md)
- [ADR-0046 レイとの約束と屋台組合の評判で開く、3つ目のエンディングを足す](./adr-0046-third-ending.md)
- [ADR-0047 話とエンディングの分岐図を、街と人物の画面の3つ目のタブに出す](./adr-0047-branch-chart.md)
- [ADR-0048 話の段と永続強化の組を、いつでも選び直せるようにする](./adr-0048-no-point-of-no-return.md)
- [ADR-0049 転生の画面とメインの画面を1280x720に収める](./adr-0049-fit-screens-1280x720.md)
- [ADR-0050 話の選び直しを、エンディングにたどり着いてから使えるようにする](./adr-0050-choose-again-after-ending.md)
- [ADR-0051 仕事を、終わったら報酬が入る形にする](./adr-0051-job-pays-on-completion.md)
- [ADR-0052 画面の見た目の方向と、その土台を決める](./adr-0052-ui-style-foundation.md)
- [ADR-0053 仕事の様子を、ログの左に線と点で描く](./adr-0053-job-scene.md)
- [ADR-0054 仕事の1回を、ミニゲームで置き換えて遊べるようにする](./adr-0054-minigame-frame.md)
- [ADR-0055 ハッカーの仕事のミニゲームを、符号の表を縦横にたどる遊びにする](./adr-0055-hacking-minigame.md)
- [ADR-0056 運び屋の仕事のミニゲームを、追っ手をかわして升目を進む遊びにする](./adr-0056-courier-minigame.md)
- [ADR-0057 傭兵の仕事のミニゲームを、窓に出る敵を撃つ遊びにする](./adr-0057-mercenary-minigame.md)
<!-- graph:children:end -->

## 追加するとき

```bash
python -m tools.graph new --type adr --id ADR-0002 --title "..." --slug some-slug
```
