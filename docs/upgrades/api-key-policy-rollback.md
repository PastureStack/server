# API Key policy rollback safety

Server 519 / Engine 334 enforce API Key policy, expiry and live owner access.
Server 518 and other policy-unaware Engines do not understand those limits.
An image-only downgrade is unsupported: a custom, closed or expired Key can
otherwise regain full access under the older credential interpretation.

Prefer recovery to a compatible policy-aware version. If that is not possible,
keep the external API disabled or isolated while preparing the recovery. Do
not expose a policy-unaware Engine merely because startup or database restore
succeeds.

Before exposing an older Engine, revoke every affected credential through a
compatible version and retain the revocation tombstones. Include restricted,
closed and expired Keys, and credentials revoked or narrowed after the proposed
backup was taken. Do not convert their policies to full access as a downgrade
workaround. A previously issued secret must remain unusable after revocation.

A database restore must not resurrect revoked, narrowed or expired credentials.
Retain and reconcile the current revocation state before serving requests;
an old backup alone is not sufficient evidence that this is safe. If the
restored version or data cannot preserve that state, leave external API access
disabled and recover to a compatible version. Validate affected credentials
are denied before re-enabling access, and issue replacements only through the
normal authenticated management flow.

Keep the matching database/volume backups and image recovery point. This guide
does not authorize a production downgrade, database rewrite or deletion of
credential/audit history.
