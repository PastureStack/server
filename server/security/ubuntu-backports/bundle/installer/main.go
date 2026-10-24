// install-existing-backports is a build-only, dependency-free verifier/installer.
// It never invokes a shell, apt, force flags, alternatives, or network tools.
package main

import (
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"os"
	"os/exec"
	"runtime"
)

type boundedBuffer struct {
	bytes.Buffer
	limit int
}

func (b *boundedBuffer) Write(p []byte) (int, error) {
	if len(p) > b.limit-b.Len() {
		return 0, fmt.Errorf("command output exceeds bound")
	}
	return b.Buffer.Write(p)
}

type systemRunner struct{}

func (systemRunner) Run(binary string, args ...string) ([]byte, error) {
	switch binary {
	case "/usr/bin/dpkg", "/usr/bin/dpkg-query", "/usr/bin/dpkg-deb":
	default:
		return nil, fmt.Errorf("command is not allowed")
	}
	cmd := exec.Command(binary, args...)
	cmd.Env = []string{"PATH=/usr/sbin:/usr/bin:/sbin:/bin", "LC_ALL=C", "LANG=C", "DEBIAN_FRONTEND=noninteractive", "DPKG_COLORS=never", "HOME=/root", "TERM=dumb"}
	var out = boundedBuffer{limit: 768 << 20}
	var stderr = boundedBuffer{limit: 64 << 10}
	cmd.Stdout = &out
	cmd.Stderr = &stderr
	cmd.Stdin = nil
	err := cmd.Run()
	if err != nil {
		return out.Bytes(), fmt.Errorf("%s %v: %w; %s", binary, args, err, stderr.String())
	}
	return out.Bytes(), nil
}
func cli(args []string, stdout io.Writer) error {
	flags := flag.NewFlagSet("install-existing-backports", flag.ContinueOnError)
	install := flags.Bool("install-in-docker-build", false, "install the fixed qualified bundle into a disposable Docker build rootfs")
	verify := flags.Bool("verify-installed", false, "verify existing installed packages against the fixed qualified bundle")
	if err := flags.Parse(args); err != nil {
		return err
	}
	if flags.NArg() != 0 || *install == *verify {
		return fmt.Errorf("choose exactly one of --install-in-docker-build or --verify-installed; no path overrides are accepted")
	}
	if runtime.GOOS != "linux" || runtime.GOARCH != "amd64" || runtime.Version() != "go1.27.3" || os.Geteuid() != 0 {
		return fmt.Errorf("requires root inside a Linux amd64 Docker build, compiled with Go 1.27.3")
	}
	receipt, err := (Installer{bundle: bundleRoot, root: "/", run: systemRunner{}}).Execute(*install)
	if err != nil {
		return err
	}
	encoder := json.NewEncoder(stdout)
	encoder.SetIndent("", "  ")
	return encoder.Encode(receipt)
}
func main() {
	if err := cli(os.Args[1:], os.Stdout); err != nil {
		fmt.Fprintln(os.Stderr, "BACKPORT_INSTALLATION_FAILED:", err)
		os.Exit(1)
	}
}
