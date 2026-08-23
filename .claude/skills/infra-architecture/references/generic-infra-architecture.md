# オンプレミス・汎用インフラアーキテクチャ図ベストプラクティス

## 概要

オンプレミス (汎用ネットワーク機器・Cisco・ラック)、Kubernetes、およびそれらとクラウドが混在するハイブリッド・マルチクラウド構成の図を draw.io で作成する際のガイドライン。粒度・帯・コネクタの色と線種・凡例・命名など provider に依存しない原則は [architecture-principles.md](./architecture-principles.md) を参照する。本ファイルにはこれらのライブラリ固有のアイコン・色・境界表現のみを記載する。

## アイコンの利用方法

### 汎用ネットワーク機器 (`mxgraph.networks`)

`shape=mxgraph.networks.<name>` を直接指定する。

#### 基本 style

```
fontColor=#0066CC;verticalAlign=top;verticalLabelPosition=bottom;labelPosition=center;align=center;html=1;outlineConnect=0;fillColor=#CCCCCC;strokeColor=#6881B3;gradientColor=none;gradientDirection=north;strokeWidth=2;shape=mxgraph.networks.<name>;fontSize=12;fontFamily=Helvetica;
```

注意: `mxgraph.networks.cloud` の sidebar 定義は `fontColor=#ffffff` でラベルを雲の中に白で描くため、白背景の図ではラベルが沈む。雲を使うときは上の基本 style (ラベルを下に、`fontColor=#0066CC`) に揃える。

サイズは 60x60 を基準にし、横長の機器 (`router`/`switch`/`hub`/`modem`/`load_balancer`/`patch_panel`) は 100x30 にする。

#### 名前の取得元 (取得日: 2026-08-23)

```
grep -aoE 'mxgraph\.networks\.[a-z0-9_]+' "$ASAR" | sort -u | sed 's/mxgraph.networks.//' | tr '\n' ' '
biometric_reader bus business_center cloud comm_link comm_link_edge community copier desktop_pc external_storage firewall gamepad hub laptop load_balancer mail_server mainframe mobile modem monitor nas_filer patch_panel pc phone_1 phone_2 printer proxy_server rack radio_tower router satellite satellite_dish scanner secured security_camera server server_storage storage supercomputer switch tablet tape_storage terminal unsecure ups_enterprise ups_small usb_stick user_female user_male users video_projector video_projector_screen virtual_pc virtual_server virus web_server wireless_hub wireless_modem
```

上記のうち `comm_link_edge` と `video_projector_screen` 以外の 57 個を実描画で確認した (`comm_link` はエッジ用の稲妻型、`bus` は横長バー)。

#### 用途別の代表

サーバ `server`/`web_server`/`mail_server`/`proxy_server`/`virtual_server`/`mainframe`/`supercomputer`、ストレージ `storage`/`server_storage`/`nas_filer`/`external_storage`/`tape_storage`、ネットワーク機器 `router`/`switch`/`hub`/`modem`/`firewall`/`load_balancer`/`wireless_hub`/`wireless_modem`/`patch_panel`/`rack`、端末 `pc`/`desktop_pc`/`laptop`/`terminal`/`mobile`/`tablet`/`phone_1`/`phone_2`/`printer`/`scanner`/`copier`、人 `user_male`/`user_female`/`users`、境界 `cloud`/`comm_link`/`bus`/`radio_tower`/`satellite`/`satellite_dish`、その他 `secured`/`unsecure`/`virus`/`security_camera`/`biometric_reader`/`ups_enterprise`/`ups_small`/`usb_stick`/`monitor`/`video_projector`/`business_center`/`community`/`gamepad`。

### Cisco (`mxgraph.cisco19`)

角丸四角の台紙 `shape=mxgraph.cisco19.rect;prIcon=<name>` に機器アイコンを載せる形。一部は単体シェイプ (`mxgraph.cisco19.server2`/`workstation2`/`laptop2`/`cloud`)。

