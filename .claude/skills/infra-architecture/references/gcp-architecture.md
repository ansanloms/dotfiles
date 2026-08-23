# Google Cloud アーキテクチャ図ベストプラクティス

## 概要

Google Cloud (GCP) アーキテクチャ図を draw.io で作成する際のガイドライン。粒度・帯・コネクタの色と線種・凡例・命名など provider に依存しない原則は [architecture-principles.md](./architecture-principles.md) を参照する。本ファイルには GCP 固有のアイコン・色・境界表現のみを記載する。

## アイコンの利用方法

### draw.io 組み込みライブラリ (`mxgraph.gcp2`)

GCP アイコンは `shape=mxgraph.gcp2.<name>` を直接指定する。AWS の `resourceIcon` + `resIcon` のようなラッパ形式は無い。

#### 基本 style

```
sketch=0;html=1;aspect=fixed;strokeColor=none;shadow=0;fillColor=#3B8DF1;verticalAlign=top;labelPosition=center;verticalLabelPosition=bottom;shape=mxgraph.gcp2.<name>;fontSize=12;fontFamily=Helvetica;
```

`fillColor=#3B8DF1` は draw.io の GCP sidebar が使っている値で、六角形アイコンの地色になる。サイズは 60x60 を既定にする (`aspect=fixed` なので縦横比は保たれる)。

### gcp2 名の正規の取得元

`mxgraph.gcp2.*` の名前を推測してはならない。無効な名前は空表示になる。一次情報源はレンダリングに使う drawio 本体の `app.asar`。取得コマンドと実出力は次の通り (取得日: 2026-08-23、`$ASAR` は `app.asar` のパス)。

```
grep -aoE 'mxgraph\.gcp2\.[a-z0-9_]+' "$ASAR" | sort -u | wc -l
255
```

```
grep -aoE 'mxgraph\.gcp2\.[a-z0-9_]+' "$ASAR" | sort -u | sed 's/mxgraph.gcp2.//' | tr '\n' ' '
a7_power admin_connected advanced_solutions_lab ai_hub anomaly_detection api_analytics api_monetization apigee_api_platform apigee_sense app_engine app_engine_icon application arrow_cycle arrows_system aspect_ratio automl_natural_language automl_tables automl_translation automl_video_intelligence automl_vision avere beacon beyondcorp big_query bigquery biomedical_beaker biomedical_test_tube biomedical_trio blue_hexagon bucket_scale calculator campaign_manager capabilities certified_industry_standard check check_2 check_available check_scale clock cloud cloud_apis cloud_armor cloud_automl cloud_bigtable cloud_cdn cloud_checkmark cloud_code cloud_composer cloud_computer cloud_connected_insight cloud_data_catalog cloud_data_fusion cloud_dataflow cloud_dataflow_icon cloud_datalab cloud_dataprep cloud_dataproc cloud_dataproc_icon cloud_datastore cloud_deployment_manager cloud_dns cloud_endpoints cloud_external_ip_addresses cloud_filestore cloud_firestore cloud_firewall_rules cloud_functions cloud_iam cloud_inference_api cloud_information cloud_iot_core cloud_jobs_api cloud_load_balancing cloud_machine_learning cloud_memorystore cloud_messaging cloud_monitoring cloud_nat cloud_natural_language_api cloud_network cloud_pubsub cloud_router cloud_routes cloud_run cloud_scheduler cloud_security cloud_security_command_center cloud_security_scanner cloud_server cloud_service_mesh cloud_spanner cloud_speech_api cloud_sql cloud_storage cloud_test_lab cloud_text_to_speech cloud_tools_for_powershell cloud_tpu cloud_translation_api cloud_video_intelligence_api cloud_vision_api cloud_vpn compute_engine compute_engine_2 compute_engine_icon connected container_builder container_engine container_engine_icon container_optimized_os container_registry cost cost_arrows cost_savings data_access data_increase data_loss_prevention_api data_storage_cost data_studio database database_2 database_3 database_cycle database_speed database_uploading debugger dedicated_game_server dedicated_interconnect desktop_and_mobile developer_portal dialogflow_enterprise_edition double enhance_ui enhance_ui_2 error_reporting external_data_center external_data_resource files folders forseti_lockup forseti_logo frontend_platform_services gateway gateway_icon gear gear_arrow gear_chain gear_load genomics gke_on_prem globe_world google_analytics google_cloud_platform google_cloud_platform_lockup google_network google_network_edge_cache gpu half_cloud hex identity_aware_proxy increase_cost_arrows internet_connection key key_management_service laptop legacy_cloud legacy_cloud_2 lifecycle list load_balancing loading loading_2 loading_3 lock logging management_security maps_api mem_instances memory_card mobile_devices modifiers_autoscaling modifiers_custom_virtual_machine modifiers_high_cpu_machine modifiers_high_memory_machine modifiers_preemptable_vm modifiers_shared_core_machine_f1 modifiers_shared_core_machine_g1 modifiers_standard_machine modifiers_storage monitor monitor_2 network node outline_blank_1 outline_blank_2 outline_blank_3 outline_highcomp outline_highmem partner_interconnect people_security_management persistent_disk phone phone_android placeholder play_gear play_start prediction_api premium_network_tier primary process profiler replication_controller replication_controller_2 replication_controller_3 report repository repository_2 repository_3 repository_primary retail safety save scale search search_api security_key_enforcement segments segments_2 segments_overlap servers_stacked service social_media_time solution speed stackdriver stacked_ownership standard_network_tier storage swap systems_check tape_record task_queues_2 tensorflow_logo thumbs_up time_clock trace traffic_director transfer_appliance users view_list virtual_private_cloud visibility vpn website zones
```

