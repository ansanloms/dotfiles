---
name: find-docs
description: >-
  ライブラリ・フレームワーク・SDK・API・CLI ツール・クラウドサービス (React, Next.js, Prisma, Express, Tailwind, Django, Spring Boot 等の著名なものを含む) について質問された際に、Context7 CLI で最新の公式ドキュメントを取得してから回答する。
  API 構文・設定方法・バージョン移行・ライブラリ固有のデバッグ・セットアップ手順・CLI ツールの使用方法が対象。ライブラリのドキュメントに関しては Web 検索よりこちらを優先する。
  リファクタリング・ゼロからのスクリプト作成・ビジネスロジックのデバッグ・コードレビュー・一般的なプログラミング概念の質問には使わない。
---

# 技術調査 (ライブラリドキュメント取得)

ライブラリ、フレームワーク、SDK、API、CLI ツール、またはクラウドサービスについて質問された際は、Context7 CLI (コマンドは `ctx7`、後述のとおり `npm:ctx7@latest` 経由で実行する) を使用して最新のドキュメントを取得する。

たとえ答えを知っていると思われる場合でも、学習データには最新の変更が反映されていない可能性があるため、この手順を優先する。API のシグネチャ・設定オプション・バージョン依存の挙動は特に陳腐化しやすいので、学習データに頼らず現行ドキュメントで裏取りする。ライブラリのドキュメントに関しては、Web 検索よりもこちらを優先して使用する。

## 適用する場合 / 適用しない場合

判定軸は「対象がライブラリかどうか」ではなく「質問の意図がライブラリ・フレームワーク・SDK・API・CLI の最新仕様や使い方を問うているか」。

- 適用する: API 構文・設定方法・バージョン移行・ライブラリ固有のデバッグ・セットアップ手順・CLI ツールの使用方法を問う質問。
- 適用しない: リファクタリング、ゼロからのスクリプト作成、ビジネスロジックのデバッグ、コードレビュー、一般的なプログラミング概念の質問。対象コードがライブラリを import していても、意図が上記なら起動しない。

## 実行手順

ライブラリ名を ID に解決してから、その ID でドキュメントを引く 2 段階。Step 1 と Step 2 は別々のコマンド実行になる (Step 1 の結果を見てライブラリ ID を選んでから Step 2 に進むため)。

Step 1・Step 2 のコマンドは、deno の権限フラグから `npm:ctx7@latest` までの部分 (以下「基点コマンド」) が共通する。この基点コマンドはここで 1 度だけ定義し、これを唯一の権威とする。

```sh
# 基点コマンド (Step 1・Step 2 で共通)
deno run --no-lock --allow-env --allow-sys=osRelease,homedir --allow-read --allow-net=context7.com,registry.npmjs.org npm:ctx7@latest
```

以降、各 Step のコマンド例では基点コマンドの部分を `<基点コマンド>` と表記する。これはシェル変数ではない。実行時は、上記の基点コマンドの文字列をそのまま書き下してから、後ろにサブコマンドと引数を続けること。基点コマンドをシェル変数に代入して参照する構成は使わない。Step 1 と Step 2 は別々のコマンド実行になり、その間でシェル変数は保持されないため、Step 2 の実行時に変数が空文字へ展開されて失敗する。権限フラグの追加・変更が必要になった場合 (「注意事項」参照) は、この基点コマンドの定義 1 箇所だけを直す。

### Step 1: ライブラリの特定

次の library コマンドで、パッケージ・プロダクト名を Context7 互換のライブラリ ID に解決し、候補一覧を得る。

```sh
<基点コマンド> library <name> "<user's question>"
```

`<name>` が複数語の場合はクォートで囲む (例: `library "Spring Boot" "..."`)。

`query` 引数は必須で、結果のランキングに直接影響する。ユーザの質問全文をクエリに使う。同名のライブラリが複数ある場合の曖昧性解消にも効く。

#### 出力フィールド

各候補は番号付きリストで返り、番号の下にインデントされた `フィールド名: 値` の行が続く。選択基準 (後述) はこれらの値を見て判断する。