#### 基本 style

```
sketch=0;verticalLabelPosition=bottom;html=1;verticalAlign=top;aspect=fixed;align=center;pointerEvents=1;shape=mxgraph.cisco19.rect;prIcon=<name>;fillColor=#FAFAFA;strokeColor=#005073;fontSize=12;fontFamily=Helvetica;
```

サイズは 50x50 (`router` 等)/64x50 (`firewall`/`load_balancer`/`storage` 等の横長) を既定にする。

#### 実描画で確認したアイコン

`l2_switch`/`l3_switch`/`router`/`wireless_router`/`firewall`/`load_balancer`/`storage`/`asa_5500`/`nexus_9300`/`dual_mode_access_point`/`ip_telephone_router`/`wireless_lan_controller`/`ups`/`vpn_concentrator`。単体シェイプは `server2` (28x50)/`workstation2` (50x40)/`laptop2` (50x35)/`cloud` (50x30、`fillColor=#6B6B6B;strokeColor=none`)。

#### 全 `prIcon` 名の取得元 (取得日: 2026-08-23、索引から)

```
node -e '
const idx=JSON.parse(require("fs").readFileSync("search-index.json","utf8"));
const pr=[...new Set(idx.filter(s=>(s.style||"").includes("mxgraph.cisco19.rect")).map(s=>/prIcon=([a-z0-9_]+)/.exec(s.style)[1]))];
console.log(pr.length); console.log(pr.join(" "));'
195
l2_switch l3_switch l2_modular l3_modular 6500_vss l2_switch_with_dual_supervisor l3_switch_with_dual_supervisor l2_modular2 l3_modular2 6500_vss2 secure_catalyst_switch_color secure_catalyst_switch_subdued secure_switch workgroup_switch secure_catalyst_switch_color3 secure_catalyst_switch_color2 secure_catalyst_switch_subdued2 router csr_1000v wireless_router l3_modular3 ucs_express router_with_voice router_with_firewall netflow_router secure_router ip_telephone_router content_router service_ready_engine cisco_15800 appnav router_with_firewall2 netflow_router2 asr_1000 asr_9000 net_mgmt_appliance nam_virtual_service_blade nexus_9300 hypervisor nexus_9500 fabric_interconnect fibre_channel_director_mds_9000 virtual_matrix_switch ucs_c_series_server nexus_5k_with_integrated_vsm aci aci2 vts2 ucs_5108_blade_chassis storage ups rps nexus_2000_10ge blade_server nexus_5k nexus_4k nexus_3k nexus_2k nexus_1kv_vsm nexus_1k layer3_nexus_5k_switch nexus_1010 nexus_7k fibre_channel_fabric_switch database_relational dual_mode_access_point wireless_location_appliance wireless_lan_controller mesh_access_point (以下省略。残りはビデオ会議・コラボレーション・セキュリティ製品の名前)
```

未掲載の名前を推測して使わない。実際に使う `prIcon` は上の一覧に無ければ [icon-lookup.md](./icon-lookup.md) の索引検索で確認する。

### ラック (`mxgraph.rack.general` / `mxgraph.rackGeneral`)

#### 機器 style

```
strokeColor=#666666;html=1;labelPosition=right;align=left;spacingLeft=15;shadow=0;dashed=0;outlineConnect=0;shape=mxgraph.rack.general.<name>;fontSize=12;fontFamily=Helvetica;
```

ラベルは右横に出る。サイズは 1U = 160x15 (`cat5e_enhanced_patch_panel_48_ports` のみ 160x30)。

#### キャビネット style

```
shape=mxgraph.rackGeneral.rackCabinet3;rackUnitSize=14.8;fillColor2=#f4f4f4;container=1;collapsible=0;childLayout=rack;allowGaps=1;marginLeft=9;marginRight=9;marginTop=21;marginBottom=22;textColor=#666666;numDisp=off;strokeColor=#666666;html=1;verticalLabelPosition=bottom;labelBackgroundColor=#ffffff;verticalAlign=top;outlineConnect=0;shadow=0;dashed=0;
```

