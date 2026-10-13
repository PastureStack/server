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

Server 已通過原有封裝、必要 CodeQL、merged-rootfs 安全／SBOM、
不可變發行與讀回檢查。只更新 VEX／待供應商修補清單的數字版本識別；
既有決策、修補條件與期限不變。歷史 344 控制保留，另驗證舊 345
來源與 WAR 不得冒充 346。KVM 與完整矩陣的未驗項目不宣稱通過。

## 發行與實機結果

不可變映像來源：`cbd0a988d0cd2882842f4f2a8012af3f841b479e`。
[正式發行工作](https://github.com/PastureStack/server/actions/runs/38372165651)
通過；linux/amd64 成品只有一個 runtime layer。
Registry manifest：
`ghcr.io/pasturestack/server:v1.6.528@sha256:1d6bbc1081b5ead8cabcd3f72ff17bf3522d90d94ad97ed83add425a9880e42f`。
不同的 OCI config：
`sha256:d420681bc58de55239ae212b7d929d37e9eca2beb484a44d48368f609054fa0c`。

正式映像的 16 項唯讀驗收通過：Link 與 Container 各 8 項，涵蓋 v1／v2-beta、
直接 ID／集合及 Stack 範圍命中／未命中。32 筆決策與回應稽核均可關聯，
23 欄資料庫投影前後不變，測試容器與三個資料卷已清除。
這是 owner 單一帳號的範圍驗收，不代表完整角色矩陣、資源寫入或生命週期。
既有不受修改影響的通過項目沒有重跑。

另一項隔離 QA 從 526 升至 528，啟動與一次重啟均回應 HTTP 200／pong，
五類資料筆數不變，原環境變數、三個資料卷與 runtime 安全設定保留。
已保留 526 容器與資料庫備份；沒有更新公司正式站。
註冊入口檢查不等於完成新節點生命週期驗收。

## 升級與回復

使用正式數字版本映像與原有 Compose，保留環境變數、named volumes、
restart、安全設定、HTTPS origin、OIDC 與 nftables 架構。
部署前備份設定與資料庫，並保留最近已驗收版本的回復點。
本次未修改資料庫結構或 HAProxy，也不需要 runtime patch；
回到舊版本仍會帶回其已知的自訂 Key Link 查詢缺口。

實際 Server 發行身分、部署與驗收結果以本版發行資產及目前安裝文件為準。

