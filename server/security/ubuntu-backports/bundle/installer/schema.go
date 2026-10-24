package main

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"path"
	"path/filepath"
	"regexp"
	"strings"
)

const bundleRoot = "/opt/pasturestack/ubuntu-security-backports"

var families = map[string][]string{
	"pcre2":          {"libpcre2-8-0", "libpcre2-posix3"},
	"glibc":          {"libc6", "libc-bin", "libc-gconv-modules-extra"},
	"rust-coreutils": {"rust-coreutils"}, "jq": {"jq", "libjq1"},
	"p11-kit":    {"libp11-kit0", "p11-kit", "p11-kit-modules"},
	"libxrender": {"libxrender1"},
}

type Platform struct{ Distribution, Release, Architecture string }
type Ref struct{ Path, SHA256 string }
type Family struct {
	Name, Source, Version string
	Provenance            Ref
}
type Package struct {
	Name, Family, Version, Architecture, Source string
	Archive, Payload                            Ref
}
type Manifest struct {
	SchemaVersion int
	BundleVersion string
	Platform      Platform
	Qualification Ref
	Families      []Family
	Packages      []Package
}
type QualifiedFamily struct {
	Name, Status, ProvenanceSHA256 string
	NativeInput                    struct{ LockSHA256 string }
}
type Qualification struct {
	SchemaVersion                           int
	BundleVersion, Status, SourceLockSHA256 string
	Platform                                Platform
	Families                                []QualifiedFamily
}
type File struct {
	Path, Type, SHA256, Target string
	Mode                       uint32
	UID, GID                   int
}
type ELF struct {
	Path, SHA256           string
	ELFClass, Machine      int
	SONAME                 *string
	Needed, DefinedSymbols []string
}
type Payload struct {
	SchemaVersion                          int
	Package, Version, Architecture, Source string
	Files                                  []File
	ELF                                    []ELF
}

var digestPattern = regexp.MustCompile(`^[0-9a-f]{64}$`)
var versionPattern = regexp.MustCompile(`^[0-9][A-Za-z0-9.+:~\-]*$`)

func digest(b []byte) string { h := sha256.Sum256(b); return hex.EncodeToString(h[:]) }
func check(ok bool, format string, args ...any) error {
	if !ok {
		return fmt.Errorf(format, args...)
	}
	return nil
}
func safeRelative(p string) bool {
	return p != "" && p != "." && !strings.ContainsAny(p, "\\\x00\r\n:") &&
		!strings.HasPrefix(p, "/") && path.Clean(p) == p && p != ".." && !strings.HasPrefix(p, "../")
}

// Every component is checked without following links, even for SHA-bound files.
func regularRead(root, name string, limit int64) ([]byte, error) {
	if !safeRelative(name) {
		return nil, fmt.Errorf("unsafe bundle path %q", name)
	}
	p := root
	parts := strings.Split(name, "/")
	for n, part := range parts {
		p = filepath.Join(p, part)
		info, err := os.Lstat(p)
		if err != nil {
			return nil, err
		}
		if info.Mode()&os.ModeSymlink != 0 || (n < len(parts)-1 && !info.IsDir()) {
			return nil, fmt.Errorf("linked/non-directory parent %s", p)
		}
		if n == len(parts)-1 && (!info.Mode().IsRegular() || info.Size() > limit) {
			return nil, fmt.Errorf("not a bounded regular file: %s", p)
		}
	}
	f, err := os.Open(p)
	if err != nil {
		return nil, err
	}
	defer f.Close()
	b, err := io.ReadAll(io.LimitReader(f, limit+1))
	if err != nil {
		return nil, err
	}
	if int64(len(b)) > limit {
		return nil, fmt.Errorf("file grew beyond size bound: %s", p)
	}
	return b, nil
}
func boundRead(root string, ref Ref, limit int64) ([]byte, error) {
	if !digestPattern.MatchString(ref.SHA256) {
		return nil, fmt.Errorf("invalid SHA256 for %s", ref.Path)
	}
	b, err := regularRead(root, ref.Path, limit)
	if err != nil {
		return nil, err
	}
	if digest(b) != ref.SHA256 {
		return nil, fmt.Errorf("SHA256 mismatch: %s", ref.Path)
	}
	return b, nil
}
func decode(b []byte, value any, strict bool) error {
	d := json.NewDecoder(bytes.NewReader(b))
	if strict {
		d.DisallowUnknownFields()
	}
	if err := d.Decode(value); err != nil {
		return err
	}
	if err := d.Decode(new(any)); err != io.EOF {
		return fmt.Errorf("trailing JSON data")
	}
	return nil
}
func validatePlatform(p Platform) bool { return p == (Platform{"ubuntu", "26.04", "amd64"}) }

