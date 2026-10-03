# Compatibility Contract

Server `v1.6.508` 已正式發布，封裝 Web Console `1.6.171`。
Server source為 `69744f3ef0c00c14147fb83480306e07ccb667d9`，不可變映像為
`ghcr.io/pasturestack/server:v1.6.508@sha256:e24f9993593bb609a7a0e26dc12fbbb21ab402b73c60af28955b988b83b6ac04`。
正式publisher `37095694250` 與公開讀回通過：23 assets／22 SHA-256、
public tag／digest／config、單runtime layer、34 MFA/API、首次啟動／重啟與TLS均核對。
正式成品讀回不代表QA部署、Docker healthy或native Volume驗收。
Web signed source 固定為 `fc37f5af9320e492bec7e7244cd62144908b720e`；1.6.171 已正式發布。
公開 archive SHA256 為 `49fac41ca93eb628d0877104f9512ef382ffd9dbc89e04c940196b3a9c57798b`，
CI `37094728912` 通過802/802，含10項新回歸、100次barrier與22項audit self-tests；CodeQL通過。
API-store compatibility revision 5 的 canonical adoption 僅限新建 POST201、
精確 type／server-generated ID、同 Store／generation／base URL；action 清除 createIdentity。
無相符 cache、GET／PUT／action／非201／204／errors 維持原語意，沒有狀態／時間排序 heuristic。
Engine保持 `v0.183.332`，WAR SHA256為
`31090699e214f8e357f7fe413ce307e722b9b53177003e5de0bbbca1bc7bc3f5`；
API／Auth／CRUD、pool/mount證明與部署／回復參數不變。
8個 MEDIUM package findings／4 CVE、51個 VEX statements 與安全 exact-set 不放寬。
Web建置audit仍為7 High／3 Moderate／0 Critical，精確上游待補風險複核至2026-10-10；
這不是零CVE或runtime整體不受影響的宣告。
QA8080已部署508，首次10次／重啟9次HTTP200/pong；runtime、environment及
五表counts差異0。三named volumes、AppArmor、restart policy與507回復點保留；
health=null，不宣稱healthy。Registry member生命周期分項通過（5次原生寫入及
2次API憑證收尾），英文憑證必填驗證／取消零寫入通過。原生Volume同ID生命週期
已可追溯續接通過：POST201／DELETE200、readonly兩版DELETE405、no-access兩版
GET／DELETE403，繁中／英文可讀拒絕與取消、刪除、刷新終態皆核對。
16個生命週期守門區分12個既有證據與4個本次守門；no-access API既有4請求／9守門
與本次零API請求／5畫面及終態守門分開，不重送已完成請求，不追認歷史HOLD。
完整矩陣INCOMPLETE。
Quick start對齊已發布508完整不可變映像；507歷史來源、HOLD與scoped PASS不拼成新版本整體PASS。

Server `v1.6.507` 已正式發布，封裝
Web Console `1.6.170`（source `09df1480c5f4b58c6a9a9060ff94d980792f7015`）。
範圍僅 nullable Volume 關聯欄位的前端分類相容性；Engine `v0.183.332`／
原 WAR、API／Auth、角色授權、pool/mount 證明、部署參數與安全門檻保留。
正式 CI archive SHA-256 為 `900974b07bb20ba5b2e7c1dede7012a53c6e2c96cd094c67cb7019434c4f27c9`；
Web170 與 Server507 已正式公開；Server source 為
`34287791861643ba93edd9923fa11dd504172f60`，不可變映像為
`ghcr.io/pasturestack/server:v1.6.507@sha256:c0ee312207e38f4e31b8503521c0e43cbf178110e91fac61c23056026603c91e`。
publisher37083174895及23 assets／22 SHA-256、單runtime layer、34 MFA/API、TLS、
SBOM與安全門檻均讀回；QA／原生驗收另行記錄，不借用506證據。
完整矩陣仍 INCOMPLETE，506 已發布／部署實績及歷史 HOLD 保留。
QA507首次9次／restart8次HTTP200/pong，runtime／環境參數／五表counts差異0，
原named volumes、AppArmor、restart policy與506回復點保留；health=null。
首輪QA根分割區滿的HOLD不追認，新部署通過3GiB空間及本機精確image守門。
本版兩筆既有隔離Volume已通過原生Store／列表／刷新、取消零寫入、
唯讀兩根DELETE405、owner原生DELETE200及終態消失；新建仍在追查。
主機新增入口三低權限角色的繁中、英文拒絕分項通過，無資源或註冊Token寫入。
這些不是全矩陣、主機註冊或完整多語系版面PASS。精確清除10個停止的舊Server
容器後，保留507與最近506回滾點，主機UI重新登入／刷新無舊重複項目；VM與資料卷未刪除。

Server `v1.6.506` 已正式封裝 Web Console `1.6.169`，將本機 Volume 的
`externalId` 視為識別碼而非配置綁定。完整 pool/mount 關聯、主機／image／
instance null binding、環境 schema 與 API 授權保護均不變。Engine 保持
`v0.183.332`，不涉及資料遷移、認證或防火牆變更。正式 source 為
`3cfb920a428fc2af6af6a07a832d6882663f544d`，不可變映像為
`ghcr.io/pasturestack/server:v1.6.506@sha256:f6860a1d0e96587b05afbf72d52c063921ff8473a976552c6d0a01d223a7a188`。
publisher37079727511已通過；Web169正式CI791/791。QA8080部署完成，首次11次／
restart9次HTTP200/pong，runtime／environment／五表counts差異0，505回復點保留；
health=null，不稱healthy。原生生命週期及完整角色矩陣另案驗收，不以正式成品或來源測試代替。

The packaging migration preserves established database schemas, API paths and fields, event names, environment-variable aliases, service names used by stored data, container labels, filesystem upgrade paths, and bootstrap contracts.