#### 代表アイコン (63 個。分類は本 skill で付けたもの)

- コンピューティング: `compute_engine` (Compute Engine)/`app_engine` (App Engine)/`cloud_functions` (Cloud Functions)/`cloud_run` (Cloud Run)/`container_engine` (GKE。旧名 Container Engine)/`gke_on_prem` (GKE On-Prem/Anthos)/`cloud_tpu`/`gpu`
- ストレージ: `cloud_storage` (Cloud Storage)/`persistent_disk` (Persistent Disk)/`cloud_filestore` (Filestore)
- データベース: `cloud_sql` (Cloud SQL)/`cloud_spanner` (Spanner)/`cloud_bigtable` (Bigtable)/`cloud_firestore` (Firestore)/`cloud_datastore` (Datastore)/`cloud_memorystore` (Memorystore)
- データ分析: `bigquery` (BigQuery)/`cloud_dataflow` (Dataflow)/`cloud_dataproc` (Dataproc)/`cloud_pubsub` (Pub/Sub)/`cloud_composer` (Composer)/`cloud_data_catalog` (Data Catalog)/`data_studio` (Data Studio/Looker Studio)
- ネットワーキング: `cloud_load_balancing` (Cloud Load Balancing)/`cloud_cdn` (Cloud CDN)/`cloud_dns` (Cloud DNS)/`virtual_private_cloud` (VPC)/`cloud_nat` (Cloud NAT)/`cloud_router` (Cloud Router)/`cloud_vpn` (Cloud VPN)/`dedicated_interconnect` (Dedicated Interconnect)/`partner_interconnect` (Partner Interconnect)/`cloud_armor` (Cloud Armor)/`cloud_firewall_rules` (Firewall Rules)/`cloud_external_ip_addresses` (External IP)/`traffic_director` (Traffic Director)/`cloud_service_mesh` (Service Mesh)/`cloud_network` (汎用ネットワーク)
- セキュリティ・ID: `cloud_iam` (IAM)/`key_management_service` (Cloud KMS)/`identity_aware_proxy` (IAP)/`cloud_security_command_center` (Security Command Center)
- 運用: `cloud_monitoring` (Cloud Monitoring。円柱型アイコン)/`logging` (Cloud Logging)/`stackdriver` (旧 Stackdriver)/`trace` (Cloud Trace)/`error_reporting` (Error Reporting)
- 開発者ツール・API 管理: `container_registry` (Container Registry)/`container_builder` (Cloud Build。旧名 Container Builder)/`cloud_scheduler` (Cloud Scheduler)/`task_queues_2` (Cloud Tasks 相当。数字タイル型アイコン)/`cloud_endpoints` (Cloud Endpoints)/`apigee_api_platform` (Apigee)
- AI・IoT: `cloud_iot_core` (IoT Core)/`cloud_machine_learning` (AI Platform/旧 Cloud ML)
- 周辺要素: `users` (ユーザ)/`laptop`/`mobile_devices`/`google_cloud_platform` (GCP ロゴ)/`internet_connection` (インターネット)/`external_data_center` (外部データセンター/オンプレ)/`cloud` (雲)

#### 制約

