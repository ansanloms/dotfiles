# AWS アーキテクチャ図ベストプラクティス

## 概要

AWS アーキテクチャ図を draw.io で作成する際のガイドライン。

## AWS アイコンの利用方法

### draw.io 組み込みライブラリ（AWS 2025）

draw.io には AWS 2025 ライブラリが組み込まれている。これが最も簡単な方法。

#### 主要な AWS サービスの resIcon 値

##### コンピューティング

- EC2: `shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.ec2;fillColor=#ED7100;strokeColor=#ffffff;`
- Lambda: `shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.lambda_function;fillColor=#ED7100;strokeColor=#ffffff;`
- ECS: `shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.ecs;fillColor=#ED7100;strokeColor=#ffffff;`
- ECS on Fargate: `shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.fargate;fillColor=#ED7100;strokeColor=#ffffff;`
- EKS: `shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.eks_cloud;fillColor=#ED7100;strokeColor=#ffffff;`

##### ストレージ

- S3: `shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.s3;fillColor=#7AA116;strokeColor=#ffffff;`
- EBS: `shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.elastic_block_store;fillColor=#7AA116;strokeColor=#ffffff;`
- EFS: `shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.efs;fillColor=#7AA116;strokeColor=#ffffff;`

##### データベース

- RDS: `shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.rds;fillColor=#2E73B8;strokeColor=#ffffff;`
- DynamoDB: `shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.dynamodb;fillColor=#2E73B8;strokeColor=#ffffff;`
- ElastiCache: `shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.elasticache;fillColor=#2E73B8;strokeColor=#ffffff;`
- Aurora: `shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.aurora;fillColor=#2E73B8;strokeColor=#ffffff;`

##### ネットワーキング

- VPC: `shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.vpc;fillColor=#8C4FFF;strokeColor=#ffffff;`
- ALB: `shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.application_load_balancer;fillColor=#8C4FFF;strokeColor=#ffffff;`
- NLB: `shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.network_load_balancer;fillColor=#8C4FFF;strokeColor=#ffffff;`
- CloudFront: `shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.cloudfront;fillColor=#8C4FFF;strokeColor=#ffffff;`
- Route 53: `shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.route_53;fillColor=#8C4FFF;strokeColor=#ffffff;`

##### アプリ統合

- API Gateway: `shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.api_gateway;fillColor=#FF4F8B;strokeColor=#ffffff;`

##### セキュリティ

- IAM: `shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.identity_and_access_management;fillColor=#DD344C;strokeColor=#ffffff;`
- Cognito: `shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.cognito;fillColor=#DD344C;strokeColor=#ffffff;`
- WAF: `shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.waf;fillColor=#DD344C;strokeColor=#ffffff;`

##### 管理・監視

- CloudWatch: `shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.cloudwatch;fillColor=#E7157B;strokeColor=#ffffff;`
- CloudTrail: `shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.cloudtrail;fillColor=#E7157B;strokeColor=#ffffff;`

### resIcon 名の正規の取得元（重要）

上記の resIcon 一覧は主要サービスの抜粋であり、網羅していない。また AWS のステンシル名は命名規則が一定でない（`ecs` のような略称と `elastic_container_service` のようなフル名が混在し、後者は存在しないこともある）。**サービスの正式名からステンシル名を推測してはならない。**推測した名前が無効だとアイコンが描画されない（空表示になる）。

resIcon 名の一次情報源は、**レンダリングに使う drawio 本体にバンドルされたシェイプ定義** (`app.asar`)。実際に使うレンダラと同一なので最も確実。

#### app.asar の場所を特定する

`app.asar` の場所は環境依存（`/opt/drawio/resources/` や nix の `share/lib/drawio/resources/` など）。決め打ちせず、インストール先から発見する。

```bash
ASAR=$(find -L "$(dirname "$(dirname "$(readlink -f "$(which drawio)")")")" -name app.asar 2>/dev/null | head -1)
echo "$ASAR"
```

#### resIcon 名を確認する

候補のステンシル名が app.asar に含まれるかを grep で確認する（例: ECS/Fargate）。

```bash
grep -aoE 'mxgraph\.aws4\.(ecs|fargate)' "$ASAR" | sort -u
```