已發布的 Server `v1.6.505` 封裝 Engine `v0.183.332` 與既有 Web Console `1.6.168`。
Server source 為 `400f7dc8d533a5f13a555398c595b9ae42e0c454`，不可變映像為
`ghcr.io/pasturestack/server:v1.6.505@sha256:b3dd402cfd773b4d37ecf06f716187833e56cc6f211b7ab920dccf8dcb7366c5`。
正式 publisher `37072151759` 及23個 assets／22項 SHA-256、公開 image/component
identity 讀回通過。隔離映像首次啟動／一次重啟均 HTTP 200/pong，分別在第10／6次
探測取得；34項 MFA/API、TLS、單 runtime layer 與成品 SBOM／安全門檻通過。
這些是正式成品證據，不是 QA8080 部署、Docker healthy 或原生 Volume PASS。
本次 API/schema 有窄幅相容性補齊：v1 與 v2-beta Volume 恢復 server-owned
唯讀 `isNative`。客戶端不能寫入該欄位；其他欄位、methods、完整 actions、
角色限制及環境隔離不變，無資料庫 migration。8080 的實際 504 schema 讀回
證明兩個 API 根都缺漏分類，補充更正先前只歸因於 v1 驗收工具的診斷；
原始零資源寫入 HOLD 不改成 PASS。Engine 正式 source 為
`7a625eee58fb2bdba83d2f008bdf7dd3c0ae4295`，WAR SHA-256 為
`31090699e214f8e357f7fe413ce307e722b9b53177003e5de0bbbca1bc7bc3f5`；
正式 CI 通過270 suites／1,150 tests，failure／error／skip皆為0，含6個新增回歸。
QA8080 已部署本版並完成一次重啟；HTTP 200/pong、runtime／環境參數與
五項資料筆數保存，504 回復點保留。Docker health 為 `null`，不稱為 `healthy`。
原生建立／列表／取消／刷新／刪除仍在驗收，完整資源／角色矩陣尚未完成。
未配置 local Volume 的 `inactive` 是合法狀態，原生清單不要求 `active`；
移除須核對當次 action 與空關聯，不要求額外 activate／deactivate。
部署環境、掛載、restart、AppArmor、HTTPS origin、OIDC/MFA 與 firewall 契約保持。
Vendor-pending 8個 Medium package findings／4個 CVE、2026-10-20複核期限、
VEX 51 statements 與安全門檻不放寬；正式發行不代表零 CVE或完整矩陣 PASS。

已發布的 Server `v1.6.504` 固定封裝 Web Console `1.6.168`；Web tested source／
archive、SSH-signed numeric tag 與 Server 正式成品均已讀回。Server source 為
`e33ef8565ebe40dd188170baa46da8092fc131b9`，不可變映像為
`ghcr.io/pasturestack/server:v1.6.504@sha256:11393d4a5189601464d2a2e1ffc823160bedd6bda6c1fbae12457337f7cb9e2f`。
正式 publisher `37063207602` 與 23 個公開 assets／22 項 SHA-256 驗證通過。
測試環境首次啟動／重啟均 HTTP 200/pong，runtime、環境參數、既有掛載及五表
counts 無差異；503 回復容器與資料庫備份保留，health=null，不稱 healthy。
安裝指引已對齊本版；正式公司站未部署或修改。

Volume 的新增 CTA、直接新增路由及既有 update 路由都要求目前 project 與
schemaProjectId 相符；建立仍須實際 schema 的 POST 能力，update 原有 PUT
判斷保留。獨立未配置 local 區段及原生 Add 不依賴任何 pool 存在；列表以
實際 GET storagePools 完整 collection 與包含 inactive mounts 的完整 scoped
mount cache 判斷，避免將停止工作負載仍持有的 Volume 當成未使用。
原始403、network／sync error 保留並交既有 route／growl 診斷，不轉成空關聯。
只有目前 project/schema 相符且當次資源 advertised deactivate 才原生停用，
active→detached 後沿用既有 advertised remove／原生刪除，不另造清理 API。

API/schema、後端授權、資料／state 語意、Engine `v0.183.331`／exact WAR、
session ownership、OIDC/MFA、部署參數、相依套件、安全門檻及多階段／單 runtime
layer 契約不變；無需 migration 或 runtime patch。Web168正式CI `37061716638`
通過788／788個 QUnit案例、fail／skip／todo皆為0，包含16個 scoped Volume案例；
兩次production archive一致。上述 component 與成品／部署證據不代替原生
建立／列表／清理或完整矩陣 PASS。首次原生驗收在任何資源寫入前，因工具
誤要求 v1 schema 的 isNative 欄位中止；原 HOLD 保留，原生驗收仍待完成。Vendor-pending
8 個 Medium package findings／4 個 CVE、reviewAfter、VEX statements 與 policy
保留；正式504僅同步必要的 release-coordinate metadata，不放寬任何門檻。
詳見[發行說明](docs/releases/server-1.6.504.md)。

Published Server `v1.6.503` packages immutable Web Console `1.6.167` for
schema-only ID lookup normalization. It does not change API schemas, server
authorization, ordinary resource IDs, project-store isolation, Engine
`v0.183.331`, authentication/session ownership, MFA or runtime/firewall settings.
Missing schemas do not grant capabilities. No migration or runtime patch is
required. Web source `dff35fc4bce340e21cac7204146a7bcb20a7b60b` and archive
SHA-256 `e8e714fc06282de75a3570aac1d4d4d04a3c9478d982d0d5aaeae14efa8ebbaf`
match the immutable component publication. Its validation passed 772/772 tests
with zero failures, skips or todo, including four actual Store/schema cases,
and produced byte-identical production archives. Official publisher
37015013747 passed isolated startup/restart, 34 MFA/API checks, TLS,
exact-rootfs single-layer comparison and final-image SBOM/security gates.
Anonymous registry and all 23 release assets match Server source
`df061d5c93d0e4fdbc0e06664493ac5328a6f596`; the public image is
`ghcr.io/pasturestack/server:v1.6.503@sha256:4a8997768c5c16a9aefdc682f906aab34417e204d622d03116e62b2fcfe0af79`.
Eight Medium package findings covering four CVEs remain vendor-pending until
review on 2026-10-20; publication is not a zero-vulnerability result.
QA deployment passed first start and one restart with HTTP 200/pong after nine
attempts each. Runtime settings, environment overrides, named mounts and
five-table count baselines were preserved; the prior immutable Server502
rollback and database backup were retained. Docker health is `null`, not
`healthy`. Packaged exact-fixture QA confirmed GET-only registry/credential
models for the readonly role and denied all 24 normal-CSRF v1/v2-beta writes for readonly/no-access
roles, with the existing readable permission errors. That bounded result does
not establish all API authorization, thirteen-locale or lifecycle acceptance.
Existing 502 HOLD results are not promoted and the complete matrix remains
INCOMPLETE. See [the release notes](docs/releases/server-1.6.503.md).

