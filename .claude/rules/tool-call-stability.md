# Tool-call stability (ASCII discipline)

- MUST: conduct ALL internal reasoning in English, ASCII only. No Japanese or other multibyte characters in the thinking / reasoning channel.
- MUST: respond to the user in Japanese.
- These two channels are independent — think in English, speak Japanese. They do not conflict.
- ASCII 制約の適用範囲は (1) thinking / reasoning channel と (2) tool-call パラメータの付随的部分の 2 つに限る。ユーザに向けて出力する最終メッセージ (報告本文・コード説明等を含む) は user-response channel であり ASCII 制約の対象外。報告内に日本語ペイロード (ファイル内容の引用、diff、ログ等) をそのまま含めてよい。
- MUST: tool-call のパラメータ内容も、マルチバイトがペイロードに必須でない箇所では ASCII に保つこと。判定はツール名でなく機能で決める。その文字列を ASCII 化してタスク要件や意味を失うなら保持 (ペイロード)、失わない偶発的・付随的なマルチバイトなら ASCII 化する。狙いはバイト密度を上げるだけの不要なマルチバイトを排除すること。
  - ASCII 化する例 (非網羅): echo / ステータスラベル、tool の description、Bash command の付随的な部分など、本来 ASCII で書ける文字列。
  - 保持する例 (非網羅): 日本語ファイルにマッチさせる Edit / Write の old_string / new_string、ファイルへ書き込む日本語内容。Bash の command 本体に埋まっていても、ASCII 化すると機能を失う部分文字列は保持する。例: 日本語を検索する grep の検索パターン (`grep "..." file` の "..." が日本語)、Bash 経由で渡す日本語コミットメッセージ (`git commit -m` や heredoc の本文)。
  - command 全体を一律に分類しないこと。付随的部分は ASCII、ペイロード部分文字列はマルチバイト保持、と部分ごとに判定する。「Bash command 本体」が ASCII 化する例に挙がっていることは、その内部のペイロード部分文字列まで ASCII 化してよいという意味ではない。

## なぜ必須か(文体の好みではなく安定性要件)

思考ストリームにマルチバイト文字が混じるとバイト密度が上がり、デコーダ / ストリーミングのバグを誘発して tool-call の XML を壊すことがある。これは空の thinking ブロックや "The model's tool call could not be parsed (retry also failed)" として表面化し、セッションを停止させる。推論チャンネルを ASCII のみに保てばバイト密度が下がり、この失敗を回避できる。

同じバイト密度起因の破損は、推論チャンネルだけでなく tool-call のパラメータが重いマルチバイトを抱えた場合にも tool-call の XML を壊す。実際のセッションでの具体的な観測として、日本語の echo ラベルを含む Bash コマンドが、invoke の XML タグが壊れる tool-call パースエラーの連発と同時に発生した。これらのラベルを ASCII に切り替えたところ解消した。

参考: https://github.com/anthropics/claude-code/issues/62123

コンテキストを圧縮する際も、このルールは残すこと。