機器は `parent` をキャビネットにして縦に積む (`childLayout=rack` が整列する)。

#### 名前の取得元 (取得日: 2026-08-23)

```
grep -aoE 'mxgraph\.rack\.general\.[a-z0-9_]+' "$ASAR" | sort -u | sed 's/mxgraph.rack.general.//' | tr '\n' ' '
1u_rack_server cat5e_enhanced_patch_panel_48_ports cat5e_rack_mount_patch_panel_24_ports cat5e_rack_mount_patch_panel_96_ports hub server_1 server_2 server_3 switches_1 switches_2
```

実描画で確認したのは `1u_rack_server`/`server_1`/`server_2`/`server_3`/`switches_1`/`switches_2`/`hub`/`cat5e_rack_mount_patch_panel_24_ports`/`rackGeneral.rackCabinet3` の 9 個。`cat5e_enhanced_patch_panel_48_ports` と `cat5e_rack_mount_patch_panel_96_ports` は未確認。

### Kubernetes (`mxgraph.kubernetes.icon2`)

`shape=mxgraph.kubernetes.icon2;prIcon=<abbr>` (七角形の青いアイコン)。

#### 基本 style

```
aspect=fixed;sketch=0;html=1;dashed=0;whitespace=wrap;verticalLabelPosition=bottom;verticalAlign=top;fillColor=#2875E2;strokeColor=#ffffff;shape=mxgraph.kubernetes.icon2;prIcon=<abbr>;fontSize=12;fontFamily=Helvetica;
```

サイズは 50x48。`prIcon` は Kubernetes 公式アイコンセットの略称 (38 種。全て実描画で確認済み)。略称と意味の対応は本 skill で付けたもの。

| 略称      | 意味                    | 略称            | 意味                     |
| --------- | ----------------------- | --------------- | ------------------------ |
| `pod`     | Pod                     | `role`          | Role                     |
| `deploy`  | Deployment              | `rb`            | RoleBinding              |
| `svc`     | Service                 | `c_role`        | ClusterRole              |
| `ing`     | Ingress                 | `crb`           | ClusterRoleBinding       |
| `node`    | Node                    | `sa`            | ServiceAccount           |
| `ns`      | Namespace               | `user`          | User                     |
| `cm`      | ConfigMap               | `group`         | Group                    |
| `secret`  | Secret                  | `control_plane` | Control Plane            |
| `sts`     | StatefulSet             | `api`           | kube-apiserver           |
| `ds`      | DaemonSet               | `etcd`          | etcd                     |
| `rs`      | ReplicaSet              | `sched`         | kube-scheduler           |
| `pv`      | PersistentVolume        | `c_m`           | controller-manager       |
| `pvc`     | PersistentVolumeClaim   | `c_c_m`         | cloud-controller-manager |
| `sc`      | StorageClass            | `kubelet`       | kubelet                  |
| `vol`     | Volume                  | `k_proxy`       | kube-proxy               |
| `job`     | Job                     | `crd`           | CustomResourceDefinition |
| `cronjob` | CronJob                 | `limits`        | LimitRange               |
| `hpa`     | HorizontalPodAutoscaler | `quota`         | ResourceQuota            |
| `ep`      | Endpoints               | `psp`           | PodSecurityPolicy        |
| `netpol`  | NetworkPolicy           |                 |                          |

#### 取得元 (取得日: 2026-08-23、索引から。title=prIcon の形)

