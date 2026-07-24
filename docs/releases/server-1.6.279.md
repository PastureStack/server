# PastureStack Server v1.6.279

PastureStack Server `v1.6.279` completes the Catalog restoration introduced by
Catalog Templates `v0.3.0-rc8` and renders Catalog metadata in Taiwan
Traditional Chinese when that locale is selected.

## Catalog

- The Catalog is pinned to
  `f28c1d4d03b19cd7d8cd273573f8eb2a8da0ddda`.
- The reviewed set contains one native project template and seven
  infrastructure templates.
- NFS Storage uses
  `ghcr.io/pasturestack/nfs-storage-driver:v0.9.13`.
- Layer 2 Flat Network and Per-Host Subnet Network use
  `ghcr.io/pasturestack/ipsec-vxlan-overlay-network:v0.14.26`.
- Catalog, Compose, API, and web-console image fields use semantic version tags
  only.

The two alternative network templates are release candidates. They are
discoverable but not installed automatically. Operators must review host
interfaces, non-overlapping subnets, routing, and access-recovery procedures
before deployment.

## Web Console

- Source:
  [`PastureStack/web-console@2dd5e5b0154ddbb8e41ef2887fa786b93e74827b`](https://github.com/PastureStack/web-console/tree/2dd5e5b0154ddbb8e41ef2887fa786b93e74827b)
- Package: `1.6.56-pasturestack.5`
- Compatibility artifact: `1.6.56`
- Catalog cards select their Taiwan-localized names and descriptions from
  reviewed Catalog labels, with English fallback for missing metadata.
- The artifact passed 196 browser tests and two byte-identical production
  builds.

## Runtime inheritance

This patch image inherits the reviewed runtime, licenses, SBOM, and immutable
binary assets from Server `v1.6.278`. It replaces only the Web Console and
updates the default pinned Catalog commit. The base image is referenced by the
semantic version tag `ghcr.io/pasturestack/server:v1.6.278`.

## Run

```sh
docker run -d \
  --name pasturestack-server \
  --restart unless-stopped \
  -p 8080:8080 \
  ghcr.io/pasturestack/server:v1.6.279
```

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.
