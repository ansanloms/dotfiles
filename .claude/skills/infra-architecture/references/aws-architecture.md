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

他ライブラリを含む横断的な調べ方は [icon-lookup.md](./icon-lookup.md) を参照。

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

図の粒度（俯瞰図と詳細図）、レイアウト原則（左右上下配置・グループ化・帯配置）、命名規則、矢印とデータフロー、ベストプラクティスといった provider 非依存の原則は [architecture-principles.md](./architecture-principles.md) を参照。

## レイアウト原則

### 1. 階層構造を明示する

VPC、サブネット、セキュリティグループなどの境界を視覚的に表現する。subnet 専用の group アイコンは無いため、subnet は `grIcon=mxgraph.aws4.group_security_group` を使い、public/private は色で区別する。public subnet は緑系 (`fillColor=#E9F3E6`/`strokeColor=#248814`/`fontColor=#248814`)、private subnet は青系 (`fillColor=#E6F2F8`/`strokeColor=#147EBA`/`fontColor=#147EBA`) を使う。

コンテナへのリソース配置には 2 方式がある。`container=1` を設定し子要素に `parent=<コンテナID>` を指定すると、意味的な入れ子になり座標もコンテナ相対になる（下記例の方式。リソースがコンテナの子であることを要する場合はこちら）。一方 `container=0` にして全ノードを `parent="1"` のまま絶対座標で枠内に配置する方式もある (多ノードでは座標管理がしやすい)。レンダリング結果は同じなので次で選ぶ。リソースをコンテナの子として扱いたい (まとめて移動・折りたたみ等) なら `container=1`、ノード数が多く座標を独立管理したいなら `container=0`。迷ったら `container=1` を既定とする。

```xml
<mxCell id="vpc" value="VPC"
  style="points=[[0,0],[0.25,0],[0.5,0],[0.75,0],[1,0],[1,0.25],[1,0.5],[1,0.75],[1,1],[0.75,1],[0.5,1],[0.25,1],[0,1],[0,0.75],[0,0.5],[0,0.25]];outlineConnect=0;gradientColor=none;html=1;whiteSpace=wrap;fontSize=12;fontStyle=0;container=1;pointerEvents=0;collapsible=0;recursiveResize=0;shape=mxgraph.aws4.group;grIcon=mxgraph.aws4.group_vpc;strokeColor=#248814;fillColor=none;verticalAlign=top;align=left;spacingLeft=30;fontColor=#AAB7B8;dashed=0;"
  vertex="1" parent="1">
  <mxGeometry x="80" y="80" width="640" height="480" as="geometry" />
</mxCell>

<mxCell id="subnet" value="Public Subnet"
  style="points=[[0,0],[0.25,0],[0.5,0],[0.75,0],[1,0],[1,0.25],[1,0.5],[1,0.75],[1,1],[0.75,1],[0.5,1],[0.25,1],[0,1],[0,0.75],[0,0.5],[0,0.25]];outlineConnect=0;gradientColor=none;html=1;whiteSpace=wrap;fontSize=12;fontStyle=0;container=1;pointerEvents=0;collapsible=0;recursiveResize=0;shape=mxgraph.aws4.group;grIcon=mxgraph.aws4.group_security_group;grStroke=0;strokeColor=#248814;fillColor=#E9F3E6;verticalAlign=top;align=left;spacingLeft=30;fontColor=#248814;dashed=0;"
  vertex="1" parent="vpc">
  <mxGeometry x="40" y="40" width="280" height="200" as="geometry" />
</mxCell>

<mxCell id="ec2" value="Web Server"
  style="sketch=0;outlineConnect=0;fontColor=#232F3E;gradientColor=none;fillColor=#ED7100;strokeColor=#ffffff;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;fontStyle=0;aspect=fixed;pointerEvents=1;shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.ec2;fontFamily=Helvetica;"
  vertex="1" parent="subnet">
  <mxGeometry x="100" y="60" width="78" height="78" as="geometry" />
</mxCell>
```

その他のレイアウト原則（左から右・上から下へのフロー、同じ階層の水平配置、グループ化、横断サービスの帯配置）は [architecture-principles.md](./architecture-principles.md) を参照。

## 参考資料

- [AWS Architecture Icons](https://aws.amazon.com/architecture/icons/)
- [draw.io AWS diagrams guide](https://www.drawio.com/blog/aws-diagrams)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Atlassian Architecture Diagram guide](https://www.atlassian.com/work-management/project-management/architecture-diagram)
- [AWS の"俯瞰"構成図を自動生成する](https://qiita.com/ntaka329/items/d457f309e33c4602a693) - 俯瞰図の粒度・帯配置・見やすさの機械チェックの出典
