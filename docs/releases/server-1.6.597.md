# Server v1.6.597

Published image: `ghcr.io/pasturestack/server:v1.6.597@sha256:09a9c7741b3dca23e228de32b146c7f4f2878b1e65489bf9c3f13ba7e7089636`.

Source commit: `e250a0fdc519ed874dea90bac6b12f599818efb0`.

The release workflow passed its source, security, startup and restart checks before publishing this image. Deployment-specific acceptance is separate and is not claimed by these build results.

## Verified component inputs

This patch packages Web Console 1.6.236 with Engine v0.183.395, optional Bridge 0.2.37 and Compose 0.14.45.

Shared dialogs stay above the floating Shell and Log workspace. API key preview and cancellation remain accessible when the dock overlaps the dialog. Closing the dialog returns access to the dock.