```
node -e '
const idx=JSON.parse(require("fs").readFileSync("search-index.json","utf8"));
const k=idx.filter(s=>(s.style||"").includes("mxgraph.kubernetes.icon2"));
console.log([...new Set(k.map(s=>{const m=/prIcon=([a-z_0-9]+)/.exec(s.style);return s.title+"="+m[1]}))].join(" "));'
API=api C-C-M=c_c_m CM=cm C-M=c_m C-Role=c_role Control Plane=control_plane CRB=crb CRD=crd CronJob=cronjob Deploy=deploy DS=ds EP=ep ETCD=etcd Group=group HPA=hpa ING=ing Job=job K-proxy=k_proxy Kubelet=kubelet Limits=limits Netpol=netpol Node=node NS=ns Pod=pod PSP=psp PV=pv PVC=pvc Quota=quota RB=rb Role=role RS=rs SA=sa SC=sc Sched=sched Secret=secret STS=sts SVC=svc User=user Vol=vol
```

## スタイル詳細

### 汎用ネットワーク機器

- `fontColor=#0066CC` - ラベル色
- `verticalAlign=top;verticalLabelPosition=bottom;labelPosition=center;align=center` - ラベルをアイコン下部中央に配置
- `html=1` - HTML ラベルを有効化
- `outlineConnect=0` - 接続点をアウトラインに固定しない
- `fillColor=#CCCCCC;strokeColor=#6881B3` - 機器アイコンの既定色
- `gradientColor=none;gradientDirection=north` - グラデーションなし
- `strokeWidth=2` - 枠線の太さ
- `shape=mxgraph.networks.<name>` - 機器の指定
- `fontSize=12;fontFamily=Helvetica` - 本 skill の正準フォント設定

### Cisco

- `sketch=0` - スケッチ風描画を無効化
- `verticalLabelPosition=bottom;verticalAlign=top;align=center` - ラベル配置
- `html=1` - HTML ラベルを有効化
- `aspect=fixed` - アスペクト比固定
- `pointerEvents=1` - クリック判定を形状全体に広げる
- `shape=mxgraph.cisco19.rect;prIcon=<name>` - 台紙と機器アイコンの指定
- `fillColor=#FAFAFA;strokeColor=#005073` - 台紙の色
- `fontSize=12;fontFamily=Helvetica` - 本 skill の正準フォント設定

### ラック

機器: `strokeColor=#666666` (枠線色)/`html=1`/`labelPosition=right;align=left;spacingLeft=15` (ラベルを右横に配置)/`shadow=0;dashed=0;outlineConnect=0`/`shape=mxgraph.rack.general.<name>` (機器の指定)/`fontSize=12;fontFamily=Helvetica`。

キャビネット: `shape=mxgraph.rackGeneral.rackCabinet3` (キャビネット本体)/`rackUnitSize=14.8` (1U の高さ)/`fillColor2=#f4f4f4` (内部の地色)/`container=1;collapsible=0` (子要素を格納するコンテナ)/`childLayout=rack;allowGaps=1` (子要素を縦にラック整列)/`marginLeft/marginRight/marginTop/marginBottom` (内側余白)/`textColor=#666666` (ラベル色)/`numDisp=off` (ユニット番号を非表示)。

### Kubernetes

- `aspect=fixed` - アスペクト比固定
- `sketch=0` - スケッチ風描画を無効化
- `html=1` - HTML ラベルを有効化
- `dashed=0` - 実線
- `whitespace=wrap` - ラベルの折り返し
- `verticalLabelPosition=bottom;verticalAlign=top` - ラベルをアイコン下部に配置
- `fillColor=#2875E2;strokeColor=#ffffff` - Kubernetes のブランド色
- `shape=mxgraph.kubernetes.icon2;prIcon=<abbr>` - アイコンの指定
- `fontSize=12;fontFamily=Helvetica` - 本 skill の正準フォント設定

## 色の使い方

