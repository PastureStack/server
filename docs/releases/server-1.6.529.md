# Server v1.6.529

Prepared source only; no Server image or release has been published.

本候選組裝 Engine `v0.183.347` 與 Web Console `1.6.184`。
Engine 補齊 API Key WebSocket 訂閱的終止稽核：保留首次關閉／失敗原因、
清除關閉後才完成的註冊，並以既有有界排程重試終止事件傳遞。
實際資源清理仍只執行一次；重試只保留生命週期 metadata，
不保留 request、token、writer 或授權，也不記錄客戶端關閉文字或例外內容。
Web 將 `subscribe` 顯示為事件訂閱，包含空 target ID 的 completion 記錄；
這只是稽核標籤，不新增 scope picker 類型或 grant 能力。

## 元件輸入與檢查範圍

- Engine 正常合併來源：`09eb6950551b65c514786b4a1dee91fcfd8aa43b`。
  `cattle.jar` SHA-256：
  `22751db8829767d1ab9caedbca4e29de5260f26cafa677abb6f3ee0ee3c7e6f6`。
- Web 正常合併來源：`c41fcf05b42f648d6a7e3859285b95c07b4dd40d`。
  `web-console-1.6.184.tar.gz` SHA-256：
  `a374e6eed0ad8daec785cc3ba833e6219d46ffd23ead77d2fd720aed5d5d52f9`。
- Engine 30 項 focused 測試與 Web 3 項 focused unit 通過；Web 檢查包含
  13 個正式語系的實際翻譯文字。這些是元件證據，不是 Server native PASS。

Full／legacy 相容、受限 Key 的即時檢查、owner RBAC、deny precedence、
expiry、API 契約與持久稽核上限不變。其他元件、CLI `0.6.14`、工具鏈、
nftables、Compose／HA／runtime 設定與資料庫結構均不修改。
安全清單只更新本版數字識別，既有 VEX 決策與 vendor-pending 條件不變。
原歷史 Engine 負控制保留，另加入舊 346 不得冒充 347 的封裝檢查。

## 尚待完成

Engine 與 Web 元件已正式發行並匿名讀回相同 SHA-256 成品。
Server 來源／封裝、安全／SBOM、必要 CodeQL、正式工作流、不可變映像
發行與讀回仍須依原有 gates 完成。
Server 訂閱 native 驗收、啟動／一次重啟與部署尚待驗，不宣稱完整矩陣、
全角色、active-node 註冊生命週期或公司正式站通過。
目前安裝文件保持已發布 `v1.6.528` 的數字 tag，不使用候選 digest。

## 升級與回復

只部署完成正式發行與讀回的整套 Server 映像，不在運行容器中替換 WAR。
保留既有環境變數、三個 named volumes、restart、安全設定、HTTPS origin、
OIDC 與 nftables 架構；部署前備份資料庫與設定並保留已驗收版本的回復點。
來源檢查、元件發行、Server 組裝與實機驗收是不同證據，不能互相替代。
