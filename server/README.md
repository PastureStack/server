# PastureStack Server image

This directory builds the PastureStack Server runtime image. It retains the
legacy API, database, label, event, and agent contracts documented in
[`../COMPATIBILITY.md`](../COMPATIBILITY.md).

## Development source overrides

`REPOS` is a space-separated list of source repositories to clone and build at
container startup. Each entry is either a full Git URL, optionally followed by
`,origin/<branch>`, or one of these reviewed PastureStack shorthands:

- `cattle` (compatibility shorthand for `PastureStack/orchestration-engine`)
- `node-agent`
- `host-api`
- `compose-cli`
- `mount-propagation`
- `catalog-service`
- `authentication-service`
- `host-provisioner`

The orchestration engine is always included and is checked out into the
protocol-compatible `cattle` working directory. Unknown shorthands fail closed;
they are not expanded through a personal namespace.

Example:

```sh
docker run --rm -p 8080:8080 \
  -e REPOS="node-agent https://github.com/PastureStack/compose-cli.git,origin/main" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  ghcr.io/pasturestack/server:development
```

This development path does not publish images, artifacts, or releases.
