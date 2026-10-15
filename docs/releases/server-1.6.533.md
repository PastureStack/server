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

正式成品安全 gate 發現 curl `8.18.0-1ubuntu2.7` 的 `CVE-2026-92392` HIGH。
本候選版改用 Ubuntu 2026-10-14 [USN-8927-1](https://ubuntu.com/security/notices/USN-8927-1)
正式修補的 `curl`、`libcurl3t64-gnutls`、`libcurl4t64` `8.18.0-1ubuntu2.8`。
三包直接取自官方安全套件庫，以簽章索引與實際 deb bytes 核對 SHA-256 後鎖定；
保留其他套件的既有 snapshot、原套件 metadata、授權與安裝路徑。
既有 `PASTURESTACK_CURL_SECURITY_SNAPSHOT=20261002T000000Z` 僅保留為 apt 來源標記；
本次 curl 三包由上述獨立官方 ADD 與 checksum 提供，不來自該舊 snapshot。
不新增 HIGH 豁免或 vendor-pending；仍須由正式成品安全 gate 確認修補結果。

第二次官方掃描已讀回三包 `.8`，未解決輸出仍列 74 筆：上述 curl
18 個 CVE／54 筆（含 3 筆 HIGH）及原本 20 筆 MEDIUM，curl 的
`FixedVersion` 欄位仍空白。正式 `.8` deb 的變更紀錄逐項列出這 18 個
CVE 的安全補丁，並與 Ubuntu USN-8927-1、curl 上游修補 commit 交叉核對。
本版以 OpenVEX `fixed` 記錄已套用的 Ubuntu backport；每項只對三個精確
`.8` PURL 生效，附官方公告、補丁與已驗簽 deb SHA-256。
gate 同步精確鎖定 69 項聲明及這 18 項修補集合，舊 `.7`、缺包、
`not_affected` 或無證據的新 CVE 都不得通過。保留 scanner 原始判斷，
不宣稱原始掃描為零，不降低 HIGH gate，仍需正式 workflow 以原 gate 重驗。

## 邊界與升級

不改註冊API、帳號權限、OIDC、MFA、HAProxy、DB、網路後端或效能設定。
官方成品確認後只更新Server數字tag，保留既有三卷、環境變數、restart、
AppArmor及Runtime。無DB遷移，保留532容器／SQL備份作回復點。

保留既有OpenVEX判斷與vendor-pending精確集合；20筆MEDIUM／10CVE仍無官方
修補版，2026-10-20複查。正式workflow必要安全與來源檢查不可繞過。