- 汎用ネットワーク機器: `fillColor=#CCCCCC;strokeColor=#6881B3` (機器アイコンの既定色)。ラベル色は `fontColor=#0066CC` (`cloud` の sidebar 既定 `fontColor=#ffffff` は使わない)。
- Cisco: 台紙 `fillColor=#FAFAFA;strokeColor=#005073`。単体シェイプの `cloud` のみ `fillColor=#6B6B6B;strokeColor=none`。
- ラック: 機器・キャビネットとも `strokeColor=#666666`。キャビネット内部は `fillColor2=#f4f4f4`。
- Kubernetes アイコン: `fillColor=#2875E2;strokeColor=#ffffff`。

境界 (コンテナ) の既定色は次の通り (本 skill が決めた値であり、Kubernetes プロジェクト等の規定ではない)。

| 境界                                    | `fillColor` | `strokeColor` | 備考                |
| --------------------------------------- | ----------- | ------------- | ------------------- |
| Cluster                                 | `none`      | `#326CE5`     |                     |
| Namespace                               | `#EEF3FC`   | `#326CE5`     | `dashed=1` を付ける |
| Node                                    | `#F5F5F5`   | `#9E9E9E`     |                     |
| オンプレ (データセンター/拠点/ラック室) | `#FAFAFA`   | `#616161`     |                     |

汎用ネットワーク機器・Cisco・ラックの境界 (データセンター、ラック室等) の既定色は `fillColor=#FAFAFA;strokeColor=#616161;fontColor=#616161`。どのベンダの規定でもなく、本 skill が決めた値。

## 境界 (コンテナ) の表現

これらのライブラリには枠専用シェイプが無い (AWS の `mxgraph.aws4.group` のようなものは無い)。境界は draw.io の汎用コンテナで描く。子は `parent=<コンテナ id>` にして座標をコンテナ相対にし、コンテナをまたぐエッジは `parent="1"` にする (コンテナ内に置くとクリップされる)。

本 skill の既定の枠 style (ラベルは左上、`container=1;pointerEvents=0` 必須):。

```
rounded=0;whiteSpace=wrap;html=1;container=1;pointerEvents=0;collapsible=0;recursiveResize=0;verticalAlign=top;align=left;spacingLeft=8;spacingTop=4;fontSize=12;fontStyle=1;fontFamily=Helvetica;fillColor=<枠の地色>;strokeColor=<枠線色>;fontColor=<枠線色と同じ>;
```

Kubernetes の典型的な階層は Cluster → Namespace → Node で、色は上表を使う。オンプレ境界は色の使い方の表の既定色を使う。

Kubernetes の 3 段の入れ子の例 (色の使い方の表を適用したセル断片):。

```xml
<mxCell id="cluster-nest" value="Cluster" style="rounded=0;whiteSpace=wrap;html=1;container=1;pointerEvents=0;collapsible=0;recursiveResize=0;verticalAlign=top;align=left;spacingLeft=8;spacingTop=4;fontSize=12;fontStyle=1;fontFamily=Helvetica;fillColor=none;strokeColor=#326CE5;fontColor=#326CE5;" vertex="1" parent="1">
  <mxGeometry x="40" y="40" width="560" height="360" as="geometry"/>
</mxCell>
<mxCell id="ns-nest" value="Namespace" style="rounded=0;whiteSpace=wrap;html=1;container=1;pointerEvents=0;collapsible=0;recursiveResize=0;verticalAlign=top;align=left;spacingLeft=8;spacingTop=4;fontSize=12;fontStyle=1;fontFamily=Helvetica;fillColor=#EEF3FC;strokeColor=#326CE5;dashed=1;fontColor=#326CE5;" vertex="1" parent="cluster-nest">
  <mxGeometry x="40" y="40" width="480" height="220" as="geometry"/>
</mxCell>
<mxCell id="node-nest" value="Node" style="rounded=0;whiteSpace=wrap;html=1;container=1;pointerEvents=0;collapsible=0;recursiveResize=0;verticalAlign=top;align=left;spacingLeft=8;spacingTop=4;fontSize=12;fontStyle=1;fontFamily=Helvetica;fillColor=#F5F5F5;strokeColor=#9E9E9E;fontColor=#9E9E9E;" vertex="1" parent="ns-nest">
  <mxGeometry x="40" y="40" width="400" height="140" as="geometry"/>
</mxCell>
```

