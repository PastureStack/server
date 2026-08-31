# PastureStack Server v1.6.387

Server v1.6.387 embeds Web Console `1.6.90` and fixes the Host details live
statistics charts without changing the surrounding Host page layout.

## Operator-visible result

- CPU, memory, network, and storage use the same fixed data series and palette
  during initial rendering and subsequent live updates.
- Dense area charts no longer create per-sample point nodes, avoiding the
  Billboard update failure that left all four charts blank.
- Chart-specific Host and tooltip styles now target Billboard's current SVG
  class names instead of retired C3 selectors.
- The CPU system color matches the visible legend, and CPU and memory axes use
  the Host's actual capacity from the first render.
- Host status, container rows, navigation, and unrelated pages remain unchanged.

## Verification

- Web Console QUnit: `376/376` passed, including a real Billboard redraw test.
- Web Console validation run: `33360058020`; source gates, browser tests, and
  two byte-identical production builds passed on Node.js `24.20.0`.
- The Web Console release archive was verified at SHA-256
  `7a7c85b1f2da49f1d7648588e204a341ef245fb5933b07b996634e46a35532cb`.

## Bound release inputs

- Web Console: `1.6.90`
- Web Console source: `476f5b7f9418c3d237e6cb237cfd11c1f2aad3a2`
- Web Console release: <https://github.com/PastureStack/web-console/releases/tag/1.6.90>
- Docker Engine support: `>=v29.4.1 <=v29.7.2`, including `v29.6.2`

This release retains Ember `7.2`, Bootstrap `5.3.8`, Go `1.27.0`, OpenSSL
`3.5.8`, zlib `1.3.2`, the current OpenVEX closure, and the existing runtime
hardening.

The image retains the reviewed GNU coreutils fix commit
`d64e35a8a4c0e4608321433e0d84d917e4e36371`, the OpenSSL closure for
`CVE-2026-75803`, and removal of the unreachable `diff3` path for
`CVE-2026-53910`.

The Server publish workflow performs the merged-rootfs vulnerability scan,
SBOM, restart smoke, provenance, and immutable release. Any unmatched vulnerability at any severity remains a release blocker.
