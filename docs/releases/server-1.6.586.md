# Server v1.6.586

Published image: `ghcr.io/pasturestack/server:v1.6.586@sha256:8c5f2e3a15bb6f3b3720b835a50ed6a8c34b03c2ced71e8aa27a2bf5b059fd52`.

Source commit: `6ffef66fda7190fe59cefd18224a6621b2a558cf`.

The release workflow passed its source, security, startup and restart checks before publishing this image. Deployment-specific acceptance is separate and is not claimed by these build results.

## Verified component inputs

Engine v0.183.388 is published as immutable release 438056242. Original
workflow 42450335938 passed 4,306 tests in 483 suites, with zero failures or
errors and one inherited skip. All 492 required methods and 89 packaged class
roots passed. Producer `09b12c0f0e5488fc8d25b3a58a228bec4e0c7da8` supplies
JAR SHA256 `2ad513ed2003c10723779cfb85d5b80276f742430a9605ad82e430ac73294bbb`.

Web Console 1.6.228 / Bridge 0.2.30 is published as immutable release 438057610.
Original workflow 42444938289 passed 332 distinct focused methods (326 carried,
six new) and 1,144 browser cases. The packaged Bridge passed one SDK 1.32.2
handshake, with zero failures. Producer `67611b6b9e90064952651ff368062a68933526f2`
supplies Web archive SHA256 `acf0f4c33f92b12316537cf08e189090bf297c06f10a3aab84fce6be7c2c2715`.
Original release and anonymous-byte evidence covers twelve Engine assets and
thirteen Web assets. These are component results, separate from Server acceptance.
Host API 0.38.9, Go Node Agent 0.13.35 and bootstrap Agent 1.2.34 are unchanged.

Host activate/deactivate changes native scheduling availability through preview
and human confirmation. It does not stop workloads, remove Hosts or evacuate VMs.
Cookie lifecycle verification must prove the exact operation's native processes
as well as existing readiness, endpoints, configuration and retirement checks.
Failed or uncertain operations stay visible; retry requires inspecting state and
obtaining a fresh human-reviewed plan. No automatic resubmission is introduced.

Existing Key/role ceilings, twelve tools, independent default-off flags,
multistage build and flatten pipeline, package pins and security scope remain.
Server deployment and affected native/UI workflows remain pending. Component publication does not establish complete frontend coverage.
Preserve named volumes, configuration, origin, performance settings, restart
policy, AppArmor and firewall behavior; retain the prior image and database backup.

Use only the numeric tag `ghcr.io/pasturestack/server:v1.6.586` after publication.
