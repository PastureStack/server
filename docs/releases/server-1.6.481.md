# Server v1.6.481 source candidate

This candidate assembles Web Console `1.6.146` with the unchanged
Orchestration Engine `v0.183.326` on the Server `v1.6.460` runtime base. All
other component coordinates remain those of published Server `v1.6.480`.

The Web Console's shared required-field validation now uses the visible,
translated form label when a model-specific label is absent. The affected
fields are Secret name, description, and value; Certificate name, description,
certificate, and private key; Registry server address; and Registry Credential
username and password. Certificate upload also reports an encrypted private
key with localized feedback. These changes are confined to browser validation
feedback; Server authorization, authentication, API schema, database, and
existing resources are unchanged.

The unchanged Orchestration Engine input is commit
`66160dfc1d9d134d1c9c85b4f2908c3f07f99365`, with `cattle.jar` SHA-256
`6427120ef0047deb0c436a5cd9167a9afb3a2fb3075123b50340ec1216a5fe81`.
The Web Console `1.6.146` source commit is
`97e52e09569681f7452942d0775f0ddac2d5e67e`. Its independently verified
release archive SHA-256 is
`1489c69edfbb531f021ed34aca014bb17d70d8f1a2aacbddc3b3af8b7a317dd6`.

Source and image gates must verify the Web Console package version and the
required label and encrypted-key error keys in all 13 bundled locales.
Separate isolated `8080` QA must compare the complete visible required-field
labels and encrypted-key error in English, Traditional Chinese, and Japanese
on the affected forms. It must also recheck Secret, Certificate, and Registry
Add visibility and direct-route denial for superadministrator, owner, member,
restricted, readonly, and no-access-to-matrix-project roles, plus scoped POST
capabilities and zero unintended writes. Retain the current QA container's
runtime configuration, volumes, and a stopped rollback container; verify
startup and one restart. Neither `v1.6.479` nor the still-pending `v1.6.480`
browser matrix is acceptance evidence for this candidate. Production deployment
to `stack.ascdc.tw` is outside this QA run.
