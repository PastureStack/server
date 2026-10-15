# Server v1.6.536 candidate

This packaging update changes the three default external CLI download links and
advertised CLI version to the maintained `v0.6.18` release. It does not replace
the unchanged Web Console `1.6.189` or Engine `v0.183.349`, change API Key policy,
authentication, firewall rules, volumes or operator runtime configuration.

The old `0.6.14` client swallowed a rejected schema request and exited zero.
The maintained CLI propagates the original failure. CLI publication/security
checks, exact release checksums and native Full/legacy/Closed command acceptance
remain required; this candidate is not a claim that they have passed.

Explicit URL settings already saved in the database remain authoritative. An
upgrade does not silently replace an operator's mirror or pinned client. If a
saved URL still points to the historical Server `v1.6.278` CLI `0.6.14` asset,
an administrator can update the three `rancher.cli.*.url` settings through the
normal settings API/UI after verifying the new release checksums. Preserve any
intentional custom URLs. No database script or runtime binary patch is required.

The full Server release and final-image checks must pass before publication.
Existing 535 acceptance is carried only where unchanged. Installation continues
to use a numeric image tag; do not overwrite earlier releases. Keep the previous
container and its configuration for rollback, without restoring an older database.
