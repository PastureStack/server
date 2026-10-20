# Server v1.6.539

Prepared source candidate, not a published Server image. No Server539 artifact,
runtime, clean-install or deployment acceptance is claimed by this note.
The current published installation remains Server `v1.6.538` until the normal
release process completes; do not substitute this candidate in installation
commands before its official publication.

## Targeted changes

- Node Agent `0.13.29` is intended to collect host disk capacity and availability
  from the host mount namespace rather than treating a container mount view as
  the host filesystem. Candidate source:
  `28803d4baa7012734f7ae5162db32d263f464860`; package ID
  `28803d4baa7012734f7ae5162db32d26`.
  [Scoped producer CI](https://github.com/PastureStack/node-agent/actions/runs/39409627071)
  passed, and the original CI archive and its contained binary/apply script were
  downloaded and verified. Candidate SHA-256 identities are:
  - `node-agent-0.13.29.tar.gz`:
    `0783deb5958d7d3be317725256ed42e0966f626535f240eb805335ac98bfa7d3`.
  - `bin/node-agent`:
    `e5049052c555f3eb35732d9de56f9c34c2b103fb90eeb64252cf97b08127cc71`.
  - `apply.sh`:
    `dd8cb342518a43e7468cc121db5c4e44b16731f2620b77ea0fd03c02c03766a9`.
- Official Web Console `1.6.192` distinguishes unknown disk values from a real
  zero instead of displaying missing data as `0 B`. Producer:
  `a8e2ab0c8242355f06c1ab2584978ccfc4d76c02`; immutable archive
  `web-console-1.6.192.tar.gz`, 3,037,760 bytes, SHA-256
  `52840ebf2800f9588ec7910fe617b7782a6e92a27046b4876e9656ef4883e609`.
  [Producer validation](https://github.com/PastureStack/web-console/actions/runs/39408830305)
  and the [official component release](https://github.com/PastureStack/web-console/releases/tag/1.6.192)
  are component evidence, not Server539 acceptance.

The Node029 pins identify verified original CI bytes, not an official Node
publication. Its required CodeQL review, normal merge and formal release are
still pending. The official component release must preserve these exact source
and artifact identities before Server publication; do not overwrite an old tag
or reuse the Node028 artifact identity for Node029. Static recipe agreement and
CI artifact checks do not establish Server539 build or runtime acceptance.

## Preserved boundaries

The base image, Engine, API Explorer, Catalog/Scheduler, JDK, Host API and all
other component pins remain unchanged from the prepared base. Existing artifact
integrity, native-runtime, security, attestation and required CI gates remain in
force. This targeted disk-data correction does not claim an additional CVE fix.
The exact VEX decisions and unresolved vendor findings retain their previous
contents, severity policy and 2026-10-27 review deadline; only the candidate
Server subject changes to `v1.6.539`.

Focused acceptance is still pending for the final published Node/Web inputs:
host-root disk collection, genuinely unknown versus zero UI values, actual
packaged component identities and the resulting Server image. Unaffected prior
PASS evidence keeps its original scope; this candidate does not promote any
historical pending item or KVM item to PASS.

## Upgrade and rollback

Changing a Server image alone does not prove replacement of an already running
Node Agent. Verify the actual host-agent producer and disk payload in the
targeted acceptance environment after the normal agent lifecycle.
Keep the working published `v1.6.538` image/container and matching recovery
evidence. Preserve existing settings and named volumes; do not reset databases
or credential state. VM definitions/disks must not be removed or reconfigured.
No company-production deployment is included in this candidate preparation.
