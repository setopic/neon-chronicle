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

ストーリー、音楽と効果音、オフライン中の進行は、まだ決まっていない。残りの作業はGitHubのissueとProjectで管理する。

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
```

<!-- graph:diagram:end -->
