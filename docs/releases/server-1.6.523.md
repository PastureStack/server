# Server v1.6.523

This patch packages Engine `v0.183.341` for the HA database backup repair.
Component tests and final-image acceptance are distinct evidence: the focused
tests below do not claim complete API Key matrix or deployment acceptance.
The README identifies the immutable published release. Deployment-specific
acceptance is recorded separately below and is not inferred from publication.

## Minimal HA database dump repair

Engine `v0.183.341` fixes the native HA database dump using an unrelated
local-root connection and returning an empty SQL ZIP. It uses the configured
database host, port, username and database. SQL is written to a private spool;
a successful child-process exit and nonempty output are required before a ZIP
response is committed. Timeout, interruption and failure clean up owned
temporary resources. Failure responses do not return CLI stderr, SQL or
credential details.

The change is limited to one HA production manager, two direct test families
and four existing source/artifact gate corrections. The gates retain their
assertions and include the actual HA prefix and private-spool entry point;
they are not bypassed or weakened.

Web Console `1.6.183`, all other component pins, Ubuntu package inputs,
runtime configuration and schema overlays remain unchanged. Engine340 native
registration-token Basic authentication, full/legacy project creation,
existing instance/volume lifecycle rules, owner RBAC and API Key authorization
are preserved by identical source and packaged classes, not newly retested.
There is no new database migration, authentication setting or ordinary-user
database-export permission. Separate API Key integration-candidate changes
are not included.

## Released component inputs

Engine `v0.183.341` uses normally merged source
`b245cf778479445ded0786d3898b03fea153212e`, tree
`65cecdc6bc894fb210f4c2ebb8fd7b624936e27c`. Its original-packager `cattle.jar`
is 87868337 bytes with SHA-256
`3ede1ad28b7a7e0754c4c953bd486162f7ffe0b2f76ce384ec485632af6b8e6d`.
The immutable Engine release and both original release assets were
independently read back; this is not a transplanted candidate JAR or WAR.

Web Console remains the released `1.6.183`, source
`e056a0111d20816742eff17a65dfabb5d003dae2`, archive SHA-256
`8540758ad4521f901f53fc79473570cf98862add2addcb49271d8dbf125b4217`.

## Evidence and remaining acceptance

Windows executed 18 focused HA cases successfully. The original POSIX method
was executed separately on Linux and passed; the other 18 were not rerun.
These are 19 actual cases from separate executions. Their source and compiled
production class bytes match the clean original-packager Engine341 artifact.
Normal PR104 HA and PR105 gate-fix checks and signed merges are separately
bound to the final producer. This is component evidence, not final Server HA
runtime acceptance or a complete BE-06/API Key matrix PASS.

At publication, native authorized HA export of a complete SQL ZIP and the
existing readonly/read+export Key rejection checks were still pending.
Those six HA cases subsequently passed as recorded below, with matching audit
context, unchanged protected resources and no export-created jobs.
Candidate66 evidence was not substituted for final-image evidence.
The complete role matrix remains a separate acceptance scope.

Normal Server publication gates remain mandatory: clean source and complete
formal recipe, component bindings, image build and flatten comparison,
startup/restart and existing API checks, final merged-rootfs security/SBOM
policy, provenance, immutable numeric publication and release-asset readback.
Existing vulnerability decisions are unchanged. Eight vendor-pending Medium
findings covering four CVEs retain their 2026-10-20 review deadline; the strict
policy must still pass on the new image.

## Upgrade and rollback

Keep all three named volumes, environment variables, networking, restart
policy and security options; follow the existing backup and rollback guide.
Rollback to `v1.6.522` preserves the released onboarding repair but restores
the known HA dump defect. A successful download response alone is not proof
of a complete database backup.

## Post-publication native HA acceptance

The original publication-stage requirements above are retained. On the final
immutable image, six native HA cases passed: v1 and v2-beta each returned a
complete SQL ZIP for full access and HTTP 403 `KeyScopeDenied` for readonly
and read-plus-export Keys. Twelve exclusive-Key audit events matched their
requests, principals, policy revisions and decision/response phases. Protected
resource snapshots matched at three observation points; no export-created or
pending jobs remained. The test container and its three temporary volumes
were removed, preserving existing resources. This verifies the HA repair,
not the remaining sensitive export paths or the complete role matrix.

The image producer is `d20b39b896631b7e7e384ed9c60dc29080679f67` and publication
run `38287883898` passed the original mandatory gates. The single-layer
linux/amd64 manifest is
`sha256:ba9eddbdaa2d7b10c402f59f767de9b5728e48e69d07120c12d9e630c2d2d57a`;
the distinct configuration digest is
`sha256:02a25d1bd58e1ab4e7b8f7986bd0b7eb61e2c5c08a1034ebbae9209f5d4bfdec`.
Native HA evidence SHA-256:
`5c3769956bc249cc348ec14a051e55d05ef5ee31ec0ea1985f921434bc9852e8`.
