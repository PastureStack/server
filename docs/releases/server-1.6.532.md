# Server v1.6.532

本版封裝正式不可變 Web Console `1.6.187`；Engine 維持 `v0.183.348`。
修正共用複製元件在初次渲染、無滑鼠移入或鍵盤操作時讀到未定義翻譯鍵，
以及複製提示受按鈕窄寬度影響而成為直條、超出視窗的問題。

## 修改範圍

- 共用提示在初次渲染即有有效翻譯，複製成功或失敗後恢復正確提示。
- 13 個支援語系都有原生預設、成功及失敗文字；俄文不再誤稱複製連結。
- 非同步複製失敗顯示可操作的訊息，HTTP fallback 即使例外也清除暫存 textarea。
- 已銷毀元件不接收遲到結果，個別按鈕的計時器不覆寫別人的提示。
- 複製提示依文字寬度換行並限制在視窗內；重用一般 tooltip 時移除 copy 專用樣式。
- Custom 主機的 Linux／Windows 指令在 RTL 語系仍為 LTR；窄版可換行長 URL。

不改註冊指令或密鑰、API 契約、權限、Authentication Service、OIDC、MFA、
HAProxy、資料庫、plugin 或防火牆後端。其他元件及必要安全 gates 保留。

## 元件與證據

Web producer：`b45f8ee73c72b5f58b010dd55c64d5aef7406c61`。
`web-console-1.6.187.tar.gz` 為 3,024,923 bytes，SHA-256：
`b9797c08cf8c698e7cabac4bc9cd12fba0faa181c8781875d93a3de7109f2db3`。
正常必要檢查、簽章合併、正式不可變發行與匿名成品讀回已完成。

13 項相關整合案例通過。修正舊測試的非法翻譯 fixture 後，只重跑受影響的
1 項案例並通過；沒有重跑其他已通過案例。語系資源檢查涵蓋 32 鍵 × 13 語系，
沒有缺鍵、空值或 ICU 參數契約錯誤。既有 MFA 的宣告英文 fallback 另列，
不聲稱所有頁面都已有 13 語系原生翻譯。

Server 正式發行、digest 讀回、部署及瀏覽器 13 語系 × 桌面／窄版 × 亮／暗色
驗收仍為獨立必要 gate，完成後更新實際結果。既有較廣矩陣及 KVM 待驗不升格。

## 升級與回復

正式成品確認後，僅更新 Compose 的 Server 數字版本 tag，保留現有環境變數、
named volumes、restart policy、AppArmor、HTTPS origin、OIDC 與效能設定。
不使用 runtime patch。本版沒有資料庫遷移；回復可沿用同資料卷切回
上一個正式 `v1.6.531` 映像。實際回復點及首次啟動／重啟結果在部署後記錄。

## 安全範圍

只更新發行識別，保留既有 OpenVEX 決策、vendor-pending 精確集合、嚴重性
與無官方修補版的限制。正式發行依原 workflow 對成品執行必要掃描；
不為發行放寬檢查，也不將待 vendor 的 findings 宣稱為零。
