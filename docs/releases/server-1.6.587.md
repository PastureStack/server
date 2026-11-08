# Server v1.6.587 candidate

Prepared source only; no Server image or release has been published. No Server587 build has run.
Server build, publication, deployment and affected native/UI workflows remain
pending. Web Console229 / Bridge031 immutable release 438112925 has been
reported published by the release owner, but final anonymous-byte and
cryptographic verification remain pending. The normal local prepared metadata
supplies the pins below; it does not substitute for those publication checks.
Do not assemble or publish until the release owner supplies their exact results.

## Verified component inputs

Engine `v0.183.388` is unchanged from published Server586: producer
`09b12c0f0e5488fc8d25b3a58a228bec4e0c7da8`, JAR SHA256
`2ad513ed2003c10723779cfb85d5b80276f742430a9605ad82e430ac73294bbb`.
Its existing qualified release evidence remains separate from Server acceptance.

Web Console `1.6.229` / optional Bridge `0.2.31` uses producer
`feb75265ca36e1cc683924113a8106129ebbc5e3`, tested tree
`9dc98cf030e2b5741333d961868847036112ebd6` and tag merge
`ff1a0de2aa08ce3b4c5a01d4a8cf3c946d6854cc`. The source input is Web archive SHA256
`d20d4df444a6b9268c9e55918b9922f3857a77e670486c9142c831d21eacce4d`,
lock SHA256 `a9a96e5b38281ed8c5ea8646e203d07fc8c243c18d5f2a4703ab2edbce33c889`
and runtime SBOM SHA256
`f9a3709c6429b45a91e5a5f60d16d4a69668eeed79260dc8eafffd5d475e3775`.
Optional Bridge archive SHA256 is
`95f466ae9d3113969038859da29cd80e4340c5924803d05c8a620664484ff2b8`;
it is a separately installed client and is not added to the Server component set.

Browser environment selection uses names and opaque references, preview and
human confirmation. Switching context is browser-only; setting the default
awaits the account preference save and readback. Actor/session/generation and
review ownership changes reject stale results. Model apply remains needs_user;
the fixed-profile Bridge directs the human to the Browser instead of changing
identity. These actions do not create native processes or workload proof.

Host API `0.38.9`, Go Node Agent `0.13.35`, bootstrap Agent `1.2.34` and all
other components are unchanged. Native roles/Key limits, twelve tools, four
independent default-off settings, multistage/flatten assembly, exact SHA fetch,
crypto/security gates and runtime defaults remain. The same component fetcher
continues checking archive, manifest, source, lock and runtime SBOM identities.

Server deployment and affected native/UI workflows remain pending. Component
publication does not establish complete frontend coverage. Preserve all three
named volumes, configuration, origin, performance settings, restart policy,
AppArmor and firewall behavior, and keep the prior image and matching backup.
Use only the numeric tag `ghcr.io/pasturestack/server:v1.6.587` after publication.
