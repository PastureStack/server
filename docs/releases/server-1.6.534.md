# Server v1.6.534 candidate

This candidate packages the new immutable Web Console `1.6.189` RTL
host-onboarding step alignment repair. The step circle and timeline now follow
their number on the right in RTL output, using the existing RTL compiler.
LTR geometry, SVGs, copy controls, tooltip lifecycle and API behavior are retained.

Server `v1.6.533` and Web `1.6.188` remain immutable published artifacts. Their
52 clipboard combinations and ordinary-HTTP copy passed, but subsequent visual
review found this existing step-background defect. This candidate is a focused
follow-up, not a replacement of those artifacts or a whole-site retest.

Engine remains `v0.183.348`; other component versions, the official Ubuntu curl
security backport, all 69 evidence-backed VEX decisions and the exact 20
vendor-pending MEDIUM findings are retained. See the
[533 release note](server-1.6.533.md) for the security evidence.

Native acceptance will rerun the four RTL combinations and four LTR controls,
plus a separate ordinary-HTTP native copy. The unaffected 44 combinations retain
their immutable 188 evidence. Publication, deployment and the new eight views
remain pending; historical matrix HOLDs and KVM are not promoted to PASS.

No authentication, authorization, database, HAProxy, networking backend, volume
or performance-setting change. Preserve the previous working Server as rollback.
