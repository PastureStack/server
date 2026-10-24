//go:build !linux

package main

import (
	"fmt"
	"os"
)

func fileOwnership(info os.FileInfo) (uint32, int, int, error) {
	return 0, 0, 0, fmt.Errorf("installer requires Linux")
}
