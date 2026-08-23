# Azure アーキテクチャ図ベストプラクティス

## 概要

Azure アーキテクチャ図を draw.io で作成する際のガイドライン。粒度・帯・コネクタの色と線種・凡例・命名など provider に依存しない原則は [architecture-principles.md](./architecture-principles.md) を参照する。本ファイルには Azure 固有のアイコン・色・境界表現のみを記載する。

## アイコンの利用方法

### draw.io 組み込みライブラリ (`azure2` 画像シェイプ)

Azure アイコンは `image` スタイル + `image=img/lib/azure2/<category>/<Name>.svg` を使う。drawio 本体に同梱された SVG を参照するため、ネットワーク接続は不要。

#### 基本 style

```
image;aspect=fixed;html=1;points=[];align=center;fontSize=12;fontFamily=Helvetica;image=img/lib/azure2/<category>/<Name>.svg;
```

`image` は draw.io の定義済みスタイル名で、ラベルはアイコンの下に出る。サイズは 64x64 を既定にする (索引上は 64x64/68x68 が多く、`aspect=fixed` で縦横比は保たれる)。

#### 世代について

`azure2` (索引 645 件) が現行世代であり、本 skill ではこれを使う。旧世代として `mxgraph.azure.*` (109 件) と `mxgraph.mscae.*`/`img/lib/mscae/*.svg` (旧 Cloud and Enterprise) があるが使わない。`mxgraph.azure.*` は `fillColor` を明示しないと不可視になる罠があり、実際に `mxgraph.azure.key_vault` を試したところ無地の四角になった (名前違いか旧世代の問題かは未特定。いずれにせよ本 skill では使わない)。

#### カテゴリ (フォルダ) と件数 (取得日: 2026-08-23、`search-index.json` を集計)

ai_machine_learning 30/app_services 9/compute 37/analytics 14/databases 27/networking 51/azure_ecosystem 3/azure_stack 8/blockchain 6/containers 7/devops 10/other 148/general 98/hybrid_multicloud 5/identity 35/intune 17/integration 21/storage 17/iot 19/management_governance 32/migrate 5/preview 9/security 14/web 5 ほか。

#### 名前の取得元

`azure2` の `<category>/<Name>` を推測してはならない。無効な名前は空表示になる。一次情報源は jgraph/drawio-mcp の shape 索引 (`search-index.json`)。検索コマンドと実出力の例は次の通り (取得日: 2026-08-23。jgraph/drawio-mcp の `shape-search/search-index.json` を `idx` に読み込み、`style` に `img/lib/azure2/` を含む要素の `title` を部分一致で引いた)。

```
node -e '
const idx=JSON.parse(require("fs").readFileSync("search-index.json","utf8"));
const az=idx.filter(s=>(s.style||"").includes("img/lib/azure2/"));
for (const w of ["cosmos","virtual network gateway","postgresql","container apps"]) {
  const h=az.filter(s=>(s.title||"").toLowerCase().includes(w));
  console.log(w+": "+h.map(s=>s.title+" {"+/azure2\/([^;]+)\.svg/.exec(s.style)[1]+" "+s.w+"x"+s.h+"}").join(" | "));
}'
cosmos: Cosmos DB {databases/Azure_Cosmos_DB 64x64}
virtual network gateway: Virtual Network Gateways {networking/Virtual_Network_Gateways 52x69}
postgresql: Database PostgreSQL Server {databases/Azure_Database_PostgreSQL_Server 48x64} | Database PostgreSQL Server Group {databases/Azure_Database_PostgreSQL_Server_Group 60x68} | Arc PostgreSQL {other/Arc_PostgreSQL 65x68}
container apps:
```

(`container apps` は該当なし = Container Apps 専用アイコンは索引に無い)

ライブラリ横断の調べ方 (asar の grep 等) は [icon-lookup.md](./icon-lookup.md) を参照。

#### 代表アイコン (79 個。`<category>/<Name>` の形)

