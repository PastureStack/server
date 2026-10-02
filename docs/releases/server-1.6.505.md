# Server v1.6.505 — 已發布

## 根因與修補

8080 的正式 Server504 綁定讀回確認：v1 與 v2-beta Volume schema 都缺少
`isNative`。共用 user authorization overlay 移除了欄位，frozen v1 role
schemas 也未包含它。Web168 正確拒絕把未知分類視為非 native，因此無法
正常完成未配置 local Volume 的原生列表與清理流程。

正式封裝 Engine `v0.183.332`，tested source 為
`7a625eee58fb2bdba83d2f008bdf7dd3c0ae4295`。修改只有共用 user overlay 的
`volume.isNative:r` 與 FileSchemaFactory 的 Volume 欄位補齊；保留實際
server true／false、既有非 nullable boolean default，不授予寫入能力。
其他欄位、methods、完整 resource／collection actions、角色與 account
scoping 不變，沒有資料庫 migration、前端缺值 fallback 或 runtime patch。

Web Console 固定保留 `1.6.168`，source
`2120e0416fd4a0efb5d351f9da4ec632ac8eacdc`，archive SHA-256
`fdd1d33d47b032eef8b5b6d5dbb1401110daf860d84a6c17003577463d3d2cb5`。
原 Web component 的 788 個 QUnit、16 個 scoped Volume tests 及13語系翻譯
封裝證據保持；不是這次 packaged UI／完整語系驗收。

## 正式發行與驗證邊界

[正式發行](https://github.com/PastureStack/server/releases/tag/v1.6.505)的 Server source 為
`400f7dc8d533a5f13a555398c595b9ae42e0c454`，不可變映像為
`ghcr.io/pasturestack/server:v1.6.505@sha256:b3dd402cfd773b4d37ecf06f716187833e56cc6f211b7ab920dccf8dcb7366c5`。
[Publisher 37072151759](https://github.com/PastureStack/server/actions/runs/37072151759)
完成正式成品發布與公開讀回，23個 assets／22項 SHA-256、image/component
identity、單 runtime layer 與成品 SBOM／安全契約相符。
隔離映像首次啟動／一次重啟均 HTTP 200/pong，分別在第10／6次探測取得；
34項 MFA/API、TLS1.2／1.3 HTTP200與不信任憑證拒絕皆驗證通過。
這不是 QA8080 部署、Docker healthy 或原生 browser 驗收。

Engine scoped Maven reactor 的18個測試通過，failure／error／skip皆為0，
含6個新增回歸：六種 frozen v1 roles、現行 overlays、實際 readonly
processor sequence、其他 methods/actions/fields 保留、formatter true/false
與 server default、POST／PUT 偽造分類拒絕。正式 Engine CI `37069556952`
通過270 suites／1,150 tests，failure／error／skip皆為0，包含6個新增回歸。
Signed numeric component release、6個 assets 與exact WAR已核對；WAR SHA-256為
`31090699e214f8e357f7fe413ce307e722b9b53177003e5de0bbbca1bc7bc3f5`，
bytes為87,700,267；同WAR通過隔離JDK25.0.3／H2啟動。

QA8080 已部署本版；首次／一次重啟均 HTTP 200/pong，分別在第10／9次
探測取得。runtime／環境參數與五項資料筆數保存，504 容器與資料庫回復點
保留。Docker health 為 `null`，不稱為 `healthy`。
原生生命週期仍在驗收，完整資源／角色矩陣未完成。504兩次零資源寫入 HOLD
與505的前置能力判斷 HOLD 保留，不追認為 PASS。505 實際 schema 已恢復
`isNative`；其 `nullable=false` 描述依 `Field.isNullable()` 的 `NON_DEFAULT`
契約省略，驗收工具已修正這項判斷，未放寬資源分類或授權條件。
來源核對另確認未配置 local Volume 可合法處於 `inactive`；原生清單不要求
`active`，該狀態可 remove 但不可 deactivate。驗收依實際狀態、action 與
空 host／image／mount／storagePool 關聯進行，不修改產品來迎合工具。

## 安全、升級與回復

只更新正式不可變 component／image 座標，不覆寫既有 tag。保留 Compose
環境參數、named volumes、restart、AppArmor、HTTPS origin、OIDC/MFA、
效能參數及 nftables 架構；正式公司站不直接部署。

先保留資料庫及既有資料卷的回復點，再僅更換映像。沒有資料庫 migration。
回復到504會恢復缺少唯讀分類的舊輸出，可能再次隱藏未配置 Volume。
不刪除資料卷、不改 HAProxy 或 OIDC。
No migration or runtime patch is required.

Vendor-pending 8個 Medium package findings／4個 CVE、reviewAfter、policy及
VEX 51 statements 保留，不放寬 Critical／High、fix-available、secret 或
untracked 門檻，也不宣稱零 CVE。多階段建置與單 runtime layer 契約保持。