grep で見つかれば有効。ただし**grep の不在は「無効」を意味しない**。app.asar の格納形式の都合で、有効なのに plaintext grep に現れない名前がある（例: `eks_cloud` は grep に出ないが正しく描画される）。`resIcon=` 接頭辞付きの grep は特に取りこぼしが多いので使わない。

resIcon 名の最終的な真偽は、推奨ワークフローの**PNG レンダリングで判定する**。アイコンが空表示になったら resIcon 名が誤り。grep は推測を避けるための事前確認であって、レンダリング結果が最終判定。

### AWS アイコンのスタイル詳細

```
sketch=0;
outlineConnect=0;
fontColor=#232F3E;
gradientColor=none;
fillColor=#ED7100;
strokeColor=#ffffff;
dashed=0;
verticalLabelPosition=bottom;
verticalAlign=top;
align=center;
html=1;
fontSize=12;
fontStyle=0;
aspect=fixed;
pointerEvents=1;
shape=mxgraph.aws4.resourceIcon;
resIcon=mxgraph.aws4.ec2;
fontFamily=Helvetica;
```

重要なポイントは次の通り。

- `shape=mxgraph.aws4.resourceIcon` - AWS リソースアイコンの基本形状
- `resIcon=mxgraph.aws4.<service_name>` - AWS サービスの指定
- `fillColor` - AWS の公式カラー（サービスカテゴリごとに異なる）
- `gradientColor=none` - グラデーションなし
- `strokeColor=#ffffff` - アイコンの白い縁取り
- `aspect=fixed` - アスペクト比固定

### 色の使い方

AWS の公式カラーパレットを使用する。

- オレンジ（コンピューティング）: `#ED7100`
- 緑（ストレージ）: `#7AA116`
- 青（データベース）: `#2E73B8`
- 紫（ネットワーキング）: `#8C4FFF`
- 赤（セキュリティ）: `#DD344C`
- ピンク（管理・監視）: `#E7157B`
- ローズ（アプリ統合）: `#FF4F8B`
- グラデーションは使わない： `gradientColor=none;`
- 線は常に白： `strokeColor=#ffffff`

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

### 1. 階層構造を明示する

VPC、サブネット、セキュリティグループなどの境界を視覚的に表現する。subnet 専用の group アイコンは無いため、subnet は `grIcon=mxgraph.aws4.group_security_group` を使い、public/private は色で区別する。public subnet は緑系 (`fillColor=#E9F3E6`/`strokeColor=#248814`/`fontColor=#248814`)、private subnet は青系 (`fillColor=#E6F2F8`/`strokeColor=#147EBA`/`fontColor=#147EBA`) を使う。

コンテナへのリソース配置には 2 方式がある。`container=1` を設定し子要素に `parent=<コンテナID>` を指定すると、意味的な入れ子になり座標もコンテナ相対になる（下記例の方式。リソースがコンテナの子であることを要する場合はこちら）。一方 `container=0` にして全ノードを `parent="1"` のまま絶対座標で枠内に配置する方式もある (多ノードでは座標管理がしやすい)。レンダリング結果は同じなので次で選ぶ。リソースをコンテナの子として扱いたい (まとめて移動・折りたたみ等) なら `container=1`、ノード数が多く座標を独立管理したいなら `container=0`。迷ったら `container=1` を既定とする。

