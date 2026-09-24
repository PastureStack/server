# Server v1.6.467

This patch assembles Orchestration Engine `v0.183.322` and Web Console
`1.6.130` on the preserved digest-pinned `v1.6.460` runtime base. The Engine
retries account-owned networks left in `removing` after an interrupted purge;
completed removals are not repeated. Its release gate also rejects packaged
`cattle-dev` archives and `dev-defaults.properties`. The console clarifies
denied or missing stack/account pages and keeps identity-link authorization
failures visible instead of presenting a false empty identity. No database
migration or authentication-policy change is included.

## Verification boundary

Production adoption is blocked until the official component artifacts, clean
Server build, image scan, and isolated `10.0.0.125:8080` permission matrix pass.
The matrix must distinguish live v1/v2-beta API results from simulated UI
error responses and list untested resource families explicitly. A passing
subset must not be described as proof that every API endpoint is authorized.
No deployment to `stack.ascdc.tw` is part of this release procedure.

## Upgrade and rollback

After an immutable digest is published, update only the Server image reference
from `v1.6.466`. Retain the existing Compose environment variables, named
volumes, restart policy, AppArmor, public HTTPS origin, OIDC, performance
settings, and host firewall backend. Rollback selects the preserved
`v1.6.466` image with the same configuration and volumes. Account-network
purge retries should be assessed before rollback because the prior Engine can
leave a partially removed network behind.
