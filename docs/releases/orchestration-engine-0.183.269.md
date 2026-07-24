# Orchestration Engine 0.183.269 release evidence

This evidence applies to the exact public source and Runtime artifacts consumed by PastureStack Server `v1.6.273` and `v1.6.274`.

## Source

- Repository: `https://github.com/PastureStack/orchestration-engine`
- Source commit: `f8f6f1bbf7970d459ee3e5101cf8d647b846683d`
- Preserved upstream boundary: `82d154a53f4089fecfb9f320caad826bb4f6055f`
- Downstream commit count after the preserved boundary: exactly one

## Complete package validation

The complete gate was rerun from the exact public commit on 2026-07-23 with Maven `3.9.14`, Eclipse Temurin `25.0.2`, and `maven.compiler.failOnWarning=true`.

- All source hygiene gates ended with `failure_count=0`.
- The 89-module Maven package completed successfully.
- The reproducible Hazelcast compatibility artifact is `5.7.0-pasturestack.2`,
  with its embedded Jackson 2 and Jackson 3 lines updated to `2.21.5` and
  `3.1.5`.
- packaged-lib hygiene OK: one Runtime library directory, 184 JARs, and no blocked retired library family.
- Runtime JAR uniqueness: zero duplicate artifact identities, zero mixed legacy/modern families, and one expected logging binding.
- bytecode major `69`: 2,268 target classes and 2,259 classes in 82 packaged engine JARs passed.
- standalone startup OK: version `0.183.269`, one generated WAR, and isolated H2 startup reached the success marker.
- Final result: `CATTLE_JDK25_FULL_PACKAGE_OK`, 84 target class directories, 205 Surefire XML reports, and `failure_count=0`.

## Published Runtime artifacts

- `orchestration-engine-0.183.269.jar`
  - SHA-256: `509fb5c941c1722edb1039d7026c654f3d7168e9a2f95e4dc2abba143c1df06d`
  - Size: 79,909,672 bytes
- `orchestration-engine-auth-logic-0.183.269.jar`
  - SHA-256: `a55dca39b89f8f94f90b78fe2692956382238c830300425bee6bde7c3b3ce2a4`
  - Size: 209,340 bytes

The primary artifact passed the release-archive gate for engine version `0.183.269`: one web application descriptor, launcher, Runtime resources, authentication-logic archive, Maven version record, and implementation-version record were present.

This file records a source and artifact gate. Database restoration, authenticated API behavior, node registration, system stacks, upgrade, rollback, and failure recovery remain Server-level release gates.
