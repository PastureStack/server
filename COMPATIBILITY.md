# Compatibility Contract

The packaging migration preserves established database schemas, API paths and fields, event names, environment-variable aliases, service names used by stored data, container labels, filesystem upgrade paths, and bootstrap contracts.

Preferred product-facing coordinates use `PastureStack/*`, `ghcr.io/pasturestack/*`, `PLATFORM_*`, and `PASTURESTACK_*`. Historical identifiers remain only where existing databases, agents, clients, templates, or upgrade tooling consume them. They must not be mechanically removed.

The catalog helper is packaged and installed as `catalog-service` and `catalog-service-sqlite`. The historical executable path remains only as a compatibility wrapper because the preserved service supervisor and persisted settings still invoke it. Release assets must use the PastureStack filename `catalog-service-<version>.tar.xz`; compatibility aliases must never leak back into the public asset name.

The authentication helper follows the same boundary: the GitHub Release asset and actual executable use `authentication-service`, while the preserved supervisor-facing executable name exists only as a compatibility wrapper.

Machine management uses the neutral `machine-driver-bundle` asset, and vSphere operations use the neutral `vsphere-cli-bundle` asset. The externally defined executable names inside those archives are compatibility interfaces, not PastureStack branding. Artifact, license, and command-surface checks must pass before assembly; real provider and authenticated vSphere lifecycles still require isolated integration tests.

Secret payload operations use the neutral `secret-delivery-api` asset. The preserved engine still invokes the historical `secrets-api` executable and `/v1-secrets` routes, so Server supplies that filename only as an internal symlink while keeping the public artifact, primary executable, source repository, and license destination under the PastureStack name. Existing database key names and encrypted payload formats remain compatibility data and must survive upgrade and rollback testing.

The established `telemetry.opt`, `service.package.telemetry.url`, and `/v1-telemetry` identifiers remain internal compatibility data. Server installs `usage-telemetry-agent`, retains `/usr/bin/telemetry` only as an internal symlink, and packages the agent privacy notice beside its license and source record. A legacy target variable never enables publishing.

The `webhook.service.*`, `service.package.webhook.service.url`, `/v1-webhooks`, and four established driver identifiers also remain internal compatibility data. Server installs the neutral `webhook-automation-service` executable and retains `/usr/bin/webhook-service` only as an internal rollback link. The public asset and license destination use the neutral name, and the child process receives only the RSA public verification key.

The `v1.6.270` assembly consumes Orchestration Engine `v0.183.269`, Web Console `1.6.56`, and API Explorer `1.1.14`. Web Console packaging must retain its fingerprinted `/assets/ui*.js` entry, and API Explorer must retain `/api-ui/ui.min.js` and `/api-ui/ui.min.css`.

Native MariaDB validation must override both `CATTLE_DB_CATTLE_MYSQL_URL` and `CATTLE_DB_LIQUIBASE_MYSQL_URL`; the application and migration pools are configured independently. The default compatibility path intentionally uses a MySQL JDBC scheme with the MariaDB driver compatibility options.

Before release, validate fresh install, preserved-database upgrade, both database modes, web console and API, CLI, node registration, authentication, subscriptions, catalog, networking, storage, backup/restore, rollback, artifact hashes, and non-root execution in isolated VMs.
