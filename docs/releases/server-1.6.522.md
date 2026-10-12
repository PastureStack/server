# Server v1.6.522 candidate

Prepared source only; no Server image or release has been published.
The candidate uses released Engine `v0.183.339` and Web Console `1.6.183`.
The published Server remains `v1.6.521`.

## Minimal onboarding changes

Engine gives the reserved `registrationToken` Basic username to its dedicated
registration lookup before ordinary API Key authentication. A rejected native
token does not fall through to an API Key or browser session. This does not
broaden the register schema, API Key permissions or account RBAC.

Web Console gates each add-host form by its actual submission path: Custom
creates a RegistrationToken and requires RegistrationToken POST; built-in and
Other driver forms create a Host and require Host POST. Machine POST alone does
not grant either path. These checks use the current project's loaded native
schemas; absent, readonly or stale schemas grant no onboarding access.

Cancel / Go Back explicitly dispatches to the active route. The external return
target is saved before the initial driver redirect and preserved across driver
changes and API-host settings refresh. Missing, loading or self-referencing
add-host targets fall back to Hosts; valid external targets and the existing
waiting destination remain. Other Server components and the console broker are
unchanged; this is not the broader API Key integration candidate.

## Released component inputs

Engine `v0.183.339` uses source
`436a37215bc5702e516ecf1feb6753b4be5bf602`; official `cattle.jar` SHA-256 is
`bce020a298ebb89ef3d14ba0666f040e4a732288d1b100da9859dcf957a7981d`.
Web Console `1.6.183` uses normally merged source
`e056a0111d20816742eff17a65dfabb5d003dae2`; official
`web-console-1.6.183.tar.gz` SHA-256 is
`8540758ad4521f901f53fc79473570cf98862add2addcb49271d8dbf125b4217`.

These components use clean merged source and the original component packagers;
the official versioned release assets and checksums were independently read back.
They are not CI-produced component artifacts. The Server image is a separate
normal publication CI output and is still pending.

## Publication prerequisites

The formal recipe, builder defaults and coordinate assertions must use the
released component identities above and the verified Engine schema hashes.
An uncommitted local build checksum or integration image is not an official
release identity.

The normal Server publication workflow still requires a clean exact source,
source gates, formal image build and flatten comparison, isolated startup and
restart, proxy/cache contracts, native MFA/API smoke, final merged-rootfs
security and SBOM gates, provenance, immutable numeric publication, and release
asset readback. Existing vulnerability decisions and review deadlines remain;
the new version is not permission to widen or reset them.

## Native acceptance boundary

Eleven focused native-schema and return-history component cases and the native
add-host UI checks passed on the component source/tree used for the released
Web bundle. They validate the component changes only, not a final Server image.

The final Server's seven-check native registration gate remains pending. It must
verify native token creation and readiness, generated script retrieval,
`GET /v1/register`, the restricted registration schema, ordinary API Key Basic
authentication and invalid-token rejection even with a valid cookie.
Successful HTTP entry alone does not prove an agent connection or active node.
The real agent lifecycle and active-node acceptance also remain pending.

## Install, upgrade and rollback

After publication and readback, use the numeric image tag
`ghcr.io/pasturestack/server:v1.6.522` shown in the README. Keep all three existing
volumes, environment variables, networking, restart policy and security options.
The intended changes do not add a database migration or authentication setting.
Rollback to `v1.6.521` restores the known registration-token authentication defect;
keep a matching database backup and follow the existing API Key rollback guide.
