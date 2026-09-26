# Server v1.6.472

This patch packages Web Console `1.6.137` on the preserved Server `v1.6.471`
assembly and digest-pinned `v1.6.460` runtime base. Empty pod-list messages
now wrap within narrow viewports without changing the pod-column layout. This
addresses the Russian no-hosts message that overflowed by 6 pixels at 320
pixels during the 13-locale QA pass, and also covers long unbroken words in
the same empty-message path. The environment switcher, error page,
permissions, and translations from Web Console `1.6.136` remain unchanged.
No backend API, host authorization, authentication policy, database schema,
HAProxy, or production deployment change is included.

Orchestration Engine `v0.183.323` remains, with FreeMarker `2.3.35` packaged
exactly once. Authentication Service remains `v0.4.42`. The signed Ubuntu
26.04 curl packages remain at `8.18.0-1ubuntu2.7`. The reviewed OpenVEX
statements and vendor-pending findings retain their exact package and CVE
sets.

## Verification boundary

The Web Console release asset must match its published commit and SHA-256.
The Server release workflow must pass source gates, an immutable image build,
isolated startup/restart, merged-rootfs security and exact-set checks, and
readback of the image version, source revision, digest, and SBOM identity.
QA 8080 must recheck the affected Russian empty state at 320 pixels alongside
the neighboring locales and layouts before production deployment. Publishing
this release does not change production `stack.ascdc.tw`.

## Upgrade and rollback

After publication, update only the Server image reference from `v1.6.471`.
Preserve existing Compose environment variables, named volumes, restart
policy, AppArmor, HTTPS origin, OIDC, performance settings, and firewall
backend. Rollback selects the preserved `v1.6.471` image with the same
configuration and volumes.
