# Server v1.6.456

PastureStack Server v1.6.456 fixes repeated OpenID Connect login resolving to
the built-in `token` account on upgraded installations. It packages
Orchestration Engine 0.183.315 with Authentication Service 0.4.42 and Web
Console 1.6.122 while preserving existing data volumes, HTTPS origin, OIDC,
TOTP, Passkey, session ownership, MFA confirmation, performance settings, and
the selected firewall backend.

## Root cause and correction

The first login correctly created a user account, but the generic credential
lifecycle could replace the explicitly supplied account owner with the
unauthenticated request's built-in `token` account while persisting the new
`authIdentity` credential. A later browser or incognito login found that link,
issued a session for the internal account, and then received 404 or 401 from
normal project, setting, and preference APIs. The visible callback could end
with `Identity externalIdType is invalid`, even though the OIDC identity type
had already passed provider validation.

Orchestration Engine 0.183.315 now verifies the persisted credential owner and
corrects it to the explicitly authenticated account before returning. Login
lookup accepts only user and administrator owners. An existing link is moved
from the built-in `token` account only when its provider, external identity
type, external ID, derived link digest, and the target account identity all
match exactly. Links owned by another real account remain fail-closed with
`IdentityAlreadyLinked`. The same explicit ownership invariant covers adjacent
identity-proof-use and provider-switch-ticket credentials.
The supported external identity types remain `oidc_user` and `oidc_group`;
this release corrects credential ownership rather than widening that contract.

## Immutable component coordinates

- Orchestration Engine `v0.183.315`, commit
  `9faa58a7bf565999a9d219200867996a85eb8a2d`, release JAR SHA-256
  `8d92bcf24ff26340f7e92013408d46c81377965d2f9ef773936ca0118895ef8d`,
  and CycloneDX SBOM SHA-256
  `7f8bb2b88838a0444ade96cf6e5b35819581b5f0e6230d36526bed761ca55fc4`.
- Authentication Service remains `v0.4.42`, commit
  `5589ef8fda68ae56e1afd64096965d452ee8a17e`, release archive SHA-256
  `f14d22036a0a88d6a8d669700506bba680fc7605bbca2b337e345c5cd71500fb`,
  and extracted binary SHA-256
  `feaabe4bba85cbe119c98a79a27abb4510401fc051f34d02aa7b48d69bdbe746`.
- Web Console remains `1.6.122`, commit
  `fac6b1f90adf8f6524f6f0745a7f54605cfa6071`, release artifact SHA-256
  `c50ace84d94575c7869dd2c01ff9e741d3ebd54a656ec23d5a94dfeda6e79dba`.
- Catalog Templates remain pinned to commit
  `e082033ba3c12b5f5cfcae93ff1d6f50d5440d07` (`v0.3.12`).

## Verification boundary

The Engine source gate passes, the 38-module reactor through auth-logic is
green, and auth-logic reports 93 tests with zero failures and errors. Four new
tests reproduce owner replacement, prove exact legacy repair, reject a target
whose external identity differs, and reject reassignment from another real
login account. CodeQL and the full source, artifact, dependency, SBOM, and
Dapper-image security gate also pass on the exact merged commit.

The six-account Server runtime acceptance uses six distinct fresh Authentik
users and isolated incognito browser contexts. It covers first and repeated
OIDC plus TOTP login,
unrestricted, group-restricted, user-restricted, and denied site access;
owner, member, read-only, restricted, and no-access environment roles; v1 and
v2 schema and API access; allowed and denied project and stack operations;
WebSocket; explicit logout; stable account reuse; and complete test-resource
cleanup. A session resolving to the internal token account, any
`externalIdType` error, or a permission mismatch fails the release.

## Upgrade and rollback

Upgrade from v1.6.455 by changing only the image tag to `v1.6.456`. Preserve
all environment variables, named volumes, restart policy, AppArmor policy,
HTTPS origin, OIDC settings, performance settings, and selected firewall
backend. The release does not add a database migration; a narrowly verified
legacy identity link is repaired during its next successful login.

Roll back by stopping v1.6.456 and starting the preserved v1.6.455 image with
the same configuration and volumes. Production `stack.ascdc.tw`, its HAProxy,
OIDC provider configuration, and runtime-patched files are outside this
release procedure.
