# Server v1.6.595: newly observed vendor-pending findings

The original final-rootfs scan in publication run 42810633061 found five additional
Medium package occurrences. The previous 23 remain unchanged. This registration
does not suppress findings, claim a remediation, change VEX, or alter the gate.

| CVE | Exact installed package | Resolute status |
| --- | --- | --- |
| CVE-2026-93990 | libexpat1 2.7.4-1ubuntu0.2 | Needs evaluation; no released fixed version |
| CVE-2026-9538 | libperl5.40, perl, perl-base, perl-modules-5.40 5.40.1-7ubuntu0.3 | Needs evaluation; no released fixed version |

Canonical's [Expat record](https://ubuntu.com/security/CVE-2026-93990) and
[Perl record](https://ubuntu.com/security/CVE-2026-9538) were checked on 2026-11-10.
Both have Ubuntu priority Medium, while upstream CVSS3 is 7.5 High; this difference
is disclosed and not reclassified. The official OSV records identify the exact
Resolute source/binary versions without a fixed event. Their SHA256 evidence is
recorded with each tracker entry. Noble's fixed Perl package and upstream fixes
are not installed over Resolute's distro-managed package.

Review the new entries by 2026-11-17. The exact-set gate continues to reject HIGH,
CRITICAL, available fixes, untracked or missing package rows, and expired reviews.
The previous failed scan is retained. No runtime patch or production change occurs.
