# 構成図の共通原則

provider に依存しない構成図の原則 (粒度・帯・コネクタの色と線種・凡例・命名) を集めたもの。provider 固有のアイコン・色・境界表現は各 provider リファレンス (`aws-architecture.md`/`gcp-architecture.md`/`azure-architecture.md`/`generic-infra-architecture.md`) に置く。

## 図の粒度（俯瞰図と詳細図）

構成図の粒度は用途で選ぶ。詳細図と俯瞰図はどちらが優れているわけではなく、見せる相手と目的で使い分ける。1 枚に両方の粒度を詰め込むと「どこを見ればいいか分からない図」になる。

- **詳細図**: 全リソース・主要パラメータを網羅する。設計レビュー・構築・引き継ぎ向け。
- **俯瞰図**: データの流れと層構造を一目で掴ませる。説明・合意形成・全体把握向け。要素を間引き、流れを主役にする。

俯瞰図を描くときの原則は次の通り。

- 線はサービス分類ではなく**フローの目的**で配色する（[コネクタの色・線種ルール](#コネクタの色線種ルール必須)）。色と線が「分類」を表すと、どこを追えばよいか分からなくなる。
- 全層を横断するサービス（監視・認証・ログ等）は各層に散らさず**帯にまとめる**（後述）。
- 細部（個々のインスタンス数、細かな設定値）は俯瞰図に載せず、詳細図へ分割する。

出典: [AWS の"俯瞰"構成図を自動生成する](https://qiita.com/ntaka329/items/d457f309e33c4602a693)

## レイアウト原則

### 2. 左から右、上から下へのフロー

情報の流れは一般的に左から右、または上から下に配置する。

```
[User] → [CloudFront] → [ALB] → [EC2] → [RDS]
```

### 3. 同じ階層は水平に配置

同じ役割のコンポーネントは水平に並べる。

```
         [ALB]
          ↓
[EC2-1] [EC2-2] [EC2-3]
```

### 4. グループ化

関連するコンポーネントは視覚的にグループ化する。

- VPC 境界
- Availability Zone
- セキュリティグループ

### 5. 横断サービスは帯にまとめる

監視・認証・ログ集約のように全層を横断するサービスは、各層の隣に散らして置かない。図の端（横一列または縦一列の領域）に**帯**としてまとめ、そこへ向かう線を 1 つの目的色（監視＝緑など）で束ねる。

散らして置くと、横断サービスへの線が四方八方へ伸び、肝心のデータの流れが読めなくなる。帯にまとめると、横断的な関心事が 1 箇所に集約され、本流の流れと分離して見える。

帯はグループ（枠）として描く。`container=1` にしてノードを子に持たせなくても、見やすさの幾何チェック（[readability-checks.md](./readability-checks.md)）の `group-cross` は、エッジの端点が帯の内側にあれば帯への接続を正当とみなす。

出典: [AWS の"俯瞰"構成図を自動生成する](https://qiita.com/ntaka329/items/d457f309e33c4602a693)

## 命名規則

### サービス名

- 表示名は役割を明確にする
  - 良い例: `Web Server`, `API Server`, `Primary DB`
  - 悪い例: `EC2`, `RDS`, `Instance-1`

### ラベル

- 接続の説明はプロトコル、ポート、データフローを記載する
  - 例: `HTTPS (443)`, `MySQL (3306)`, `WebSocket`

### グループ

- 境界の名前は階層を明確にする
  - 例: `VPC (10.0.0.0/16)`, `Public Subnet (10.0.1.0/24)`

## 矢印とデータフロー

### 矢印の種類

- 実線はデータフロー、API 呼び出しを表す
- 破線は非同期通信、イベント駆動を表す

### コネクタの色・線種ルール（必須）

コネクタの色と線種は必ず意味を持たせる。装飾目的で色を散らさない。本リポジトリでは次の「目的ベース」ルールを標準とする。コネクタ色が 2 色以上同時に現れる図には、色の意味を示す凡例ボックスを添える。1 色のみの図には添えない。

**線種（同期性）**

| 線種 | 意味                                                                 |
| :--- | :------------------------------------------------------------------- |
| 実線 | 同期通信（リクエスト/レスポンス、SQL 等のデータ本流）                |
| 破線 | 非同期・制御・外部連携・レプリケーション等（データ本流ではない通信） |

例は AWS のサービス名で書いているが、規則自体は provider を問わず適用する。

**色（フローの目的）**

| 色                 | 用途                 | 例                                                                                  |
| :----------------- | :------------------- | :---------------------------------------------------------------------------------- |
| `#545B64` グレー   | 公開リクエスト経路   | ユーザ→WAF→CloudFront→ALB→ECS, SSR→API, DNS 名前解決                                |
| `#DD344C` 赤       | 認証                 | API→Cognito                                                                         |
| `#2E73B8` 青       | データ層アクセス     | SQL, オブジェクトストレージ (S3) アクセス, セッション R/W, レプリケーション（破線） |
| `#E7157B` マゼンタ | 非同期 / イベント    | EventBridge, SQS, SES                                                               |
| `#3F8624` 緑       | 監査・監視           | ログ集約, 検知結果集約, アラート通知                                                |
| `#232F3E` 黒       | 制御・管理・外部連携 | CI/CD, Secrets/KMS 取得, 運用アクセス, VPN/外部 API                                 |

ノードのアイコン色（サービスカテゴリ色）とコネクタ色は別物として扱う。コネクタはあくまで「フローの目的」で着色する。上表に無いフローは、最も近い目的カテゴリの意図で分類する（例: アプリからストレージへのデータ取得はデータ層アクセス＝青）。

凡例ボックスは、テキスト箱に色サンプルを子要素として relative 座標で配置して作る。色サンプルは細い矩形 (vertex) を使う。edge と絶対 mxPoint で作ると枠外に飛ぶので使わない。

```xml
<mxCell id="legend" value="凡例" style="rounded=1;absoluteArcSize=1;arcSize=8;whiteSpace=wrap;html=1;fillColor=none;strokeColor=#AAB7B8;verticalAlign=top;align=left;spacingLeft=8;spacingTop=6;fontFamily=Helvetica;fontSize=12;fontStyle=1;" vertex="1" parent="1">
  <mxGeometry x="800" y="400" width="220" height="80" as="geometry" />
</mxCell>
<mxCell id="legend-s1" value="" style="fillColor=#545B64;strokeColor=#545B64;html=1;" vertex="1" parent="legend">
  <mxGeometry x="12" y="34" width="36" height="4" as="geometry" />
</mxCell>
<mxCell id="legend-t1" value="公開リクエスト経路" style="text;html=1;align=left;verticalAlign=middle;fontFamily=Helvetica;fontSize=12;" vertex="1" parent="legend">
  <mxGeometry x="55" y="26" width="150" height="20" as="geometry" />
</mxCell>
<mxCell id="legend-s2" value="" style="fillColor=#2E73B8;strokeColor=#2E73B8;html=1;" vertex="1" parent="legend">
  <mxGeometry x="12" y="58" width="36" height="4" as="geometry" />
</mxCell>
<mxCell id="legend-t2" value="データ層アクセス" style="text;html=1;align=left;verticalAlign=middle;fontFamily=Helvetica;fontSize=12;" vertex="1" parent="legend">
  <mxGeometry x="55" y="50" width="150" height="20" as="geometry" />
</mxCell>
```

### 矢印の向き

- 単方向はリクエスト/レスポンスが明確な場合に使用する
- 双方向は双方向通信の場合に使用する

### 矢印のスタイル

```xml
<mxCell id="edge1"
  style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;strokeWidth=2;fontFamily=Helvetica;fontSize=12;"
  edge="1" source="ec2" target="rds" parent="1">
  <mxGeometry relative="1" as="geometry" />
</mxCell>

<mxCell id="edge1-label" value="MySQL (3306)"
  style="edgeLabel;html=1;align=center;verticalAlign=middle;resizable=0;points=[];fontFamily=Helvetica;fontSize=12;"
  vertex="1" connectable="0" parent="edge1">
  <mxGeometry x="0" y="30" relative="1" as="geometry">
    <mxPoint as="offset" />
  </mxGeometry>
</mxCell>
```

## ベストプラクティス

### 1. シンプルさを保つ

- 必要最小限のコンポーネントのみを表示
- 詳細は別の図に分割

### 2. 一貫性を保つ

- アイコンサイズは図の中で統一する (既定は各 provider リファレンスの値。複数 provider が混在する図では 60 前後に揃える)
- フォントサイズは layout-best-practices.md の正準値に従う（ノードラベル 12px/タイトル 24px）
- アイコンの色は各 provider のリファレンスの既定に従う
- 既存図に要素を追加する場合は、追加するセルのスタイルを既存セルの流儀に合わせる（既存が簡略スタイルならフルスタイルを混在させない）

### 3. 可読性を重視

- 十分な余白を確保
- ラベルは読みやすい位置に配置
- 矢印の交差を最小限に

### 4. コンテキストを提供

- タイトルを追加
- 凡例を追加（複数のアイコン種別やコネクタ色を使用する場合）
- 日付やバージョンを記載
