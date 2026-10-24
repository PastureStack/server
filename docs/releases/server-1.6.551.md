# Server v1.6.551 candidate

Not published.

## Verified component inputs

This release retains the PCRE2 security backports and all component inputs from
550, including Web Console 1.6.195, Engine v0.183.354 and Host API 0.38.8.
No application behavior or database migration is introduced.

The manual completion of 550 accidentally replaced its standalone Host API
Release attachment with an empty gzip stream while converting an empty browser
findings table. The image itself contains the correct producer archive. Do not
use the 550 Host API attachment; the original official Host API 0.38.8 release
remains valid. The faulty immutable attachment is retained as evidence.

The normal publisher now checks the exact producer archive SHA-256 again after
report conversion and before upload. Its regression test rejects an empty gzip
substitution even though that stream is syntactically valid. All downloadable
archive bytes must match the producer pin; a self-consistent checksum manifest
alone does not establish that identity.

## Acceptance and remaining risk

Only the release-asset guards and version metadata changed. Original unaffected
PCRE2 native, consumer, UI and authorization evidence is retained. Normal release
source, image/security, startup/restart and exact attachment checks still apply.
8080 deployment and attachment readback are separate acceptance steps. No
production site, HAProxy, firewall or production database is modified.

The prior scan retains 13 pending LOW/MEDIUM occurrences across 10 CVEs. Other
product candidates and the Ruby/Onigmo build-host coverage gap remain tracked;
this release does not claim they have been remediated.

## Upgrade and rollback

Use the new numeric tag after publication and preserve existing configuration,
named volumes, restart policy and security options. Keep the prior image and
matching backup for rollback. Do not patch running containers or overwrite tags.