Published Server `v1.6.502` packages Web Console `1.6.166` for the shared
inactive-state display label in thirteen supported catalogs. Only display
translations and component/release pins change; Engine `v0.183.331`, its exact
WAR, API/schema, authorization, session ownership, OIDC/MFA, icon/color and
state semantics, deployment overrides and firewall contracts are unchanged.
No migration or runtime patch is required. Official publisher 37003831065
passed startup/restart, 34 MFA/API checks, TLS, exact-rootfs single-layer and
final-image SBOM/security checks. Anonymous registry and 23 release assets
were verified against the immutable publication. The public image is
`ghcr.io/pasturestack/server:v1.6.502@sha256:ee6d0141574280473cb27a638814ae924b3d5bfe344f1ee0e1741aae0f3efddb`.
Eight Medium package findings covering four CVEs remain vendor-pending.
Component validation passed 768/768 tests, including eight state/date rendering
cases; it does not establish all packaged UI, resource/role or layout cases.
The QA upgrade and one restart returned HTTP 200/pong with unchanged runtime
configuration, named mounts and account/credential/setting/membership/host counts;
the prior immutable 501 container and database backup were retained. This is
deployment preservation evidence, not native-browser or role-matrix acceptance.
The full permission/resource/locale matrix remains INCOMPLETE. See
[the release notes](docs/releases/server-1.6.502.md).

Published Server `v1.6.501` packages Web Console `1.6.165` to keep complete
container names readable on Host cards without shrinking IP/action areas.
The shared subpod layout alone changes; real names/IDs, API permissions,
authentication/session ownership, Engine `v0.183.331`/exact WAR, database
schema, Compose overrides, named volumes, AppArmor, restart and nftables
contracts remain unchanged. No migration or runtime patch is required.
Web source/archive are pinned in the build and verified by actual 767/767 CI
cases with identical production archives. Publisher 36980705366 passed,
including single-layer comparison, startup/restart, 34 MFA/API cases,
TLS and exact final-image SBOM/security checks. Public digest is
`ghcr.io/pasturestack/server:v1.6.501@sha256:0a671e2695eecc74d79ef666267a40e81172205f0f8b1d0b12a7dbbed446becd`.
Native QA initial/reload accepted six exact Docker IDs and complete names,
including distinguishing rollback suffixes. Actual menu open/close, separate
IP/action areas and both screenshots passed scoped review, with zero resource
writes or page/console/loading errors. One restart preserved runtime settings
and database counts. The historical 500 visual HOLD remains unchanged and the
full permission/resource/locale matrix remains INCOMPLETE. See
[the release notes](docs/releases/server-1.6.501.md).

