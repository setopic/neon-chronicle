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
  subgraph index["目次"]
    IDX-ADR["IDX-ADR<br/>決定記録"]
    IDX-ARCH["IDX-ARCH<br/>アーキテクチャ"]
    IDX-CON["IDX-CON<br/>契約"]
    IDX-DOM["IDX-DOM<br/>ドメイン"]
    IDX-ROOT["IDX-ROOT<br/>ドキュメントグラフのルート"]
    IDX-UC["IDX-UC<br/>ユースケース"]
  end
  subgraph meta["メタ / 規約"]
    META-01["META-01<br/>グラフの規約"]
    META-02["META-02<br/>ノード種別と層"]
    META-03["META-03<br/>本文のレビュー（AI）"]
    META-04["META-04<br/>文書と実装を同じリポジトリに置く"]
    META-05["META-05<br/>開発の流れ"]
    META-06["META-06<br/>開発の原則"]
    META-07["META-07<br/>issueとPRの流れ"]
  end
  subgraph architecture["アーキテクチャ"]
    ARCH-01["ARCH-01<br/>ゲームの全体構成"]
  end
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
  end
  subgraph usecase["ユースケース"]
    UC-01["UC-01<br/>itch.ioでブラウザ版を公開する"]
  end
  subgraph adr["決定記録"]
    ADR-0001["ADR-0001<br/>設計文書をグラフとして管理する"]
    ADR-0002["ADR-0002<br/>素材のライセンスの一覧をゲームの中に置く"]
    ADR-0003["ADR-0003<br/>物語の文書を既定の種別で書く"]
    ADR-0004["ADR-0004<br/>イベントの起き方と結果を決まった量で表す"]
    ADR-0005["ADR-0005<br/>クロニクルの物語文を仕事と選択と倒れた理由から組み立てる"]
    ADR-0006["ADR-0006<br/>記憶の断片を順に戻し、最後の仕事の選択でエンディングを分ける"]
    ADR-0007["ADR-0007<br/>閉じていた時間を、開いたときにまとめて進める"]
    ADR-0008["ADR-0008<br/>音楽と効果音をスクリプトで作り、最初の操作から鳴らす"]
    ADR-0009["ADR-0009<br/>生き直しを闇医者が乗っ取った企業の計画として説明し、4人の人物を置く"]
    ADR-0010["ADR-0010<br/>ミオの一言を転生の画面に出し、人物を目覚めと断片の文に入れる"]
    ADR-0011["ADR-0011<br/>倒れた理由の句をイベントごとに書く"]
    ADR-0012["ADR-0012<br/>転生のときに4種類の体から1つを選ぶ"]
    ADR-0013["ADR-0013<br/>周の始まりにジンの依頼を1つ示し、果たせば記憶ポイントを上乗せする"]
    ADR-0014["ADR-0014<br/>人物のイベントを1周に1段ずつ進め、前の段の選択で文と選択肢を変える"]
    ADR-0015["ADR-0015<br/>街と人物の資料を上のボタンから開き、記憶の断片が戻るまで追記を伏せる"]
    ADR-0016["ADR-0016<br/>インプラントと体の種類の効果を画面の文に出す"]
    ADR-0017["ADR-0017<br/>画面の右上のボタンとダイアログの見た目をそろえる"]
    ADR-0018["ADR-0018<br/>街を複数の企業が分け合い、場所と住人をイベントと資料に出す"]
    ADR-0019["ADR-0019<br/>衣食住は文だけで書き、食べ物は合成食の企業が握る"]
    ADR-0020["ADR-0020<br/>街を区画と3本の橋で分け、地図は設計文書の図に残す"]
    ADR-0021["ADR-0021<br/>電気はヨミ・システムズ、水はリンドホルム食品が握り、街に公共の交通は置かない"]
  end
  ADR-0001 -.->|decides| META-01
  ADR-0001 -.->|decides| ARCH-01
  ADR-0002 -.->|related| UC-01
  ADR-0002 -.->|decides| ARCH-01
  ADR-0003 -.->|decides| DOM-01
  ADR-0003 -.->|decides| DOM-02
  ADR-0003 -.->|decides| DOM-03
  ADR-0003 -.->|decides| DOM-04
  ADR-0003 -.->|decides| DOM-05
  ADR-0004 -.->|decides| DOM-06
  ADR-0004 -.->|decides| ARCH-01
  ADR-0005 -.->|decides| DOM-07
  ADR-0005 -.->|decides| ARCH-01
  ADR-0006 -.->|decides| DOM-08
  ADR-0006 -.->|decides| DOM-01
  ADR-0006 -.->|decides| ARCH-01
  ADR-0007 -.->|decides| DOM-02
  ADR-0007 -.->|decides| ARCH-01
  ADR-0008 -.->|decides| ARCH-01
  ADR-0009 -.->|decides| DOM-09
  ADR-0009 -.->|decides| DOM-10
  ADR-0009 -.->|decides| DOM-01
  ADR-0010 -.->|decides| DOM-10
  ADR-0011 ==>|supersedes| ADR-0005
  ADR-0011 -.->|decides| DOM-07
  ADR-0012 -.->|decides| DOM-11
  ADR-0013 -.->|decides| DOM-12
  ADR-0014 -.->|decides| DOM-13
  ADR-0014 -.->|decides| DOM-10
  ADR-0015 -.->|decides| DOM-14
  ADR-0016 -.->|decides| DOM-04
  ADR-0016 -.->|decides| DOM-11
  ADR-0017 -.->|decides| ARCH-01
  ADR-0018 -.->|decides| DOM-01
  ADR-0018 -.->|decides| DOM-14
  ADR-0018 -.->|decides| DOM-15
  ADR-0019 -.->|decides| DOM-14
  ADR-0019 -.->|decides| DOM-15
  ADR-0020 -.->|decides| DOM-15
  ADR-0021 -.->|decides| DOM-14
  ADR-0021 -.->|decides| DOM-15
  DOM-02 -->|depends_on| DOM-01
  DOM-03 -->|depends_on| DOM-02
  DOM-04 -->|depends_on| DOM-02
  DOM-04 -->|depends_on| DOM-03
  DOM-05 -->|depends_on| DOM-02
  DOM-05 -->|depends_on| DOM-03
  DOM-05 -->|depends_on| DOM-04
  DOM-06 -->|depends_on| DOM-01
  DOM-06 -->|depends_on| DOM-02
  DOM-06 -->|depends_on| DOM-03
  DOM-07 -->|depends_on| DOM-02
  DOM-07 -->|depends_on| DOM-03
  DOM-07 -->|depends_on| DOM-05
  DOM-07 -->|depends_on| DOM-06
  DOM-08 -->|depends_on| DOM-01
  DOM-08 -->|depends_on| DOM-02
  DOM-08 -->|depends_on| DOM-03
  DOM-08 -->|depends_on| DOM-05
  DOM-08 -->|depends_on| DOM-06
  DOM-08 -->|depends_on| DOM-07
  DOM-09 -->|depends_on| DOM-01
  DOM-09 -->|depends_on| DOM-02
  DOM-09 -->|depends_on| DOM-03
  DOM-09 -->|depends_on| DOM-04
  DOM-09 -->|depends_on| DOM-05
  DOM-09 -->|depends_on| DOM-08
  DOM-10 -->|depends_on| DOM-01
  DOM-10 -->|depends_on| DOM-06
  DOM-10 -->|depends_on| DOM-08
  DOM-10 -->|depends_on| DOM-09
  DOM-11 -->|depends_on| DOM-02
  DOM-11 -->|depends_on| DOM-03
  DOM-11 -->|depends_on| DOM-05
  DOM-11 -->|depends_on| DOM-10
  DOM-12 -->|depends_on| DOM-03
  DOM-12 -->|depends_on| DOM-05
  DOM-12 -->|depends_on| DOM-09
  DOM-12 -->|depends_on| DOM-10
  DOM-13 -->|depends_on| DOM-05
  DOM-13 -->|depends_on| DOM-06
  DOM-13 -->|depends_on| DOM-08
  DOM-13 -->|depends_on| DOM-10
  DOM-14 -->|depends_on| DOM-01
  DOM-14 -->|depends_on| DOM-08
  DOM-14 -->|depends_on| DOM-09
  DOM-14 -->|depends_on| DOM-10
  DOM-14 -->|depends_on| DOM-13
  DOM-14 -->|depends_on| DOM-15
  DOM-15 -->|depends_on| DOM-01
  DOM-15 -->|depends_on| DOM-06
  DOM-15 -->|depends_on| DOM-08
  DOM-15 -->|depends_on| DOM-09
  META-01 -.->|related| META-02
  META-01 -.->|related| META-03
  META-01 -.->|related| META-04
  META-01 -.->|related| META-05
  META-01 -.->|related| META-07
  META-02 -.->|related| META-01
  META-03 -.->|related| META-01
  META-04 -.->|related| META-01
  META-04 -.->|related| META-05
  META-04 -.->|related| META-06
  META-05 -.->|related| META-01
  META-05 -.->|related| META-04
  META-06 -.->|related| META-04
  META-07 -.->|related| META-01
  UC-01 -->|depends_on| ARCH-01
  UC-01 -.->|related| ADR-0002
  classDef draft stroke-dasharray: 4\,3;
  classDef deprecated opacity:0.5;
  class UC-01 draft;
  class ADR-0005 deprecated;
```

<!-- graph:diagram:end -->