`mxgraph.gcp2` のステンシル名は旧プロダクト名ベースであり、Vertex AI/Artifact Registry/Eventarc/Secret Manager 等の新しいプロダクト専用ステンシルは上記一覧に無い。該当するものは最も近い旧アイコン (例: Artifact Registry → `container_registry`) をラベルで補って使うか、汎用図形で代替する。名前を推測して書かない (無効名は空表示になる)。Web 版 draw.io の新しい GCP アイコンは `image=data:image/svg+xml,...` のインライン画像で、1 個数 KB になるため手書き XML には載せない。

## スタイル詳細

基本 style の各キーの意味は次の通り。

- `sketch=0` - スケッチ風描画を無効化
- `html=1` - HTML ラベルを有効化
- `aspect=fixed` - アスペクト比固定
- `strokeColor=none` - アイコン自体には枠線を描かない
- `shadow=0` - 影なし
- `fillColor=#3B8DF1` - GCP sidebar の既定地色 (六角形アイコンの地色)
- `verticalAlign=top;labelPosition=center;verticalLabelPosition=bottom` - ラベルをアイコン下部中央に配置
- `shape=mxgraph.gcp2.<name>` - GCP アイコンの指定
- `fontSize=12;fontFamily=Helvetica` - 本 skill の正準フォント設定

## 色の使い方

- アイコンの地色: `fillColor=#3B8DF1` (draw.io の GCP sidebar の実測値)
- 枠 (コンテナ) の既定色: 次は本 skill が決めた値であり、Google 公式の規定ではない。

| 境界          | `fillColor` | `strokeColor` | 備考                |
| ------------- | ----------- | ------------- | ------------------- |
| Project       | `#F8F9FA`   | `#9AA0A6`     |                     |
| VPC           | `#E8F0FE`   | `#4285F4`     |                     |
| Region / Zone | `#FFF8E1`   | `#F9AB00`     | `dashed=1` を付ける |
| Subnet        | `#E6F4EA`   | `#34A853`     |                     |

## 境界 (コンテナ) の表現

`mxgraph.gcp2` には AWS の `mxgraph.aws4.group` のような枠専用シェイプが無い。境界は draw.io の汎用コンテナで描く。GCP の典型的な階層は Project → VPC → Region/Zone → Subnet。子は `parent=<コンテナ id>` にして座標をコンテナ相対にし、コンテナをまたぐエッジは `parent="1"` にする (コンテナ内に置くとクリップされる)。

本 skill の既定の枠 style (ラベルは左上、`container=1;pointerEvents=0` 必須):。

```
rounded=0;whiteSpace=wrap;html=1;container=1;pointerEvents=0;collapsible=0;recursiveResize=0;verticalAlign=top;align=left;spacingLeft=8;spacingTop=4;fontSize=12;fontStyle=1;fontFamily=Helvetica;fillColor=<枠の地色>;strokeColor=<枠線色>;fontColor=<枠線色と同じ>;
```

4 段の入れ子の例 (色の使い方の表を適用したセル断片):。

```xml
<mxCell id="project" value="Project" style="rounded=0;whiteSpace=wrap;html=1;container=1;pointerEvents=0;collapsible=0;recursiveResize=0;verticalAlign=top;align=left;spacingLeft=8;spacingTop=4;fontSize=12;fontStyle=1;fontFamily=Helvetica;fillColor=#F8F9FA;strokeColor=#9AA0A6;fontColor=#9AA0A6;" vertex="1" parent="1">
  <mxGeometry x="40" y="40" width="720" height="480" as="geometry"/>
</mxCell>
<mxCell id="vpc-nest" value="VPC" style="rounded=0;whiteSpace=wrap;html=1;container=1;pointerEvents=0;collapsible=0;recursiveResize=0;verticalAlign=top;align=left;spacingLeft=8;spacingTop=4;fontSize=12;fontStyle=1;fontFamily=Helvetica;fillColor=#E8F0FE;strokeColor=#4285F4;fontColor=#4285F4;" vertex="1" parent="project">
  <mxGeometry x="40" y="40" width="640" height="400" as="geometry"/>
</mxCell>
<mxCell id="zone" value="Zone (asia-northeast1-a)" style="rounded=0;whiteSpace=wrap;html=1;container=1;pointerEvents=0;collapsible=0;recursiveResize=0;verticalAlign=top;align=left;spacingLeft=8;spacingTop=4;fontSize=12;fontStyle=1;fontFamily=Helvetica;fillColor=#FFF8E1;strokeColor=#F9AB00;dashed=1;fontColor=#F9AB00;" vertex="1" parent="vpc-nest">
  <mxGeometry x="40" y="40" width="560" height="320" as="geometry"/>
</mxCell>
<mxCell id="subnet-nest" value="Subnet (10.0.0.0/24)" style="rounded=0;whiteSpace=wrap;html=1;container=1;pointerEvents=0;collapsible=0;recursiveResize=0;verticalAlign=top;align=left;spacingLeft=8;spacingTop=4;fontSize=12;fontStyle=1;fontFamily=Helvetica;fillColor=#E6F4EA;strokeColor=#34A853;fontColor=#34A853;" vertex="1" parent="zone">
  <mxGeometry x="40" y="40" width="480" height="240" as="geometry"/>
</mxCell>
```

