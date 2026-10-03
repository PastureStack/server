# Server v1.6.507

## 修補範圍

正式封裝 Web Console `1.6.170`，修正未配置 local Volume 分類器對 nullable
關聯欄位的處理。完整 scoped pool/mount 關聯讀回、明確類型與旗標、
目前環境／schema 所有權，以及實際 advertised remove 契約維持不變；
缺少權威關聯或讀取失敗不得視為未配置。

Engine 保持 `v0.183.332`、source
`7a625eee58fb2bdba83d2f008bdf7dd3c0ae4295`，WAR SHA-256 保持
`31090699e214f8e357f7fe413ce307e722b9b53177003e5de0bbbca1bc7bc3f5`。
API／Auth、OIDC/MFA、session／token 所有權、角色 CRUD、後端 schema、
持久資料、主機防火牆與部署參數不變。不需資料遷移或 runtime patch，
不包含正式公司站部署。

## 正式來源與成品邊界

Web170 signed source 為 `09df1480c5f4b58c6a9a9060ff94d980792f7015`；
正式 CI `37082272427` 已通過792 tests，零 failure／skip／todo。
兩個 production archive SHA-256 相同：
`900974b07bb20ba5b2e7c1dede7012a53c6e2c96cd094c67cb7019434c4f27c9`。
Web170 公開發行已正式讀回。Server507 source 為
`34287791861643ba93edd9923fa11dd504172f60`；
[正式 publisher37083174895](https://github.com/PastureStack/server/actions/runs/37083174895)
已成功，不可變映像為
`ghcr.io/pasturestack/server:v1.6.507@sha256:c0ee312207e38f4e31b8503521c0e43cbf178110e91fac61c23056026603c91e`。
公開成品讀回核對23 assets／22 SHA-256、元件與映像identity、單runtime layer、
34 MFA/API、TLS/no-store及SBOM。首次啟動與重啟均HTTP200/pong，
分別在第13／9次探測取得；這是正式隔離發行測試，不是QA8080原生驗收。
實際 merged-rootfs scan為52 raw findings；8 MEDIUM package findings／4 CVE
仍依精確vendor-pending保留，51 VEX statements，reviewAfter為2026-10-20，
不宣稱零CVE。

## 驗收與回復邊界

Quick start 對齊 `v1.6.507` 的不可變digest。506的正式發布、QA8080部署與回復點
保留；原始 HOLD 不追認成功。QA507部署讀回通過首次9次／重啟8次探測HTTP200/pong，
runtime／環境參數／五表counts差異0；三named volumes、docker-default、unless-stopped
及506停止回滾容器保留。首輪因QA root partition available=0啟動失敗並回滾；
精確回收三份未引用且公開digest可重拉的舊image副本後，新部署通過3GiB容量守門，
沒有刪除container／volume／VM／backup。首輪HOLD仍保留。
Server507的兩筆既有隔離Volume均完成原生Store／列表／刷新、取消刪除零寫入、
唯讀兩API根DELETE405、owner原生DELETE200及刷新後消失。每案有owner／readonly
新MFA登入及13次完整DB/API保存檢查；未配置區段三個文字鍵完成13語系觀察，
不代表全頁或手機版面通過。新建Volume仍在追查，不能用既有資料驗收追認新建PASS。
主機新增入口restricted／readonly／noaccess在繁中與英文分項拒絕通過，
錯誤訊息可讀，資源／註冊Token／偏好寫入皆0。完整角色矩陣仍 INCOMPLETE。
另精確移除10個已停止的舊Server回滾容器，保留目前507及最近506回滾點；
主機UI重新登入及刷新後只有這兩筆，舊重複項目消失。VM、資料卷及映像保留。
Docker health null 不等於 healthy，來源或CI成功不等於原生矩陣PASS。
保留現有 named volumes、environment、restart policy、AppArmor、HTTPS
與回復點，不以 activate／deactivate 迎合未配置fixture測試。

## 安全來源座標

僅將 vendor-pending release 與 OpenVEX document coordinate 同步507，
OpenVEX metadata revision 為51。原 source-inventory timestamp保留；
此座標重綁不是重新掃描時間或新掃描結果。既有8筆MEDIUM／4 CVE、
reviewAfter、51個VEX statements與exact-set政策完整保留，不放寬
severity／fixedVersion／secrets門檻，也不宣稱零CVE。
