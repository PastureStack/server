# Server v1.6.534

本版封裝正式不可變 Web Console `1.6.189`，Engine 維持 `v0.183.348`。188視覺驗收發現既有RTL步驟圓圈背景與數字分離，本版明確設定背景定位並由RTL編譯器鏡射；原hover修正、API及權限保留。

## 修正與驗證

只新增step-list背景定位，保留SVG幾何與原生tooltip行為。新增CSS檢查6／6及受影響封裝檢查38／38、當前安裝文件檢查1／1通過。188的DOM4項與原13／caption修正1項、32鍵×13語系資源證據沿用，未重新執行冒充新測。

## 正式成品與部署證據

The immutable Server producer is `52714c372b38ea0b6f56bb205fbdfb0a584707e1`. Official workflow [38663986172](https://github.com/PastureStack/server/actions/runs/38663986172) and readback of 24 assets passed without bypassing required checks. The linux/amd64 image has one runtime layer. Registry manifest: `sha256:e218bd31b39207c969f331aab097fd9773ef0071216e794f9a4bd23010d8fc96`. Distinct OCI config: `sha256:1d31677fbc05073830eaee66592a8c274edd7d4cf743c3c3371383b5e36bd7fd`. Artifact identity, not an installation command: `ghcr.io/pasturestack/server:v1.6.534@sha256:e218bd31b39207c969f331aab097fd9773ef0071216e794f9a4bd23010d8fc96`. Documentation commits do not replace the producer.

Immutable Web producer: `f30f5e81dd9ee25878c3aff681eed5bb61883453`. `web-console-1.6.189.tar.gz` is 3,024,592 bytes, SHA-256 `1c90e273b7db8ebf9d851a0ae1ec49dc59067b5ee1099ea3886919c1a79ccdfc`. Official publication and anonymous readback passed; later documentation commits do not replace this producer.

正式 QA 部署與重啟檢查通過；部署讀回的 producer、manifest 與 config符合上述正式成品，原資料卷與 runtime 覆寫保留。文件 main 與成品 producer 分開。

最終矩陣為13語系×1440／390px×亮／暗色共52組PASS：44組同來源未受CSS影響的188證據沿用，fa-ir/en-us共8組在189新跑，絕非52組皆189新跑。另於189以未覆寫 Clipboard API 的普通 HTTP 瀏覽器確認 API 不存在時的原生 fallback，實際複製與精確剪貼簿讀回通過；拒絕權限的失敗提示是明確 denial fixture，兩者分列。偏好、呈現與剪貼簿已恢復，頁面錯誤、缺翻譯與非預期資源寫入均為0。原13／caption修正1項與188實際DOM4項證據沿用；32鍵×13語系資源來源未變，沒有重跑冒充新結果。歷史全矩陣仍未完成，HOLD與KVM待驗維持原狀；187 hover失敗不追認通過。

## curl 官方修補與掃描判定

v1.6.533 的第一個未發布候選在正式成品安全 gate 發現 curl `8.18.0-1ubuntu2.7` 的 `CVE-2026-92392` HIGH。
本版採用 Ubuntu 2026-10-14 [USN-8927-1](https://ubuntu.com/security/notices/USN-8927-1)
正式修補的 `curl`、`libcurl3t64-gnutls`、`libcurl4t64` `8.18.0-1ubuntu2.8`。
三包直接取自官方安全套件庫，以簽章索引與實際 deb bytes 核對 SHA-256 後鎖定；
保留其他套件的既有 snapshot、原套件 metadata、授權與安裝路徑。
既有 `PASTURESTACK_CURL_SECURITY_SNAPSHOT=20261002T000000Z` 僅保留為 apt 來源標記；
本次 curl 三包由上述獨立官方 ADD 與 checksum 提供，不來自該舊 snapshot。
不新增 HIGH 豁免或 vendor-pending；正式 workflow 已以既有成品安全 gate 通過。

該版第二次未發布候選的官方掃描已讀回三包 `.8`，未解決輸出仍列 74 筆：上述 curl
18 個 CVE／54 筆（含 3 筆 HIGH）及原本 20 筆 MEDIUM，curl 的
`FixedVersion` 欄位仍空白。正式 `.8` deb 的變更紀錄逐項列出這 18 個
CVE 的安全補丁，並與 Ubuntu USN-8927-1、curl 上游修補 commit 交叉核對。
本版以 OpenVEX `fixed` 記錄已套用的 Ubuntu backport；每項只對三個精確
`.8` PURL 生效，附官方公告、補丁與已驗簽 deb SHA-256。
gate 同步精確鎖定 69 項聲明及這 18 項修補集合，舊 `.7`、缺包、
`not_affected` 或無證據的新 CVE 都不得通過。保留 scanner 原始判斷，
不宣稱原始掃描為零，不降低 HIGH gate；正式 workflow 已以同一精確集合 gate 通過。

## 邊界與升級

不改註冊API、帳號權限、OIDC、MFA、HAProxy、DB、網路後端或效能設定。安裝／升級使用Server數字tag `v1.6.534`，保留既有三卷、環境變數、restart、AppArmor及Runtime。無DB遷移，保留533映像／資料備份作回復點；部署成功不代表實際回滾演練完成。

保留既有OpenVEX判斷與vendor-pending精確集合；20筆MEDIUM／10CVE仍無官方
修補版，2026-10-20複查。正式workflow必要安全與來源檢查不可繞過。
