# Server v1.6.505 — candidate

## 根因與修補

8080 的正式 Server504 綁定讀回確認：v1 與 v2-beta Volume schema 都缺少
`isNative`。共用 user authorization overlay 移除了欄位，frozen v1 role
schemas 也未包含它。Web168 正確拒絕把未知分類視為非 native，因此無法
正常完成未配置 local Volume 的原生列表與清理流程。

候選封裝 Engine `v0.183.332`，tested source 為
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

## 目前驗證與待驗邊界

Engine scoped Maven reactor 的18個測試通過，failure／error／skip皆為0，
含6個新增回歸：六種 frozen v1 roles、現行 overlays、實際 readonly
processor sequence、其他 methods/actions/fields 保留、formatter true/false
與 server default、POST／PUT 偽造分類拒絕。正式 CI additionally 要求 named
regressions 實際執行；全部 suite failures 與原安全門檻保持。

Engine 正式 WAR、component signed tag、Server publisher、immutable digest
及8080部署／原生生命週期尚待完成，不能稱為發行或完整矩陣 PASS。
504兩次零資源寫入 HOLD 保留；待新成品部署後以新版本綁定案例驗收
create／list／cancel／reload／deactivate／remove 與低角色拒絕。

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
