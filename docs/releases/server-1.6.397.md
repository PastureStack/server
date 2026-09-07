# PastureStack Server v1.6.397

Server v1.6.397 embeds Orchestration Engine `0.183.289`, Web Console
`1.6.99`, and Compose Executor `0.14.35` for end-to-end hardware resources.

## Operator-visible result

- A shared Resources and Hardware tab covers shared memory, CPU/PID limits,
  IPC, runtime, init, ulimits, temporary filesystems and namespaced sysctls.
- NVIDIA all/count/device selection and Intel/AMD device mappings use the
  selected host's reported capabilities, with device group suggestions.
- Conflicting GPU modes, invalid paths and limits, and IPC/shared-memory
  conflicts are rejected before scheduling. Hardware choices never implicitly
  enable privileged mode, host IPC, or an unconfined security profile.
- Primary containers, sidekicks, service upgrades and Compose conversion retain
  the same typed settings. Unknown existing settings are not silently erased.
- Missing or stale inventory disables unsupported GPU suggestions without
  blocking ordinary CPU/shared-memory configuration. Install Node Agent
  `v0.13.24` on the target hosts to report the new capabilities.
- All 13 supported UI locales include the new controls. Existing layouts,
  action menus and shared chart streams are retained.

Inventory is not an exclusive GPU scheduler. CUDA, ROCm and media-driver
compatibility must be tested on physical target hardware; a non-GPU VM does
not prove those workloads. Installation-level agent package/image overrides
must be checked rather than assuming every host has upgraded.

## Verification and dependency fixes

- Web Console validation: 417 browser tests and byte-identical production
  builds; source gates and CodeQL passed.
- Engine validation: full Maven reactor and artifact security checks passed.
- Agent validation: Go/race/vet and Python tests, Linux/Windows builds passed.
- An isolated Docker round-trip verified shared memory, CPU/PID, runtime,
  private IPC, init, ulimit, tmpfs, sysctl, device and group settings without
  implicit privileges or host mounts.
- The UI build dependency `@xmldom/xmldom` is locked to `0.9.12` and
  `fast-uri` to `3.1.6`. Compose uses `golang.org/x/crypto v0.56.0`.
- The Server publication workflow verifies start/restart health, scans the
  merged runtime with current vulnerability data, produces the artifact SBOM,
  publishes image attestations and creates the immutable release.

## Bound release inputs

- Orchestration Engine release: `v0.183.289`
- Orchestration Engine source: `60e97127ba49ab0b14f8bd872688257b1478aa98`
- Orchestration Engine JAR SHA-256:
  `eed36714f4d5ac6841f172562d71a9ee7a93e2e43b4d212bb1d109bd77d0a5ec`
- Web Console release: `1.6.99`
- Web Console source: `ec3e47f5ce2baa0ab83200fe469e350bb672447d`
- Web Console archive SHA-256:
  `54fefc80f3f0ebb986c2a4ed529a8861879157ab21c86009a16b01ff06208973`
- Compose Executor release: `v0.14.35`
- Compose Executor source: `9cb410a47f587782cb1d19d1896cb85bc8471cbb`
- Compose Executor archive SHA-256:
  `136308e72c384a7ec5aae350a52f607e9acc5965e7a7be1b933aa2994d42b96d`

This release retains Ember `7.2`, Bootstrap `5.3.8`, Go `1.27.0`, OpenSSL
`3.5.8`, zlib `1.3.2`, the existing runtime hardening and Docker compatibility.
It retains GNU coreutils fix commit
`d64e35a8a4c0e4608321433e0d84d917e4e36371`, the OpenSSL closure for
`CVE-2026-75803`, and removal of the unreachable `diff3` path for
`CVE-2026-53910`.
An unmatched vulnerability at any severity remains a release blocker.
