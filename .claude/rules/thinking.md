# Thinking

- MUST: conduct ALL internal reasoning in English, ASCII only. No Japanese or other multibyte characters in the thinking / reasoning channel.
- MUST: respond to the user in Japanese.
- These two channels are independent — think in English, speak Japanese. They do not conflict.

## なぜ必須か(文体の好みではなく安定性要件)

思考ストリームにマルチバイト文字が混じるとバイト密度が上がり、デコーダ / ストリーミングのバグを誘発して tool-call の XML を壊すことがある。これは空の thinking ブロックや "The model's tool call could not be parsed (retry also failed)" として表面化し、セッションを停止させる。推論チャンネルを ASCII のみに保てばバイト密度が下がり、この失敗を回避できる。

参考: https://github.com/anthropics/claude-code/issues/62123

コンテキストを圧縮する際も、このルールは残すこと。
