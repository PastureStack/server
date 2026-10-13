# Server v1.6.528

本版修正自訂 API Key 依 Stack 讀取 Instance Link 時，MariaDB 將相關
EXISTS 最佳化為不支援的 row/IN 查詢、導致 HTTP 409 的問題。
父 Stack 改用主鍵唯一的 scalar marker；精確 ID、同擁有者與存活條件仍保留。
Container／Link 共用的 Stack 比較明確處理雙 NULL 與單側 NULL，不讓
不一致的 managed／upgrade 父層關係漏過檢查。

## 元件與檢查範圍

- Engine：v0.183.346，來源 e250e4a17958216c30c1f5d0d31f7b6418a968d5。
- 正式 cattle.jar：87,874,922 bytes；SHA-256
  `9deeda5758b7f04135441a203092dd0308d90b65d25037b62ef4f9361d3cf806`。
- Web Console：1.6.183；其他元件與安全控制沿用既有組合。
- Engine 三項相關測試與 MariaDB 11.8.6 的兩個完整唯讀 SQL 查詢通過。
  這些是來源與資料庫相容性證據，不替代組裝映像的業務授權驗收。

Server 仍須通過原有封裝、必要 CodeQL、merged-rootfs 安全／SBOM、
不可變發行與實機檢查。只更新 VEX／待供應商修補清單的數字版本識別；
既有決策、修補條件與期限不變。歷史 344 控制保留，另驗證舊 345
來源與 WAR 不得冒充 346。KVM 與完整矩陣的未驗項目不宣稱通過。

## 升級與回復

使用正式數字版本映像與原有 Compose，保留環境變數、named volumes、
restart、安全設定、HTTPS origin、OIDC 與 nftables 架構。
部署前備份設定與資料庫，並保留最近已驗收版本的回復點。
本次未修改資料庫結構或 HAProxy，也不需要 runtime patch；
回到舊版本仍會帶回其已知的自訂 Key Link 查詢缺口。

實際 Server 發行身分、部署與驗收結果以本版發行資產及目前安裝文件為準。

