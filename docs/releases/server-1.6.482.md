# Server v1.6.482

This release assembles Web Console `1.6.147` with the unchanged
Orchestration Engine `v0.183.326` on the Server `v1.6.460` runtime base. All
other component coordinates remain those of published Server `v1.6.481`.

Web Console Service Edit still validates its cloned form model, but its PUT now
contains only the editable `name`, `description`, and `scale`. It no longer
sends a cloned launch configuration or upgrade strategy. The scale form keeps
an initial scale of zero; an edit-mode quick selection updates the model
immediately, and the separate quick-scale action submits only `scale` after
its debounce. These are browser write-payload changes, not changes to the
Server API, authorization, schema, or stored-resource contract.

The unchanged Orchestration Engine input is commit
`66160dfc1d9d134d1c9c85b4f2908c3f07f99365`, with `cattle.jar` SHA-256
`6427120ef0047deb0c436a5cd9167a9afb3a2fb3075123b50340ec1216a5fe81`.
The [Web Console 1.6.147 release](https://github.com/PastureStack/web-console/releases/tag/1.6.147)
is signed source commit `26090af4366a0843b09c1ff5c91373f7a1be816e`.
Its release archive `web-console-1.6.147.tar.gz` has SHA-256
`3f4c3228cb0b406f7d87b8e5e0896ebdc8b16345183e96bcf54cae92a5fc4c49`,
and the package declares `VERSION.txt=1.6.147`.

The [Web Console source validation](https://github.com/PastureStack/web-console/actions/runs/36359419974)
passed independently at that source commit. The
[Server publication run](https://github.com/PastureStack/server/actions/runs/36360601680)
passed and published Server source `3d909952d31e8577793acb7e402e10b883e1c8a6`
as `ghcr.io/pasturestack/server@sha256:e3ac65290f17981201a6cf2857e0f6def3eb79974746bc7110357fd87869a609`
(numeric tag `v1.6.482`). Its isolated publication candidate returned
`HTTP 200` / `pong` before and after restart.

The separate isolated `8080` QA deployment of `v1.6.482` is healthy on first
start and after restart, displays Web Console `1.6.147`, and retains the
previous stopped rollback container. A fresh, directly adopted Stack, Service,
and Container owner-browser run passed Service Edit Cancel and Save with one
injected `503` error and successful retry, plus same-page Container and Service
Remove Cancel/Confirm. It observed two successful Service PUTs, a
`setservicelinks` POST returning the injected `503` then `200`, and one `200`
DELETE each for the owned Container and Service. The run recorded no page
errors or route boundary failures and restored its baseline with no cleanup
remaining. Workspace-local evidence is at
`.qa-evidence/write-ui-supplement-v1.6.482/20260928T001857Z-f80439/result.json`
and the adjacent `supplement-browser.json`. This bounded owner-browser result
does not establish the six-role permission matrix or production readiness.
