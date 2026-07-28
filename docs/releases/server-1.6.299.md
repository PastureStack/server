# PastureStack Server v1.6.299

PastureStack Server `v1.6.299` adds a persistent browser console workspace for
terminal, log, and virtual machine console access.

## Runtime changes

- Embeds Web Console release `v1.6.56-pasturestack.11`.
- Opens container terminals, container logs, and virtual machine consoles in
  movable, resizable, minimizable, and maximizable windows.
- Keeps terminal and log sessions active when a browser tab is refreshed,
  minimized, closed, or reopened.
- Lists the same active sessions across signed-in tabs while retaining an
  independent window layout in each tab.
- Replays retained output to reconnected tabs and synchronizes live output to
  every attached tab.
- Assigns terminal input to one tab at a time and provides an explicit control
  handoff action.
- Replaces the embedded Kubernetes and Swarm command-line panels with launch
  actions that use the same managed workspace.
- Keeps terminal access tokens in memory only. Browser persistence stores a
  random session identifier and session secret under the current application
  origin; upstream access tokens are never persisted. Session secrets are sent
  in WebSocket subprotocol headers instead of request URLs.
- Limits the broker to 24 concurrent sessions, 2 MiB of replay data per
  session, 4 MiB upstream frames, a 72-hour idle lifetime, and 24-hour ended
  session history.
- Runs the broker as the existing unprivileged `cattle` account and retains the
  authenticated edge proxy in front of all application and session traffic.
- Keeps all operational image coordinates on semantic version tags without
  image digests.

The complete 13-locale message contract includes the new workspace. Taiwan
Traditional Chinese uses terms such as `終端機`, `工作階段`, `接手操作`, and
`重新連線`.

## Image

```text
ghcr.io/pasturestack/server:v1.6.299
```

## Rollback

Stop the `v1.6.299` container and restore the exact stopped `v1.6.297`
container with the same server data volumes. Retain both the prior image and
stopped container until live acceptance is complete.

## Attribution

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.

This release preserves the upstream history, licenses, notices, and third-party
attribution. PastureStack claims authorship only for its own changes.
