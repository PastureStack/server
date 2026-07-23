# Host compatibility

Host registration retains legacy API and label contracts. Validate Docker API,
cgroup mode, storage, DNS, overlay traffic, node-agent reconnect, and rollback on
a disposable VM before enrolling a real host.

Use `scripts/legacy-host-compat-inventory.sh` only with credentials supplied at
runtime. Never commit credentials, host addresses, inventory output, or local
machine names.

## Supported Docker versions

PastureStack does not yet declare any Docker release production-supported. The
current isolated control-plane POC used Docker 29.4.1 on Ubuntu 24.04.4, but that
result does not prove host registration, node-agent reconnect, networking,
storage, workload upgrade, or rollback compatibility.

Before enrolling a host, reproduce the intended operating-system and Docker
combination on a disposable VM. Verify registration, health checks, logs,
console and exec sessions, cross-host networking, restart persistence, upgrade,
and rollback. Treat an untested combination as unsupported until its evidence is
recorded and reviewed.

## Amazon EC2 image requirements

PastureStack does not publish or endorse a provider-specific machine image.
Select an image that boots a supported Linux distribution, permits SSH access
with the configured account and key, and can install the Docker version being
evaluated. Confirm the image architecture, root-device size, network egress,
time synchronization, and reboot persistence on a disposable instance before
using it for a durable environment.

Do not assume an image is compatible because it was listed by an upstream or
third-party project. Record the exact image ID, region, operating-system release,
Docker release, and validation result in private deployment evidence; image IDs
can differ between regions and may be replaced without notice.
