# Server v1.6.551

Published image:
`ghcr.io/pasturestack/server:v1.6.551@sha256:150c3eaa2d84df6236e7634843e506a79df71d9e434ad2038427108c14ac358e`.
Producer: `9abef4712901981e5917c41356bb261974fdba47`.

## Verified component inputs

All component inputs retain the 550 pins, including Web Console 1.6.195,
Engine v0.183.354, Host API 0.38.8 and the eight PCRE2 CVE backports. No
application behavior or database migration is introduced.

The manual completion of 550 accidentally converted its standalone Host API
attachment into an empty gzip while converting an empty browser findings table.
The 550 image itself contains the correct package. That incorrect immutable
attachment remains as evidence; do not use it. The original Host API producer
release remains valid.

The normal publisher rechecks the pinned producer archive SHA-256 after report
conversion and before upload. Its executed negative fixture rejects an empty
gzip substitution even though the stream itself is syntactically valid. No
released image or asset was overwritten.

## Verification and remaining risk

[Run 40120970328](https://github.com/PastureStack/server/actions/runs/40120970328)
passed the source, image, security, startup/restart and publication checks. All
33 immutable assets passed anonymous byte/checksum readback, and the Host API
archive additionally matches producer SHA-256
`6903ffb6a618f5a9bc8c7c8997a1e0419c93a8bbdeaee6d288957366dccef444`.
Its archive contents and internal checksums are intact. Both OCI attestations
bind the exact producer and image digest; the final image retains one layer.

The scoped 8080 cutover and one controlled restart passed. Package integrity and
linkage, grep/Git and two read-only MariaDB regex controls, ping and three active
Host/Agent states passed. Existing HostConfig, operator environment, all three
named data volumes, socket bind and AppArmor were preserved. A consistent
104-table InnoDB backup and the 550 rollback container/image remain.

The exact rootfs scan retains 51 raw occurrences, 38 VEX dispositions and 13
pending LOW/MEDIUM occurrences across 10 CVEs. Other product candidates and
Ruby/Onigmo build-host coverage remain separately tracked. Unchanged UI, role,
OIDC and MFA evidence is carried forward; no full feature-matrix rerun or
all-project zero-risk claim is made. The production site, HAProxy, firewall and
production database were not modified.

## Upgrade and rollback

Use the numeric `v1.6.551` tag after verifying backups and the published image
identity. Preserve existing Compose settings, named volumes, restart policy and
security options. Keep the prior image and matching backup until acceptance.
Do not patch running containers or overwrite release tags.
