# PastureStack Server v1.6.366

Server v1.6.366 updates the two runtime components that had newer reviewed
releases but were not yet present in production:

- Orchestration Engine `0.183.286`, including the single reviewed
  `distributed-cache-runtime` artifact `5.7.3-pasturestack.4` built on Java 25
  with Spring Framework 7 and the maintained Hazelcast 5.7 line.
- API Explorer `1.1.18`.

Both artifacts are downloaded from their exact GitHub releases and verified
with pinned SHA-256 values before they replace the corresponding files from
the digest-pinned Server v1.6.365 base. The Server image then verifies the
orchestration manifest, the exact embedded distributed-cache JAR, the API
Explorer package identity, and the unchanged first-party service wrappers and
Web Console.

The release keeps the v1.6.365 reduced runtime surface and its OpenVEX
decisions, including GNU coreutils fix commit
`d64e35a8a4c0e4608321433e0d84d917e4e36371`. The publication workflow scans the final merged root filesystem;
any new or unmatched vulnerability at any severity remains a release blocker.
It also starts the exact candidate with fresh data volumes, verifies HTTP 200
and `pong`, restarts it, verifies `pong` again, and publishes the image, SBOM,
provenance, checksums, raw scan evidence, and VEX-filtered evidence.

PastureStack is an independent community effort and is not affiliated with or
endorsed by Rancher Labs or SUSE. Existing licenses and upstream attribution
remain applicable.