- **Title** — ライブラリ・パッケージ名。
- **Context7-compatible library ID** — Context7 互換の識別子 (形式: `/org/project`)。以降この文書では「Library ID」と呼ぶ。
- **Description** — 短い概要。
- **Code Snippets** — 利用可能なコード例の数。
- **Source Reputation** — ソースの信頼性 (High/Medium/Low/Unknown)。
- **Benchmark Score** — 品質指標 (100 が最高)。
- **Versions** — バージョン一覧 (存在する場合)。
  - バージョン指定がある場合はここから選ぶ。形式は `/org/project/version`。
  - このフィールドが無い候補の扱いは「バージョン指定」の節に従う。

実際の出力例 (2026-08-10 に `<基点コマンド> library React "How to set up authentication with JWT in Express.js"` を実行して取得。基点コマンドは上記「実行手順」冒頭で定義したものと同一。実際の出力には行ごとに ANSI カラーコードが混じるが、下記はフィールド名・値のテキストのみを抜き出したもの。全 5 件を掲載する):。

```text
1. Title: React
   Context7-compatible library ID: /reactjs/react.dev
   Description: React.dev is the official documentation website for React, a JavaScript library for building user interfaces, providing guides, API references, and tutorials.
   Code Snippets: 6052
   Source Reputation: High
   Benchmark Score: 83.37
   Versions: __branch__v18

2. Title: React
   Context7-compatible library ID: /react/react
   Description: React is a JavaScript library for building user interfaces.
   Code Snippets: 6165
   Source Reputation: High
   Benchmark Score: 75.68
   Versions: v19.2.7, v18.2.0

3. Title: React
   Context7-compatible library ID: /websites/react_dev
   Description: React is a JavaScript library for building user interfaces. It allows developers to create interactive web and native applications using reusable components, enabling efficient and scalable UI development.
   Code Snippets: 6107
   Source Reputation: High
   Benchmark Score: 81.69

4. Title: React
   Context7-compatible library ID: /websites/react_dev_reference
   Description: React is a JavaScript library for building user interfaces with reusable components, hooks, and APIs for managing state and side effects.
   Code Snippets: 3031
   Source Reputation: High
   Benchmark Score: 76.69

5. Title: React
   Context7-compatible library ID: /websites/react_dev_reference_react
   Description: React is a JavaScript library for building user interfaces using reusable components with reactive data binding and server-side rendering capabilities.
   Code Snippets: 1039
   Source Reputation: High
   Benchmark Score: 85.93
```

Benchmark Score は同一クエリでも実行のたびに変動しうる値であり、上記は 2026-08-10 のある時点の実測値である。3〜5 番目のように Versions フィールドが無い候補もあることが分かる。

この 5 件は Title が全件「React」、Source Reputation が全件 High で並ぶため、選択基準は基準 3 (Benchmark Score) まで進んで決まる。最高値は 5 番目の `/websites/react_dev_reference_react` (85.93) で、次点は 1 番目の 83.37 である。両者の差が 2.0 を超えるため同点にならず、5 番目が選ばれる。後述の Step 2 のサンプルは、この選択結果である ID を使って取得したものである。

#### 選択基準

最適なライブラリ ID を次の優先順位で決定する。上位で差がつかない場合のみ下位で tie-break する。

1. 正式名称の一致 (完全一致を優先)。
2. ソースの信頼性 (High/Medium を推奨)。
3. ベンチマークスコア (高いほど良い、最高 100)。
4. Description の関連性。全候補が汎用的な説明文で質問への関連度に差が読み取れない場合は同点として次へ進む。
5. Code Snippets の数 (多いほど良い)。

ID の種別 (公式リポジトリ系 `/org/project`、ドキュメントサイト系 `/websites/...` 等) は判断材料にせず、上記 (1) から (5) で機械的に決める。「公式リポジトリを選びたい」といった直感で順位を覆さないこと。選択基準で上位が複数並ぶ場合は、その旨を述べた上で最上位の 1 つで進める。どの候補も選択基準を満たさない場合は、その旨を伝えてクエリの見直しを提案する。

Benchmark Score (基準 3) での比較は、差が 2.0 以下なら同点とみなし、次の基準で tie-break する。境界の 2.0 も同点に含める。この閾値は Benchmark Score にのみ適用し、Code Snippets の数 (基準 5) には適用しない。厳密な分岐条件ではなく「僅差を決定打に昇格させない」ための目安であり、境界ぎりぎりの判定で結論を反転させない (迷ったら同点側に倒して次の基準へ進む)。

