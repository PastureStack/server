# PastureStack Server v1.6.280

PastureStack Server `v1.6.280` publishes the reviewed optional VXLAN Catalog
entry while retaining the runtime and Taiwan Traditional Chinese Web Console
from `v1.6.279`.

## Catalog

- Catalog Templates release: `v0.3.0-rc9`.
- Pinned Catalog commit:
  `23ee314045ccbd2445748c90567dbe24b6ab801e`.
- The reviewed set contains one native project template and eight
  infrastructure templates.
- `PastureStack VXLAN Overlay Network` uses
  `ghcr.io/pasturestack/ipsec-vxlan-overlay-network:v0.14.26`.
- VXLAN traffic is not encrypted and requires UDP port `4789` between
  participating hosts.
- Catalog, Compose, API, and Web Console image fields use semantic version tags
  only.

The VXLAN template is discoverable but is not installed automatically. It
must not be enabled alongside another managed overlay network in the same
project. Operators must review host firewall, routing, MTU, and
access-recovery procedures before deployment.

## Validation

- Deployable image audit: passed with zero blockers.
- Catalog Service validation and API integration: 4 tests passed.
- Isolated two-node VXLAN forwarding and bidirectional overlay traffic: passed.
- Test containers, networks, caches, and temporary environments: removed.

## Runtime inheritance

This patch image inherits the reviewed runtime, localization, licenses, SBOM,
and immutable assets from Server `v1.6.279`. It changes only the product
version and default pinned Catalog commit. The base image is referenced by the
semantic version tag `ghcr.io/pasturestack/server:v1.6.279`.

## Run

```sh
docker run -d \
  --name pasturestack-server \
  --restart unless-stopped \
  -p 8080:8080 \
  ghcr.io/pasturestack/server:v1.6.280
```

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.
