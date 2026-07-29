# Build and source POC

The current modernization work preserves the downstream Ubuntu 26.04, current
Java runtime, MariaDB, bounded-download, checksum, WebSocket, and non-root
hardening changes. These changes are candidates until the source checks and a
disposable-VM integration test pass.

Run the repository-local source checks from a Linux environment:

```sh
./scripts/test
./scripts/check-server-source-gates.sh
```

Do not publish or deploy an image merely because source checks pass. VM tests
must use disposable data and an explicit rollback path.

The default build artifact source is the version-matched public
`PastureStack/server` GitHub Release. Before that release exists, a maintainer
may explicitly set `PASTURESTACK_ARTIFACT_BASE_URL` to a reviewed isolated
staging source. Operators are not expected to deploy a permanent artifact
mirror or catalog website.
