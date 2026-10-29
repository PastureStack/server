# Optional AI collaboration

Server v1.6.556 combines Web Console 1.6.199 and Engine 0.183.356. The twelve
supported tools are `list_capabilities`, `find_resources`, `get_resource`,
`preview_resource_change`, `apply_resource_change`, `find_stacks`,
`find_services`, `get_service`, `update_service_description`,
`preview_service_upgrade`, `apply_service_upgrade` and `get_operation`.
The capability response distinguishes safe metadata, partial coverage and
pending adapters. This is not complete WebMCP coverage of the console.
Other platform operations retain their ordinary UI/API paths.

## Activation

Append the following properties to the deployment's existing `JAVA_OPTS`,
preserving its other arguments, and recreate only the Server container with
the same volumes, network, restart policy and security settings:

```text
-Dapi.ai.service.upgrade.enabled=true -Dapi.ai.bridge.enabled=true -Dapi.ai.resource.change.enabled=true
```

The first property enables upgrade plans, the second permits dedicated bridge
Keys, and the third enables typed resource-change plans. Each defaults to false.
Disabling a bridge feature does not remove ordinary account/API Key permissions
or alter an ordinary resource API.

## Supported resource flows

Find visible resources by family and name, select an unambiguous parent when
names repeat, and use the returned scoped reference for details or a preview.
The user does not need to enter environment, Stack or Service IDs. Metadata
projection excludes credential values, private keys, full configurations and
raw process logs. Selected families remain partial and are labelled as such.

Typed plans support basic creation and metadata editing for Stack, Service and
Container resources; Stack/Service start and stop; Service/Container restart;
manual scaling of eligible non-global Services; and removal of those three resource types. Creates currently
cover name, description, image, scale where applicable, command and entry point.
They create stopped workloads. Advanced environment, port, mount, hardware,
security and other UI form fields require subsequent adapters.

The normal human review shows the exact typed changes and mounted-data rules.
Stopping or removing a workload does not mean every external data directory is
backed up or retained. Review the existing domain's removal behavior before
approval. These plans do not add an extra purge of external storage.

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

The client previews a typed resource change or image upgrade. The Key owner
reviews its target and changes in the normal authenticated UI, then explicitly
approves. The client applies that plan and reads the same operation until
`verifiedResult=true`. Approval expires; changed targets, policy revisions,
revocation or lost permissions require a new valid decision. An uncertain
response is not permission to submit another operation.

An accepted request is not verified completion. Resource plans check the actual
managed instances, desired scale, sidekicks and eligible global hosts, including
retired-instance cleanup. Stack start/stop checks its child services. The human
inbox can cancel pending or approved-but-unsubmitted plans; closing the review
dialog does not cancel a plan. Submitted operations cannot be cancelled there.

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
