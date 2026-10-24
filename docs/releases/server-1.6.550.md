# Server v1.6.550 candidate

Prepared source only; no Server image or release has been published.

## Change

Backport the twelve official PCRE2 `release/pcre2-10.46` commits through
`947809f11e9c9744aa0974b4b630a1ae461733dd` onto the original Ubuntu 26.04
`10.46-1build1` source package. The source, original packaging and every patch
are SHA-256 pinned. This is a first-party rebuild, not a Canonical release.
It avoids unrelated regex, Unicode, JIT or packaging changes.

The two packages `libpcre2-8-0` and `libpcre2-posix3` use version
`10.46-1build1+pasturestack.1`. The eight fixed vulnerabilities are
CVE-2026-103111, CVE-2026-86145, CVE-2026-89156, CVE-2026-89157,
CVE-2026-89158, CVE-2026-89160, CVE-2026-89161 and CVE-2026-89162.
The [official supported backport list](https://github.com/PCRE2Project/pcre2/blob/pcre2-10.49/SUPPORT-LIFECYCLE.md)
identifies this exact series. Ubuntu having no updated binary package does not
mean upstream has no accepted fix.

## Verification and boundaries

The build runs the unchanged Ubuntu packaging tests: `pcre2_jit_test`, `RunTest`
and `RunGrepTest`, and requires all three PASS records. The output retains source
locks, build logs, native test logs, compiler flags, package identity and ABI /
hardening evidence. Runtime checks require exact package versions, zero dpkg
integrity differences, both library hashes, resolved linkage from grep, Git,
MariaDB, libselinux and the POSIX wrapper, and C / C.utf8 regex controls.

The inherited image's documentation exclusion is overridden only while installing
the package-owned `README.Debian`; no integrity exception is added. Raw scanner
results remain intact. The fixed VEX entries apply only to the exact rebuilt
package PURLs; the other ten pending Server CVEs remain tracked.

Native library and layered-candidate checks have passed on the QA host. These do
not establish publication or startup/restart acceptance of the final image.
Those results and the immutable digest will be recorded after the release gates.
Web Console 1.6.195, its runtime SBOM and all other component pins are unchanged.
Unrelated role, UI, OIDC, MFA and feature-matrix PASS evidence is carried forward.

## Upgrade and rollback

Until publication, continue using the numeric `v1.6.549` installation examples.
Do not overwrite an existing image tag or apply library patches to a running
container. Upgrade with a new immutable image after verified backups, preserving
all existing volumes, configuration and the previous container/image for rollback.
No database migration or operator setting change is introduced by this patch.
No production deployment is part of this release task.
