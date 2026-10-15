# Server v1.6.533 candidate

本版封裝正式不可變 Web Console `1.6.188`，Engine 維持 `v0.183.348`。
實際瀏覽器驗收187時發現：Ember5預設不再委派非冒泡的
`mouseenter`／`mouseleave`，共用提示仍依賴舊事件，因此懸停沒有出現提示。

## 修正與驗證

共用 trigger 與浮動提示各自於掛載時註冊原生 listener、進入 run loop，
銷毀時移除相同 handler。維持既有虛擬方法與 action-menu 的開啟歸屬，
不改全域事件映射；既有靜態 context 代理、13語系翻譯與複製保護不變。

四項新增實際DOM回歸通過：初始／成功／失敗內容、滑鼠離開與進入、
listener清理及銷毀後事件、action-menu覆寫、原生主機註冊複製。
原13項與修正caption後1項證據保留，不重跑無關測試。

Web producer `8e12216fd6f8d843ed043b4c0afcec995d33caeb`；正式tar為
3,025,072 bytes，SHA-256
`3467dfb37d7723b9293bc64145603d09ba24799ad726feb89177c9fa38b4ed92`。
Web必要檢查、正常簽章合併、不可變發布與匿名讀回已完成。

Server正式發行、成品讀回、8080部署、13語系×桌面／窄版×亮／暗色52組
以及普通HTTP複製仍各自待完成，不將來源測試當成瀏覽器通過。
歷史矩陣與KVM待驗維持原狀。

## 邊界與升級

不改註冊API、帳號權限、OIDC、MFA、HAProxy、DB、網路後端或效能設定。
官方成品確認後只更新Server數字tag，保留既有三卷、環境變數、restart、
AppArmor及Runtime。無DB遷移，保留532容器／SQL備份作回復點。

保留既有OpenVEX判斷與vendor-pending精確集合；20筆MEDIUM／10CVE仍無官方
修補版，2026-10-20複查。正式workflow必要安全與來源檢查不可繞過。
