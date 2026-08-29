# PastureStack Server v1.6.375

Server v1.6.375 embeds Web Console `1.6.78` and repairs the production login
experience without changing authenticated tables or application pages.

## Operator-visible result

- The submit button spans the login form and is centered instead of appearing
  as a small left-aligned control.
- The language selector is integrated into the login card and its menu follows
  the same visual system without the previous disconnected double-arrow look.
- The password field has an accessible show/hide control so exact credentials
  can be checked before submission.
- Login and locale initialization remain compatible with Ember Intl 9.

## Bound release inputs

- Web Console: `1.6.78`
- Web Console source: `9eeb4e6cdf9c66113483b1f5a6cc342e3acbfa9e`
- Web Console archive SHA-256: `00430933b0f0f1ae259510b6e2f0999972c6d5bfa3de6e80ce968ba6d3c5140f`
- Web Console validation run: `33232849960`
- Web Console browser tests: `357` passed, `0` failed
- Docker Engine support: `>=v29.4.1 <=v29.7.2`, including `v29.6.2`

The image retains the reviewed GNU coreutils fix commit
`d64e35a8a4c0e4608321433e0d84d917e4e36371`, the OpenSSL closure for
`CVE-2026-75803`, and removal of the unreachable `diff3` path for
`CVE-2026-53910`.

The Server publish workflow verifies the embedded Web Console archive, runs
start and restart smoke tests, scans the merged root filesystem, generates an
SBOM and provenance, pushes the immutable image, and creates the matching
immutable release. Any unresolved vulnerability remains a release blocker.