## 最小構成の例

VPC 枠の中に Cloud Load Balancing → Cloud Run → Cloud SQL を並べ、枠の外にユーザを置く。

```xml
<mxfile host="app.diagrams.net">
  <diagram name="gcp-minimal">
    <mxGraphModel>
      <root>
        <mxCell id="0"/>
        <mxCell id="1" parent="0"/>
        <mxCell id="vpc" value="VPC" style="rounded=0;whiteSpace=wrap;html=1;container=1;pointerEvents=0;collapsible=0;recursiveResize=0;verticalAlign=top;align=left;spacingLeft=8;spacingTop=4;fontSize=12;fontStyle=1;fontFamily=Helvetica;fillColor=#E8F0FE;strokeColor=#4285F4;fontColor=#4285F4;" vertex="1" parent="1">
          <mxGeometry x="240" y="40" width="440" height="160" as="geometry"/>
        </mxCell>
        <mxCell id="lb" value="Cloud Load Balancing" style="sketch=0;html=1;aspect=fixed;strokeColor=none;shadow=0;fillColor=#3B8DF1;verticalAlign=top;labelPosition=center;verticalLabelPosition=bottom;shape=mxgraph.gcp2.cloud_load_balancing;fontSize=12;fontFamily=Helvetica;" vertex="1" parent="vpc">
          <mxGeometry x="40" y="60" width="60" height="60" as="geometry"/>
        </mxCell>
        <mxCell id="run" value="Cloud Run" style="sketch=0;html=1;aspect=fixed;strokeColor=none;shadow=0;fillColor=#3B8DF1;verticalAlign=top;labelPosition=center;verticalLabelPosition=bottom;shape=mxgraph.gcp2.cloud_run;fontSize=12;fontFamily=Helvetica;" vertex="1" parent="vpc">
          <mxGeometry x="200" y="60" width="60" height="60" as="geometry"/>
        </mxCell>
        <mxCell id="sql" value="Cloud SQL" style="sketch=0;html=1;aspect=fixed;strokeColor=none;shadow=0;fillColor=#3B8DF1;verticalAlign=top;labelPosition=center;verticalLabelPosition=bottom;shape=mxgraph.gcp2.cloud_sql;fontSize=12;fontFamily=Helvetica;" vertex="1" parent="vpc">
          <mxGeometry x="360" y="60" width="60" height="60" as="geometry"/>
        </mxCell>
        <mxCell id="users" value="users" style="sketch=0;html=1;aspect=fixed;strokeColor=none;shadow=0;fillColor=#3B8DF1;verticalAlign=top;labelPosition=center;verticalLabelPosition=bottom;shape=mxgraph.gcp2.users;fontSize=12;fontFamily=Helvetica;" vertex="1" parent="1">
          <mxGeometry x="40" y="100" width="60" height="60" as="geometry"/>
        </mxCell>
        <mxCell id="e1" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;strokeWidth=2;fontFamily=Helvetica;fontSize=12;" edge="1" source="users" target="lb" parent="1">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>
        <mxCell id="e2" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;strokeWidth=2;fontFamily=Helvetica;fontSize=12;" edge="1" source="lb" target="run" parent="vpc">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>
        <mxCell id="e3" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;strokeWidth=2;fontFamily=Helvetica;fontSize=12;" edge="1" source="run" target="sql" parent="vpc">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
```

## 参考資料

- [Google Cloud アーキテクチャ図のアイコン](https://cloud.google.com/icons)
- [jgraph/drawio-mcp](https://github.com/jgraph/drawio-mcp) - shape 索引の出所
