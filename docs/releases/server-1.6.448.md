# Server v1.6.448

PastureStack Server v1.6.448 prevents an OpenID Connect site-access
policy-only update from repeating provider discovery when the resulting
platform-setting event reaches Authentication Service. It packages
Authentication Service 0.4.41 while retaining Orchestration Engine 0.183.309
and Web Console 1.6.120. This patch changes no database schema, persistent
volume layout, firewall backend, reverse proxy, browser-session contract, or
runtime environment contract.

## Root cause and correction

The direct `UpdateConfig` path already distinguished an OIDC identity-source
change from an access-policy-only update. Saving the policy also emits platform
setting events, however, and the event subscriber invokes `Reload`. The reload
handler previously initialized every supported active provider without making
the same source-versus-policy comparison. A policy save therefore succeeded
but still fetched the OIDC discovery document and rebuilt the provider twice.

Authentication Service 0.4.41 applies an in-memory policy-only reload only
when all of the following remain true: a provider is already live, both the
active and requested configurations use OIDC, and no provider-initialization
field changed. Startup, first enablement, provider switches, issuer or client
changes, CA or secret changes, and critical claim changes retain full provider
initialization and local-recovery enforcement. The corrected path does not
weaken the actor-, purpose-, and request-digest-bound MFA confirmation used
when access is broadened.

The v1.6.447 `auth.config` migration boundary is retained. Legacy provider
settings remain a one-time migration source; saved restricted or unrestricted
policies survive Authentication Service and complete Server container restarts.

## Immutable component coordinates

- Authentication Service `v0.4.41`, commit
  `1e566c8ba00aa134eb119be9d655625c870b28bc`, release archive SHA-256
  `2980282734e4d87bd92e73b8acef1dfa166df877e504e049c3556b13f66632bd`,
  and extracted binary SHA-256
  `3edeaca6715b2e4096aa0de641ea9b6f2f558a5077b5d533de58076dbea9f35b`.
- Web Console remains `1.6.120`, commit
  `20dc8c737b365731b19abb6d71763edd2d8b41f7`, release artifact SHA-256
  `d9ce9310bda50e5eec385fe30ac55dfdf51a1f3162c16aa1480385461eaa14f7`.
- Orchestration Engine remains `v0.183.309`, commit
  `64b94f2a5c74ebf4ca3fa3737717ac02315d1565`, artifact SHA-256
  `f0feb5285146fd7b1f9f2cc4180913c8983dbc8a0edbc996972bec880eb97dfc`.
- Catalog Templates remain pinned to commit
  `e082033ba3c12b5f5cfcae93ff1d6f50d5440d07` (`v0.3.12`).

## Verification boundary

Authentication Service regression tests exercise the live policy-only reload,
startup with no provider, initial enablement, and an OIDC source change. The
exact reviewed source passed formatting and static validation, the full
race-enabled Go suite, two clean byte-identical package builds, source and
product SBOM generation, secret scanning, and applicable Critical/High gates.
The Server assembly independently verifies the release archive, extracted
binary, version output, and exact source identity.

Runtime acceptance must save restricted and unrestricted policies through the
public API and bound MFA confirmation. A policy-only save adds zero OIDC discovery requests,
while an identity-source change still requires local recovery. It must also read back an explicitly empty database
allowlist for unrestricted mode, deduplicate `oidc_user` and `oidc_group`,
reject unsupported identity types, restart the unchanged container, and read
back the same final policy.

The authentication acceptance retains Authentik OIDC, TOTP, virtual
authenticator Passkey login, manual refresh, three-tab adoption, delayed
passive failures, authenticated API and WebSocket access, and one
generation-bound explicit logout. Passive paths must produce zero token DELETE
requests, and Web Storage must contain no JWT, OTP, OIDC code, or session
secret.

The release pipeline rebuilds the complete image, compares layered and
flattened runtime configuration, publishes one rootfs layer, starts and
restarts the candidate with fresh volumes, generates a CycloneDX SBOM, and
scans the merged root filesystem. Publication fails on applicable Critical or
High findings, available but unapplied fixes, unregistered vendor findings,
detected secrets, or component identity mismatches.

Eight Ubuntu 26.04 Medium findings covering 22 package occurrences remain in
the expiring vendor-pending register. Canonical publishes no installable fix
for the recorded package revisions. They remain explicit evidence rather than
being hidden through a threshold change or an unreviewed patch.

## Upgrade and rollback

Upgrade from v1.6.447 by changing only the image tag to `v1.6.448`. Preserve
all environment variables, named volumes, restart policy, AppArmor policy,
HTTPS origin, OIDC settings, performance settings, and selected nftables or
iptables backend. Verify `/ping`, the policy-only zero-discovery invariant,
policy persistence after restart, TOTP and Passkey login, cross-tab adoption,
authenticated API and WebSocket access, and explicit logout.

Roll back by stopping v1.6.448 and starting the preserved v1.6.447 image with
the same configuration and volumes. v1.6.447 preserves policy across restart
but can repeat OIDC discovery after a policy-only save. No database migration
is introduced. No production deployment, HAProxy change, or runtime patch is
part of this release.
