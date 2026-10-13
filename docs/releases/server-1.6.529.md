# Server v1.6.529

Server `v1.6.529` 已完成正式不可變發行與匿名讀回。

本版組裝 Engine `v0.183.347` 與 Web Console `1.6.184`。
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

## 正式發行與驗收邊界

Engine 與 Web 元件已正式發行並匿名讀回相同 SHA-256 成品。
Server 正常合併 producer：`f0a1edd7258b4005c5b9fa205c1b93435f759583`。
[原正式工作流 38405824990](https://github.com/PastureStack/server/actions/runs/38405824990)
已通過來源／封裝、安全／SBOM 與發行 gates；必要 CodeQL 未繞過。
linux/amd64 成品有一個 runtime layer，不可變 tag 與實際讀回吻合。
Registry manifest：
`ghcr.io/pasturestack/server:v1.6.529@sha256:0e85f22039a17d114a0d86cf1b682063695773a09bf1a0c308baf32aa2ed394a`。
不同的 OCI config：
`sha256:00d56e427357b5e3f7517ebbb3ba3def64d022944f3ad2cb8e5ac8295067bdc2`。

正式映像的 36 個訂閱子案通過：全域管理者、owner、member、restricted、
readonly、no-access 各兩個 local-MFA 帳號；涵蓋 Full、Closed、自訂全域唯讀、
client close、owner 自訂 Key 撤權、HTTP101 與 terminal 分開、requestId 配對及
單筆終止事件。兩個已通過子案沿用，沒有重跑；專屬容器與三卷已刪除。
這不是整個角色／資源矩陣、OIDC 或 active-node 生命週期通過。
Project／Stack 唯讀白名單不會取得 synthetic subscribe 的無範圍握手授權；
此既有保護未放寬。隔離升級後首次啟動與一次重啟均為 HTTP200／pong；
原環境變數、三個 named volumes、AppArmor、network 與 restart policy 保留，
資料庫五表筆數未變，前一版容器與 SQL 備份保留。公司正式站未部署。
目前安裝文件使用已發布 `v1.6.529` 的數字 tag；immutable digest 只用於發行身分。

## 升級與回復

只部署完成正式發行與讀回的整套 Server 映像，不在運行容器中替換 WAR。
保留既有環境變數、三個 named volumes、restart、安全設定、HTTPS origin、
OIDC 與 nftables 架構；部署前備份資料庫與設定並保留已驗收版本的回復點。
來源檢查、元件發行、Server 組裝與實機驗收是不同證據，不能互相替代。
