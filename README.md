# ネオン・クロニクル（Neon Chronicle）

サイバーパンクの街で仕事をこなし、体が尽きたら記憶を持って新しい体で目覚める、放置と転生のゲームである。Godot 4.7.2とGDScriptで作っている。

まず無料のブラウザ版をitch.ioで出し、あとからPC版（itch.io・Steam）でMODを受け付ける。ブラウザ版ではMODを読まない。

## 読む順番

| 何を知りたいか | どこを読むか |
| --- | --- |
| ゲームの遊び方と、`game/`の中身 | [game/README.md](game/README.md) |
| 本体の構成と、MODとの境界 | [ARCH-01](docs/10-architecture/arch-01-game-overview.md) |
| 設計文書の置き方 | [docs/index.md](docs/index.md) |
| 開発の流れ | [META-05](docs/00-meta/dev-flow.md)と[META-07](docs/00-meta/issue-pr-flow.md) |

## 構成

| 場所 | 中身 |
| --- | --- |
| `game/` | Godotのプロジェクト |
| `docs/` | 設計文書（グラフ）。[graph-project-template](https://github.com/setopic/graph-project-template)から派生している |
| `tools/graph/` | 設計文書の検証ツール。テンプレートが配る |
| `media/screenshots/` | ストアのページに使う画面写真 |

## 未確定なもの

音楽と効果音は、まだ決まっていない。残りの作業はGitHubのissueとProjectで管理する。

## 設計文書の図

<!-- graph:diagram:start -->

<!-- この図は render --into が生成する。手で編集しない -->

```mermaid
graph LR
  %% ほかのdepends_onを辿れば分かる依存を76本省いた（render --reduce）
  subgraph domain["ドメイン"]
    DOM-01["DOM-01<br/>世界観"]
    DOM-02["DOM-02<br/>周と体"]
    DOM-03["DOM-03<br/>仕事とスキル"]
    DOM-04["DOM-04<br/>インプラント"]
    DOM-05["DOM-05<br/>転生と永続強化"]
    DOM-06["DOM-06<br/>イベントと選択肢"]
    DOM-07["DOM-07<br/>クロニクルの物語"]
    DOM-08["DOM-08<br/>記憶の断片とエンディング"]
    DOM-09["DOM-09<br/>意識の写しと目覚め"]
    DOM-10["DOM-10<br/>登場人物"]
    DOM-11["DOM-11<br/>体の種類"]
    DOM-12["DOM-12<br/>ジンの依頼"]
    DOM-13["DOM-13<br/>人物のイベント"]
    DOM-14["DOM-14<br/>街と人物の資料"]
    DOM-15["DOM-15<br/>街の場所と勢力"]
    DOM-16["DOM-16<br/>街の地図"]
    DOM-17["DOM-17<br/>街の歴史"]
    DOM-18["DOM-18<br/>住民の階級と暮らし"]
    DOM-19["DOM-19<br/>住民の生まれから死まで"]
    DOM-20["DOM-20<br/>被験体の出どころ"]
    DOM-21["DOM-21<br/>縛りの周"]
    DOM-22["DOM-22<br/>勢力の評判"]
    DOM-23["DOM-23<br/>屋台通りの対立"]
    DOM-24["DOM-24<br/>仕事の区画と身元"]
    DOM-25["DOM-25<br/>体の元の持ち主と特性"]
    DOM-26["DOM-26<br/>体の容量とインプラントの取り外し"]
    DOM-27["DOM-27<br/>前の周の跡"]
    DOM-28["DOM-28<br/>イベントの波"]
    DOM-29["DOM-29<br/>目覚めの日"]
    DOM-30["DOM-30<br/>分岐図"]
    DOM-31["DOM-31<br/>話の選び直し"]
    DOM-32["DOM-32<br/>スキルの声"]
    DOM-33["DOM-33<br/>街の噂"]
    DOM-34["DOM-34<br/>第二部の暮らし"]
  end
  DOM-02 -->|depends_on| DOM-01
  DOM-03 -->|depends_on| DOM-02
  DOM-04 -->|depends_on| DOM-03
  DOM-05 -->|depends_on| DOM-04
  DOM-06 -->|depends_on| DOM-03
  DOM-07 -->|depends_on| DOM-05
  DOM-07 -->|depends_on| DOM-06
  DOM-08 -->|depends_on| DOM-07
  DOM-09 -->|depends_on| DOM-08
  DOM-10 -->|depends_on| DOM-09
  DOM-11 -->|depends_on| DOM-10
  DOM-12 -->|depends_on| DOM-10
  DOM-13 -->|depends_on| DOM-10
  DOM-14 -->|depends_on| DOM-13
  DOM-14 -->|depends_on| DOM-20
  DOM-15 -->|depends_on| DOM-09
  DOM-16 -->|depends_on| DOM-14
  DOM-17 -->|depends_on| DOM-15
  DOM-18 -->|depends_on| DOM-17
  DOM-19 -->|depends_on| DOM-18
  DOM-20 -->|depends_on| DOM-11
  DOM-20 -->|depends_on| DOM-19
  DOM-21 -->|depends_on| DOM-07
  DOM-22 -->|depends_on| DOM-15
  DOM-23 -->|depends_on| DOM-13
  DOM-23 -->|depends_on| DOM-22
  DOM-24 -->|depends_on| DOM-16
  DOM-25 -->|depends_on| DOM-20
  DOM-25 -->|depends_on| DOM-23
  DOM-26 -->|depends_on| DOM-11
  DOM-27 -->|depends_on| DOM-09
  DOM-28 -->|depends_on| DOM-06
  DOM-29 -->|depends_on| DOM-13
  DOM-29 -->|depends_on| DOM-20
  DOM-29 -->|depends_on| DOM-22
  DOM-30 -->|depends_on| DOM-25
  DOM-30 -->|depends_on| DOM-29
  DOM-31 -->|depends_on| DOM-30
  DOM-32 -->|depends_on| DOM-27
  DOM-33 -->|depends_on| DOM-22
  DOM-33 -->|depends_on| DOM-24
  DOM-34 -->|depends_on| DOM-24
  classDef draft stroke-dasharray: 4\,3;
  classDef deprecated opacity:0.5;
```

<!-- graph:diagram:end -->