(1) の正式名称の一致は、ユーザの意図に照らして判定する。フレームワーク本体の組み込み機能を問うているのか、特定のサードパーティライブラリを名指ししているのかを見る。質問キーワードがサードパーティライブラリに強く一致しても、ユーザがフレームワーク本体の機能を問うているならフレームワーク本体を選ぶ。

選択結果が直感に反する場合 (例:「公式リポジトリを選びたい」等) や、上位が僅差だった場合は、その ID を選んだ理由を回答に 1 行添える。理由は選択基準の番号で示す (例: 選択基準 (1) から (3) で上回るため)。

### Step 2: ドキュメントの取得

選択したライブラリ ID で、最新のドキュメントとコード例を取得する。`<基点コマンド>` は「実行手順」冒頭で定義したものと同一の文字列を書き下す。

```sh
<基点コマンド> docs <libraryId> "<user's question>"
```

docs のクエリは library と同一文である必要はない。初回から対象の API 名・機能語 (例: `@@unique`) を加えて絞ってよい。

#### 出力形式

出力は、`--------------------------------` の区切り線で仕切られた複数のエントリの並び。各エントリは次の構造を持つ。

- 1 行目: `### <タイトル>`
- 空行を挟んで `Source: <元ドキュメントの URL>`
- 空行を挟んで英語散文の説明
- (エントリによっては) 空行を挟んで言語タグ付きのコードブロック

取得結果には 2 種類のエントリが含まれうる。両方あれば両方を見る。

- **コードスニペット** — タイトルが機能・用途を表す文で、コードブロックを伴う。
- **info スニペット** — タイトルが `<親トピック> > <質問文>` のパンくず形式で、コードブロックを伴わないか、説明の裏付けとして短いコードを併記することがある。散文中に markdown のリンク・箇条書きを含むことが多い。

クエリによっては片方 (コードスニペットのみ等) しか返らない。その場合はある方だけで判断してよい。

実際の出力例 (2026-08-10 に `<基点コマンド> docs /websites/react_dev_reference_react "when to use useMemo vs useCallback rationale"` を実行して取得。基点コマンドは「実行手順」冒頭で定義したものと同一。全 5 件中、コードスニペットの例として 1 件目、info スニペットの例として 4 件目を掲載し、他のエントリは省略した):。

````text
### Memoizing Function Results with useMemo and Functions with useCallback in React

Source: https://react.dev/reference/react/useCallback

This snippet demonstrates how to use `useMemo` to cache the result of a function call and `useCallback` to cache the function itself. This is useful for optimizing child components by preventing unnecessary re-renders when props do not change. It requires React's `useMemo` and `useCallback` hooks.

```javascript
import { useMemo, useCallback } from 'react';

function ProductPage({
  productId,
  referrer
}) {
  const product = useData('/product/' + productId);

  const requirements = useMemo(() => {
    // Calls your function and caches its result
    return computeRequirements(product);
  }, [product]);

  const handleSubmit = useCallback((orderDetails) => {
    // Caches your function itself
    post('/product/' + productId + '/\buy', {
      referrer,
      orderDetails,
    });
  }, [productId, referrer]);

  return (
    <div className={theme}>
      <ShippingForm requirements={requirements} onSubmit={handleSubmit} />
    </div>
  );
}
```

--------------------------------

### useCallback > How is useCallback related to useMemo?

Source: https://react.dev/reference/react/useCallback

You will often see [`useMemo`](/reference/react/useMemo) alongside `useCallback`. They are both useful when you're trying to optimize a child component. They let you [memoize](https://en.wikipedia.org/wiki/Memoization) (or, in other words, cache) something you're passing down:

* **[`useMemo`](/reference/react/useMemo) caches the *result* of calling your function.** In this example, it caches the result of calling `computeRequirements(product)` so that it doesn't change unless `product` has changed. This lets you pass the `requirements` object down without unnecessarily re-rendering `ShippingForm`. When necessary, React will call the function you've passed during rendering to calculate the result.
* **`useCallback` caches *the function itself.*** Unlike `useMemo`, it does not call the function you provide. Instead, it caches the function you provided so that `handleSubmit` *itself* doesn't change unless `productId` or `referrer` has changed. This lets you pass the `handleSubmit` function down without unnecessarily re-rendering `ShippingForm`. Your code won't run until the user submits the form.

If you're already familiar with [`useMemo`,](/reference/react/useMemo) you might find it helpful to think of `useCallback` as this:

