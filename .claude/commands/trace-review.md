---
description: 閉じたissue・TODO・Projectを読み、文書への移し忘れや止まった項目を表で報告する。読むだけで、GitHubには書かない。
---

# トレーサビリティを点検する

この手順は、持ち主の手元のPCで、持ち主が呼んだときだけ回す。GitHubの読み取り専用のMCPサーバー（`mcp__github__*`）が、このPCにしか入っていないからである。定期実行は付けていない。

結果はチャットに表で出すだけにする。issueやコメント、Projectの欄には書かない。直すものが見つかったら、持ち主に`/new-issue`で立てるよう促す。立てるかどうかは持ち主が決める。

どのツールも、`owner`は`setopic`、`repo`は`neon-chronicle`を渡す。Projectは、ユーザー`setopic`の3番である。

## 1. 閉じたissueから、文書へ移したかの手がかりを見る

META-07は、issueを閉じる前に決まったことを文書へ移したかを、「機械で強制できないもの」に挙げている。ここでは、目で確かめる前の手がかりとして、閉じたPRが「対応するノード」にノードのidを書いているかを見る。idがあれば、どの文書を読めば移したかを確かめられる。

閉じたissueは数が多く、本文を読むと文脈が大きくなる。そのため、この節の読み取りは`quick-task`のサブエージェントに任せ、気になる点のあるissueの行だけを受け取る。サブエージェントには、次の手順をそのまま渡す。

1. `list_issues`に`state: CLOSED`と`fields: ["number", "title", "labels"]`を渡し、閉じたissueを全部読む。`pageInfo.hasNextPage`が続く限り、`after`にカーソルを渡して送る
2. 各issueを`issue_read`の`get`で読む。`state_reason`が`completed`でないもの（取り下げ・重複）は除く
3. `closed_by_pull_requests`の`references`にあるPRを、`pull_request_read`の`get`で読む。本文の`## 対応するノード`の節から、次の節の見出しまでを取り出す
4. 節の中に、`DOM-34`や`ADR-0078`のようなノードのid（英大文字と数字を`-`で繋いだもの）があるかを見る

挙げるのは、次の3つにあたるissueである。

| 気になる点 | 次の一手 |
| --- | --- |
| 閉じたPRが無い | 手で閉じたissueである。決まったことがどの文書にあるかを、持ち主に確かめる |
| PRの「対応するノード」が`なし`だけ | 文書の要らない変更だったかを、issueの本文と見比べる |
| PRに「対応するノード」の節が無いか、節にidが無い | PRの差分から触った文書を探し、移したかを見る |

ラベルの無いissue（計画のissueなど）も、同じように見る。挙がっても、文書の要らないissueなら「問題なし」として表に残す。

## 2. 条件が揃ったTODOを探す

`list_issues`に`state: OPEN`、`labels: ["TODO"]`、`fields: ["number", "title", "body"]`を渡し、開いているTODOを本文ごと読む。条件は、本文の`## いつ回すか`と`## なぜいまやらないか`の節にある。雛形より前に立てたTODOでは、`## 着手する条件`の節にある。

節に`#182`のようなissueの番号があれば、`issue_read`の`get`でその状態を見る。全部が閉じていれば、条件が揃ったものとして挙げる。

条件がマイルストーンで書いてあるとき（「マイルストーンのissueがすべて閉じている」など）は、MCPにマイルストーンで絞る読み方が無いので、`gh`で開いているissueの数を見る。

```bash
gh api repos/setopic/neon-chronicle/milestones --jq '.[] | "\(.title) open=\(.open_issues)"'
```

条件が機能の名前で書いてあるとき（「仲間とアジトができたら」など）は、その名前で`search_pull_requests`を引き、マージ済みのPRがあるかを見る。言い回しが合わずに見つからないことがあるので、見つからないときは「要確認」として挙げ、揃っていないとは書かない。

「やること」の中身が、条件とは別に、ほかのissueですでにできていることもある。その名前で`search_pull_requests`を引き、マージ済みのPRがあれば「要確認」として挙げる。TODOの前提が変わっているので、閉じるか書き直すかを持ち主に聞く。

## 3. Projectで止まっている項目を探す

`projects_list`の`list_project_views`で、RoadMapのビューの`filter`を読む。いまは`has:milestone`である。

続けて、`list_project_items`で開いているissueを全部読む。

| 引数 | 値 |
| --- | --- |
| `owner_type` | `user` |
| `project_number` | `3` |
| `query` | `is:issue is:open` |
| `field_names` | `["Status", "開始日", "期日", "Milestone"]` |
| `perPage` | `50` |

1ページは50件までである。`pageInfo.hasNextPage`が続く限り、`after`に`nextCursor`を渡し、ほかの引数は同じにして送る。

挙げるのは、次の2つである。

| 気になる点 | 見分け方 | 次の一手 |
| --- | --- | --- |
| `Todo`のまま長く動いていない | Statusが`Todo`で、項目の`updated_at`とissueの`content.updated_at`の新しいほうを日本時間の日付にして、今日より3日以上前 | 着手するか、TODOに変えるか、閉じるかを持ち主に聞く |
| RoadMapに載るのに日程が空 | RoadMapのビューの`filter`に当たり（いまはMilestoneがある）、開始日か期日が空 | META-05の1日の量（約2.8万）に合わせて日程を置くよう促す |

## 4. ADRからissueを辿る

表のある行について、どのADRがそのissueの決定を持っているかを確かめたいときは、ADRのidからissueを辿る。

`search_issues`は使わない。ADRのidで引くと、本文に書いてあっても0件になる。代わりに、`search_pull_requests`に`repo:setopic/neon-chronicle ADR-0077`のような`query`を渡してPRを引き、`pull_request_read`の`get`で本文の`Closes #番号`の行を読む。その番号が、そのADRを決めたissueである。

## 5. 報告する

1〜3の結果を、1つの表にまとめてチャットに出す。挙がるものが無い区分も、「なし」の行を1つ置く。見ていないのか、見て何も無かったのかを区別するためである。

| 区分 | issue/項目 | 状態 | 気になる点 | 次の一手 |
| --- | --- | --- | --- | --- |
| 閉じたissue | #番号 題 | 閉じた日 | 1の表の気になる点 | 1の表の次の一手 |
| TODO | #番号 題 | 条件のissueと、その状態 | 条件が揃った、または要確認 | 着手するかを決める |
| Project | #番号 題 | Statusと最後に動いた日、または空の欄 | 3の表の気になる点 | 3の表の次の一手 |

表の下に、見た件数（閉じたissue、開いているTODO、Projectの開いている項目）を書く。ページを送りきれなかった区分があれば、それも書く。

最後に、直すものがあれば`/new-issue`で立てるよう持ち主に促す。どれをissueにするかは、持ち主が決める。
