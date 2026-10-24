# Retain the exact Ubuntu exports/features; only replace its non-gating test recipe.
include debian/rules

.PHONY: pasturestack-strict-test
pasturestack-strict-test:
	$(MAKE) -f GNUmakefile SELINUX_ENABLED=1 PROFILE=release MULTICALL=y TEST_NO_FAIL_FAST=--no-fail-fast test
