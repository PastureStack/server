# Server v1.6.450

PastureStack Server v1.6.450 packages Web Console 1.6.122 and replaces three
independent Promise/callback bridges plus the shared create/edit save path with
central lifecycle contracts. It retains Orchestration Engine 0.183.309,
Authentication Service 0.4.41, the existing persistent-volume layout,
reverse-proxy contract, session-bound explicit logout, OIDC, TOTP, Passkey, MFA
confirmation, and the selected nftables or iptables backend.

## Root causes and correction

The old Promise-to-callback pattern used
`promise.then(successThatCallsCb).catch(errorThatCallsCb)`. If the callback
raised while completing an `async.auto` dependency, the trailing catch treated
that callback exception as a Promise rejection and called the same callback a
second time. Async's only-once guard then replaced the first diagnostic with
`Callback was already called.` A task factory could also throw before Promise
adoption, leaving the final async callback and loading transition unsettled.

Web Console 1.6.122 provides one RSVP-based Promise-to-callback adapter. It
starts the task factory in a deferred Promise turn, adopts Promises, thenables,
and plain values, and uses `then(onFulfilled, onRejected)` so each async task
settles its callback exactly once. `PromiseToCb`, authenticated-route `cbFind`,
and `settings.load` now share this implementation.

Once the secondary callback stopped masking the first error, the environment
route exposed its actual incompatibility: the maintained `ember-api-store`
boundary no longer implements `importLink`. The route now uses the supported
`followLink('projectMembers')`, assigns the returned members to the project,
and returns the project only after that link resolves. Failures from
allProjects, project, projectMembers, networks, and policyManagers retain their
original exception and reach the normal error route instead of hanging.

The shared `NewOrEdit` mixin previously invoked `willSave` before Promise
adoption, failed to return the inner save chain, and swallowed cleanup errors.
A synchronous `doSave` exception could therefore leave `saving=true`
permanently. The new lifecycle returns one awaitable Promise covering
`willSave`, `doSave`, `didSave`, `doneSaving`, diagnostic error display,
`errorSaving`, the completion callback, and cleanup. It reserves ownership
before the first asynchronous turn; duplicate submits, including a caller that
can observe only an existing `saving=true`, cannot persist or clear another
operation's lock.

## Immutable component coordinates

- Web Console `1.6.122`, commit
  `fac6b1f90adf8f6524f6f0745a7f54605cfa6071`, release artifact SHA-256
  `c50ace84d94575c7869dd2c01ff9e741d3ebd54a656ec23d5a94dfeda6e79dba`.
- Authentication Service remains `v0.4.41`, commit
  `1e566c8ba00aa134eb119be9d655625c870b28bc`, release archive SHA-256
  `2980282734e4d87bd92e73b8acef1dfa166df877e504e049c3556b13f66632bd`,
  and extracted binary SHA-256
  `3edeaca6715b2e4096aa0de641ea9b6f2f558a5077b5d533de58076dbea9f35b`.
- Orchestration Engine remains `v0.183.309`, commit
  `64b94f2a5c74ebf4ca3fa3737717ac02315d1565`, artifact SHA-256
  `f0feb5285146fd7b1f9f2cc4180913c8983dbc8a0edbc996972bec880eb97dfc`.
- Catalog Templates remain pinned to commit
  `e082033ba3c12b5f5cfcae93ff1d6f50d5440d07` (`v0.3.12`).

## Verification boundary

The clean Node 24 Web Console release job runs 518 browser tests with zero
failures. Deterministic cases cover fulfilled, rejected, synchronously thrown,
plain-value and thenable adapter inputs; callback exceptions; concurrent and
dependent `async.auto` tasks; each synchronous and asynchronous save-hook
failure; error and completion callbacks; cleanup exceptions; owner-only lock
release; environment view/edit/save/cancel; load-balancer edit/save; settings
loading; and authenticated initialization. The asynchronous-source audit
reports zero High and zero Medium findings, and its focused reproduction proves
that callback exceptions are preserved while synchronous throws and thenables
settle once. The release candidate is built twice byte-identically, contains
all expected locale assets, and contains no source maps.

Runtime acceptance compares the same environment route before and after the
upgrade. v1.6.449 must reproduce the masked `Callback was already called.`
failure even while project, network, and policy-manager APIs return HTTP 200.
After the upgrade, environment view and edit must settle within five seconds;
project member, network, and policy-manager loading must complete; saving must
survive a reload; cancellation must not write; and the temporary QA description
must be restored. Console and network evidence must contain no callback error,
`Loading Error`, unhandled rejection, permanent saving state, or failed request.
TOTP, virtual-authenticator Passkey, Authentik OIDC, cross-tab adoption, expired
session convergence, manual refresh, WebSocket access, and generation-bound
explicit logout remain regression gates.

The Server publication pipeline rebuilds the complete image, compares layered
and flattened configuration, publishes one rootfs layer, starts and restarts
the candidate with fresh volumes, validates Host API SHA-256 chains, generates
a CycloneDX SBOM, and scans the merged root filesystem. Applicable Critical or
High findings, available but unapplied fixes, secrets, component identity drift,
or an unregistered vendor finding fail publication. Existing Ubuntu 26.04
Medium and Low findings without an installable vendor fix remain recorded in
the expiring vendor-pending register.

## Upgrade and rollback

Upgrade from v1.6.449 by changing only the image tag to `v1.6.450`. Preserve
all environment variables, named volumes, restart policy, AppArmor policy,
HTTPS origin, OIDC settings, performance settings, and selected firewall
backend. No database migration is introduced.

Roll back by stopping v1.6.450 and starting the preserved v1.6.449 image with
the same configuration and volumes. Production `stack.ascdc.tw`, its HAProxy
configuration, Authentication Service configuration, OIDC provider settings,
and runtime-patched files are outside this release procedure.
