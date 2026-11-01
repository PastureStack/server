# Server v1.6.563 candidate

Source candidate; not a published image. The published component bytes below
are qualified independently. Server image publication and matching runtime QA
remain pending; installation instructions stay on published Server562.

## Corrected workflows

Engine364 repairs native CUSTOM-Key standalone container DELETE cleanup through
its exact private OS-image/cache graph, retaining current owner/role/Key checks,
explicit DENY and verified native execution frames. It also classifies a removed
or different exact External hostname target as stale so normal map cleanup can
finish hostname-to-IP and hostname replacement. These are substantive native
behavior fixes; unchanged HTTP classification is not zero authorization change.
The previously corrected External before-value previews, ServiceIndex cleanup,
JDBC3.5.11, Web203 restricted-Key selector, sanitized human 403 guidance and
confirmation-footer layout remain inherited. Bridge0.2.5 stays unchanged.

## Verified component inputs

- Engine v0.183.364: producer `e780d1613ab2a14112ba9e14fa55754b4e16ed0b`; tag source `04f5db394efd1ad9bc39b0193be94ac8b7746fd6`; tested tree `5c73690c54218d3537a06a641a0e38bb944a4689`.
- Original cattle.jar SHA256 `279ae58c5ec0189df09e57fb9a9014b633a5323c884d49e63036046c6f8b15bb` (88235150 bytes); runtime SBOM `0eeae6ab2ccbc87672473005b987b63431447a4a2c9283e685a00e9c398e27eb`.
- Original Security run 41283488278 attempt 1; CodeQL 41283488281 / 41283492244; 3872 tests in 416 suites, zero failure/error, 1 existing skip(s).
- Actual new methods: 14, including six private cleanup and eight External lifecycle methods; seven preview and eight Index cleanup methods are inherited, not new tests.
- Operation contract: 432 inputs / 1396 HTTP tuples / 1397 projection rows; source fingerprint `169fe350bed9358c2d9cbdac24f75c8636258325f2a92305507ad06e79c993e1`. HTTP tuples/classification and historical producer355/review chains are preserved; derived cleanup authorization changes substantively.
- Packaged official JDBC3.5.11 SHA256 `42604178b9e57ec08ee0035079961516f086e455d0141f0b22c6eff29fb2fff4`; all four reported JDBC CVEs remain absent from original product and raw/effective scanner reports, including ignored entries. No new exception is added.
- Unchanged Web 1.6.203 / bridge 0.2.5: producer `d97a8990801a281b519573a48b0db7dd12c9a616`; tag source `ae409b8404e946512297f00a71bdb4c141a3d5eb`; tested tree `6fff4d815fa34edc0287626e2ab83990fbc3a061`.
- Web archive SHA256 `81e2e81becb2a006f0a753d781d7ec0383a908081c10864f451e8372b246b59d`; lock SHA256 `a0dfad456f43949e8c7c707197a0d73c2bb54b1a2a6d0ce763db1e3be7038452`; runtime SBOM `a34c07e7c6289a72174ddf5be4e83d1ccc8db0ad5fea07264f0b623eb77f013e`.
- Optional bridge ZIP SHA256 `cafe59ca00122dfaf9534f65f2cbd96500e6c014f4819dd8c49fd3cd4fa23b93`. All 12 Engine and 13 Web assets passed anonymous SHA readback against fresh metadata bytes.
- Engine provenance is original GitHub artifact/source/tree evidence; no native Engine SLSA attestation is inferred.

Catalog0.20.17 / Compose0.14.40, other component/package pins, base image,
VEX statements and vendor entries are retained. This source change does not
rebuild components. The original Server publisher must pass source, build,
restart, merged-image/browser scan and native attestation gates. Matching Core,
External/Alias, role/Key/cross-ID, cleanup and designated business workflows
remain separate pending gates. The four AI opt-ins remain independently
default-off. These component results are not complete frontend acceptance.