```js
// Simplified implementation (inside React)
function useCallback(fn, dependencies) {
  return useMemo(() => fn, dependencies);
}
```
````

上記のコードスニペットの例 (1 件目) 中の `'/\buy'` という文字列は、バックスペース制御文字 `\b` を含む ctx7 の実出力どおりの転記である。壊れた文字列に見えるが誤字ではない。理由: ctx7 の実出力をそのまま転記しているため。直さないこと。info スニペットの例 (4 件目) は、この後に続くエントリと切り分ける区切り線の直前までを掲載しており、エントリ内で省略した部分は無い。

取得したドキュメントに基づいて回答する。

## クエリの書き方

クエリの質が結果の質を直接左右する。具体的かつ詳細に書く。曖昧な単語 1 つでは一般的すぎる結果しか返らない。

クエリはドキュメントの主要言語 (多くは英語) で書き、ユーザの質問の意図を表現する。ユーザが日本語など他言語で質問した場合は、意図と具体性を保ったまま英語に翻訳してクエリにする。「質問全文を使う」とは原文の言語をそのまま使う意味ではなく、語句の具体性を削らないという意味。

| 良し悪し | 例                                                         |
| -------- | ---------------------------------------------------------- |
| 良い     | `"How to set up authentication with JWT in Express.js"`    |
| 良い     | `"React useEffect cleanup function with async operations"` |
| 悪い     | `"auth"`                                                   |
| 悪い     | `"hooks"`                                                  |

## バージョン指定

バージョン固有のドキュメントは、ユーザが特定バージョンを明示した場合、またはバージョン依存の挙動を問うている場合にのみ使う。その際は library コマンドの出力 (Versions フィールド) から、そのバージョンを指す ID を使う。ID の形式は問わない (`/org/project/version` 形式の例は `/vercel/next.js/v14.3.0`、バージョン別のドキュメントサイト系の例は `/websites/v3_xxx`)。

そのバージョンを指す ID が無い場合は、当該バージョンが現行であれば通常の ID (バージョンなしの ID やドキュメントサイト系の ID) を代替として使ってよい。指定がなければバージョンなしの ID を使う。Versions フィールドが無くても、候補の Title や ID 文字列にバージョン記号 (v3、v2 等) を含むものがあれば、それを当該バージョンを指す ID とみなす。

差分や移行を問う質問で「現行」側を選ぶ際、どの候補にも明示的なバージョン記号が無ければ、最上位の通常 ID を現行とみなし、その前提 (現行がどのバージョンか) を回答に明示する。候補の Description が対象バージョンへの対応を示していれば、それを優先する。現行が具体的にどのバージョンかは、学習データではなく取得したドキュメント本文のバージョン記載で確認する。

2 つのバージョン間の差分や複数ライブラリの比較を問う質問では、新しい方 (現行) を通常 ID で取得することを主とする。旧バージョンの取得は、現行側のアップグレードガイド等に旧仕様が併記されているかをまず確認し、併記で差分を把握できれば省く。併記が無く差分の把握に旧仕様が必要な場合のみ、旧バージョンを指す ID (形式は問わない) から実行上限内で追加取得する。

## エラー処理

失敗時、コマンドの終了コードは 0 以外 (実測値は 1) になる。ただし失敗の種類はメッセージの内容で判別すること。ネットワーク遮断・deno/npm の解決失敗・候補ゼロ・docs が空の 4 件は 2026-08-10 に実際にコマンドを実行して得たメッセージの実例である (実行環境やライブラリによって変わりうる)。クォータ超過のみ、クォータを使い切らないと再現できないため実測しておらず、`main` からの既存記述 (出典未確認) をそのまま引き継いでいる。

- **クォータ超過 (未実測、既存記述)**: `Monthly quota reached`/`quota exceeded` 等を含むメッセージで失敗する。Context7 のクォータを使い切っており、これ以上はドキュメントを取得できない旨をユーザに伝える。理由: 再実行しても回復しないため。以降の実行上限は使わない。
- **ネットワーク遮断**: `Requires net access to "..."` のようなメッセージで失敗する (実測例: `Requires net access to "context7.com:443", run again with the --allow-net flag`)。
  - 実行環境が `--allow-net` で許可した通信先へ到達できていない。ネットワークが使えず取得できない旨をユーザに伝える。
  - 理由: 実行環境側の問題であり、再実行しても解決しないため。以降の実行上限は使わない。
