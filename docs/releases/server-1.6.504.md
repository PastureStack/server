# Server v1.6.504

已正式發布，固定封裝 Web Console `1.6.168`，不覆寫既有版本。
Server source：`e33ef8565ebe40dd188170baa46da8092fc131b9`。
不可變映像：`ghcr.io/pasturestack/server:v1.6.504@sha256:11393d4a5189601464d2a2e1ffc823160bedd6bda6c1fbae12457337f7cb9e2f`。
[正式 publisher 37063207602](https://github.com/PastureStack/server/actions/runs/37063207602)
通過啟動／重啟、34 項 MFA/API 檢查、TLS、單 runtime layer 與成品 SBOM／安全門檻。
23 個公開 assets、22 項 SHA-256、匿名 registry 與 component identity 已核實。

Web component公開座標：

- release：[`1.6.168`](https://github.com/PastureStack/web-console/releases/tag/1.6.168)
- tested source：`2120e0416fd4a0efb5d351f9da4ec632ac8eacdc`
- source tree：`d118b85e51e2f039bca223461a67544be1c4cb6b`
- artifact：`web-console-1.6.168.tar.gz`，2,981,125 bytes
- archive SHA-256：`fdd1d33d47b032eef8b5b6d5dbb1401110daf860d84a6c17003577463d3d2cb5`

正式CI `37061716638` 與immutable匿名下載讀回相符；正常merge與tested source樹相同。
這些是 Web component publication 證據，不代替 packaged native browser 驗收。

## Volume 入口與未配置 local 列表

Storage-pool 新增 CTA 與直接新增 Volume 網址，使用目前環境的建立能力判斷。
只有 current project 與 schemaProjectId 相符的當次 schema 才可授權；CTA
隨 schema load generation 重算，避免舊環境或已撤回 POST 的能力仍顯示。
共用路由守門也為既有 update 分支保留相同新鮮度條件及原有 PUT 判斷，
既有可讀權限訊息與安全轉向行為保留。

Storagepools 的未配置 local Volume 使用獨立區段與原生 Add，不依賴
「具有 driverName 的 pool 列表」是否存在或剛好顯示它。候選必須屬於目前 project、是非 native／非 host-path 的
local Volume，沒有 host／image／instance 或 external 關聯，且不是 removed
或 purged。未配置狀態須由實際 advertised storage-pool 關聯的完整空 collection
及完整 scoped mount cache 證明；inactive mounts 仍計入使用關聯。這是實際 GET
storagePools 的 collection，不以假空陣列取代省略欄位。Unknown／partial
collection、載入失敗或 stale response 不等於空關聯；原始403、network／sync
error 不吞，保留既有 route／growl 診斷，不自動重試。

普通清理只使用當次資源 advertised deactivate 與 advertised remove：只有目前
project/schema 相符且 actual advertised deactivate 才開原生停用，待 active→detached
及模型同步後沿用原生刪除，不假造動作、不重送清理或更改已被
工作負載使用的 Volume。這是產品流程界線，尚不是 packaged lifecycle PASS。

## 證據與相容性界線

Web168正式CI通過788／788個 QUnit案例，fail／skip／todo皆為0；包含16個 scoped
Volume案例，涵蓋入口能力與schema freshness、未配置關聯／live cache、錯誤傳遞
及原生停用動作守門。兩次production build archive SHA-256一致；正式匿名asset
與CI成品相符。未配置區段的5個翻譯key已封裝於13語系，包含關聯不完整的人話錯誤。
測試環境 8080 已升級並重啟一次，HTTP 200/pong 分別於第 10／9 次檢查成立。
runtime、環境參數、既有掛載及 account／credential／setting／project_member／host
counts 均保持；三個快照皆 529／4123／38／14／3。503 停止回復容器與資料庫備份
保留；Docker health=null，不稱 healthy。未修改正式公司站、HAProxy 或 OIDC。
首次原生 Volume 驗收在任何資源寫入前，因工具錯誤要求 v1 schema 的 isNative
欄位中止；原始 HOLD 保留。原生 create／edit／cancel／deactivate／delete 與完整
resource／role／locale 矩陣仍未完成，不能以發行、QUnit 或部署成功代替。

Engine `v0.183.331`、source `515a5d37a1194f827bc3ffde34db729905ecb2b1` 與 WAR
SHA-256 `0c8310d9e9a872589972658d2fd8cb88f59f473ab8072a4746df5b0f4ef9e70e`
不變。API/schema、後端授權、state 語意、session ownership、OIDC/MFA、部署
參數與相依套件不變；無需 migration 或 runtime patch。
No migration or runtime patch is required.

Vendor-pending 保留原有 8 個 Medium package findings／4 個 CVE 與 reviewAfter；
VEX 51 statements、policy、Critical/High、fix-available、untracked／secret
門檻原封不動。正式504只同步必要 release-coordinate metadata；本文件不
宣稱零 CVE。成品 raw scan count 為 52；多階段建置及單 runtime layer
契約保留。Quick start 已對齊已核實的 504 immutable image。

## 升級與回復

先備份資料庫與既有資料卷，再僅更換映像版本及 digest；保留原 Compose 環境
參數、named volumes、restart policy、AppArmor、HTTPS origin 與 nftables 架構。
無需資料庫 migration 或 runtime patch。保留先前已知可用的 immutable image
及備份；回復時沿用原資料卷與設定，不重建或清除它們。此版本不代表完整
權限／資源／語系矩陣通過，請依部署需求確認上述待驗項目。
