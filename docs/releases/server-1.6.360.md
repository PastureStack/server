# PastureStack Server v1.6.360

Server v1.6.360 supersedes v1.6.359 before production rollout. It keeps the
same API Explorer 1.1.17, Go 1.27.0 runtime refresh, Ubuntu 26.04 package
refresh, orchestration engine, Web Console, database schema, and control-plane
API contract.

The only runtime delta from v1.6.359 is Catalog Service 0.20.11 at source
commit `9a892bc2bb5e0917b7a5cdb056426036ec99c979`. Catalog Service now constructs
MySQL DSNs from the current driver's reviewed defaults. This preserves
`mysql_native_password` compatibility for existing installations after the
upgrade to `go-sql-driver/mysql` 1.10.0 without changing database users,
passwords, authentication plugins, or stored data.

The checksum-pinned Catalog Service release coordinates are:

- Archive SHA-256:
  `b44bc4d337ea3b54d5a5febca2060ce23e3b988c298c2fb926227fea3c228d3d`
- Runtime binary SHA-256:
  `ccfc75831678df31f58b327b3177da6f40d31603ab329af7bdf700a8513ea329`
- SQLite binary SHA-256:
  `e5c517bc7beb6857c12a7df1ffee93d87499107e12ddeca758297b930f0bb4d1`

The Catalog Service release gate passed full tests, two byte-identical builds,
source and product scans, exact builder OpenVEX reconciliation, and immutable
source-coordinate validation before these artifacts were consumed.

PastureStack is an independent community effort and is not affiliated with or
endorsed by Rancher Labs or SUSE. Existing licenses and upstream attribution
remain applicable.
