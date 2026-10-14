# Server v1.6.531

本版組裝已正式不可變發行的 Engine `v0.183.348` 與 Web Console `1.6.186`。
Server 數字 tag `v1.6.531` 已正式發布並完成不可變成品讀回，producer source 為
`aea01351c270133607bcc0104236c58ff91fc7fd`；
`ghcr.io/pasturestack/server:v1.6.531` 的 registry manifest 為
`sha256:950a9cee2400c3ac0a97aac75e5ff278994d03293e28ac7c821b782e8bed48a4`。
文件更新不替換此正式 source 或映像身分。
完整成品識別（不是安裝指令）：
`ghcr.io/pasturestack/server:v1.6.531@sha256:950a9cee2400c3ac0a97aac75e5ff278994d03293e28ac7c821b782e8bed48a4`。

Engine 的預設專案範本名稱對齊真正 Catalog `project.yml` 的
`PastureStack Native`。乾淨安裝的共用 Default 能自動綁定範本；
catalog reload 也可補上已安裝範本、但 `adminProject` 仍未綁定的狀況。
補綁只接受有效設定名稱符合的 public 範本、目前版本且未移除的 Default，
使用原範本 lock，先持久化綁定再觸發原 system-stack 流程。
不覆蓋已有綁定、明確自訂設定或其他專案；不使用別名 fallback、
直接資料庫修補、手動補 stack 或 provider/backend 替換。

零主機時可先有 network-services、IPsec、scheduler 與 healthcheck 定義，
服務啟動沿用首台 active host 的正常觸發。Network、Metadata、DNS 與 health
本版隔離首台主機原生驗收已確認實際就緒。

Web 的原共用 driver card 在模型沒有 `catalogDisplayName` 時顯示 native API
名稱，讓共用通用圖示的 `hyperv`、`libvirt`、`vmwarefusion`、`virtualbox`
仍有各自名稱與 ID。Catalog 的本地化、格式化及刻意空白 display name 保留。
不刪除 driver、不合併記錄、不改初始化或操作目標；既有本人 API Key 頁保持。

## 元件輸入與驗收邊界

- Engine 正常合併來源：`f19cd64183c0fa93464e9a9f9c2477c9e902b56d`。
  `cattle.jar` 為 87,888,240 bytes，SHA-256：
  `72581f6eead8633b6bbafbe15512cd44561b9ff25df68d00dd7120ad507aa449`。
  14 項定向案例通過；原封裝／成品 gates 與測試來源對應的
  4 個 production class、預設 properties 精確 bytes 核對通過。
- Web 正常合併來源：`236973cb28dd7600a697902e3e3445b1a210a87a`。
  `web-console-1.6.186.tar.gz` 為 3,023,477 bytes，SHA-256：
  `95b319150d75b927b5474400129eee43eeec181a86c5b6d5065d44815df3da76`。
  4 項實際頁面 render 案例通過，涵蓋 en-us、zh-tw、native driver 名稱與 ID、
  320px card 容器、Catalog 語系切換及刻意空白 display name。
- 兩個元件的正式不可變發行與匿名成品讀回已完成，正常合併與必要 checks
  未繞過。上述是元件證據，不是 Server native 或完整矩陣 PASS。

其他元件及 pins、工具鏈、readonly/restricted schema SHA、後端、角色、
HTTPS origin、MFA、nftables、Compose／HA 與資料庫結構均保留。
安全清單更新 Server 數字識別及下列精確 vendor-pending 範圍；VEX 決策、
vendor-pending exact-set、原必要 gates 與既有元件歷史負控制不弱化。

## 待 vendor 的安全範圍

本版安全 tracker 收錄 Trivy 原始掃描新增的 6 個 PCRE2 CVE，
各對應 Ubuntu 26.04 `libpcre2-8-0` 與 `libpcre2-posix3` 的
`10.46-1build1`，合計 12 筆 MEDIUM，`FixedVersion` 均為空。
vendor-pending 現記錄共 10 個 CVE／20 筆精確 MEDIUM package findings，
覆核期限維持 `2026-10-20`。

2026-10-14 03:45 UTC 直接讀回 Ubuntu 官方 HTTP 200 頁面：

- Ubuntu 26.04 pcre2 標為 Vulnerable：
  [CVE-2026-103111](https://ubuntu.com/security/CVE-2026-103111)、
  [CVE-2026-89156](https://ubuntu.com/security/CVE-2026-89156)、
  [CVE-2026-89157](https://ubuntu.com/security/CVE-2026-89157)、
  [CVE-2026-89158](https://ubuntu.com/security/CVE-2026-89158)、
  [CVE-2026-89160](https://ubuntu.com/security/CVE-2026-89160)，
  頁面最後更新為 2026-10-13。
- Ubuntu 26.04 pcre2 標為 Needs evaluation：
  [CVE-2026-89162](https://ubuntu.com/security/CVE-2026-89162)，
  頁面最後更新為 2026-09-16。

上述官方狀態未列出 Ubuntu 26.04 已發布修復版本。
tracker 的 `needs-evaluation` 沿用本專案的到期覆核狀態，
不是 Canonical 的套件狀態；新增項目的 `upstreamVendorStatus` 與
`verifiedAt` 保留此次官方讀回。這些 finding 仍待 vendor，未宣告已修復、
未改成 VEX not-affected 或安全豁免。允許 severity、空 `FixedVersion`、
精確 package/CVE/version/target 比對與原發布 gates 保持原契約；
正式 Server 發布與不可變讀回已完成；待 vendor 清單仍依原 exact-set 契約覆核。

發行流程保留原來源／封裝、安全／SBOM、CodeQL、不可變發行及成品讀回閘門。
安裝及元件配對見 Server README，
正式映像身分與安全掃描結果由同版本 GitHub Release 提供。

## 受影響路徑原生驗收

現有 Server 530 未綁定 Default 的升級補綁與一輪重啟通過，沒有新增重複
stack、service 或 driver。Fresh Server 531 使用三個持久化 volumes，經正常
公開流程註冊一次首台主機；Default 綁定範本 `1pt1`，四個 core stacks 與六個
core services 均 active／healthy。Metadata、managed DNS、HTTPS egress HTTP
200，以及公開 host port `18297` 到 probe port `18080` 的存取均通過。

隔離 Server restart、Docker restart、guest reboot（boot ID 已改變）後保留
上述 readiness；再經正常 native API 重建 probe workload，`1i15` 到 `1i16`
仍通過。正式發行映像的現有安裝部署與後續 restart 亦已通過。

真實 Chrome 154.0.8037.98 載入 Server 531／Web 186：十一個不同 driver ID 與
名稱在 v1／v2-beta exact-set 相符，zh-tw／en-us 的 1440px／390px 都顯示正確。
四個 generic icons 對應不同記錄；重啟後 IDs／names 不變，page errors 為零，
五張截圖均已人工檢視。沒有刪除或合併 driver。

Narrow affected-path acceptance completed。驗收使用既有 host 預設 backend，
role logic 未變；範圍涵蓋上述受影響路徑，不宣稱所有角色／backend 矩陣完成。

## 升級與回復

使用完成正式發行與讀回的整套 Server 映像，不在運行容器中替換元件。
保留既有環境變數、三個 named volumes、restart、安全設定、HTTPS origin、
OIDC 與 nftables 架構；先備份資料庫與設定並保留已驗收版本的回復點。