## 最小構成の例

### オンプレミス (データセンター)

「データセンター」枠の中に users → firewall → server → storage を並べる。

```xml
<mxfile host="app.diagrams.net">
  <diagram name="onprem-minimal">
    <mxGraphModel>
      <root>
        <mxCell id="0"/>
        <mxCell id="1" parent="0"/>
        <mxCell id="dc" value="データセンター" style="rounded=0;whiteSpace=wrap;html=1;container=1;pointerEvents=0;collapsible=0;recursiveResize=0;verticalAlign=top;align=left;spacingLeft=8;spacingTop=4;fontSize=12;fontStyle=1;fontFamily=Helvetica;fillColor=#FAFAFA;strokeColor=#616161;fontColor=#616161;" vertex="1" parent="1">
          <mxGeometry x="40" y="40" width="480" height="160" as="geometry"/>
        </mxCell>
        <mxCell id="users" value="users" style="fontColor=#0066CC;verticalAlign=top;verticalLabelPosition=bottom;labelPosition=center;align=center;html=1;outlineConnect=0;fillColor=#CCCCCC;strokeColor=#6881B3;gradientColor=none;gradientDirection=north;strokeWidth=2;shape=mxgraph.networks.users;fontSize=12;fontFamily=Helvetica;" vertex="1" parent="dc">
          <mxGeometry x="30" y="60" width="60" height="60" as="geometry"/>
        </mxCell>
        <mxCell id="firewall" value="firewall" style="fontColor=#0066CC;verticalAlign=top;verticalLabelPosition=bottom;labelPosition=center;align=center;html=1;outlineConnect=0;fillColor=#CCCCCC;strokeColor=#6881B3;gradientColor=none;gradientDirection=north;strokeWidth=2;shape=mxgraph.networks.firewall;fontSize=12;fontFamily=Helvetica;" vertex="1" parent="dc">
          <mxGeometry x="160" y="60" width="60" height="60" as="geometry"/>
        </mxCell>
        <mxCell id="server" value="server" style="fontColor=#0066CC;verticalAlign=top;verticalLabelPosition=bottom;labelPosition=center;align=center;html=1;outlineConnect=0;fillColor=#CCCCCC;strokeColor=#6881B3;gradientColor=none;gradientDirection=north;strokeWidth=2;shape=mxgraph.networks.server;fontSize=12;fontFamily=Helvetica;" vertex="1" parent="dc">
          <mxGeometry x="290" y="60" width="60" height="60" as="geometry"/>
        </mxCell>
        <mxCell id="storage" value="storage" style="fontColor=#0066CC;verticalAlign=top;verticalLabelPosition=bottom;labelPosition=center;align=center;html=1;outlineConnect=0;fillColor=#CCCCCC;strokeColor=#6881B3;gradientColor=none;gradientDirection=north;strokeWidth=2;shape=mxgraph.networks.storage;fontSize=12;fontFamily=Helvetica;" vertex="1" parent="dc">
          <mxGeometry x="390" y="60" width="60" height="60" as="geometry"/>
        </mxCell>
        <mxCell id="e1" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;strokeWidth=2;fontFamily=Helvetica;fontSize=12;" edge="1" source="users" target="firewall" parent="dc">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>
        <mxCell id="e2" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;strokeWidth=2;fontFamily=Helvetica;fontSize=12;" edge="1" source="firewall" target="server" parent="dc">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>
        <mxCell id="e3" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;strokeWidth=2;fontFamily=Helvetica;fontSize=12;" edge="1" source="server" target="storage" parent="dc">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
```

### Kubernetes

