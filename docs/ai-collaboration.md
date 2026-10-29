# Optional AI collaboration

Server v1.6.554 combines Web Console 1.6.196 and Engine 0.183.355. The supported
tools are `find_stacks`, `find_services`, `get_service`,
`update_service_description`, `preview_service_upgrade`,
`apply_service_upgrade` and `get_operation`. Other platform operations remain
available through the normal UI/API, not through a generic AI proxy.

## Activation

Append the following properties to the deployment's existing `JAVA_OPTS`,
preserving its other arguments, and recreate only the Server container with
the same volumes, network, restart policy and security settings:

```text
-Dapi.ai.service.upgrade.enabled=true -Dapi.ai.bridge.enabled=true
```

The first property enables the upgrade-plan API. The second permits dedicated
AI bridge Keys. Both default to false. Disabling the bridge does not remove
ordinary account/API Key permissions or alter an ordinary service API.

The supplied Web Console supports the enabled build profile but starts each
new page with native browser tools off. Use the header's AI collaboration panel
to select read-only or enabled mode. Native browser support requires a secure
context and feature detection; unsupported browsers can still review plans and
use the optional stdio client. Do not disable browser security or install a
polyfill to force native support.

For custom Web Console builds, `WEBMCP_MODE` is the build capability ceiling,
not the initial user setting. An off build does not register browser tools.
The release archive records the ceiling and initial mode in `webmcp-build.json`.

## Scoped clients and approval

Create an **AI collaboration bridge** Key in the existing Key editor. Start
from full access or deny-by-default and choose permitted resources and
operations by name. Its maximum authority is always the owner's current role
and membership. To bootstrap a scoped client, grant read on the selected
environment resource as well as the intended stack/service operations; an
environment-resource rule does not grant all its child stacks.

Install the standalone bridge source archive and configure the client as
described in the [bridge guide](https://github.com/PastureStack/web-console/blob/main/bridge/README.md).
Keep the credential file local to that client. The bridge accepts HTTPS, with
an HTTP exception only for loopback development connections. It does not take
browser cookies, general-purpose Keys, arbitrary URLs or an approval command.

The client finds a named service and previews the target image. The Key owner
reviews the target and changes in the normal authenticated UI, then explicitly
approves. The client applies that plan and reads the same operation until
`verifiedResult=true`. Approval expires; changed targets, policy revisions,
revocation or lost permissions require a new valid decision. An uncertain
response is not permission to submit another upgrade.

Description updates use the captured expected description and preserve the
other service settings. A conflict requires reading the current value again.
Do not automatically retry an uncertain write.

## Audit and disabling

Per-Key audit distinguishes the server's authorization decision, the HTTP
result and the later operation result. Client-reported tool events are labelled
separately; an ALLOW decision or accepted request is not proof of completion.
Credentials, OTPs and description contents are not tool audit payloads.

To stop native tools, select off in the panel. Before disabling the backend or
downgrading, let accepted operations reach a terminal state, cancel unused
plans, and revoke the dedicated bridge Keys. Stop local bridge processes and
remove their private credential files when no longer needed. Retain the normal
database/volume backup and previous Server image. Follow the
[API Key rollback guide](upgrades/api-key-policy-rollback.md); do not assume an
older Engine understands a newer Key policy or restore an older database while
clients continue sending requests.
