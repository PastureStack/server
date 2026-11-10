# Server v1.6.593

Published immutable image: `ghcr.io/pasturestack/server:v1.6.593@sha256:dcb694d5b36ed2dc87e993b60b3df592a0b70b3c15f892f1ba719736b877524f`.
Source: `b59661f6867bc0ce2cd01e4e485fc7fd45b9d15d`; publisher **42770771604**.
All 35 public assets, 36 release subjects and both OCI attestations were verified.
The normal final image scan, startup and restart gates passed. Twenty-three
Medium package findings without official Resolute fixes remain registered.
This release result does not establish all native business-workflow acceptance.

## Verified component inputs

Packages the original immutable Engine v0.183.393 artifact, Web Console1.6.233 /
Bridge0.2.35 and Compose0.14.45. Web, Bridge and Compose bytes remain unchanged.

Machine Driver lifecycle waits use the existing blocking executor so they do
not starve control workers during Server recovery. Human Cookie confirmation
of an API Key lifecycle plan retains that plan's original snapshot binding.
Cookie plans retain their witness. Live account, membership, Key policy, CAS,
human-only approval and at-most-once dispatch checks remain required.

The Engine build image uses the official SHA256-pinned Ubuntu rust-coreutils
backport. Server does not install that build-only package. New rsync, util-linux and
expat findings without official Resolute fixes are tracked separately by exact
runtime package/version. HIGH/CRITICAL, fixed-version and unregistered findings
still block publication. Source inventory is not a substitute for the final scan.

The initial final-runtime publication check found CVE-2026-59171 in the
relocated org.json classes of Hazelcast 5.7.6. No Server image or tag was
published by that failed run. Engine 0.183.393 now consumes the immutable
maintained runtime 5.7.7 with official org.json 20260719. Embedded metadata,
artifact hash, numeric conversion regression cases and original runtime CI
are verified. The final Server scan passed without an org.json exemption.
The Server archive gate verifies the actual nested runtime hash and JSON version;
13 archive controls include old-runtime and malformed-metadata rejection cases.

Original component CI does not establish native Server workflow acceptance.
Registry removal, Stack restart/recovery and the remaining weak-model cases
require matching 8080 acceptance. Existing opt-ins, origin, OIDC/MFA, firewall
backend, mounts, performance settings and rollback image must be preserved.
