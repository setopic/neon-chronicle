---
description: issueを立て、見積もり・マイルストーン・Project・関係まで付ける。引数は立てたい内容の一言。
argument-hint: <立てたい内容>
---

# issueを立てる：$ARGUMENTS

この手順は、持ち主の手元のPCで回す。issueの型と書き方はMETA-07に、見積もりと日程はMETA-05にある。先に`docs/00-meta/issue-pr-flow.md`（META-07）と`docs/00-meta/dev-flow.md`（META-05）の「issueを立てる」と「見積もりと実績」を読む。

## 1. どのセッションで立てるか

issueを立てる作業にかかった分は、その作業を生んだissueの実績にする（META-05）。実績は、そのセッションのコミットに付く`Cost-Index:`の行から出る。そのため、どこで立てるかで実績の行き先が変わる。

| 場面 | 立て方 | 実績の行き先 |
| --- | --- | --- |
| `/issue <番号>`の作業の中で見つけた | 同じセッションの中で、このコマンドを呼ぶ | そのissueのPRの次のコミットに、自動で入る |
| どのissueの作業でもない（思いつき、点検の結果など） | 新しいセッションで、このコマンドを呼ぶ | マイルストーンの「計画」のissue。下の7で手で記録する |

## 2. 重なりを確かめる

同じ内容のissueが無いかを探す。開いているものも、閉じたものも見る。

```bash
gh issue list --state all --search "<キーワード>" --limit 20
```

重なるものがあれば、持ち主に伝えて、新しく立てるか、既存のissueにコメントを足すかを聞く。

## 3. 中身を詰める

型を決める。決めることが書けるなら要件、現象しか書けないなら問題、いま決めようが無いならTODOである（META-07）。雛形は`.github/ISSUE_TEMPLATE/`にある。

「決めること」が3つ以上ある、または埋められないなら、書く前に`/grill`を回す（META-05）。持ち主に聞くときは、`Q1`、`Q2`のように番号を振り、各質問に推奨案と理由を付ける。

本文の下書きを持ち主に見せてから立てる。下書きには、次の5つを添える。

| 添えるもの | 決め方 |
| --- | --- |
| 型（ラベル） | 要件・問題・TODO |
| マイルストーン | 下のコマンドで一覧を出し、合うものを選ぶ |
| 見積もり | META-05の目安（小0.5万・中0.7万・大1万）から、数字で決める。1行で理由を添える |
| 親（sub-issue） | 点検や計画のissueから立てたなら、そのissue |
| 待つ先（blocked by） | 答えを待たないと決められないissue |

```bash
gh api repos/setopic/neon-chronicle/milestones --jq '.[] | "\(.number) \(.title)"'
```

**見積もりは本文に書かない**。Projectの欄と二重になるからである（META-05）。本文の文章は、`CLAUDE.md`の「日本語の書き方」に沿って書く。

## 4. 立てる

持ち主が下書きを認めたら立てる。

```bash
gh issue create --title "<題>" --body-file <本文のファイル> --label <型> --milestone "<マイルストーンの名前>"
```

続けて、見積もりのコメントを付ける。1行目は`見積もり: <数字>`だけにし、理由は2行目から書く。

```bash
gh issue comment <番号> --body "見積もり: 7000

<理由を1文>"
```

`.github/workflows/add-to-project.yml`がissueをProject 3に載せ、`.github/workflows/project-record.yml`がこのコメントを見積もりの欄に写す。Projectの見積もりの欄には、手で書かない。

## 5. 関係を付ける

親と待つ先は、GitHubの関係の欄で付ける。本文に「#147と合わせる」と書くだけでは、着手の順が一覧に出ない（META-05）。関係のAPIは、issueの番号ではなく`id`（数字）を取る。

