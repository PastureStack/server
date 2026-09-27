# Server v1.6.482 source candidate

This candidate assembles Web Console `1.6.147` with the unchanged
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
passed independently at that source commit; the full Server source gate suite,
image gates, publication, and isolated `8080` browser acceptance have not yet been
performed for this candidate. Isolated QA must use fresh, directly adopted
Stack, Service, and Container IDs, then confirm Service Edit Cancel, an exact
three-field Save with a single injected failure and retry, and same-page
Service Remove Cancel/Confirm. The bounded run also confirms Container Remove
and restores its owned fixture without deleting baseline resources. A source
or archive check alone is not evidence that these UI writes succeed on a
deployed Server. Production deployment is outside this candidate.
