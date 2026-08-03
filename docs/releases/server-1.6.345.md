# PastureStack Server v1.6.345

Server v1.6.345 supersedes v1.6.344 after formal acceptance found that the
new project `portpreflight` action was present but its nested input and result
schemas were filtered out of project-scoped API schemas.

## Runtime components

- Orchestration Engine: `0.183.275`
- Orchestration Engine source: `ebec367ba740652e1d93a8ad9dbc68ea255c58e2`
- Orchestration Engine artifact SHA-256:
  `c270547c11a63787a690973b37f0cf3c0d22f49940279bd2f055bbf8e590c0d5`
- Node Agent: `0.13.22`
- Web Console: `1.6.56-pasturestack.56`
- Web Console source: `0ed6f5ea8bf96122045ee979f83c44461a4a204a`
- Web Console artifact SHA-256:
  `ed46edb896afc2ac2d5dd887d42bc594e16fad12ca986a7967ef5d5be6160a43`

## Corrected behavior

Project-scoped users can now call the authoritative host-port preflight
action. Its request schemas are create/read, its result schemas are read-only,
and every request and response field remains explicitly authorized. Existing
resource ownership validation and final server-side conflict enforcement are
unchanged.

The Engine regression test loads the shipped user and project authorization
overlays. Server assembly also inspects the packaged authorization files, and
the built-image gate repeats those checks against the installed runtime.

Host storage `All` pagination, page clamping, and immediate successful-removal
refresh remain included from Web Console `1.6.56-pasturestack.56`.

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.
