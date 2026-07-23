# Security Policy

## Supported state

This repository is under migration review and is not release-ready.

## Security boundaries

- The assembled server controls credentials, secrets, databases, hosts, networks, storage, containers, and privileged agents.
- Every downloaded artifact and base image must be pinned, checksummed, source-attributed, and reviewed.
- Database migration, backup, restore, and authentication changes require isolated rollback tests.
- Do not commit credentials, tokens, private registry coordinates, production databases, lab topology, certificates, or private artifact URLs.
- Usage telemetry remains disabled by default. Enabling the compatible launcher does not enable external publishing: an operator must also configure a reviewed HTTPS target through `PASTURESTACK_USAGE_TELEMETRY_TARGET_URL`. Keep the aggregate endpoint on loopback and review the installed privacy notice before configuring a destination.
- Webhook automation stays on loopback, verifies exact RS256 tokens with the public key, and must never receive the control-plane private key. Preserve its request-size, timeout, redirect, and sensitive-header safeguards.

## Reporting

Report suspected vulnerabilities through this repository's private security advisory channel. Do not include live credentials, production data, or private infrastructure details in a public issue.
