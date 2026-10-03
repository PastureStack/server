# Server v1.6.508

## 已發布修補範圍

本版僅升級 Web Console `1.6.171`，固定 signed source
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

## 正式發行與驗收邊界

Web171 已正式發布並匿名下載確認與 CI 原始成品逐位元相同；正式 archive SHA256 為
`49fac41ca93eb628d0877104f9512ef382ffd9dbc89e04c940196b3a9c57798b`。
CI [37094728912](https://github.com/PastureStack/web-console/actions/runs/37094728912)：
802/802 QUnit、10 項新回歸含100次決定性 barrier、22/22 audit-tool self-tests。
CodeQL 通過；Windows npm audit runner 不再讀取 APPDATA 指定的腳本，亦阻止目前目錄遮蔽 CLI。
建置 advisory GHSA-vfj7-8cjw-p6xm 的正式 CI 原始 audit 為 7 High／3 Moderate／0 Critical，
精確 development closure 限期至2026-10-10；未宣稱零 CVE 或全 runtime 不受影響。
Server508已正式發布，source為 `69744f3ef0c00c14147fb83480306e07ccb667d9`，
不可變映像為
`ghcr.io/pasturestack/server:v1.6.508@sha256:e24f9993593bb609a7a0e26dc12fbbb21ab402b73c60af28955b988b83b6ac04`。
[正式publisher37095694250](https://github.com/PastureStack/server/actions/runs/37095694250)
與完整公開讀回已通過：23項assets／22項SHA-256，public tag與不可變manifest、
image config、版本／source labels、component與SBOM identity逐項相符；單runtime layer保留。
正式隔離映像首次啟動／一次重啟均HTTP200/pong，分別在第13／9次探測取得；
34項MFA/API、TLS1.2／1.3 HTTP200及不可信憑證拒絕皆核對。
這些是正式publisher證據，不是QA8080部署或Docker healthy的宣告。
QA8080已部署508：首次10次／重啟9次探測HTTP200/pong；runtime、environment及
account／credential／setting／project_member／host五表counts差異0。
沿用三named volumes、AppArmor、restart policy及507回復點；Docker health=null。
Registry member原生建立／編輯／取消／移除已分項通過：5次原生成功寫入，
另2次API憑證收尾，20個完整資料守門；英文憑證三個必填錯誤及取消零寫入通過。
原生Volume `1v36653` 的同ID生命週期已通過可追溯續接驗收：原生POST201較晚
抵達仍保留先到WebSocket的canonical模型；刷新、取消與原生DELETE200終態皆核對。
readonly兩版DELETE405；no-access兩版GET／DELETE403與繁中／英文清單、
新增頁的可讀拒絕均通過。16個生命週期完整守門含12個既有證據與4個本次守門；
no-access另將既有4API請求／9守門與本次零API請求／5畫面及終態守門分開記錄。
本次owner與no-access雙MFA登入都有獨立完整資料守門；readonly沿用已完成的同ID證據。
只刪除本案隔離Volume，其他資料保全；歷史HOLD及未證實的舊登入轉換仍不升格。
不得以來源／局部測試／既有資料 cleanup 證據代替本版 fresh native PASS。
507 原生 fresh HOLD 與 scoped existing cleanup 分開保留；完整角色矩陣仍 INCOMPLETE。
Quick start對齊已發布508完整不可變映像；不部署正式公司站。
原 named volumes、environment、unless-stopped、AppArmor、socket、port 與回復點保留。
不以 activate／deactivate 迎合未配置 local fixture 的 inactive 合法狀態。

## 安全座標保存

僅將 vendor-pending release 與 OpenVEX document ID 同步508；source-inventory timestamp
及既有 OpenVEX metadata version51 保留，不假裝新增掃描。
8筆 MEDIUM package findings／4 CVE、reviewAfter、51個 VEX statements、severity／fixedVersion
與 secrets／exact-set 門檻均不變，不宣稱零 CVE。
正式merged-rootfs掃描原始52筆findings，經精確VEX／purl核對後仍保留8筆Medium／4個CVE；
untracked、Critical／High、已有修補版與secrets均為0，vendor複核期限維持2026-10-20。
Web建置的7 High／3 Moderate與其2026-10-10上游待補期限分開記錄，不混同Server掃描結果。
