# Retain Ubuntu exports/features and its pinned 17 exclusions. Remove only the
# accidental positional filter and failure swallowing from its test recipe.
override _PS_TEST_HELPER := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/build-rust-coreutils-backport.py)
include debian/rules
override _PS_TEST_ARGS := $(shell python3 "$(_PS_TEST_HELPER)" --print-ubuntu-test-arguments)
ifneq ($(.SHELLSTATUS),0)
$(error Pinned Ubuntu owning-test arguments could not be verified)
endif
override TEST_NO_FAIL_FAST := $(_PS_TEST_ARGS)

.PHONY: pasturestack-strict-test
pasturestack-strict-test:
	$(MAKE) -f GNUmakefile SELINUX_ENABLED=1 PROFILE=release MULTICALL=y TEST_NO_FAIL_FAST="$(TEST_NO_FAIL_FAST)" test