- **deno/npm の解決失敗**: `npm:ctx7@latest` 自体の解決に失敗し、`error: npm package '...' does not exist.` のようなメッセージで失敗する。パッケージ名や deno の設定を疑い、無闇な再実行はしない。解決できない旨をユーザに伝える。
- **候補ゼロ (library)**: library コマンドが `No libraries found for "...". Try a different search term.` のようなメッセージで、候補を 1 件も返さない。クエリの表記や語を変えて実行上限内で 1 回まで再試行してよい。それでも候補が出なければ、その旨を伝えて回答を保留する。
- **docs が空**: docs コマンドが本文を返さない。
  - ライブラリ ID が不正な場合は `Library "..." not found. Please check the library ID or your access permissions.`、クエリに合致する内容が無い場合は `No documentation in "..." matched this query. Try a more specific query with different terms, or search for another library that covers this topic.` のようなメッセージになる。
  - クエリを絞り直すか library からやり直すかは「バージョン指定」「クエリの書き方」の各節に従い、実行上限内で 1 回まで再試行する。それでも空なら取得不可を伝える。

上記のいずれで失敗した場合も、その実行は「注意事項」に記す実行上限 (1 つの質問につき 3 回) に含める。エラーで終了した実行もコマンドを実行した回数として数え、上限を超えて再実行しない。

取得できなかった場合に学習データから回答してはならない。Context7 のドキュメントに基づかない API 仕様・設定値の回答は、注記を添えても返さないこと。取得不可の事実だけを伝え、回答は保留する。

## 注意事項

- MUST: **クエリに機密情報 (API キー、パスワード、認証情報、個人データ、proprietary なコード) を含めないこと**。
- ユーザから `/org/project` 形式で直接 ID が提供されない限り、必ず最初に library コマンドを実行して有効な ID を取得すること。
- deno の権限は `--allow-net` で通信先を、`--allow-sys` でシステム情報アクセスを絞り、外部への露出を抑える方針。
  - `--allow-env` と `--allow-read` は絞らない。理由: ctx7 が読む対象が多く、read のパスも deno キャッシュ位置に依存して壊れやすいため。
  - `--allow-write` は不要。
  - ctx7 の更新で `Requires sys access to "X"` 等が出たら、その権限を「実行手順」冒頭で定義した基点コマンド 1 箇所に追記する。Step 1・Step 2 のコマンド例はどちらもその基点コマンドを `<基点コマンド>` として書き下す構成なので、追記した内容は両方の Step の実行コマンドに反映される。
- ライブラリ ID は `/` 始まり。`/facebook/react` であって `facebook/react` ではない。
- 質問内容は、「nextjs」ではなく「Next.js」、「customerio」ではなく「Customer.io」、「threejs」ではなく「Three.js」など、正しい句読点を用いた公式のライブラリ名を使用すること。
- CLI ツールやコマンドについて問われた場合、library のクエリ名にはツール単体の名前ではなく、それが属するプラットフォーム・プロダクトの正式名称を優先する (例:「Wrangler」より「Cloudflare Workers」、「gcloud」より「Google Cloud」)。ツール名で関連性の低い結果しか出ない場合はプラットフォーム名で引き直す。
- 1 つの質問につき 3 回を超えてコマンドを実行しないこと。これはハード上限であり、library の引き直しや docs の再取得、および「エラー処理」に記す失敗した実行もこの回数に含まれる。上限内で核心に到達できるよう、初回 library のクエリ名を正確に選ぶこと。
- docs の取得結果が質問の核心 (主要なユースケースや対象 API) を直接カバーしていない場合は、上記の実行上限内で観点を絞ったクエリで再取得してよい。クエリを絞る例は機能名やメソッド名を加えることである。
- 残りの実行回数の使途が複数 (旧バージョンの追加取得・核心の絞り込み再取得等) で競合する場合は、質問の核心を厚くする取得を優先する。核心とは新しい側の新仕様や対象 API を指し、旧側の補完取得より優先する。
- ドキュメントソースは既定で pre-release・canary チャネルを指すことがある (例: `/vercel/next.js`)。取得したドキュメントが canary・開発版由来で、用語や API 名が安定版の広く知られた仕様と食い違う場合は、その差異を回答で明示し、どのバージョンの話かを添える。開発版の名称を現行の標準であるかのように提示しないこと。
