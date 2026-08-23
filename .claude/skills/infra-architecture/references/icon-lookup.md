# アイコン名の調べ方

サービス名やプロダクト名からステンシル名・画像パスを**推測して書いてはならない**。推測が外れると、アイコンが無効な名前として空表示になる (エラーにならず黙って空になる)。一次情報源は次の 2 つ。

## draw.io 本体の app.asar を grep する

resIcon 名やステンシル名の一次情報源は、実際のレンダリングに使う drawio 本体にバンドルされたシェイプ定義 (`app.asar`)。実際に使うレンダラと同一なので最も確実。

### app.asar の場所を特定する

`app.asar` の場所は環境依存 (`/opt/drawio/resources/` や nix の `share/lib/drawio/resources/` など)。決め打ちせず、インストール先から発見する。

```bash
ASAR=$(find -L "$(dirname "$(dirname "$(readlink -f "$(which drawio)")")")" -name app.asar 2>/dev/null | head -1)
echo "$ASAR"
```

### ステンシル名を grep で確認する

```bash
grep -aoE 'mxgraph\.<lib>\.[a-z0-9_]+' "$ASAR" | sort -u
```

grep で見つかれば有効。ただし**grep の不在は「無効」を意味しない**。app.asar の格納形式の都合で、有効なのに plaintext grep に現れない名前がある。最終的な真偽は PNG レンダリングで判定する (後述)。

### ライブラリ別の grep 例

以下は 2026-08-23 に実測したコマンドと実出力。件数が多いものは省略している箇所を明記する。

**GCP (`mxgraph.gcp2.*`)**

```bash
grep -aoE 'mxgraph\.gcp2\.[a-z0-9_]+' "$ASAR" | sort -u | wc -l
```

```
255
```

**汎用ネットワーク (`mxgraph.networks.*`)**

```bash
grep -aoE 'mxgraph\.networks\.[a-z0-9_]+' "$ASAR" | sort -u | sed 's/mxgraph.networks.//' | tr '\n' ' '
```

```
biometric_reader bus business_center cloud comm_link comm_link_edge community copier desktop_pc external_storage firewall gamepad hub laptop load_balancer mail_server mainframe mobile modem monitor nas_filer patch_panel pc phone_1 phone_2 printer proxy_server rack radio_tower router satellite satellite_dish scanner secured security_camera server server_storage storage supercomputer switch tablet tape_storage terminal unsecure ups_enterprise ups_small usb_stick user_female user_male users video_projector video_projector_screen virtual_pc virtual_server virus web_server wireless_hub wireless_modem
```

**ラック (`mxgraph.rack.general.*`)**

```bash
grep -aoE 'mxgraph\.rack\.general\.[a-z0-9_]+' "$ASAR" | sort -u | sed 's/mxgraph.rack.general.//' | tr '\n' ' '
```

```
1u_rack_server cat5e_enhanced_patch_panel_48_ports cat5e_rack_mount_patch_panel_24_ports cat5e_rack_mount_patch_panel_96_ports hub server_1 server_2 server_3 switches_1 switches_2
```

**Azure (`azure2`)**

`azure2` はステンシル名ではなく画像ファイルのパス (`img/lib/azure2/<category>/<Name>.svg`) を `image=` に指定する方式なので、grep パターンもパス形式にする。

```bash
grep -aoE 'img/lib/azure2/[a-z_]+/[A-Za-z0-9_]+\.svg' "$ASAR" | sort -u | head -3
```

```
img/lib/azure2/compute/Azure_Compute_Galleries.svg
img/lib/azure2/compute/Azure_Spring_Cloud.svg
img/lib/azure2/compute/Mesh_Applications.svg
```

2026-08-23 の実測ではこのコマンドで 67 件しか出なかった。後述の shape 索引 (645 件) より少ないため、`azure2` の網羅的な調査は索引を優先し、grep は候補の存在確認程度に使う。

## jgraph/drawio-mcp の shape 索引 (search-index.json) を引く

jgraph/drawio-mcp リポジトリは `shape-search/search-index.json` という shape 索引を配布している (2026-08-23 時点で約 4.8MB、10,446 件)。各要素は `{style, w, h, title, tags, type}` の形。app.diagrams.net (Web 版 draw.io) の `app.min.js` から生成されたもので、`title` (表示名) から `style` を逆引きできる。

```bash
curl -sL https://raw.githubusercontent.com/jgraph/drawio-mcp/main/shape-search/search-index.json -o search-index.json
```

`node -e` や `jq` で `title`/`tags`/`style` を検索する。索引は Web 版由来なので、手元の Desktop 版と差がある場合がある。最終判定は PNG 描画で行う (後述)。

