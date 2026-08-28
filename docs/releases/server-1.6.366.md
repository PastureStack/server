# PastureStack Server v1.6.366

Server v1.6.366 updates the two runtime components that had newer reviewed
releases but were not yet present in production:

- Orchestration Engine `0.183.286`, including the single reviewed
  `distributed-cache-runtime` artifact `5.7.3-pasturestack.4` built on Java 25
  with Spring Framework 7 and the maintained Hazelcast 5.7 line.
- API Explorer `1.1.18`.

Both artifacts are downloaded from their exact GitHub releases and verified
with pinned SHA-256 values before they replace the corresponding files from
the digest-pinned Server v1.6.364 build base. The same recipe reapplies the
v1.6.365 runtime hardening before the Server image verifies the
orchestration manifest, the exact embedded distributed-cache JAR, the API
Explorer package identity, and the unchanged first-party service wrappers and
Web Console. The Server compatibility wrapper also normalizes the upgraded
Orchestration Engine's explicit WebSocket proxy flags: the Console broker keeps
the public `:8080` listener, the authenticated proxy uses private `:8083`, and
the application remains on `127.0.0.1:8081`. This avoids changing the public
API port while resolving the candidate listener collision.

The new Orchestration Engine is expanded into the runtime tree before startup,
then receives the Server's existing catalog `pinned_commit`, service subscribe,
bootstrap, and serialized-schema overlays. This preserves fresh-database
migrations and Server authorization contracts instead of replacing them with
the unassembled upstream JAR contents.

The release keeps the v1.6.365 reduced runtime surface and its OpenVEX
decisions, including GNU coreutils fix commit
`d64e35a8a4c0e4608321433e0d84d917e4e36371`. It also replaces the active
OpenSSL CLI, 3.5 ABI libraries, engines, and legacy provider with verified
OpenSSL `3.5.8` LTS source
(`a8f84a39918ec6415ce765d9b429d313ba97b8143169c172e734b9514464f5b2`)
to close `CVE-2026-75803`. The vulnerable `diff3` executable is removed
because Server does not invoke it; the unaffected `cmp` validation path is
retained. This closes `CVE-2026-53910` without replacing or removing unrelated
diffutils behavior.

The publication workflow scans the final merged root filesystem;
any new or unmatched vulnerability at any severity remains a release blocker.
It also starts the exact candidate with fresh data volumes, verifies HTTP 200
and `pong`, restarts it, verifies `pong` again, and publishes the image, SBOM,
provenance, checksums, raw scan evidence, and VEX-filtered evidence.

PastureStack is an independent community effort and is not affiliated with or
endorsed by Rancher Labs or SUSE. Existing licenses and upstream attribution
remain applicable.