Published Server `v1.6.500` packages Engine `v0.183.331` to accept only the two
stable imported-container lifecycle pairs, running/active and stopped/inactive,
in both selection and the name-only full-row CAS. All existing ownership,
full Docker ID, active Host/Agent, unique mapping, managed/service exclusions,
role/schema denials and deployment/authentication contracts remain unchanged.
No migration or runtime patch is required. Engine source is
`515a5d37a1194f827bc3ffde34db729905ecb2b1`, with exact WAR SHA-256
`0c8310d9e9a872589972658d2fd8cb88f59f473ab8072a4746df5b0f4ef9e70e`.
The immutable image is
`ghcr.io/pasturestack/server:v1.6.500@sha256:7ffd67a7f82da0d374d7846b97b5a2fb71647ad01a159120418544591899f5f5`,
from source `abdee460eb67c8cd02a2db8e9a55b15f58020d83` and successful
[publication run `36973764295`](https://github.com/PastureStack/server/actions/runs/36973764295).
Exact public asset/image/component readback matched. The unchanged merged-rootfs
gate retains 52 raw findings and eight Medium vendor-pending package findings
(four unique CVEs), with zero untracked, Critical/High, fixed-available or secret
findings; this is not a zero-CVE claim.
QA500 first start/restart returned `HTTP 200` / `pong` (nine and 10 attempts).
Runtime-contract and tracked five-table count differences are zero; original
environment overrides, three named volumes, `docker-default` AppArmor and
`unless-stopped` restart policy were preserved. Docker health is `null`, not
Docker `healthy`; count equality is not a whole-database comparison. The
previous Server499 rollback is retained and stopped. Native Host1 initial/reload
checks matched five unique full Docker IDs, names and links, excluded removed
mappings, and observed a forwarded WebSocket server message without resource
writes or browser/console errors. Screenshot review still found indistinguishable
truncated rollback names, so visual acceptance remains HOLD pending a scoped
Web Console layout correction; the full resource/role matrix
remains INCOMPLETE. No company-site, all-page or all-locale acceptance is claimed.
See [the release notes](docs/releases/server-1.6.500.md). Historical 499 name
failure and browser HOLD below remain unchanged and are not promoted to 500.

Published Server `v1.6.499` packages Engine `v0.183.330` from source
`3f7320a8063a5471618be5b8be6a168f49559847`, with exact CI WAR SHA-256
`c01cbbfd63625fc09f39c5494775919aad6db22c92050b217b28b940b57e1de3`.
Only eligible standalone imported-container names are synchronized to fresh
full-ID Docker names; managed-service logical names remain unchanged. No
database-schema or stored-data-format migration is introduced. Web Console
`1.6.164`, Engine329 role/schema protections, Compose, mounts, OIDC/MFA/session
ownership, runtime base and security thresholds remain unchanged. Engine330's
signed release, exact CI assets and isolated H2 startup passed. The immutable
Server image is
`ghcr.io/pasturestack/server:v1.6.499@sha256:8552137dd4e40bf20dee5524cabf09540ed7431328e584ca1e488065e6fec394`,
from source `0a656e617c51059b92fb37a9b0571f142e8463aa` and successful
[publication run `36969193015`](https://github.com/PastureStack/server/actions/runs/36969193015).
Exact build/flatten and isolated first start/restart `HTTP 200` / `pong`
(12 and eight attempts), 34 MFA policy/API checks and TLS 1.2/1.3 checks passed;
untrusted certificates were rejected. Public assets/image/SBOM readback matched.
The unchanged merged-rootfs gate reports 52 raw findings and eight exact Medium
vendor-pending package findings (four unique CVEs), with zero untracked,
Critical/High, fixed-available or secret findings; this is not a zero-CVE claim.
QA499 first start/restart returned `HTTP 200` / `pong` (nine attempts each), with
original environment overrides, mounts, AppArmor and restart policy preserved;
runtime-contract and tracked five-table count differences are zero. Docker
health is `null`, not Docker `healthy`. Targeted name acceptance remains failed:
Engine330 rejects normal stopped/inactive instance/mapping pairs. Retained
rollback containers were not deleted or manually renamed. The browser HOLD
and this product defect remain recorded pending a new immutable correction;
these results are not full-matrix or company-site acceptance. See
[the release notes](docs/releases/server-1.6.499.md). The published 498
evidence below is historical to that release and is not promoted to 499 proof.

Published Server `v1.6.498` packages Engine `v0.183.329` and Web Console `1.6.164`.
Readonly/restricted GenericObject key/resourceData visibility changes in both
API versions; privileged roles retain those fields. Use typed plugin APIs for
safe low-role configuration reads. No stored-data migration, authentication,
session, Compose/AppArmor/nftables or Web Console version change is introduced.
The immutable image is
`ghcr.io/pasturestack/server:v1.6.498@sha256:bd8671e99fbf3661f91d6667f6cb04b16ade89a8d463ae872ffd84ce1e65a6e7`,
from source `ea58d92167eef31b76c7616f41df4d515530c359` and successful
[publication run `36954622994`](https://github.com/PastureStack/server/actions/runs/36954622994).
Exact build/flatten, isolated first start/restart `HTTP 200` / `pong` (10 and six
attempts), 34 MFA policy/API checks and TLS 1.2/1.3 checks passed; public
assets/image/SBOM readback matched. The final one-layer merged-rootfs scan has
52 raw findings and eight exact Medium vendor-pending package findings (four
unique CVEs), with zero untracked, Critical/High, fixed-available or secret
findings. This is not a zero-CVE claim. The exact Engine329 WAR's normal CI
executed 266 suites / 1,123 tests with zero failures, errors or skips.
The recorded QA498 `8080` upgrade ran the immutable 498 image / Web Console `1.6.164`.
First start/restart returned `HTTP 200` / `pong` (11 and 10 attempts); runtime
contract and tracked five-table DB-count differences were zero. The original
three named volumes, environment overrides, `docker-default` AppArmor and
`unless-stopped` restart policy were preserved. Docker health is `null`, not
Docker `healthy`; counts do not establish whole-database equality. The previous
`v1.6.497` rollback container is retained and stopped. Limited Receiver
role/API/header/message gates passed in scoped QA. Member retains privileged
reads; restricted/readonly typed reads retain safe configuration without URLs,
and GenericObject exact/list reads omit key/resourceData in both API versions.
No-access exact API requests return 403. Member Add is visible;
restricted/readonly Add is hidden, with Traditional Chinese direct-create
denial and no-access unavailable messages verified. Normal owner fixture
creation/deletion and cleanup were verified. Secret and other 498 resources,
all-resource, full-page and all-locale acceptance are not established.
Publication smoke and QA startup alone do not establish backend-write
authorization or company-site acceptance. Historical HOLDs remain
HOLD and the matrix remains INCOMPLETE. Preserve original volumes/settings for
rollback; rolling back to 497 restores the low-role capability exposure.
See [the release notes](docs/releases/server-1.6.498.md) for exact component pins.

The first 498 publisher run failed the fixed-available OpenSSL gate and remains
failed evidence. This release selects official Ubuntu `3.5.5-1ubuntu3.7` via
the signed HTTPS `20261002T000000Z` snapshot; security thresholds and the four
remaining unfixed CVEs / eight Medium package findings are retained.

Published Server `v1.6.497` packages officially published Web Console `1.6.164`.
It includes the shared state/date display-locale fixes
and Receiver validation-label fixes without changing API authorization, driver
actions, clone behavior, schemas or stored data. Engine `v0.183.328`, embedded
Cache `5.7.5`, base Server `v1.6.460`, Compose, AppArmor and nftables contracts
remain unchanged. The immutable image is
`ghcr.io/pasturestack/server:v1.6.497@sha256:1a1f05415e50d2ea337140d89063c6d7ae993140befa5aa79c5c83922990021d`,
from source `80d97523052aa86ec761ade8ec487c382a8d5e1d` and successful
[publication run `36836319609`](https://github.com/PastureStack/server/actions/runs/36836319609).
All 56 source gates, exact build/flatten, isolated first start/restart and 34 MFA
policy/API checks passed; public assets/image/SBOM readback matched. The final
one-layer merged-rootfs scan has 58 raw findings and 14 exact vendor-pending
package findings (eight Medium and six Low, six unique CVEs), with zero untracked,
Critical/High, fixed-available or secret findings. This is not a zero-CVE claim.
The recorded QA497 `8080` deployment ran `v1.6.497` / Web Console `1.6.164`;
first start/restart
returned `HTTP 200` / `pong` (10 and nine attempts), with zero runtime-contract
and tracked five-table DB-count differences. The original three named data
volumes, environment overrides, AppArmor and restart policy were preserved.
This is count preservation, not a whole-database row comparison; Docker health
is `null`, and no Docker `healthy` result is claimed. That deployment did not
establish packaged native Receiver browser acceptance. Publication smoke and
QA startup do not
establish full-language/layout, backend-write authorization or company-site
acceptance. Historical HOLDs remain HOLD and the matrix remains INCOMPLETE.
Preserve the nearest `v1.6.496` QA rollback with its original volumes/settings.
The `v1.6.495` image and backups remain retained; its obsolete stopped container
was removed.
See [the release notes](docs/releases/server-1.6.497.md).

Published Server `v1.6.496` pins Web Console `1.6.162`, Orchestration Engine
`v0.183.328` and the WAR's distributed-cache runtime `5.7.5`. Jackson
core/databind metadata is `2.22.3` / `3.2.3`; numeric Hazelcast cluster runtime
remains `5.7.3`. The Host Add Container entry follows the loaded exact-project
Container POST schema; the Secret desktop headings use existing translation
keys. Neither a schema GET nor a hidden UI entry establishes API write
authorization. Established schemas, stored-data formats and API permissions
are unchanged. The immutable image is
`ghcr.io/pasturestack/server:v1.6.496@sha256:6c85435b3de8771e5adff0b247274e0f1b9fe9d66c8b91e07d55a444e5589678`,
from source `d8e0e898b08aae45e040eb085936d11de14027fb` and successful
[publication run `36821096323`](https://github.com/PastureStack/server/actions/runs/36821096323).
Public assets/image readback, official candidate first start/restart and 34 MFA
policy/API checks passed. The one-layer merged-rootfs scan retains 58 raw
findings and 14 exact vendor-pending package findings (eight Medium and six
Low) after VEX, with zero untracked, Critical/High, fixed-available or secret
findings; it is not a zero-CVE claim. Isolated QA496 deployment passed first
start/restart `HTTP 200` / `pong` (10 attempts each), with zero runtime-contract
and tracked five-table DB-count differences; Docker health is `null`, not
`healthy`. Two zero-resource-write `1440 x 1000` desktop cases passed: readonly
Host Add Container absence/Edit unavailability and the member Secret table's
four Traditional Chinese headings. Host statistics remained connecting and
its right-side table was not fully reviewed; the Secret body was masked.
No full-layout, backend-write authorization or lifecycle acceptance is inferred.
Mobile and all-language acceptance remain pending.
Historical HOLDs and the first failed publication remain unchanged; the broader
resource/role matrix remains INCOMPLETE. No company-site deployment is claimed.
Retain `v1.6.495` with its original volumes/settings for rollback; see
[the release notes](docs/releases/server-1.6.496.md) for component source/hash
identities and the publication/QA boundary.

Published Server `v1.6.495` changes the Web Console Certificate editor and
installs Ubuntu's official `libdbi-perl` `1.647-1ubuntu0.26.04.3` security fix.
An existing matching certificate with a masked key and unchanged certificate
and chain may submit only name/description. New or replacement material keeps
full validation. No global write-only exemption, API permission change or
stored-data migration is introduced. The immutable image is
`ghcr.io/pasturestack/server:v1.6.495@sha256:ffd4d1c2a208b0bce3f9f961500ddebfdf7024bbddcf2d1e156cdbe76d30ba56`,
from signed source `512d4b2377e34ce04a33266af19b62ed45949eda` and successful
[publication run `36744673716`](https://github.com/PastureStack/server/actions/runs/36744673716).
It pins Web Console `1.6.161` and the unchanged Engine `v0.183.327`.
Independent assets/image readback and isolated first start/restart passed;
runtime settings and database-count baselines were preserved. The one-layer
runtime scan retains 52 raw findings and eight exact Medium vendor-pending
package findings after VEX, not a zero-CVE claim. Browser and broader
resource/role acceptance remain separate; see [the release notes](docs/releases/server-1.6.495.md).

Published Server `v1.6.494` pins Orchestration Engine `v0.183.327` and
Web Console `1.6.160`; both component releases are published and hash-verified.
The official image is
`ghcr.io/pasturestack/server:v1.6.494@sha256:9d1ddbe6f0c3fa11fefc141e14f419163c7bd14609163373d898ab0a857d790c`,
from source `c3b50ad6891ebbde4612e89dd5a1114bc731431c` and successful
[publication run `36704785404`](https://github.com/PastureStack/server/actions/runs/36704785404).
Its single-layer image and 22 checksummed assets were independently read back.
The security gate retains 52 raw findings and eight exact Medium
vendor-pending package findings after VEX, with zero untracked, Critical/High,
fixed-available or secret findings; it does not assert zero CVEs.
Isolated `8080` deployment start/restart passed with unchanged runtime and
database-count baselines. Certificate API/browser acceptance and the broader
resource/role matrix remain pending. Retain the immutable `v1.6.493` image and
original volumes/settings for rollback; that image retains the Certificate defects.

Certificate name-only and description-only
updates omit `cert` without replacing stored certificate or private-key data.
Explicit null `cert` values are rejected by the existing non-nullable API schema
with 422 / NotNullable; empty and malformed non-null values receive
422 / InvalidFormat. Create validation is unchanged. Certificate
DELETE and remove actions reject alternate and default references from
non-removed load balancer services in the certificate's account with the
existing 405 / InvalidAction response. The console explains only the known
certificate-in-use response in English, Traditional Chinese and Japanese;
public action names remain case-sensitive: undeclared `ReMoVe` receives
422 / InvalidAction during schema validation, not the reference guard's 405.
403 and 404 remain neutral, without service names or IDs. API shapes,
authorization, key masking, database formats and authentication/session
behavior are preserved. No database migration is required. All other packaging
coordinates and runtime security gates are retained from `v1.6.493`.

Preferred product-facing coordinates use `PastureStack/*`, `ghcr.io/pasturestack/*`, `PLATFORM_*`, and `PASTURESTACK_*`. Historical identifiers remain only where existing databases, agents, clients, templates, or upgrade tooling consume them. They must not be mechanically removed.

The catalog helper is packaged and installed as `catalog-service` and `catalog-service-sqlite`. The historical executable path remains only as a compatibility wrapper because the preserved service supervisor and persisted settings still invoke it. Release assets must use the PastureStack filename `catalog-service-<version>.tar.xz`; compatibility aliases must never leak back into the public asset name.

The authentication helper follows the same boundary: the GitHub Release asset and actual executable use `authentication-service`, while the preserved supervisor-facing executable name exists only as a compatibility wrapper.

PastureStack keeps the platform account as the authorization principal
and treats local credentials and external identities as explicit login links.
Provider changes therefore preserve the account identifier, direct project
memberships, and administrator role. OpenID Connect links use exact issuer and
subject values; username and email are never compatibility matching keys.
Explicit reassignment may copy direct memberships and administrator status,
but never copies passwords, API keys, sessions, MFA factors, recovery codes,
or audit history.

Machine management uses the neutral `machine-driver-bundle` asset, and vSphere operations use the neutral `vsphere-cli-bundle` asset. The externally defined executable names inside those archives are compatibility interfaces, not PastureStack branding. Artifact, license, and command-surface checks must pass before assembly; real provider and authenticated vSphere lifecycles still require isolated integration tests.

Server `v1.6.483` packages Web Console `1.6.149`. Secret Edit follows the
effective Secret schema: `name` and stored `value` remain immutable, while
only `description` is submitted on save, including an explicit empty string
when the user clears it. The Server API, authorization, Engine, and stored
resource formats are unchanged from `v1.6.482`. New Registry,
RegistryCredential, Certificate, and Secret action links are refreshed by ID
after creation; ambiguous RegistryCredential writes are not repeated.
Browser write acceptance remains an independent isolated `8080` check.

Secret payload operations use the neutral `secret-delivery-api` asset. The preserved engine still invokes the historical `secrets-api` executable and `/v1-secrets` routes, so Server supplies that filename only as an internal symlink while keeping the public artifact, primary executable, source repository, and license destination under the PastureStack name. Existing database key names and encrypted payload formats remain compatibility data and must survive upgrade and rollback testing.

The established `telemetry.opt`, `service.package.telemetry.url`, and `/v1-telemetry` identifiers remain internal compatibility data. Server installs `usage-telemetry-agent`, retains `/usr/bin/telemetry` only as an internal symlink, and packages the agent privacy notice beside its license and source record. A legacy target variable never enables publishing.

The `webhook.service.*`, `service.package.webhook.service.url`, `/v1-webhooks`, and four established driver identifiers also remain internal compatibility data. Server installs the neutral `webhook-automation-service` executable and retains `/usr/bin/webhook-service` only as an internal rollback link. The public asset and license destination use the neutral name, and the child process receives only the RSA public verification key.

The published `v1.6.482` release changes only Web Console packaging to
`1.6.147`. Service Edit sends just `name`, `description`, and `scale` instead
of the cloned launch configuration or upgrade strategy; the separate quick
scale action sends only `scale`. The Server API and stored-resource contracts
are unchanged. Its verified release identity is Server source
`3d909952d31e8577793acb7e402e10b883e1c8a6` and immutable image
`ghcr.io/pasturestack/server@sha256:e3ac65290f17981201a6cf2857e0f6def3eb79974746bc7110357fd87869a609`.
Isolated `8080` deployment and restart are healthy with Web Console `1.6.147`;
a bounded owner-browser run passed Service Edit Cancel, Save, and injected
`503` retry, plus Container and Service Remove Cancel/Confirm. The six-role
permission matrix remains a separate validation scope.

The published `v1.6.481` release consumes Orchestration Engine `v0.183.326`,
Web Console package `1.6.146`, Webhook Automation Service `v0.10.3`,
Authentication Service `v0.4.42`, API Explorer
`v1.1.18`, Compose Executor `v0.14.36`, Node Agent `v0.13.27`, Load Balancer Service `v0.9.27`, Catalog
Service `v0.20.11`, WebSocket Proxy `v0.23.14`, vSphere CLI Bundle `v0.55.2`, distributed cache runtime
`v5.7.4`, and Catalog Templates at commit
`e082033ba3c12b5f5cfcae93ff1d6f50d5440d07` (Catalog Templates `v0.3.12`). A Catalog upgrade changes
`pinned_commit` first and leaves the last indexed `commit` untouched until
Catalog Service has rebuilt the template index; pre-advancing both values can
preserve a stale nonempty index. Operational container references must use
numeric semantic version tags. The verified release identity is signed Server
source `9c6914cda01a48dda4fb38f62d1a3f0c4db10be8` and immutable image
`ghcr.io/pasturestack/server@sha256:013eb045ed669344a67b8ac85d2ce56193abb74f34628281dec503dced8ab415`.
Web Console `1.6.146` localizes required-field and encrypted-key feedback;
the isolated `8080` browser and six-role write matrix remains pending. The
published `v1.6.480` identity and its pending Registry Add QA are retained in
its release notes. Web Console packaging must retain its
fingerprinted `/assets/ui*.js` entry, and API Explorer must retain
`/api-ui/ui.min.js` and `/api-ui/ui.min.css`.

The frozen `/v1` authorization snapshots expose `runtime`, `shmSize`, and
typed `deviceRequests` on both direct containers and service `launchConfig`
payloads, matching `/v2-beta`. Role-specific create and update permissions
remain authoritative; neither API version bypasses the shared service create
and upgrade validation or Docker conversion path.

OIDC configuration retains a strict source-versus-policy boundary. An already
enabled provider can change only its site access policy without repeating
discovery or local-recovery initialization. The same comparison is applied to
the platform-setting reload event emitted after the save, so the event cannot
reinitialize an unchanged live provider. Startup, a first enablement, provider
switch, or identity-source change still requires fresh local recovery.
Broadening access requires the existing one-use MFA confirmation bound to the
operator, `oidcAccessPolicyUpdate` purpose, and canonical request digest.
`unrestricted` is represented with an empty allowlist in both the API and
database. Its setting update carries an explicit `value: ""` field; generated
client omission rules cannot turn the clear into a no-op. Restricted
allowlists contain only deduplicated `oidc_user` and
`oidc_group` principals, while stable error codes preserve the client contract.
The same two identity types are present in the default external-identity list
and generated project-member schema. Engine `v0.183.310` makes schema creation
wait for completed configuration startup, loads the reviewed list from the
packaged runtime defaults, then merges base and configured
options in stable deduplicated order. Engine `v0.183.311` also unions the
reviewed OIDC types with an older database override and exposes the same types
from its frozen `/v1` schema, so an upgraded installation cannot reject a
valid OIDC project member merely because its persisted list predates OIDC.
Unknown types remain rejected, and the
configured-provider state is restored from persisted settings after restart.
For an external token exchange that Authentication Service has already
validated, Engine `v0.183.311` treats that successful exchange as the provider
boundary and validates every returned identity against the reviewed external
type allowlist. It does not re-read the asynchronously propagated provider
flag for those same identities. Unknown and missing types remain rejected;
generic identity and project-member operations still require current provider
state.
Engine `v0.183.312` validates Authentication Service identities before access
policy evaluation, account lookup, or persistent mutation. The Engine-owned
stable `rancher_id` added after account resolution is handled on a separate
internal path and is accepted only when it resolves to the account
authenticated by that token. A provider-supplied or mismatched platform
identity cannot select another account. This completes the boundary that
`v0.183.311` began without broadening the external or project-member type
contracts.
Engine `v0.183.313` preserves that boundary and makes fresh external-account
activation synchronous. The complete `account.create` lifecycle now reaches
`active` before the token path enters MFA, while MFA continues to reject every
non-active account. Existing accounts, identity validation, session ownership,
and access-policy behavior are unchanged.
Engine `v0.183.314` closes the remaining frozen-v1 schema boundary. When the
historical `/v1 projectMember.externalIdType` options are loaded, only that
field is enriched from the reviewed current core schema. Historical provider
values remain in stable order, `oidc_user` and `oidc_group` become available to
v1 environment and membership creation, and unrelated schemas or enum fields
are not widened. Runtime validation of unknown external identity types remains
fail-closed.
Engine `v0.183.315` restores identity ownership across repeated OIDC logins on
upgraded installations. Authentication credentials are persisted for the
explicitly verified user or administrator, and internal service accounts are
not accepted by login-identity lookup. A historical link owned by the built-in
`token` account is repaired only when the provider, external identity type,
external ID, derived link digest, and target account identity all match. Links
owned by another real account remain fail-closed and require the explicit
reassignment workflow.
Engine `v0.183.316` keeps the existing local administrator recovery path usable
when the external provider is configured with required site access. The
exception is limited to a server-encrypted local-auth payload whose stable
principal is revalidated as an active administrator while platform security
and local recovery are enabled. Ordinary OIDC sessions continue through the
unchanged user or group allow-list.
Engine `v0.183.317` makes shared-project provisioning explicit and
role-preserving. In the default `shared` mode, each successful login reconciles
the stable internal account identity into the single `adminProject` Default
environment only when no direct or group membership already exists. Existing
owner, member, restricted, readonly, and noaccess decisions are never replaced;
existing personal environments remain intact. The optional `personal` and
`none` modes preserve compatible deployments without changing authorization
semantics.
Engine `v0.183.318` resolves an existing external identity link before applying
restricted-site admission. Restricted mode can therefore honor that account's
existing project membership, including the shared Default membership, without
weakening required mode: required mode continues to admit only the configured
OIDC user or group allow-list (plus the separately guarded local recovery
administrator). Inactive or unresolved accounts still fail closed.
Engine `v0.183.319` makes shared-Default reconciliation atomic. It checks all
active direct, group, and stable-identity memberships and creates a baseline
member only while holding the same project lock used by administrator member
updates. Existing owner, member, restricted, readonly, and noaccess decisions
remain authoritative under concurrent login and policy changes.
Engine `v0.183.320` checks project-member collection requests against the
requested project before loading members. A token authorized for project A
cannot use that project's `X-API-Project-Id` header to list project B's members
through `?projectId=B` on either `/v1/projectMembers` or
`/v2-beta/projectMembers`; unauthorized and malformed project IDs return 404.
Authorized collections and direct member-ID access retain their established
project checks.
Engine `v0.183.321` excludes inactive or removed project-member rows from
direct ID reads, matching active membership collections. Active direct reads
still require the caller to have access to the row's project, and an ID from
another project remains unavailable. This applies equally to `/v1` and
`/v2-beta`; a removed row is not exposed merely because its database ID still
exists.
Web Console `1.6.132` uses the effective per-project schema for workload create
and upgrade controls as well as direct routes. A missing POST or PUT method
therefore cannot be bypassed by typing the route, and a project switch forces
capability re-evaluation. Account administration reads exact per-account
`authIdentityLink` records for local and OpenID Connect identity display.
The environment editor separately follows project `update`, project
`setmembers`, and network `update` action links; a direct `?editing=true` URL
does not grant a missing action. These UI guards supplement, and do not replace,
server-side token and project authorization.
The environment editor's network-policy lookup also supplies its project ID
in `X-Api-Project-Id`; an unscoped read of a project-only network is not
treated as evidence that the selected project has no network policy.
The environment detail page offers an Edit entry for network-only capability
after its network model loads, without inferring permissions from a role name.
Direct `/env/:project_id` navigation and refresh select that permitted project
from the router's public RouteInfo before the tab or user Default fallback.
Missing, inactive, and inaccessible IDs retain the existing authorized
fallback; valid URL environments are not replaced by a saved preference.
Each readable account still receives an exact `authIdentityLink` lookup. HTTP
404 for an inactive historical account is isolated to that row and uses the
embedded identity fallback; 401, 403, 5xx, transport, and unexpected failures
continue to reject the route.
Environment view and edit use the project `projectMembers` link, so member
reads follow the same project authorization boundary. A 403 or 404 during the
project or member load is shown as a localized access or not-found message.
Server failures during environment load show a localized retry message instead
of the raw response.
Save failures identify whether the project, members, or network policy failed;
the form warns that an earlier save step may already have completed. Identity
search distinguishes a zero-result lookup from 401, 403, and server failure.
An authenticated account with no active environment is a valid empty state.
The console clears stale project scope, skips project-scoped collections until
an authorized environment exists, and does not loop on an obsolete direct
URL. Account names prefer authoritative identity links in the order name,
login, then external ID; a missing link falls back to the embedded identity.
Descriptions remain account data, and display-only identity links are never
serialized in an account update.
Web Console `1.6.133` applies the active project's effective host POST schema
to host creation and cloning. A direct Add Host URL without that permission
shows a 403 before registration data loads; responses from an earlier project
selection cannot restore stale permissions. Project details wait for the
selected project before reading its network and policy. Host access errors use
localized text across all 13 console locales and remain readable in narrow
and right-to-left layouts. This release changes no backend API or
authentication contract.
Web Console `1.6.135` requests the full active environment collection for a
site administrator's switcher, including environments where that account is
not a direct member. Other signed-in users still request their authorized
collection; the Server remains the authority for `all=true` and direct IDs.
The affected switcher labels use reviewed French and Russian translations.
Web Console `1.6.136` bounds the environment-switcher menu in left-to-right
and right-to-left views and corrects the Persian `/fail` page direction. It
revalidates a stored environment selection with a fresh direct GET. A 403 or
404 falls back to an available environment; 401 and 5xx errors remain visible
to the caller. Environment management consumes a fresh collection, so stale
cached records cannot keep a revoked environment in the list. This refresh
preserves the active environment and its loaded schema on return navigation;
a permitted direct URL still works when its environment is absent from the
collection. An already open view can retain its former selection until
reinitialization or an explicit switch; Server authorization still checks
membership on each request.
Web Console `1.6.137` lets empty pod-list messages wrap within narrow
viewports, including the Russian no-hosts message that overflowed by 6 pixels
at 320 pixels. Pod-column layout, translations, host API, and authorization
behavior are unchanged.
Web Console `1.6.138` waits for each confirmed deletion, prevents duplicate
submits, and keeps failed items available for retry. Authenticated routes wait
for language initialization; denied and missing resource pages translate in
the active locale without changing API authorization.
Webhook Automation Service `v0.10.2` requires the trusted project header to
match a receiver management request and confines receiver lookup, deletion,
name checks, and key or signed-JWT execution to `webhookReceiver` objects.
The internal `/usr/bin/webhook-service` compatibility link is preserved.
Web Console `1.6.139` reads project schema methods before showing Container,
project API-key, or Receiver Hook write controls. Its Container edit modal waits
for primary, port, and link saves; a failed port or link update restores that
field and leaves the modal open, while successful peer updates are not retried.
These separate API writes are not atomic. Webhook Automation Service `v0.10.3`
returns role-specific Receiver schema methods for both schema endpoints and
marks those responses private and non-cacheable; stored receivers and existing
routes are unchanged.
Orchestration Engine `v0.183.325` exposes `projectTemplate.isPublic` read-only
in its core schema, but its frozen `/v1` non-admin user schema omits the field.
It omits remove actions for public or non-owned templates and keeps direct
non-admin mutations owner-scoped. Web Console `1.6.140` shows
ProjectTemplate edit/remove only for administrators or an exact, non-empty
template owner account ID match; direct edit routes check ownership again.
Its sortable-table controls reflow at narrow widths, and closing an API-key
modal before delayed focus runs no longer targets a destroyed input. Role
labels alone do not establish Container write capabilities: use each account's
effective project schema methods when validating the controls and API writes.
Orchestration Engine `v0.183.325` packages FreeMarker `2.3.35` exactly once.
Server `v1.6.475` retains the signed Ubuntu 26.04 curl security revision
`8.18.0-1ubuntu2.7` without replacing the preserved runtime base.
Orchestration Engine `v0.183.326` restores the read-only `projectTemplate.isPublic`
field in the frozen `/v1` non-admin user schema, matching `/v2-beta`; the
administrator's create/update schema and stored data are unchanged.
Web Console `1.6.141` gives the same localized denial on ProjectTemplate
direct-edit routes for 403, 404, and owner mismatch while retaining 401
session recovery. Failed API-key saves display the existing API error inside
the modal without rendering key values.
Web Console `1.6.142` keeps server-issued Receiver URLs and lifecycle state
out of cloned create requests, clears inherited catalog identity on new
private ProjectTemplates, and reports inaccessible direct environment routes
without revealing whether an ID exists. Container table actions remain within
their visible scroll host while data columns keep their own width in LTR,
RTL, narrow panels, and desktop-to-mobile resize transitions.
Web Console `1.6.143` constructs a new private ProjectTemplate from editable
fields and deep-copies its initial stacks. The create request omits Default's
server-owned creation time, lifecycle state, ID, UUID, and catalog identity.
Shared new-resource clones for Host, Service, Container, and VM likewise omit
server-owned identity and lifecycle fields; edit and upgrade copies retain
their existing behavior. Receiver clones omit inactive driver configurations,
and unsupported drivers cannot submit the create form.
Web Console `1.6.144` introduced create-capability checks for Secret,
Certificate, and Registry Add controls and direct Add routes; Registry creation
requires both registry and registryCredential POST. Follow-up isolated QA found
that Registry Add was falsely denied for superadministrator, owner, member,
and restricted roles when schema IDs had different casing, despite both POST
capabilities. Readonly and no-access roles passed their denial checks; Secret
and Certificate checks passed in English and Traditional Chinese. The false
denial caused no resource writes. Web Console `1.6.145` resolves create
capabilities across the mixed-case schema IDs. Denied direct routes retain
localized 403 feedback, and Secret Edit follows its update action link. These
are browser controls and feedback, not changes to Server authorization or API
contracts.
Legacy provider settings are imported only while the encrypted `auth.config`
object does not exist. After that one-time migration boundary, the common
access-mode and allowlist settings are authoritative; service and Server
container restarts cannot replay absent legacy OIDC keys over a saved
restricted or unrestricted policy.
The `/v1-auth` proxy preserves the caller's PastureStack authorization for an
exact `POST /v1-auth/config`, so the actor-bound policy confirmation reaches
the Authentication Service. Provider-backed reads continue to receive the
external identity-provider token; unrelated proxy routes are unchanged.
New browser tokens keep the create-only `clientSessionId` field through the
dynamic authorization overlay and the frozen `base`, `superadmin`, and `token`
v1 schemas. Explicit logout normalizes a cookie's bare key and a
standard `Authorization: Bearer` value to the same database key; mismatched
generations and unsupported authorization schemes cannot revoke the token.
Cookie and session-generation reads, login commit, and explicit logout share
one origin-level mutex. A tab captures its generation when starting requests,
timers, and subscriptions; stale passive failures stop their own work and
adopt the newer committed session without clearing shared state. Storage and
sanitized BroadcastChannel events carry no token material and converge through
one serialized reconciliation path. An explicit logout is the only browser
path allowed to revoke the bound token.
The current-token collection is authenticated only when its first entry has a
non-empty `accountId`, `user`, or `userIdentity`; an HTTP 200 provider
login-options object with no identity is an unauthenticated response. The
console normalizes it to its local 401 contract, clears only an unchanged
Cookie and generation under the authentication mutex, and routes to login
without a passive DELETE or reload loop.
Promise/callback interoperability uses one RSVP-based adapter for
`PromiseToCb`, authenticated-route lookup, and settings loading. Task factories
start in a deferred RSVP turn, so synchronous throws, thenables, plain values,
and Promises share one settlement contract; callback exceptions cannot enter a
second error callback. The 27 `NewOrEdit` consumers share one awaitable,
owner-bound save lifecycle covering validation, persistence, success hooks,
error hooks, completion callbacks, and cleanup. A pre-existing `saving=true`
lock is never claimed or cleared by a duplicate submission. Environment member
loading uses the supported `followLink('projectMembers')` store boundary.

External-service `healthState` remains writable API data, including `null`.
Load-balancer editing persists the chosen target through
`PortRule.serviceId`; this changes no load-balancer runtime or API shape.

Deployments that terminate TLS before the Server container may set
`PROXY_PLATFORM_PUBLIC_ORIGIN` to one exact public HTTP(S) origin. The proxy
uses that origin only for requests whose Host matches the configured authority;
unrelated hosts retain transport-derived forwarding values. Credentials,
paths, queries, and fragments are rejected. Platform API responses are always
rewritten to `Cache-Control: private, no-store`, while static assets preserve
their existing cache policy.

Native MariaDB validation must override both `CATTLE_DB_CATTLE_MYSQL_URL` and `CATTLE_DB_LIQUIBASE_MYSQL_URL`; the application and migration pools are configured independently. The default compatibility path intentionally uses a MySQL JDBC scheme with the MariaDB driver compatibility options.

The embedded database explicitly sets `innodb_snapshot_isolation=OFF`. MariaDB
11.8 enables snapshot isolation by default, but the preserved control-platform
transaction layer predates that behavior and already performs its own
optimistic locking and retries. Leaving the new database default enabled can
surface error 1020 during concurrent system-stack creation. External MariaDB
deployments must apply the same compatibility setting before the Server starts.

Image defaults do not override rows already persisted in the `setting` and
`catalog` tables. Existing installations must audit and migrate the narrow
distribution-coordinate allowlist with
`scripts/migrate-approved-runtime-coordinates.sh` against an isolated restore
before cutover. The tool preserves compatibility setting names, creates an
exact rollback bundle, and changes only approved GitHub, GHCR, CLI, Agent,
load-balancer, and Catalog coordinates.

Before a future release, validate fresh install, preserved-database upgrade,
both database modes, web console and API, CLI, node registration,
authentication, subscriptions, catalog, networking, storage, backup/restore,
rollback, artifact hashes, and non-root execution in isolated VMs.