索引にある `image=data:image/svg+xml,...` 形式のインライン画像 style (GCP の新プロダクト用アイコン等) は 1 個あたり数 KB になるため、手書き XML には推奨しない。

### Azure の検索例 (実測)

```bash
node -e '
const idx=JSON.parse(require("fs").readFileSync("search-index.json","utf8"));
const az=idx.filter(s=>(s.style||"").includes("img/lib/azure2/"));
for (const w of ["cosmos","virtual network gateway","postgresql","container apps"]) {
  const h=az.filter(s=>(s.title||"").toLowerCase().includes(w));
  console.log(w+": "+h.map(s=>s.title+" {"+/azure2\/([^;]+)\.svg/.exec(s.style)[1]+" "+s.w+"x"+s.h+"}").join(" | "));
}'
```

```
cosmos: Cosmos DB {databases/Azure_Cosmos_DB 64x64}
virtual network gateway: Virtual Network Gateways {networking/Virtual_Network_Gateways 52x69}
postgresql: Database PostgreSQL Server {databases/Azure_Database_PostgreSQL_Server 48x64} | Database PostgreSQL Server Group {databases/Azure_Database_PostgreSQL_Server_Group 60x68} | Arc PostgreSQL {other/Arc_PostgreSQL 65x68}
container apps:
```

`container apps` は該当なし。Container Apps 専用アイコンは索引に無い (2026-08-23 時点)。

### Cisco の prIcon 一覧を取得する例 (実測)

```bash
node -e '
const idx=JSON.parse(require("fs").readFileSync("search-index.json","utf8"));
const pr=[...new Set(idx.filter(s=>(s.style||"").includes("mxgraph.cisco19.rect")).map(s=>/prIcon=([a-z0-9_]+)/.exec(s.style)[1]))];
console.log(pr.length); console.log(pr.join(" "));'
```

```
195
l2_switch l3_switch l2_modular l3_modular 6500_vss l2_switch_with_dual_supervisor l3_switch_with_dual_supervisor l2_modular2 l3_modular2 6500_vss2 secure_catalyst_switch_color secure_catalyst_switch_subdued secure_switch workgroup_switch secure_catalyst_switch_color3 secure_catalyst_switch_color2 secure_catalyst_switch_subdued2 router csr_1000v wireless_router l3_modular3 ucs_express router_with_voice router_with_firewall netflow_router secure_router ip_telephone_router content_router service_ready_engine cisco_15800 appnav router_with_firewall2 netflow_router2 asr_1000 asr_9000 net_mgmt_appliance nam_virtual_service_blade nexus_9300 hypervisor nexus_9500 fabric_interconnect fibre_channel_director_mds_9000 virtual_matrix_switch ucs_c_series_server nexus_5k_with_integrated_vsm aci aci2 vts2 ucs_5108_blade_chassis storage ups rps nexus_2000_10ge blade_server nexus_5k nexus_4k nexus_3k nexus_2k nexus_1kv_vsm nexus_1k layer3_nexus_5k_switch nexus_1010 nexus_7k fibre_channel_fabric_switch database_relational dual_mode_access_point wireless_location_appliance wireless_lan_controller mesh_access_point (以下省略。残りはビデオ会議・コラボレーション・セキュリティ製品の名前)
```

### Kubernetes の prIcon 一覧を取得する例 (実測)

```bash
node -e '
const idx=JSON.parse(require("fs").readFileSync("search-index.json","utf8"));
const k=idx.filter(s=>(s.style||"").includes("mxgraph.kubernetes.icon2"));
console.log([...new Set(k.map(s=>{const m=/prIcon=([a-z_0-9]+)/.exec(s.style);return s.title+"="+m[1]}))].join(" "));'
```

```
API=api C-C-M=c_c_m CM=cm C-M=c_m C-Role=c_role Control Plane=control_plane CRB=crb CRD=crd CronJob=cronjob Deploy=deploy DS=ds EP=ep ETCD=etcd Group=group HPA=hpa ING=ing Job=job K-proxy=k_proxy Kubelet=kubelet Limits=limits Netpol=netpol Node=node NS=ns Pod=pod PSP=psp PV=pv PVC=pvc Quota=quota RB=rb Role=role RS=rs SA=sa SC=sc Sched=sched Secret=secret STS=sts SVC=svc User=user Vol=vol
```

## 最終判定は PNG 描画

grep や索引検索で候補を絞っても、最終的な真偽は PNG レンダリングで判定する。アイコンが空表示になったら名前が誤り。複数候補があるときは、1 枚の `.drawio` に並べて一度に PNG 描画すると効率がよい。
