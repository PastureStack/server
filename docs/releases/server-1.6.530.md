# Server v1.6.530

本版目前僅為來源組裝候選，尚未發布 Server 映像。
組裝已正式不可變發行的 Web Console `1.6.185`，Engine `v0.183.347` 不變。

Web 新增獨立的 `/account/keys` 本人 API Key 入口，讓沒有環境的已登入帳號
也能使用既有 Key 編輯器與稽核頁。頁面共用原 route／controller／template，
只載入本人完整與受限 Key，不請求或顯示環境 Key；audit 的 `targetKey`
留在本人頁。既有環境 Keys／Hooks 導航保持原路徑。
這不新增角色、環境、授權能力或登入途徑，原 MFA、Session、owner RBAC、
Key policy、403 與錯誤處理不變。

## 元件輸入與驗收邊界

- Web 正常簽署合併來源：`ad5a68dd30a6e136745123e26c97c4925c2ed263`。
  `web-console-1.6.185.tar.gz` 為 3,016,944 bytes，SHA-256：
  `49ac7dff80143329e88ab036a50fdb9e3a043412f67ca68fabe3b485c87df05e`。
  正式不可變發行與匿名成品讀回已完成。
- Engine 保留正式來源 `09eb6950551b65c514786b4a1dee91fcfd8aa43b`；
  `cattle.jar` SHA-256 保持
  `22751db8829767d1ab9caedbca4e29de5260f26cafa677abb6f3ee0ee3c7e6f6`。
- Web 的 10 項定向測試通過，涵蓋本人兩種 Key、無額外環境請求、
  原環境模式、導航、audit 路由與錯誤傳遞。未重播不受影響測試。
  這是元件證據，不是 Server native 或完整矩陣 PASS。

CLI `0.6.14`、其他 binary／元件、工具鏈、nftables、Compose／HA、
runtime 設定與資料庫結構均不修改。安全清單只更新 Server 數字識別，
VEX 決策、vendor-pending exact-set 與原必要 gates 不變。
既有 Engine 及 Web 歷史負控制保留。

Server 的原正常來源／封裝、CodeQL、安全／SBOM、不可變發行與成品讀回
仍須依正常流程通過。新映像原生本人 Key 驗收、首次啟動／重啟與部署待驗。
目前安裝文件維持實際已發布的 `v1.6.529`；530 發布後才對齊數字安裝 tag。

## 升級與回復

只部署完成正式發行與讀回的整套 Server 映像，不在運行容器中替換元件。
保留既有環境變數、三個 named volumes、restart、安全設定、HTTPS origin、
OIDC 與 nftables 架構；先備份資料庫與設定並保留已驗收版本的回復點。