- コンピューティング: `compute/Virtual_Machine`/`compute/VM_Scale_Sets`/`compute/Availability_Sets`/`compute/Kubernetes_Services` (AKS)/`compute/Function_Apps`/`compute/Container_Instances`/`compute/Batch_Accounts`/`compute/Service_Fabric_Clusters`/`compute/Azure_Spring_Cloud`/`compute/Disks`
- App Service 系: `app_services/App_Services`/`app_services/App_Service_Plans`/`app_services/API_Management_Services`/`app_services/CDN_Profiles`/`preview/Static_Apps`
- データベース: `databases/SQL_Database`/`databases/SQL_Managed_Instance`/`databases/SQL_Server`/`databases/Azure_Database_PostgreSQL_Server`/`databases/Azure_Database_MySQL_Server`/`databases/Azure_Database_MariaDB_Server`/`databases/Azure_Cosmos_DB`/`databases/Cache_Redis`/`databases/Data_Factory`
- ストレージ: `storage/Storage_Accounts`/`general/Blob_Block`/`general/Storage_Azure_Files`/`general/Storage_Queue`/`general/Table`/`storage/Data_Lake_Storage_Gen1`
- ネットワーキング (基盤): `networking/Virtual_Networks` (VNet)/`networking/Subnet`/`networking/Network_Security_Groups` (NSG)/`networking/Load_Balancers`/`networking/Application_Gateways`/`networking/Front_Doors`/`networking/Traffic_Manager_Profiles`/`networking/Public_IP_Addresses`/`networking/NAT`/`networking/Route_Tables`/`networking/DNS_Zones`/`networking/Virtual_Router`
- ネットワーキング (接続・セキュリティ): `networking/Firewalls` (Azure Firewall)/`networking/Web_Application_Firewall_Policies_WAF`/`networking/DDoS_Protection_Plans`/`networking/ExpressRoute_Circuits`/`networking/Virtual_Network_Gateways` (VPN Gateway)/`networking/Private_Link`/`networking/Private_Endpoint`/`networking/Bastions`/`networking/Virtual_WANs`/`networking/On_Premises_Data_Gateways`
- セキュリティ・ID: `security/Key_Vaults`/`security/Azure_Sentinel`/`security/Application_Security_Groups`/`identity/Azure_Active_Directory`/`identity/Entra_ID_Protection`/`identity/Managed_Identities`/`identity/Users`
- コンテナ・統合・メッセージング: `containers/Container_Registries` (ACR)/`general/Service_Bus`/`analytics/Event_Hubs`/`integration/Event_Grid_Domains`/`integration/Logic_Apps`
- 運用・管理: `management_governance/Monitor`/`devops/Application_Insights`/`analytics/Log_Analytics_Workspaces`/`management_governance/Automation_Accounts`/`management_governance/Policy`/`general/Resource_Groups`/`general/Subscriptions`
- 分析・AI・IoT: `analytics/Azure_Synapse_Analytics`/`analytics/Azure_Databricks`/`iot/IoT_Hub`/`ai_machine_learning/Azure_OpenAI`/`ai_machine_learning/Machine_Learning`/`web/SignalR`
- 周辺要素: `general/Browser`/`general/Mobile`

#### 制約

Container Apps、Azure DevOps、GitHub のアイコンは索引に無い。Entra ID は `identity/Entra_ID_Protection` 等の派生名のみで、単体の「Entra ID」という title は無い (`identity/Azure_Active_Directory` を使う)。

## スタイル詳細

基本 style の各キーの意味は次の通り。

- `image` - draw.io の画像シェイプ (定義済みスタイル名)
- `aspect=fixed` - アスペクト比固定
- `html=1` - HTML ラベルを有効化
- `points=[]` - 接続ポイントを既定のまま使う
- `align=center` - ラベルを中央揃え
- `fontSize=12;fontFamily=Helvetica` - 本 skill の正準フォント設定
- `image=img/lib/azure2/<category>/<Name>.svg` - Azure アイコンの指定

## 色の使い方

