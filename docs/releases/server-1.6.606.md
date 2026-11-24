# Server v1.6.606

Published image: `ghcr.io/pasturestack/server:v1.6.606@sha256:5046b87cfb1d24634e3f792e2dba45ccd15efa6c8753a13d2ae46feccfcc3c80`.

Source commit: `99c8c13f7888c517c0715276c22e1d25923aa378`.

The release workflow passed its source, security, startup and restart checks before publishing this image. Deployment-specific acceptance is separate and is not claimed by these build results.

## Verified component inputs

Web Console 1.6.242 producer: `948fa3833797ebdac75d8eb89026b354613f23de`.
Archive SHA-256: `61545513d850cc5a69b110d49b51c087a6e1327a95c4d83548839e9144351f21`.
Runtime SBOM SHA-256: `00d5cd731e71595a32d80a541ed2977eabdfddee1e9d40106c3dde09ae916cb7`.
Dependency lock SHA-256: `4d30635e6f84d10dfeb83b301c5159ccbe20608660b34a70e307712d08da3eda`.
The full source qualification passed 1174 tests and required CodeQL. The exact
main producer uses an identical Git tree; it does not claim another full test run.
The unchanged Server consumer verified the original archive/SBOM identity and
enabled/off WebMCP profile. Provenance and CycloneDX attestations bind that same
archive and exact main source. Browser SBOM inventory coverage remains incomplete.

Engine 0.183.395, Catalog Service 0.20.20, Agent 1.2.36, Catalog pin
`8c1c28318580d5ec18c14a13b224ce0e02e40bf8` and LB Service 0.9.35 / HAProxy 3.4.8
retain their existing component identities. There is no scheduler, firewall,
authentication or load-balancer binary change in this Server patch.

## Settings visibility and update contract

The public `lb.instance.image` setting and internal `lb.instance.image.uuid`
have different visibility. A token receiving a 404 for the latter does not
establish an invalid Engine value. Use an authorized administrator and the
resolved fields actually returned by the Settings API; missing `source` is
unknown, not evidence of a database override. Do not insert a database row to
make a read return 200. See the [supported procedure](../upgrades/README.md#managed-load-balancer-image-settings).

## Acceptance boundaries

Publication checks, exact Catalog reads, real browser submissions and workload
runtime behavior are separate evidence. The earlier legacy-Catalog UI fixture
used a maintained 0.6.1 runtime: that result does not establish an original
0.5.0-to-0.6.2 scheduler migration. Its historical files and unrelated passing
results remain retained. Existing operators still use native upgrade, rollback
and finish transactions; updating the Server alone does not replace running
Cron or LB containers.

## Upgrade and recovery

Keep the existing volumes, environment overrides, HTTPS origin, AppArmor and
restart policy. Preserve the previous Server image/container and a verified
database backup before replacing the Server. Explicit custom Catalog pins are
retained; an inherited image default follows the new image. Workload image
rollback retains the previous primary and secondary launch configurations until
Finish Upgrade. Separately persisted service metadata keeps its own semantics.
