# Host compatibility

Host registration retains legacy API and label contracts. Validate Docker API,
cgroup mode, storage, DNS, overlay traffic, node-agent reconnect, and rollback on
a disposable VM before enrolling a real host.

Use `scripts/legacy-host-compat-inventory.sh` only with credentials supplied at
runtime. Never commit credentials, host addresses, inventory output, or local
machine names.

## Supported Docker versions

PastureStack Server `v1.6.465` recognizes the following modern Docker Engine
compatibility ranges:

| Docker Engine | Validated host | cgroup | Agent line | Result |
|---|---|---|---|---|
| `29.4.1` through `29.7.2` (inclusive) | Ubuntu 24.04.4 LTS | v2 | `v1.2.31` | Supported |
| `29.8.0` | Ubuntu 26.04.1 LTS | v2 | `v1.2.31` | Supported |
| `24.0.9` | Ubuntu 22.04.5 LTS | v1 | legacy-compatible agent | Supported |

The bounded interval includes every stable patch release between `29.4.1` and
`29.7.2`, including `29.6.2`; `29.8.0` is a separately validated point.
Versions below `29.4.1`, versions above `29.8.0`, Docker 25 through 28, and
Docker 30 or newer remain outside this policy. Preserved legacy ranges remain
available for compatible installations; new deployments should use a listed
version instead of assuming that a newer major or minor release is compatible.

The two-host matrix covered registration and reconnect, control-plane proxy
traffic, logs, console and exec sessions, statistics, image pull, managed
container create/start/restart/delete, metadata, system services, cross-host
encrypted overlay traffic, Server restart recovery, Docker upgrade, and package
rollback. Disposable managed workloads were removed after validation, and
existing data volumes were preserved.

The Ubuntu 26.04 matrix was extended to Docker Engine `29.8.0` before Server
v1.6.462. See the official
[Docker Engine 29 release notes](https://docs.docker.com/engine/release-notes/29/)
and [static Linux archive index](https://download.docker.com/linux/static/stable/x86_64/).
PastureStack build tooling retains immutable archive hashes for the versions it
uses in isolated validation. Those build hashes are evidence coordinates, not
permission to enroll an untested operating-system, kernel, or storage-driver
combination.

Before enrolling a durable host, reproduce its operating-system, kernel,
storage-driver, cgroup, and Docker combination on a disposable VM. Treat any
combination outside the ranges above as unsupported until its evidence is
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
