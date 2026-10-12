# Server v1.6.522

The [official release](https://github.com/PastureStack/server/releases/tag/v1.6.522)
packages Engine `v0.183.340` and Web Console `1.6.183` from Server source
`cb1b71035ad6389760f76b6257699037a62a481a`.
Successful [publication run 38251097504](https://github.com/PastureStack/server/actions/runs/38251097504)
produced the linux/amd64 image with one runtime layer. Its immutable registry
manifest is `ghcr.io/pasturestack/server:v1.6.522@sha256:9569cdcc49156ee0bcdefd493d0067b7c6c1c32a8d39aed55710e83c5661f149`.
The OCI configuration is a different identity:
`sha256:6f1e91d67014d50ab7d3a64c0e9b272a0ffe6967a01b2a0befa958652929ebdd`.
The version tag, manifest, configuration, source, 24 release asset checksums and
publication receipt have been independently read back.

## Minimal onboarding changes

Engine gives the reserved `registrationToken` Basic username to its dedicated
registration lookup before ordinary API Key authentication. A rejected native
token does not fall through to an API Key or browser session. This does not
broaden the register schema, API Key permissions or account RBAC.

The formal publication gate also exposed a project-create lifecycle regression:
the new project inherited the user kind, and ordinary Key authorization ran
before its initial owner membership existed. Engine340 sets project kind before
INSERT and binds the initial account/member/default-network work to the actual
manager-created project. Legacy/full Keys retain native creation; custom policies
do not gain this exception. After the manager scope closes, live owner membership
is mandatory. Existing volume/instance process rules remain unchanged.

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

Engine `v0.183.340` uses source
`ff0a41e7676211043eb4f755a306a9e2a19abee1`; official `cattle.jar` SHA-256 is
`5e5a1b908b43bf3824fc3bb2108bd661cd5199ce9bcfd187e0b18b5608a38cea`.
Web Console `1.6.183` uses normally merged source
`e056a0111d20816742eff17a65dfabb5d003dae2`; official
`web-console-1.6.183.tar.gz` SHA-256 is
`8540758ad4521f901f53fc79473570cf98862add2addcb49271d8dbf125b4217`.

These components use clean merged source and the original component packagers;
the official versioned release assets and checksums were independently read back.
They are not CI-produced component artifacts. The Server image is a separate
normal publication CI output and has passed its existing gates.

## Publication prerequisites

The final image also uses Ubuntu's official `libdbi-perl`
`1.647-1ubuntu0.26.04.4`, addressing
[USN-8912-1](https://ubuntu.com/security/notices/USN-8912-1).
The original `.deb` is SHA256-pinned to
`3040f61cc06ebf363e5895db4cc2c7a2db8951296d39d4ef5fa0fc3fd364654e`;
package identity, runtime bytes and loading are checked. Other dated Ubuntu
inputs and the strict vulnerability/VEX/vendor-pending policy are unchanged.

The formal recipe, builder defaults and coordinate assertions must use the
released component identities above and the verified Engine schema hashes.
An uncommitted local build checksum or integration image is not an official
release identity.

The normal Server publication workflow passed with a clean exact source,
source gates, formal image build and flatten comparison, isolated startup and
restart, proxy/cache contracts, native MFA/API smoke, final merged-rootfs
security and SBOM gates, provenance, immutable numeric publication, and release
asset readback. Existing vulnerability decisions and review deadlines remain;
the new version is not permission to widen or reset them. Eight vendor-pending
Medium findings covering four CVEs remain, with review due 2026-10-20.
Untracked, Critical/High, fixed-available and secret findings are zero; this is
not a claim that the image has no vulnerabilities.

## Native acceptance boundary

Eleven focused native-schema and return-history component cases and the native
add-host UI checks passed on the component source/tree used for the released
Web bundle. They validate the component changes only, not a final Server image.
The 34 focused Engine340 creation/authority tests passed, and their compiled
classes match the packaged clean-main artifact. The unchanged registration
tests are carried by identical source and compiled classes, not rerun.

The final Server's seven-check native registration gate passed, verifying
native token creation and readiness, generated script retrieval,
`GET /v1/register`, the restricted registration schema, ordinary API Key Basic
authentication and invalid-token rejection even with a valid cookie.
Successful HTTP entry alone does not prove an agent connection or active node.
A separate fresh-volume Linux rehearsal using this published image passed
ordinary-Key project creation, native registration, the real LAN add-host copy
and close buttons, and a reported active host matching the intended node.
The launched node agent used new credentials and the correct isolated Server;
the original test VM was restored and the temporary Server/volumes were removed.
This proves initial enrollment, not the complete node restart/upgrade/rollback
lifecycle or the two-source six-role API Key matrix.

## Install, upgrade and rollback

Use the published numeric image tag
`ghcr.io/pasturestack/server:v1.6.522` shown in the README. Keep all three existing
volumes, environment variables, networking, restart policy and security options.
The intended changes do not add a database migration or authentication setting.
Rollback to `v1.6.521` restores the known registration-token authentication defect;
keep a matching database backup and follow the existing API Key rollback guide.
