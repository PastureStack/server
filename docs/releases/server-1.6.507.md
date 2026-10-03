# Server v1.6.507

## 候選範圍

預定封裝 Web Console `1.6.170`，修正未配置 local Volume 分類器對 nullable
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
Web170 公開發行已正式讀回；Server507 的 merged source、publisher、
不可變映像與公開成品須依其實際 receipt 核對，目前不得宣稱已發布或
使用506的 digest／receipt作507證明。

## 驗收與回復邊界

Quick start 保持已發布的 `v1.6.506`。506的正式發布、QA8080部署與回復點
保留；原始 HOLD 不追認成功。Server507的原生建立、store讀回、取消、
刷新、刪除與逐ID拒絕仍待實際驗收，完整角色矩陣仍 INCOMPLETE。
Docker health null 不等於 healthy，來源或CI成功不等於原生矩陣PASS。
保留現有 named volumes、environment、restart policy、AppArmor、HTTPS
與回復點，不以 activate／deactivate 迎合未配置fixture測試。

## 安全來源座標

僅將 vendor-pending release 與 OpenVEX document coordinate 同步507，
OpenVEX metadata revision 為51。原 source-inventory timestamp保留；
此座標重綁不是重新掃描時間或新掃描結果。既有8筆MEDIUM／4 CVE、
reviewAfter、51個VEX statements與exact-set政策完整保留，不放寬
severity／fixedVersion／secrets門檻，也不宣稱零CVE。