`azure2` の SVG は各アイコンにブランド色が焼き込まれているため、`fillColor` は指定しない。枠 (コンテナ) の既定色は次の通りで、本 skill が決めた値であり Microsoft 公式の規定ではない。

| 境界           | `fillColor` | `strokeColor` | 備考                |
| -------------- | ----------- | ------------- | ------------------- |
| Subscription   | `none`      | `#605E5C`     | `dashed=1` を付ける |
| Resource Group | `#F3F2F1`   | `#8A8886`     |                     |
| VNet           | `#E6F2FB`   | `#0078D4`     |                     |
| Subnet         | `#F3F9FD`   | `#7FBCE9`     | `dashed=1` を付ける |

## 境界 (コンテナ) の表現

`azure2` は `Resource_Groups`/`Subscriptions`/`Virtual_Networks`/`Subnet` をアイコンとして持つが、枠 (group) 用シェイプは無い。境界は draw.io の汎用コンテナで描く。Azure の典型的な階層は Subscription → Resource Group → VNet → Subnet。子は `parent=<コンテナ id>` にして座標をコンテナ相対にし、コンテナをまたぐエッジは `parent="1"` にする (コンテナ内に置くとクリップされる)。必要なら枠の左上に該当するアイコン (`Resource_Groups` 等) を小さく添えてもよい。

本 skill の既定の枠 style (ラベルは左上、`container=1;pointerEvents=0` 必須):。

```
rounded=0;whiteSpace=wrap;html=1;container=1;pointerEvents=0;collapsible=0;recursiveResize=0;verticalAlign=top;align=left;spacingLeft=8;spacingTop=4;fontSize=12;fontStyle=1;fontFamily=Helvetica;fillColor=<枠の地色>;strokeColor=<枠線色>;fontColor=<枠線色と同じ>;
```

4 段の入れ子の例 (色の使い方の表を適用したセル断片):。

```xml
<mxCell id="subscription" value="Subscription" style="rounded=0;whiteSpace=wrap;html=1;container=1;pointerEvents=0;collapsible=0;recursiveResize=0;verticalAlign=top;align=left;spacingLeft=8;spacingTop=4;fontSize=12;fontStyle=1;fontFamily=Helvetica;fillColor=none;strokeColor=#605E5C;dashed=1;fontColor=#605E5C;" vertex="1" parent="1">
  <mxGeometry x="40" y="40" width="720" height="480" as="geometry"/>
</mxCell>
<mxCell id="rg" value="Resource Group" style="rounded=0;whiteSpace=wrap;html=1;container=1;pointerEvents=0;collapsible=0;recursiveResize=0;verticalAlign=top;align=left;spacingLeft=8;spacingTop=4;fontSize=12;fontStyle=1;fontFamily=Helvetica;fillColor=#F3F2F1;strokeColor=#8A8886;fontColor=#8A8886;" vertex="1" parent="subscription">
  <mxGeometry x="40" y="40" width="640" height="400" as="geometry"/>
</mxCell>
<mxCell id="vnet-nest" value="VNet" style="rounded=0;whiteSpace=wrap;html=1;container=1;pointerEvents=0;collapsible=0;recursiveResize=0;verticalAlign=top;align=left;spacingLeft=8;spacingTop=4;fontSize=12;fontStyle=1;fontFamily=Helvetica;fillColor=#E6F2FB;strokeColor=#0078D4;fontColor=#0078D4;" vertex="1" parent="rg">
  <mxGeometry x="40" y="40" width="560" height="320" as="geometry"/>
</mxCell>
<mxCell id="subnet-nest" value="Subnet" style="rounded=0;whiteSpace=wrap;html=1;container=1;pointerEvents=0;collapsible=0;recursiveResize=0;verticalAlign=top;align=left;spacingLeft=8;spacingTop=4;fontSize=12;fontStyle=1;fontFamily=Helvetica;fillColor=#F3F9FD;strokeColor=#7FBCE9;dashed=1;fontColor=#7FBCE9;" vertex="1" parent="vnet-nest">
  <mxGeometry x="40" y="40" width="480" height="240" as="geometry"/>
</mxCell>
```

