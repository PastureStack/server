# Runtime advisory review, 2026-09-07

The v1.6.397 candidate built from `441b1d7afe14cefd2d005fc2a4fb72c386473bde`
passed isolated start and restart checks, but publication run `34135783885`
failed the merged-rootfs vulnerability gate. No image was published by that run.
The raw scan is retained in its workflow artifact. An absent package implementation
and an installed vulnerable implementation are not the same evidence.

## Direct remediation and applicability

- **Host Provisioner:** `CVE-2026-56855` and `CVE-2026-78662` concern SSH channel
  dispatch. Docker Machine calls `ssh.Dial`, so this is a relevant path, not an
  OpenPGP false positive. Release `v0.39.7`, source
  `c396df52491cf115de49fd909ea09afe5c6ce135`, upgrades to
  `golang.org/x/crypto v0.56.0`; the owning
  repository tests undecided-channel traffic, unexpected established-channel
  messages and legitimate request/response behavior. Server validates both
  SSH-bearing binaries' embedded module versions, in addition to artifact hashes.
  Main validation run `34137894997` and security run `34137895006` passed; the
  downloaded release archive and executable hashes match both main CI artifacts.
- **Authentication Service:** the same module-level findings do not contain the
  affected package in the pinned `v0.4.36` product. Source revision
  `f9609e657486693575753f1bfdfdf1aeb13e1fc5` imports `md4` and `ripemd160` through
  LDAP/SAML dependencies, not `golang.org/x/crypto/ssh`. The exact module/package
  graph and the vendored source were checked. The v0.55.0 applicability statement
  is valid only while no other shipped binary retains that version with SSH.
- **libssh2:** Ubuntu [USN-8722-1](https://ubuntu.com/security/notices/USN-8722-1)
  fixes `CVE-2026-66032`, `CVE-2026-66033` and `CVE-2026-66035` in
  `1.11.1-1ubuntu0.26.04.4`. Refresh the signed Ubuntu snapshot and enforce that
  minimum in the image build and post-build check. A rebuild/scan is still needed
  to claim the resulting artifact is fixed.
- **Expat:** all newly reported Expat findings refer to package database metadata.
  The runtime already removes `git-http-push`, `libexpat.so.1` and its implementation
  file, and validates both file absence and the dynamic linker cache. Each CVE
  remains individually represented in OpenVEX; no severity-wide ignore is added.
- **GnuPG:** `CVE-2026-57062` affects CMS parsing in `gpgsm`. Explicitly enforce
  absence of `gpgsm` as well as the already removed `gpgv`.

## Resolved in the candidate: CVE-2026-18374

[Ubuntu's advisory](https://ubuntu.com/security/CVE-2026-18374) requires an
attacker-controlled **fopen mode string** with an effectively empty `,ccs=`
extension. A filename, file contents or locale setting alone is not that input.
The live Ubuntu advisory (last updated 2026-09-03, checked 2026-09-07) marks
26.04 as **Vulnerable, fix deferred**, without a fixed Ubuntu package. That page
predates the upstream fix published on 2026-09-04.

The candidate rebuilds the signed Ubuntu `2.43-2ubuntu2.3` source package as
`2.43-2ubuntu2.3+pasturestack1` with upstream fix commit
`9765a538ebf8661a6e5578e01e35a3dd30db7eb4`. The patch rejects an empty
post-strip charset before the old out-of-bounds fallback. Its checksum and the
Ubuntu source version are both build gates; Debian or another distribution's
binary packages are not mixed into the image.

The reviewed native entry points provide useful counterevidence:

- [OpenJDK file I/O](https://github.com/openjdk/jdk25u/blob/master/src/java.base/unix/native/libjava/io_util_md.c)
  uses integer flags and `open`, not a caller-provided fopen mode.
- [MariaDB 11.8.6 my_fopen](https://github.com/MariaDB/server/blob/mariadb-11.8.6/mysys/my_fopen.c)
  constructs the mode from integer flags using a fixed alphabet in `make_ftype`.
- The reviewed Go services are CGO-disabled; their package source does not expose
  the affected libc mode-string API.

The build runs the three malicious cases from upstream test commit
`cca93e5d88d3d4ed073c03100467696f652269e7`: a one-megabyte continuing mode
string after a blank `ccs` value, `w,ccs=`, and `w,ccs=,`. Each must fail with
`EINVAL`. It also requires ordinary `fopen` and `w,ccs=UTF-8` to continue
working. The rebuilt packages remain subject to the existing merged-rootfs
Trivy/OpenVEX, initial-start and restart gates before publication.
