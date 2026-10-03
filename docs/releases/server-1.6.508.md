# Server v1.6.508

## 候選修補範圍

本候選僅升級 Web Console `1.6.171`，固定 signed source
`fc37f5af9320e492bec7e7244cd62144908b720e`。API-store compatibility revision 5 修正
新建 POST201 較晚到達時覆寫先到 WebSocket 模型的順序問題；不以狀態高低或時間 heuristic 判斷。
Type.save 僅在原本沒有 ID 的新建請求標記 createIdentity；既有 save 與 doAction 會清除標記。
Store 僅於 HTTP201／POST、相同 generation／base URL、精確 concrete type／server-generated ID
且 canonical model 屬於同一 Store 時採用該模型。沒有相符 cache 或其他 HTTP／操作保留原匯入路徑。
GET、PUT、action POST、204 與 errors 語意不變，不修改回應或 subscribe、不追加 GET。
成品封裝與隔離映像檢查皆須在 actual assets JavaScript 找到 createIdentity／hasRecord。

Engine 保持 `v0.183.332`、source
`7a625eee58fb2bdba83d2f008bdf7dd3c0ae4295`，WAR SHA-256 保持
`31090699e214f8e357f7fe413ce307e722b9b53177003e5de0bbbca1bc7bc3f5`。
API／Auth、角色 CRUD、後端 schema、持久資料與 pool/mount 完整關聯保護不變。
No migration or runtime patch is required.

## 正式成品與驗收仍待完成

Web171 已正式發布並匿名下載確認與 CI 原始成品逐位元相同；正式 archive SHA256 為
`49fac41ca93eb628d0877104f9512ef382ffd9dbc89e04c940196b3a9c57798b`。
CI [37094728912](https://github.com/PastureStack/web-console/actions/runs/37094728912)：
802/802 QUnit、10 項新回歸含100次決定性 barrier、22/22 audit-tool self-tests。
CodeQL 通過；Windows npm audit runner 不再讀取 APPDATA 指定的腳本，亦阻止目前目錄遮蔽 CLI。
建置 advisory GHSA-vfj7-8cjw-p6xm 的正式 CI 原始 audit 為 7 High／3 Moderate／0 Critical，
精確 development closure 限期至2026-10-10；未宣稱零 CVE 或全 runtime 不受影響。
Server508 source／publisher／digest 尚待正式發布流程核實。
QA8080 部署、隔離首次啟動／重啟、成品 SBOM、安全閘門及新建 Volume 原生生命週期尚待完成。
不得以來源／局部測試／既有資料 cleanup 證據代替本版 fresh native PASS。
507 原生 fresh HOLD 與 scoped existing cleanup 分開保留；完整角色矩陣仍 INCOMPLETE。
Quick start 保持已發布507不可變映像；不部署正式公司站。
原 named volumes、environment、unless-stopped、AppArmor、socket、port 與回復點保留。
不以 activate／deactivate 迎合未配置 local fixture 的 inactive 合法狀態。

## 安全座標保存

僅將 vendor-pending release 與 OpenVEX document ID 同步508；source-inventory timestamp
及既有 OpenVEX metadata version51 保留，不假裝新增掃描。
8筆 MEDIUM package findings／4 CVE、reviewAfter、51個 VEX statements、severity／fixedVersion
與 secrets／exact-set 門檻均不變，不宣稱零 CVE。