func loadManifest(root string) (Manifest, map[string]Payload, error) {
	var m Manifest
	b, err := regularRead(root, "manifest.json", 2<<20)
	if err != nil {
		return m, nil, err
	}
	if err = decode(b, &m, true); err != nil {
		return m, nil, err
	}
	if m.SchemaVersion != 1 || m.BundleVersion != "0.1.0" || !validatePlatform(m.Platform) || len(m.Families) != 6 || len(m.Packages) != 12 || m.Qualification.Path != "qualification.json" {
		return m, nil, fmt.Errorf("unsupported bundle identity/catalog")
	}
	qb, err := boundRead(root, m.Qualification, 16<<20)
	if err != nil {
		return m, nil, err
	}
	var q Qualification // Native owning-test evidence is family-specific; required fields remain mandatory.
	if err = decode(qb, &q, false); err != nil {
		return m, nil, err
	}
	if q.SchemaVersion != 1 || q.BundleVersion != m.BundleVersion || !validatePlatform(q.Platform) || q.Status != "qualified" || len(q.Families) != 6 {
		return m, nil, fmt.Errorf("bundle is not qualified")
	}
	if _, err = boundRead(root, Ref{"source-inputs.lock.json", q.SourceLockSHA256}, 8<<20); err != nil {
		return m, nil, err
	}
	fm := map[string]Family{}
	qm := map[string]QualifiedFamily{}
	for _, f := range q.Families {
		if _, ok := qm[f.Name]; ok {
			return m, nil, fmt.Errorf("duplicate qualification family")
		}
		qm[f.Name] = f
	}
	for _, f := range m.Families {
		_, allowed := families[f.Name]
		_, duplicate := fm[f.Name]
		qualified, exists := qm[f.Name]
		if !allowed || duplicate || f.Source != f.Name || !versionPattern.MatchString(f.Version) || f.Provenance.Path != "provenance/"+f.Name+"/provenance.json" || !exists || qualified.Status != "qualified" || qualified.ProvenanceSHA256 != f.Provenance.SHA256 {
			return m, nil, fmt.Errorf("invalid family %q", f.Name)
		}
		pb, err := boundRead(root, f.Provenance, 32<<20)
		if err != nil {
			return m, nil, err
		}
		var provenance struct{ SourceLockSHA256, LockSHA256 string }
		if err = decode(pb, &provenance, false); err != nil {
			return m, nil, err
		}
		pin := provenance.SourceLockSHA256
		if pin == "" {
			pin = provenance.LockSHA256
		}
		if !digestPattern.MatchString(pin) || pin != qualified.NativeInput.LockSHA256 {
			return m, nil, fmt.Errorf("source provenance lock mismatch: %s", f.Name)
		}
		fm[f.Name] = f
	}
	result := map[string]Payload{}
	for _, p := range m.Packages {
		f, exists := fm[p.Family]
		allowed := false
		for _, n := range families[p.Family] {
			if n == p.Name {
				allowed = true
			}
		}
		_, duplicate := result[p.Name]
		if !exists || !allowed || duplicate || p.Source != f.Source || p.Version != f.Version || p.Architecture != "amd64" || !strings.HasPrefix(p.Archive.Path, "debs/") || path.Base(p.Archive.Path) != strings.TrimPrefix(p.Archive.Path, "debs/") || !strings.HasSuffix(p.Archive.Path, ".deb") || p.Payload.Path != "payload/"+p.Name+".json" {
			return m, nil, fmt.Errorf("invalid package catalog entry %q", p.Name)
		}
		if _, err = boundRead(root, p.Archive, 256<<20); err != nil {
			return m, nil, err
		}
		pb, err := boundRead(root, p.Payload, 32<<20)
		if err != nil {
			return m, nil, err
		}
		var payload Payload
		if err = decode(pb, &payload, true); err != nil {
			return m, nil, err
		}
		if payload.SchemaVersion != 1 || payload.Package != p.Name || payload.Version != p.Version || payload.Source != p.Source || payload.Architecture != p.Architecture || len(payload.Files) == 0 {
			return m, nil, fmt.Errorf("payload identity mismatch: %s", p.Name)
		}
		result[p.Name] = payload
	}
	return m, result, nil
}
