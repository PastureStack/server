# Windows agent status

PastureStack does not currently build or publish a Windows agent image.

The inherited build depended on an end-of-life Windows base image and remote
helper binaries that have not passed the PastureStack provenance and integrity
review. The build remains disabled. Re-enabling it requires all of the following:

- a supported Windows base image;
- source-controlled helper binaries or pinned downloads with verified hashes;
- build, registration, upgrade, rollback, and cross-host networking tests;
- an explicit license and redistribution review for every bundled artifact.

The maintained scope is Linux server and node-agent compatibility. This notice
does not claim support for historical Windows deployments.