## 最小構成の例

VNet 枠の中に Subnet 枠を置き、その中に Virtual Machine を配置する。VNet 枠の外に Front Door と SQL Database を置き、ブラウザ → Front Door → (VNet/Subnet 内の) Virtual Machine → SQL Database の接続を描く。Front Door → VM と VM → SQL Database は枠をまたぐので `parent="1"`。

```xml
<mxfile host="app.diagrams.net">
  <diagram name="azure-minimal">
    <mxGraphModel>
      <root>
        <mxCell id="0"/>
        <mxCell id="1" parent="0"/>
        <mxCell id="vnet" value="VNet" style="rounded=0;whiteSpace=wrap;html=1;container=1;pointerEvents=0;collapsible=0;recursiveResize=0;verticalAlign=top;align=left;spacingLeft=8;spacingTop=4;fontSize=12;fontStyle=1;fontFamily=Helvetica;fillColor=#E6F2FB;strokeColor=#0078D4;fontColor=#0078D4;" vertex="1" parent="1">
          <mxGeometry x="280" y="120" width="320" height="200" as="geometry"/>
        </mxCell>
        <mxCell id="subnet" value="Subnet" style="rounded=0;whiteSpace=wrap;html=1;container=1;pointerEvents=0;collapsible=0;recursiveResize=0;verticalAlign=top;align=left;spacingLeft=8;spacingTop=4;fontSize=12;fontStyle=1;fontFamily=Helvetica;fillColor=#F3F9FD;strokeColor=#7FBCE9;dashed=1;fontColor=#7FBCE9;" vertex="1" parent="vnet">
          <mxGeometry x="40" y="40" width="240" height="120" as="geometry"/>
        </mxCell>
        <mxCell id="vm" value="Virtual Machine" style="image;aspect=fixed;html=1;points=[];align=center;fontSize=12;fontFamily=Helvetica;image=img/lib/azure2/compute/Virtual_Machine.svg;" vertex="1" parent="subnet">
          <mxGeometry x="88" y="30" width="64" height="64" as="geometry"/>
        </mxCell>
        <mxCell id="frontdoor" value="Front Door" style="image;aspect=fixed;html=1;points=[];align=center;fontSize=12;fontFamily=Helvetica;image=img/lib/azure2/networking/Front_Doors.svg;" vertex="1" parent="1">
          <mxGeometry x="80" y="190" width="64" height="64" as="geometry"/>
        </mxCell>
        <mxCell id="sqldb" value="SQL Database" style="image;aspect=fixed;html=1;points=[];align=center;fontSize=12;fontFamily=Helvetica;image=img/lib/azure2/databases/SQL_Database.svg;" vertex="1" parent="1">
          <mxGeometry x="680" y="190" width="64" height="64" as="geometry"/>
        </mxCell>
        <mxCell id="browser" value="Browser" style="image;aspect=fixed;html=1;points=[];align=center;fontSize=12;fontFamily=Helvetica;image=img/lib/azure2/general/Browser.svg;" vertex="1" parent="1">
          <mxGeometry x="80" y="20" width="64" height="64" as="geometry"/>
        </mxCell>
        <mxCell id="e1" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;strokeWidth=2;fontFamily=Helvetica;fontSize=12;" edge="1" source="browser" target="frontdoor" parent="1">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>
        <mxCell id="e2" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;strokeWidth=2;fontFamily=Helvetica;fontSize=12;" edge="1" source="frontdoor" target="vm" parent="1">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>
        <mxCell id="e3" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;strokeWidth=2;fontFamily=Helvetica;fontSize=12;" edge="1" source="vm" target="sqldb" parent="1">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
```

## 参考資料

- [Azure architecture icons](https://learn.microsoft.com/azure/architecture/icons/)
- [jgraph/drawio-mcp](https://github.com/jgraph/drawio-mcp) - shape 索引の出所