```xml
<!-- VPC コンテナ -->
<mxCell id="vpc" value="VPC"
  style="points=[[0,0],[0.25,0],[0.5,0],[0.75,0],[1,0],[1,0.25],[1,0.5],[1,0.75],[1,1],[0.75,1],[0.5,1],[0.25,1],[0,1],[0,0.75],[0,0.5],[0,0.25]];outlineConnect=0;gradientColor=none;html=1;whiteSpace=wrap;fontSize=12;fontStyle=0;container=1;pointerEvents=0;collapsible=0;recursiveResize=0;shape=mxgraph.aws4.group;grIcon=mxgraph.aws4.group_vpc;strokeColor=#248814;fillColor=none;verticalAlign=top;align=left;spacingLeft=30;fontColor=#AAB7B8;dashed=0;"
  vertex="1" parent="1">
  <mxGeometry x="80" y="80" width="640" height="480" as="geometry" />
</mxCell>

<!-- VPC 内のサブネット -->
<mxCell id="subnet" value="Public Subnet"
  style="points=[[0,0],[0.25,0],[0.5,0],[0.75,0],[1,0],[1,0.25],[1,0.5],[1,0.75],[1,1],[0.75,1],[0.5,1],[0.25,1],[0,1],[0,0.75],[0,0.5],[0,0.25]];outlineConnect=0;gradientColor=none;html=1;whiteSpace=wrap;fontSize=12;fontStyle=0;container=1;pointerEvents=0;collapsible=0;recursiveResize=0;shape=mxgraph.aws4.group;grIcon=mxgraph.aws4.group_security_group;grStroke=0;strokeColor=#248814;fillColor=#E9F3E6;verticalAlign=top;align=left;spacingLeft=30;fontColor=#248814;dashed=0;"
  vertex="1" parent="vpc">
  <mxGeometry x="40" y="40" width="280" height="200" as="geometry" />
</mxCell>

<!-- サブネット内の EC2 -->
<mxCell id="ec2" value="Web Server"
  style="sketch=0;outlineConnect=0;fontColor=#232F3E;gradientColor=none;fillColor=#ED7100;strokeColor=#ffffff;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.ec2;fontFamily=Helvetica;"
  vertex="1" parent="subnet">
  <mxGeometry x="100" y="60" width="78" height="78" as="geometry" />
</mxCell>
```

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
<mxCell id="legend" value="凡例" style="rounded=1;whiteSpace=wrap;html=1;fillColor=none;strokeColor=#AAB7B8;verticalAlign=top;align=left;spacingLeft=8;spacingTop=6;fontFamily=Helvetica;fontSize=12;fontStyle=1;" vertex="1" parent="1">
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
<!-- 標準的な矢印 -->
<mxCell id="edge1"
  style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;strokeWidth=2;fontFamily=Helvetica;fontSize=12;"
  edge="1" source="ec2" target="rds" parent="1">
  <mxGeometry relative="1" as="geometry" />
</mxCell>

<!-- ラベル付き矢印 -->
<mxCell id="edge1-label" value="MySQL (3306)"
  style="edgeLabel;html=1;align=center;verticalAlign=middle;resizable=0;points=[];fontFamily=Helvetica;fontSize=12;"
  vertex="1" connectable="0" parent="edge1">
  <mxGeometry x="0" y="30" relative="1" as="geometry">
    <mxPoint as="offset" />
  </mxGeometry>
</mxCell>
```

## テンプレート例

### 3層アーキテクチャ

```
[CloudFront]
     ↓
   [ALB]
     ↓
[EC2 Web Tier]
     ↓
[EC2 App Tier]
     ↓
[RDS Database]
```

### サーバーレスアーキテクチャ

```
[API Gateway] → [Lambda] → [DynamoDB]
                    ↓
               [S3 Bucket]
```

### マイクロサービス

```
[Route 53]
     ↓
[CloudFront]
     ↓
[API Gateway]
     ↓
   [ALB]
     ↓
[ECS Service 1] [ECS Service 2] [ECS Service 3]
     ↓               ↓               ↓
 [RDS Aurora]    [DynamoDB]    [ElastiCache]
```

## ベストプラクティス

### 1. シンプルさを保つ

- 必要最小限のコンポーネントのみを表示
- 詳細は別の図に分割

### 2. 一貫性を保つ

- アイコンサイズを統一（単体・小規模図: 78x78/複合アーキテクチャ図: 60x60）
- フォントサイズは layout-best-practices.md の正準値に従う（ノードラベル 12px/タイトル 24px）
- 色は AWS 公式カラーを使用
- 既存図に要素を追加する場合は、追加するセルのスタイルを既存セルの流儀に合わせる（既存が簡略スタイルならフルスタイルを混在させない）

### 3. 可読性を重視

- 十分な余白を確保
- ラベルは読みやすい位置に配置
- 矢印の交差を最小限に

### 4. コンテキストを提供

- タイトルを追加
- 凡例を追加（複数のアイコン種別やコネクタ色を使用する場合）
- 日付やバージョンを記載

## 参考資料

- [AWS Architecture Icons](https://aws.amazon.com/architecture/icons/)
- [draw.io AWS diagrams guide](https://www.drawio.com/blog/aws-diagrams)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Atlassian Architecture Diagram guide](https://www.atlassian.com/work-management/project-management/architecture-diagram)
- [AWS の"俯瞰"構成図を自動生成する](https://qiita.com/ntaka329/items/d457f309e33c4602a693) - 俯瞰図の粒度・帯配置・見やすさの機械チェックの出典
