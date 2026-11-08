# Server v1.6.589 candidate

Prepared source only; no Server image or release has been published.

## Candidate boundary

This source candidate targets Engine `0.183.391`, Web Console `1.6.232` /
optional Bridge `0.2.34`, and Compose `0.14.44`. Component publication and
anonymous readback are verified. Server build and image publication remain
pending. The preceding qualified Server `v1.6.588` and its
matching data backup remain the rollback; no deployment configuration is changed.

## Verified component inputs

Engine `v0.183.391`, immutable release 438521849, passed twelve anonymous
asset checks and thirteen native release-attestation subjects. Its original
JAR SHA-256 is `54d574c92999c9eaafd0288626b0b996b543793e41e9194ab70ec474949d07d4`,
from producer `bcd470712a4e8d429760b02e8df337ae53d92e2b` and normal same-tested-tree
tag commit `b832c463afca3cad704b6d72da5a76bf1c37d771`. Original CI passed
4,336 tests with zero failures/errors, one inherited skip and all 523 required
methods. C03 retains 1,396 native operation tuples, with zero new role/base-field
grants and the exact private navigation enum delta. These are component
qualifications and do not establish a native workflow result on this assembly.

Web Console `1.6.232` / optional Bridge `0.2.34`, immutable release 438525417,
passed thirteen anonymous asset checks and fourteen native release-attestation
subjects. The exact original archive, runtime SBOM and lock are bound to
producer `2377a76d1e9db0d5ca31cdfbeb58e2ac6e8ee91f` and normal same-tested-tree
tag commit `02ec2f6afd1fb03b222237ced875c4965966be1e`. The original Web archive
SHA-256 is `de7d98c05e3b7361935d40f571962b3ab46549d9200f28d5402c5c2e98ed6156`;
its runtime SBOM and lock have their own exact build pins.

Compose `v0.14.44` remains the same published archive and binary used by
Server588; its twenty anonymous assets and twenty-one cryptographic subjects
remain the component evidence. Host API `0.38.9`, Node Agent `0.13.35`, bootstrap
Agent `1.2.34`, Catalog `0.20.17` and all other component coordinates are unchanged.

## Affected behavior and acceptance boundary

Human-reviewed inactive Registry removal uses the existing native StoragePool
DELETE and shared parent/credential writer lock. Exact Registry identity,
complete captured credential-set comparison, live role/Key authorization and
this plan's native process witness remain required; credential values are not
review operands.

The private AI-purpose Bridge context view projects only parent id, UUID, name
and state after an ordinary authorized child read, current ancestry and final
identity recheck. Explicit parent denial wins. This navigation identity does
not grant ordinary Project reads or business access, expose a new public tool,
or replace native authorization.

The optional Bridge remains a separate fixed-profile client, not another image
input. All four feature opt-ins, operator networking/storage settings, official
dependency pins, raw/effective security separation, crypto and anonymous-byte
gates remain unchanged. Deployment-specific and whole-workflow acceptance
require their own evidence; source and component qualification do not prove them.
