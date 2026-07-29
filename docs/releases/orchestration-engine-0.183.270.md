# Orchestration Engine 0.183.270 release evidence

This evidence applies to the exact public source and Runtime artifacts consumed
by PastureStack Server `v1.6.316`.

## Source

- Repository: `https://github.com/PastureStack/orchestration-engine`
- Source commit: `da4fe8cf5b0c3379a01fd680be7dd394be2fdf00`
- Preserved upstream boundary: `82d154a53f4089fecfb9f320caad826bb4f6055f`
- Downstream commit count after the preserved boundary: exactly one

## Complete package validation

The complete release build was rerun from the exact source commit on
2026-07-29 with Maven `3.9.14`, Eclipse Temurin `25`, and compiler warnings
treated as errors for PastureStack-owned modules.

- The complete Maven reactor and its tests passed.
- The pinned Hazelcast `5.7.0-pasturestack.2` source, patch, dependency
  coordinates, archive paths, and canonical package passed their independent
  gates. Its canonical JAR SHA-256 is
  `f958a9c5e21aef87f4bfc28ce8b0519d3214cea22ba3dde210de78779b342e5e`.
- The release archive contains exactly one web application descriptor,
  launcher, Runtime resources archive, authentication-logic archive, Maven
  version record, and implementation-version record for `0.183.270`.
- The frozen v1 administrator, user, and token schemas contain the identity
  link, provider-switch, local-recovery, MFA, passkey, and SMTP types used by
  the Runtime. Sensitive proof, password, and verification-code fields are
  create-only and readable only on the create response.
- The token schema accepts `authProvider` on token creation so the guarded
  local-recovery, MFA-resume, and one-use provider-switch paths reach the
  Runtime. The field is not updateable, and local recovery still requires an
  active system administrator, a valid local password, and the explicit
  recovery setting.
- A provider-switch recovery ticket carries only the login identity proved by
  that ticket and the stable platform account identity. It does not claim
  linked identities from an inactive provider, which keeps reverse switching
  valid and prevents a recovery session from overclaiming identities.
- Stable-account sessions import linked external identities only for the
  currently active provider. A primary local session therefore keeps its
  stable platform identity without importing an inactive OIDC alias.
- Identity links, MFA status, and MFA factors expose an explicit exact
  account filter. Administrators can therefore inspect a selected account
  instead of silently receiving their own records. Synthetic API resources
  also preserve their stable identifier and declared resource type.
- MFA login challenges remain owned by the stable authorization principal
  even when an unauthenticated object-creation context attempts to substitute
  its transient token account. A dedicated regression test reproduces that
  substitution and requires the corrected owner to be persisted.
- Disabled local accounts retain a stable, formatted public account identity
  in project-membership responses. This keeps the permission-transfer,
  restoration, and review workflows unambiguous without making an inactive
  account eligible for authentication or new membership assignment.
- Audit attribution tolerates internal service identities that do not have an
  external identity type. Provider configuration writes therefore cannot be
  interrupted by audit attribution, while a typed user identity is still
  preferred whenever one is present.
- The v1 schema serializer was run twice from independent empty state. All 18
  generated schema files were byte-identical between runs.
- A dedicated unit test deserializes every role schema used by account and MFA
  administration. It requires the exact `accountId` equality filter on every
  exposed identity-security collection and verifies that ordinary user roles
  do not receive the administrator-only identity-link collection.
- The Java 25 standalone startup gate passed with one generated web
  application and `failure_count=0`.
- A second package-only build from the same commit produced the same byte
  length and SHA-256 as the complete release build.

## Published Runtime artifacts

- `orchestration-engine-0.183.270.jar`
  - SHA-256:
    `cdd211f4967db35edf7506adb324127ffef5b8704b4c8e8791b158bc2c08c106`
  - Size: 83,846,115 bytes
- `orchestration-engine-auth-logic-0.183.270.jar`
  - SHA-256:
    `773ed7818e2a0f6504497b43c7798495ec52cc62eb325730fc5a8e9487b06507`
  - Size: 343,300 bytes
- `orchestration-engine-framework-auditing-0.183.270.jar`
  - SHA-256:
    `73e9b2c77ef445e131f50671ca3693bed84573603adb55187eaa8d1482620630`
  - Size: 17,189 bytes
- Nested `cattle-resources-0.183.270.jar`
  - SHA-256:
    `2fc8f09a9dd4261377be2ed6176ca034f7a9245e58090627def05be39df9712b`
  - Size: 659,429 bytes

This file records source, package, reproducibility, archive, and standalone
startup gates. Database restoration, authenticated API behavior, node
registration, system stacks, provider failure recovery, upgrade, and rollback
remain Server-level release gates.