Cluster 枠 → Namespace 枠の中に ing → svc → deploy → pod を並べる。

```xml
<mxfile host="app.diagrams.net">
  <diagram name="k8s-minimal">
    <mxGraphModel>
      <root>
        <mxCell id="0"/>
        <mxCell id="1" parent="0"/>
        <mxCell id="cluster" value="Cluster" style="rounded=0;whiteSpace=wrap;html=1;container=1;pointerEvents=0;collapsible=0;recursiveResize=0;verticalAlign=top;align=left;spacingLeft=8;spacingTop=4;fontSize=12;fontStyle=1;fontFamily=Helvetica;fillColor=none;strokeColor=#326CE5;fontColor=#326CE5;" vertex="1" parent="1">
          <mxGeometry x="40" y="40" width="560" height="220" as="geometry"/>
        </mxCell>
        <mxCell id="ns" value="Namespace" style="rounded=0;whiteSpace=wrap;html=1;container=1;pointerEvents=0;collapsible=0;recursiveResize=0;verticalAlign=top;align=left;spacingLeft=8;spacingTop=4;fontSize=12;fontStyle=1;fontFamily=Helvetica;fillColor=#EEF3FC;strokeColor=#326CE5;dashed=1;fontColor=#326CE5;" vertex="1" parent="cluster">
          <mxGeometry x="40" y="40" width="480" height="140" as="geometry"/>
        </mxCell>
        <mxCell id="ing" value="Ingress" style="aspect=fixed;sketch=0;html=1;dashed=0;whitespace=wrap;verticalLabelPosition=bottom;verticalAlign=top;fillColor=#2875E2;strokeColor=#ffffff;shape=mxgraph.kubernetes.icon2;prIcon=ing;fontSize=12;fontFamily=Helvetica;" vertex="1" parent="ns">
          <mxGeometry x="30" y="60" width="50" height="48" as="geometry"/>
        </mxCell>
        <mxCell id="svc" value="Service" style="aspect=fixed;sketch=0;html=1;dashed=0;whitespace=wrap;verticalLabelPosition=bottom;verticalAlign=top;fillColor=#2875E2;strokeColor=#ffffff;shape=mxgraph.kubernetes.icon2;prIcon=svc;fontSize=12;fontFamily=Helvetica;" vertex="1" parent="ns">
          <mxGeometry x="150" y="60" width="50" height="48" as="geometry"/>
        </mxCell>
        <mxCell id="deploy" value="Deployment" style="aspect=fixed;sketch=0;html=1;dashed=0;whitespace=wrap;verticalLabelPosition=bottom;verticalAlign=top;fillColor=#2875E2;strokeColor=#ffffff;shape=mxgraph.kubernetes.icon2;prIcon=deploy;fontSize=12;fontFamily=Helvetica;" vertex="1" parent="ns">
          <mxGeometry x="270" y="60" width="50" height="48" as="geometry"/>
        </mxCell>
        <mxCell id="pod" value="Pod" style="aspect=fixed;sketch=0;html=1;dashed=0;whitespace=wrap;verticalLabelPosition=bottom;verticalAlign=top;fillColor=#2875E2;strokeColor=#ffffff;shape=mxgraph.kubernetes.icon2;prIcon=pod;fontSize=12;fontFamily=Helvetica;" vertex="1" parent="ns">
          <mxGeometry x="390" y="60" width="50" height="48" as="geometry"/>
        </mxCell>
        <mxCell id="e1" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;strokeWidth=2;fontFamily=Helvetica;fontSize=12;" edge="1" source="ing" target="svc" parent="ns">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>
        <mxCell id="e2" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;strokeWidth=2;fontFamily=Helvetica;fontSize=12;" edge="1" source="svc" target="deploy" parent="ns">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>
        <mxCell id="e3" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;strokeWidth=2;fontFamily=Helvetica;fontSize=12;" edge="1" source="deploy" target="pod" parent="ns">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
```

