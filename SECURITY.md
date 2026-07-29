# Security Policy

## Supported state

The latest PastureStack release and the current `main` branch receive security fixes. Historical upstream tags are retained for provenance and are not supported by PastureStack.

## Security boundaries

- The assembled server controls credentials, secrets, databases, hosts, networks, storage, containers, and privileged agents.
- Every downloaded artifact and base image must be pinned, checksummed, source-attributed, and reviewed.
- Database migration, backup, restore, and authentication changes require isolated rollback tests.
- Authentication providers must be switched with a verified, short-lived,
  single-use account-and-identity-bound ticket while access control remains
  enabled. Keep at least one active local system-administrator credential as a
  tested recovery path.
- External identities must be linked by provider, identity type, issuer, and
  subject. Never infer an account match from username or email.
- Account reassignment must revoke source sessions and must not transfer
  passwords, API keys, MFA factors, recovery codes, or audit history.
- Email codes are account recovery only, not MFA. Recovery revokes existing
  factors and sessions and requires fresh enrollment.
- WebAuthn requires an exact HTTPS origin and relying-party ID except for the
  standards-defined localhost development exception. SMTP credentials remain
  encrypted and non-loopback plaintext delivery is prohibited.
- Do not commit credentials, tokens, private registry coordinates, production databases, lab topology, certificates, or private artifact URLs.
- Usage telemetry remains disabled by default. Enabling the compatible launcher does not enable external publishing: an operator must also configure a reviewed HTTPS target through `PASTURESTACK_USAGE_TELEMETRY_TARGET_URL`. Keep the aggregate endpoint on loopback and review the installed privacy notice before configuring a destination.
- Webhook automation stays on loopback, verifies exact RS256 tokens with the public key, and must never receive the control-plane private key. Preserve its request-size, timeout, redirect, and sensitive-header safeguards.

## Reporting

Report suspected vulnerabilities through this repository's private security advisory channel. Do not include live credentials, production data, or private infrastructure details in a public issue.
