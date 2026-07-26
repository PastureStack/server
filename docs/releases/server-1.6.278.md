# PastureStack Server v1.6.278

PastureStack Server `v1.6.278` makes semantic version tags the only operational container-image format exposed through defaults, persisted coordinates, Compose, Catalog, API, and the web console.

## Runtime image references

- Node Agent defaults use `ghcr.io/pasturestack/node-agent:v1.2.31`.
- Load Balancer Service defaults use `ghcr.io/pasturestack/load-balancer-service:v0.9.25`.
- Server startup and migration commands use `ghcr.io/pasturestack/server:v1.6.278`.
- Digest-qualified values are rejected by migration preflight and source gates.
- Resolved digests remain in the release manifest, SBOM, and build verification only; they are not operational input.

## Network stack recovery

- The Catalog is pinned to commit `025742e579efebb28d7ead2dc5e573138658d13e`.
- The reviewed Catalog set contains one native project template and four first-party infrastructure templates.
- The IPsec overlay template separates the `cni-driver` and `overlay-network` services so a clean replacement cannot retain duplicate network drivers.
- Every IPsec component uses `ghcr.io/pasturestack/ipsec-vxlan-overlay-network:v0.14.26`.
- Release validation checks the Catalog template content, not only the number of indexed entries.

## Included runtime

- Orchestration Engine `v0.183.269`
- Web Console compatibility artifact `1.6.56`
- API Explorer `1.1.14`
- Catalog Service `v0.20.7`
- Node Agent `v1.2.31`
- Load Balancer Service `v0.9.25`
- Catalog commit `025742e579efebb28d7ead2dc5e573138658d13e`

## Run

```sh
docker run -d \
  --name pasturestack-server \
  --restart unless-stopped \
  -p 8080:8080 \
  ghcr.io/pasturestack/server:v1.6.278
```

Keep operational image references in semantic version-tag form. The matching GitHub Release retains the resolved digest as verification evidence.

PastureStack is an independent community effort to preserve, audit, and modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by Rancher Labs or SUSE.
