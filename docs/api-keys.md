# API Keys

This guide describes the Server `v1.6.519` source candidate, with Engine
`0.183.334` and Web Console `1.6.181`. It is not a publication or a claim that
every role/resource combination has passed acceptance. Use the published numeric
image tag in the installation guide until the candidate is separately released.

## Access and expiry

Full retains the owner's existing account/environment scope. Closed allows no
Key-authorized operations. Custom narrows access by stable environment, Stack or
resource IDs and explicit operations; an explicit deny takes precedence.
In the console, select resources by searchable names and readable context,
not by entering IDs. Choose allow-by-default with deny exceptions (blacklist),
or deny-by-default with allow exceptions (whitelist). Both allow direct exception
editing, and changing the default preserves those exceptions. With no exceptions,
the original full or closed behavior applies.
Every policy is intersected with the owner's current RBAC. It neither snapshots
nor adds a role. Browser operation choices are not proof of backend authority.
Untouched legacy Keys are not automatically narrowed during an upgrade.

The editor and reviewed changes show the same resource-by-operation policy
matrix. It explains deny precedence, partial scopes, unresolved ancestry and
expiry, with readable resource names. This is a Key-rule preview, not a guarantee
of effective authorization: live owner access, creation destinations and all
targets of multi-resource actions remain server-checked. An expired reviewed
policy cannot be submitted even if MFA confirmation arrives later.

Policy-bearing writes are checked after authentication and before schema
sanitization. Forbidden owner or credential fields are rejected rather than
silently discarded into an accepted policy change. Ordinary legacy writes
without policy input retain their existing schema behavior. The sensitive
`secretValues` and `dbdump` links require the `export` operation, not `read`;
this classification does not add a restriction to full Keys' existing RBAC.

Optional expiry uses a UTC timestamp. Policy changes use the stored revision;
broadening access or extending validity requires the existing platform MFA
confirmation bound to the operator and exact reviewed change. A stale revision
or failed confirmation uses the existing error contract. Refresh and review the
current Key instead of bypassing the conflict or reusing a confirmation.

## Secret and per-Key audit

A new secret is delivered once through the normal creation dialog. Store it
securely; later GET/list/detail views do not return it. Audit contains safe
identifiers and status metadata, not Key secrets or authentication material.

Open audit from the Key's normal entry point. Access is checked against the
current viewer, including for an inactive Key. All-time has no hidden 24-hour
restriction; explicit UTC ranges and filters apply before bounded totals and
pagination. Failed queries or loss of access must not leave old records visible.

Read decision, outcome and phase separately. ALLOW does not imply success; an
HTTP 200/202 response is not later job or stream completion. A response error
such as 405 is not automatically a Key permission denial. Only the actual
terminal event establishes completion. Container targets use their persisted
instance ID (`1i` prefix) consistently across decision, response and terminal
records, even when an agent schema has no `container` alias. Errors retain the
existing API status/code/request-id and console handling; no alternate login,
role override or secret recovery path is introduced.

## Integration and recovery

Delegated Linux streams require Host API `0.38.5`, Node Agent `0.13.28` and
WebSocket Proxy `0.23.15`. Windows retains its existing `0.13.27` compatibility
path; these Linux versions do not establish Windows delegation support.

An expired, signed Key-traced stream ticket cannot start a backend or persistent
session. Its verified trace and authenticated host proof are accepted only for
audit, never to restore execution authority. After durable acceptance, the
handshake returns `ApiKeyExpired` (401) and records `DENY`/`FAILED`, phase
`handshake`; this is not an executor completion. If proof or durable acceptance
is unavailable, it returns `AuditUnavailable` (503), without starting execution
or claiming that the denial was durably recorded.

See the [candidate contract and component boundary](releases/server-1.6.519.md).
Deploy the complete compatible Server image and preserve existing volumes and
backups. Do not downgrade restricted or expired Keys to a policy-unaware Engine,
or convert them to unrestricted legacy Keys as a workaround. Follow the
[API Key rollback safety guide](upgrades/api-key-policy-rollback.md) before any
downgrade or database restore.
