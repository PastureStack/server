# TLS termination

Terminate TLS at a reviewed reverse proxy or configure the server with explicit
certificate and key paths. Keep private keys outside the repository and image.
Validate secure redirects, WebSocket upgrades, API subscriptions, certificate
rotation, and rollback before production use.

When the reverse proxy terminates HTTPS and forwards plain HTTP to the Server,
set the exact public origin on the Server container:

```yaml
environment:
  PROXY_PLATFORM_PUBLIC_ORIGIN: https://stack.example.com
```

The value must be only `scheme://host[:port]`; credentials, paths, queries,
and fragments are rejected. The public origin is used only when the incoming
Host matches that configured authority. Continue forwarding the original Host
and support WebSocket upgrades at the outer proxy.

After deployment, verify that `/v2-beta/schemas` returns an HTTPS
`X-Api-Schemas` absolute URL through the public hostname, and that
authentication/private API responses include `Cache-Control: private,
no-store`. A successful HTTP probe does not replace one real browser OIDC and
MFA login against the deployment's identity provider.
