# Server v1.6.601

Published image: `ghcr.io/pasturestack/server:v1.6.601@sha256:c512538a5ae41f7c684fd718be2ddbee0bf83e17fb504cb6e33cea5d6788ea1f`.

Source commit: `71f2d29ff1f2ce1c83867141bdabef18beddaab8`.

The release workflow passed its source, security, startup and restart checks before publishing this image. Deployment-specific acceptance is separate and is not claimed by these build results.

## Verified component inputs

The host provisioner retires verified registrations created by its legacy
service name through the platform lifecycle API. The current subscriber
handles pending built-in machine-driver activation work.

The EC2 wizard accepts the generated driver schema when the optional tags
field has no default. AWS operations still require an authorized AWS account.

See the [upgrade guide](../upgrades/README.md) for volume preservation and
rollback.
