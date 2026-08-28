# PastureStack Server v1.6.367

Server v1.6.367 fixes Docker Engine compatibility classification for the
supported Docker 29 interval. The previous setting listed only the tested
boundary releases `29.4.1` and `29.7.2`, which incorrectly marked compatible
intermediate patch releases such as `29.6.2` as unsupported.

The runtime now publishes the bounded SemVer range `>=v29.4.1 <=v29.7.2`.
Versions inside that interval are supported; versions below the lower bound or
above the current `29.7.2` upper bound remain outside the policy. Docker 25
through 28 and Docker 30 are not added by this correction.

The image retains the exact Orchestration Engine, API Explorer, Web Console,
runtime services, Ubuntu snapshot, OpenSSL, zlib, and hardening content from
v1.6.366. That includes the GNU coreutils fix commit
`d64e35a8a4c0e4608321433e0d84d917e4e36371`, the OpenSSL closure for
`CVE-2026-75803`, and removal of the unreachable `diff3` path for
`CVE-2026-53910`.

Publication still builds the final image from clean source, verifies the
embedded Docker range, starts and restarts an isolated candidate, requires HTTP
200 and `pong`, scans the merged root filesystem, and applies the reviewed
OpenVEX statements. Any new or unmatched vulnerability at any severity remains a release blocker.

PastureStack is an independent community effort and is not affiliated with or
endorsed by Rancher Labs or SUSE. Existing licenses and upstream attribution
remain applicable.
