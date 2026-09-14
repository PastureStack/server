# Server v1.6.440

This release pins the official `pasturestack` Catalog at
`e082033ba3c12b5f5cfcae93ff1d6f50d5440d07` (Catalog Templates
`v0.3.12`) and Orchestration Engine `v0.183.301` at
`88f8a457dccce88f9b6fdb6deddcc99b9d4d3179`. The Engine artifact SHA-256 is
`5c7201ef1c8653f62fa05ced1952921f8bbab53e36a09ea88401983144e1cd91`.
Only pure numeric semantic release tags are operational coordinates.

Network Services version 9 selects the official Network Plugin Manager
`v0.8.21` image. Its manifest digest is
`sha256:aab4c05b0801feeca40fa9cb82a52fbfbfe506c609d3df2024fbc07ef4b968e9`.
Metadata Service and Internal DNS are unchanged, and every prior numeric
Catalog revision remains available to existing stacks.

The manager follows Docker's active firewall path without changing the host:
native nftables remains native nftables, while Docker's iptables driver retains
the active iptables-nft or iptables-legacy frontend. A mismatch or ambiguous
owner fails safely. The manager never selects a backend from Ubuntu version,
loads legacy modules as a fallback, writes both frontends, or changes the
host's global forwarding policy.

Module ownership remains explicit. Network Plugin Manager owns platform host
NAT, forwarding, and published-host-port chains. IPsec, VXLAN, per-host-subnet,
and flat-network providers own their data plane, CNI, routes, and encryption;
they do not patch another module's firewall chains to satisfy a test.

Provider selection now chooses one eligible immutable provider per CNI binary,
prefers the highest numeric OCI version, and uses a deterministic container-ID
tie-break. Generated wrappers execute that exact provider rather than relisting
containers by service label. Content, mode, regular-file, and symlink drift are
repaired with a private temporary inode and atomic rename. Host-port recovery
may read the selected running container's network namespace only when exactly
one IPv4 address belongs to the managed subnet; it revalidates the Docker PID
after the read and otherwise retains the prior working rules.

The exact official component image passed two-host Ubuntu 26.04 and Docker
29.1.3 tests with native nftables, iptables-nft, and iptables-legacy. The gate
covered IPsec, VXLAN, per-host-subnet, and flat networks; bidirectional
cross-host workload traffic; published host ports; DNS; Metadata; platform
egress; health reporting; backend isolation; Docker restart; and one-at-a-time
host reboots. The switched test host was restored to its pre-test
iptables-nft frontend.

Orchestration Engine `v0.183.301` restores each upgraded child service's
previous primary and sidekick launch configuration before the stack rollback
process is scheduled. It reuses the direct service rollback contract, so
Catalog-managed network and storage stacks do not keep upgraded launch
configuration after a requested rollback.

The Server keeps the verified multi-stage build and publishes a one-rootfs-layer
runtime for classic overlay2 compatibility. CI compares runtime configuration
before and after flattening, starts and restarts the candidate, validates the
Host API SHA-256 chain, indexes the exact Catalog pin, exercises authenticated
API and reverse-proxy contracts, scans the merged runtime, creates an SBOM, and
publishes checksums and attestations. Vendor findings without an upstream fix
remain recorded evidence; they are not waived or patched speculatively.

Before production rollout, preserve the prior image, database, named volumes,
and configuration. Verify `/ping`, authenticated API, the exact Catalog pin,
rendered version-9 templates, host health, stack upgrade and rollback, and the
four network data paths. Keep the previous image until the replacement passes
startup, restart, browser/API, and host lifecycle checks.