### ハイブリッド (オンプレ ↔ GCP)

オンプレ枠の router と Google Cloud 枠の Cloud VPN を破線 (VPN) で結ぶ。枠をまたぐエッジなので `parent="1"` にする。

```xml
<mxfile host="app.diagrams.net">
  <diagram name="hybrid-minimal">
    <mxGraphModel>
      <root>
        <mxCell id="0"/>
        <mxCell id="1" parent="0"/>
        <mxCell id="onprem" value="オンプレミス" style="rounded=0;whiteSpace=wrap;html=1;container=1;pointerEvents=0;collapsible=0;recursiveResize=0;verticalAlign=top;align=left;spacingLeft=8;spacingTop=4;fontSize=12;fontStyle=1;fontFamily=Helvetica;fillColor=#FAFAFA;strokeColor=#616161;fontColor=#616161;" vertex="1" parent="1">
          <mxGeometry x="40" y="40" width="200" height="140" as="geometry"/>
        </mxCell>
        <mxCell id="router" value="router" style="fontColor=#0066CC;verticalAlign=top;verticalLabelPosition=bottom;labelPosition=center;align=center;html=1;outlineConnect=0;fillColor=#CCCCCC;strokeColor=#6881B3;gradientColor=none;gradientDirection=north;strokeWidth=2;shape=mxgraph.networks.router;fontSize=12;fontFamily=Helvetica;" vertex="1" parent="onprem">
          <mxGeometry x="50" y="55" width="100" height="30" as="geometry"/>
        </mxCell>
        <mxCell id="gcp" value="Google Cloud" style="rounded=0;whiteSpace=wrap;html=1;container=1;pointerEvents=0;collapsible=0;recursiveResize=0;verticalAlign=top;align=left;spacingLeft=8;spacingTop=4;fontSize=12;fontStyle=1;fontFamily=Helvetica;fillColor=#E8F0FE;strokeColor=#4285F4;fontColor=#4285F4;" vertex="1" parent="1">
          <mxGeometry x="360" y="40" width="200" height="140" as="geometry"/>
        </mxCell>
        <mxCell id="vpn" value="Cloud VPN" style="sketch=0;html=1;aspect=fixed;strokeColor=none;shadow=0;fillColor=#3B8DF1;verticalAlign=top;labelPosition=center;verticalLabelPosition=bottom;shape=mxgraph.gcp2.cloud_vpn;fontSize=12;fontFamily=Helvetica;" vertex="1" parent="gcp">
          <mxGeometry x="70" y="50" width="60" height="60" as="geometry"/>
        </mxCell>
        <mxCell id="e1" value="VPN" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;strokeWidth=2;fontFamily=Helvetica;fontSize=12;dashed=1;" edge="1" source="router" target="vpn" parent="1">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
```

AWS を含めた 3 者間のハイブリッド構成にする場合は、AWS 側のノードに [aws-architecture.md](./aws-architecture.md) に載っている resIcon を使って同様に接続すればよい。

## ハイブリッド・マルチクラウド構成の描き方

- 各 provider の style 方言をそのまま 1 枚に混在させてよい (シェイプは独立している)。
- アイコンサイズは 60 前後に揃える。
- provider ごとに枠色を変える (各 provider リファレンスの既定を使う)。
- 接続点 (VPN/Interconnect/ExpressRoute/Direct Connect) のアイコンは枠の境界付近に置く。
- 枠をまたぐエッジは `parent="1"` にする。
- コネクタの色・線種は [architecture-principles.md](./architecture-principles.md) の規則に従う。

## 参考資料

- [Kubernetes 公式アイコン](https://github.com/kubernetes/community/tree/master/icons)
- [draw.io ネットワーク図の解説](https://www.drawio.com/blog/network-diagrams)
- [jgraph/drawio-mcp](https://github.com/jgraph/drawio-mcp) - shape 索引の出所
