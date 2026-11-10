# Server v1.6.595

## Publication and deployment

Immutable image: `ghcr.io/pasturestack/server:v1.6.595@sha256:33a90620cbd48a999e95a14166e1d86d78317c2f118d04aa33079a848b0ee351`.
Source revision: `082836aed40d2399b07b6bc31aa3760d90c381dd`.

Publisher [42812240379](https://github.com/PastureStack/server/actions/runs/42812240379)
passed normal build, security, first-start and restart checks. Independent
readback verified all 35 assets, 36 signed subjects and two OCI attestations.
QA deployment and restart passed with three active Hosts and Agents. Existing
mounts, named volumes, origin, performance settings, AppArmor and restart policy
were preserved. The previous published 594 image and database backup are retained.
No production change or runtime patch is included.

The complete deployed Registry removal workflow remains a separate acceptance
step; publication alone does not prove full frontend coverage.

## Verified component inputs

Packages immutable Web Console 1.6.234 and optional Bridge 0.2.36 with retained
Engine v0.183.394 and Compose 0.14.45. Agent and other runtime components retain
their published bytes; no dependency update or new CVE remediation is claimed.

A scoped Registry removal could succeed natively but lose its final active
navigation witness. The Bridge now observes only its already-issued, context-bound
Registry removal receipt through the original native authorization path. The
current actor, Key identity/revision, live role ceiling and removed target are
still checked. Other queries and mutations retain their navigation checks.
No second apply, client approval tool, generic scope grant or backend relaxation
is introduced. Browser session handling remains unchanged.

Original Web CI passed 378 required identities and 1,149 browser cases. Static
provenance/SBOM, required CodeQL and the packaged Bridge SDK handshake passed
before component publication. These checks do not establish
deployed business acceptance or complete frontend coverage. Existing runtime CVEs
remain tracked under the unchanged fixable/HIGH/CRITICAL publication gates.

Two newly observed Medium CVEs add five exact vendor-pending package occurrences
(28 total /14 CVEs). Canonical has no released Resolute fix for these exact
packages; upstream CVSS3 High ratings remain disclosed. See the
[vendor review](../../server/security/reviews/server-1.6.595-vendor-pending.md).

## Upgrade and rollback

Use the numeric `v1.6.595` tag in the documented Docker or Compose installation.
Keep the existing volumes, environment, security options and previous image.
Back up the database and persisted volumes before replacing the Server container.
The optional Bridge is a separate client; update it to 0.2.36 when using scoped
Registry removal. Earlier JavaScript or Bridge processes do not gain this fix
merely because the Server image was replaced.

For rollback, stop the replacement and restore the retained previous image with
the same configuration and data attachments. Do not run both against the same
database. Restore the matching cold backup if any intervening data migration
requires it; do not delete volumes or overwrite an existing immutable image tag.
