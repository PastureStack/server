# Server v1.6.590 candidate

## Candidate boundary

Not published. Normal Server source checks, image qualification and publication
must complete before this candidate can replace Server v1.6.589.

## Verified component inputs

Packages published Engine **0.183.391**, Web Console **1.6.233** / optional
Bridge **0.2.35**, and unchanged Compose **0.14.44**. Web release 438567858
passed thirteen anonymous asset checks and fourteen cryptographic subjects.
Producer `ce0f6c05b272b77b21819bc08e418f1ad41ca691` and tag target
`6c132677ba7ff609b0a533483b0143df6d325060` share tested tree
`870fdbff071ef61f15352768cf0c22c03140f810`. Original CI passed 374 specified
methods and 1,149 browser tests; Bridge 0.2.35 passed its own packaged SDK
handshake. Archive SHA256:
`73146283c973c8c04bf3c444ac7e822993e584ab20d0f80460b3cd6a07d4f0f7`.

The Bridge accepts the native GDAPI `aiResourceView` envelope without mistaking
its metadata for business fields. Metadata URLs and actions are checked and
discarded; the four-field identity DTO, UUID pins, exact child authorization,
explicit parent denial and default-deny Key boundaries remain intact.

Engine 391, Compose 0.14.44, JDK, other component pins and the thirteen tracked
runtime MEDIUM findings without an official fix are unchanged from Server589.
Only the VEX document identifier changes; no statement or security threshold
is relaxed. SHA256, original artifact, signed-source and release verification
requirements remain unchanged.

Deployment and affected native/UI acceptance remain pending. Preserve the
qualified Server589 rollback, existing mounts, volumes and operator settings;
component qualifications do not establish complete workflow acceptance.
