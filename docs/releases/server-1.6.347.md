# PastureStack Server v1.6.347

Server v1.6.347 makes host-port preflight network-mode aware when a create or
upgrade explicitly selects a target host. It also retains the verified host
storage pagination and per-success bulk-removal refresh from v1.6.346.

## Runtime components

- Orchestration Engine: `0.183.277`
- Orchestration Engine source: `1e913c88f42c9d4bc43bca94a8bff2ff0cb6b03a`
- Orchestration Engine artifact SHA-256:
  `d71c27a0f7a0686154629467d096b456636ac4d55e2eacecae52c420fdf390cb`
- Node Agent: `0.13.22`
- Web Console: `1.6.56-pasturestack.58`
- Web Console source: `d04c28add200c179298655d4e0b89cbccb8e100d`
- Web Console artifact SHA-256:
  `c6857389bd3c89ec34b29265c62e18dc720d3e088d09495f1bd30dee0f9d7068`

## Corrected behavior

Managed networking checks every eligible host in the environment even when a
specific target host is selected. An active owner on any host blocks the
requested port. Bridge and host networking remain scoped to the selected host,
so reuse on another host does not create a false conflict. Stopped owners stay
visible as warnings. Runtime host inspection follows the same network scope.

The Web Console uses matching language for an owner on another host and keeps
the complete accessible conflict context. The host storage table keeps page
size interaction in internal writable state; `10`, `25`, `50`, and `All` do not
write through a caller-owned computed property. Each successful selected-volume
removal immediately updates rows, pagination, selected count, and controls;
failed rows remain visible.

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.