```bash
CHILD_ID=$(gh api repos/setopic/neon-chronicle/issues/<新しいissue> --jq .id)
gh api -X POST repos/setopic/neon-chronicle/issues/<親>/sub_issues -F sub_issue_id=$CHILD_ID

BLOCKER_ID=$(gh api repos/setopic/neon-chronicle/issues/<待つ先> --jq .id)
gh api -X POST repos/setopic/neon-chronicle/issues/<新しいissue>/dependencies/blocked_by -F issue_id=$BLOCKER_ID
```

## 6. Projectを確かめ、日程を置く

1分ほど待ってから、issueがProjectに載り、見積もりが写ったかを確かめる。`gh project`は日本語の欄の名前が文字化けするので、`gh api graphql`を使う。

```bash
gh api graphql -f query='query{repository(owner:"setopic",name:"neon-chronicle"){issue(number:<番号>){id projectItems(first:5){nodes{id project{number} fieldValues(first:20){nodes{... on ProjectV2ItemFieldNumberValue{number field{... on ProjectV2FieldCommon{name}}} ... on ProjectV2ItemFieldDateValue{date field{... on ProjectV2FieldCommon{name}}}}}}}}}}'
```

載っていなければ、ワークフローの失敗を`gh run list --limit 5`で見て、持ち主に伝える。手で載せるときは次を使う。`<issueのid>`は、上の結果の`issue.id`である。

```bash
gh api graphql -f query='mutation{addProjectV2ItemById(input:{projectId:"PVT_kwHOArrxAs4Bngp_",contentId:"<issueのid>"}){item{id}}}'
```

見積もりを書いたら、開始日と期日を置く（META-05）。1日に使える量（約2.8万）まで、同じ日に並べる。1日で終わる見込みのissueを、1日に1件ずつ置かない。ほかのissueの日程は、次のように読む。

```bash
gh api graphql --paginate -f query='query($endCursor:String){node(id:"PVT_kwHOArrxAs4Bngp_"){... on ProjectV2{items(first:100,after:$endCursor){pageInfo{hasNextPage endCursor} nodes{content{... on Issue{number state}} fieldValues(first:20){nodes{... on ProjectV2ItemFieldNumberValue{number field{... on ProjectV2FieldCommon{name}}} ... on ProjectV2ItemFieldDateValue{date field{... on ProjectV2FieldCommon{name}}}}}}}}}}'
```

置く日を持ち主に見せてから書く。日付は日本時間で書く。

| 欄 | id |
| --- | --- |
| 開始日 | `PVTF_lAHOArrxAs4Bngp_zhmFAio` |
| 期日 | `PVTF_lAHOArrxAs4Bngp_zhmFAis` |

```bash
gh api graphql -f query='mutation{updateProjectV2ItemFieldValue(input:{projectId:"PVT_kwHOArrxAs4Bngp_",itemId:"<itemのid>",fieldId:"<欄のid>",value:{date:"2026-10-21"}}){projectV2Item{id}}}'
```

## 7. 実績を記録する（新しいセッションで立てたときだけ）

`/issue`の作業の中で立てたなら、この節は要らない。そのissueのPRの次のコミットに、ここまでの分が入る。

新しいセッションで立てたなら、コミットが無いので、消費は自動では数えられない。マイルストーンの「計画」のissueに、手で足す。「計画」のissueが無ければ、要件の型で作る（例は#166）。

このセッションのここまでの消費は、次で出る。

```bash
python -c "import sys; sys.path.insert(0, '.claude/hooks'); import cost_index as c; s, t = c.current_session(); print(s, c.cost_index(t))"
```

「計画」のissueの今の実績を6の問い合わせで読み、この値を足した合計を`実績:`のコメントにする。`実績:`のコメントは値を上書きするので、足さずに書くと前の分が消える。

```bash
gh issue comment <計画のissue> --body "実績: <今の実績＋このセッションの値>

#<立てたissue>を立てた分を足した。"
```

## 8. 伝える

立てたissueのURLと、付けたもの（型・マイルストーン・見積もり・関係・日程・実績の行き先）を、持ち主に表で伝える。
