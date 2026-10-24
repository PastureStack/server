//go:build linux

package main

import (
	"fmt"
	"os"
	"syscall"
)

func fileOwnership(info os.FileInfo) (uint32, int, int, error) {
	s, ok := info.Sys().(*syscall.Stat_t)
	if !ok {
		return 0, 0, 0, fmt.Errorf("missing Linux stat ownership")
	}
	return s.Mode & 07777, int(s.Uid), int(s.Gid), nil
}
