# Server v1.6.554 candidate

Prepared source only; no Server image or release has been published.
The release workflow records the final image digest and source
revision only after its required checks pass.

## Verified component inputs

- Web Console `1.6.196`: producer `4e3e4d51db003ef7b456166084d425bfb06e1518`,
  archive SHA256 `4f0a550c2754e244cbf77f380c5c138150687988791e063bbf39ce0150d880fa`.
- Engine `v0.183.355`: producer `9ea138d1db1718cf65157c9564c379e62bafe9a0`,
  `cattle.jar` SHA256 `a7f651f84a9fe6deef2c9f66f50c13c70e450e25f9dfa6fb59129b2681f9f54f`.

This release integrates Web Console `1.6.196` and Engine `v0.183.355` for optional
AI collaboration. Engine uses official Guava `33.7.2-jre` for
`CVE-2026-102554`; assembly verifies the exact nested artifact and rejects older
or additional Guava jars. Other component versions and the existing security backport
baseline are retained. The build recipe pins component commits, archive hashes
and the Web Console runtime SBOM; the bridge has a separate source archive and
SBOM because its Node.js process is not part of the browser bundle.

Seven typed tools provide stack/service discovery, a bounded service read,
conditional description updates, and service-upgrade preview, apply and status.
New browser pages start with tools off. The owner enables them explicitly;
upgrade plans require a separate authenticated human confirmation. The stdio
bridge uses a dedicated scoped Key, pins its policy revision, and cannot approve
its own plans. Current role, scope, expiry and revocation checks remain active.

Upgrade completion includes replacement-instance readiness and removal of the
old instance's ports, network attachments and mounts. Named/shared volume data
is preserved. Normal live storage transitions use their existing authorization;
the stricter retired-instance path does not add a general delete grant.

## Bounded pre-release acceptance

The isolated candidate completed two consecutive scoped-Key image upgrades and
return to its original image, a weak-model upgrade through human confirmation,
and an ordinary GENERAL/FULL Key upgrade as a control. Launch settings and
mounted data were retained; retired instances and their live ports were gone.
Server restart and browser refresh retained service state and data. Native
tool registration, explicit off/read-only/enabled modes, role/scope rejection,
conditional-description conflicts and per-Key audit were checked separately.

The new collaboration panel passed 78 locale/theme/width cases, including the
automatic theme's day/night timer transitions. This is scoped acceptance of the
new tools and affected UI, not completion of every existing frontend feature or
the entire planned permission matrix. Rejected pre-confirmation requests are
expected negative tests, not successful upgrades.

## Activation, upgrade and rollback

Follow the [AI collaboration guide](../ai-collaboration.md) for the opt-in backend
properties, dedicated Key and client setup. Keep the existing Compose
environment, HTTPS origin, ports, AppArmor, restart policy and all three named
volumes. Do not use a runtime bundle override or `docker compose down -v`.

Before disabling the backend or downgrading, let accepted operations reach a
terminal state, cancel unused plans and revoke the dedicated bridge Keys. Keep
the preceding image and matching database/volume backup. The existing
[API Key rollback requirements](../upgrades/api-key-policy-rollback.md) still
apply; an old Engine must not receive newer policy-bearing Keys unnoticed.
