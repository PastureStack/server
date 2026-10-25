package main

import (
	"archive/tar"
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"reflect"
	"sort"
	"strings"
	"testing"
)

type fakeRunner struct {
	t                     *testing.T
	root, bundle          string
	installed             map[string]Installed
	packages              map[string]Package
	payloads              map[string]Payload
	tars                  map[string][]byte
	contents              map[string][]byte
	beforeDiff, afterDiff map[string]string
	commands              [][]string
	installedBatch        []string
	mutate                func()
	dryFail               bool
}

func (f *fakeRunner) Run(binary string, args ...string) ([]byte, error) {
	f.commands = append(f.commands, append([]string{binary}, args...))
	if binary == "/usr/bin/dpkg-query" && args[0] == "--show" {
		names := []string{}
		for n := range f.installed {
			names = append(names, n)
		}
		sort.Strings(names)
		var b strings.Builder
		for _, n := range names {
			p := f.installed[n]
			fmt.Fprintf(&b, "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", p.Name, p.Version, p.Architecture, p.Source, p.SourceVersion, p.Status, p.Depends, p.PreDepends)
		}
		return []byte(b.String()), nil
	}
	if binary == "/usr/bin/dpkg-query" && args[0] == "--listfiles" {
		return []byte("/usr/bin/ls\n"), nil
	}
	if binary == "/usr/bin/dpkg-deb" {
		name := ""
		for n, p := range f.packages {
			if filepath.Join(f.bundle, filepath.FromSlash(p.Archive.Path)) == args[1] {
				name = n
			}
		}
		if name == "" {
			return nil, errors.New("unexpected archive")
		}
		p := f.packages[name]
		if args[0] == "--field" {
			return []byte(fmt.Sprintf("Package: %s\nVersion: %s\nArchitecture: amd64\nSource: %s\n", name, p.Version, p.Source)), nil
		}
		if args[0] == "--fsys-tarfile" {
			return f.tars[name], nil
		}
	}
	if binary == "/usr/bin/dpkg" {
		switch args[0] {
		case "--print-architecture":
			return []byte("amd64\n"), nil
		case "--audit":
			return nil, nil
		case "--compare-versions":
			if args[1] > args[3] {
				return nil, errors.New("newer installed version")
			}
			return nil, nil
		case "--verify":
			if f.installedBatch == nil {
				return []byte(f.beforeDiff[args[1]]), nil
			}
			return []byte(f.afterDiff[args[1]]), nil
		case "--no-act":
			if f.dryFail {
				return nil, errors.New("dependency unsatisfied")
			}
			return nil, nil
		}
		installAt := -1
		for n, a := range args {
			if a == "--install" {
				installAt = n
			}
			if strings.Contains(a, "force") {
				f.t.Fatal("force flag used")
			}
		}
		if installAt >= 0 {
			if f.installedBatch != nil {
				f.t.Fatal("more than one actual install")
			}
			f.installedBatch = []string{}
			for _, archive := range args[installAt+1:] {
				name := ""
				for n, p := range f.packages {
					if filepath.Join(f.bundle, filepath.FromSlash(p.Archive.Path)) == archive {
						name = n
					}
				}
				if name == "" {
					f.t.Fatal("unrecognized install path")
				}
				if _, exists := f.installed[name]; !exists {
					f.t.Fatal("added a package")
				}
				p := f.packages[name]
				f.installed[name] = Installed{Name: name, Version: p.Version, Architecture: "amd64", Source: p.Source, SourceVersion: p.Version, Status: "installed"}
				f.installedBatch = append(f.installedBatch, name)
				for _, file := range f.payloads[name].Files {
					target := filepath.Join(f.root, filepath.FromSlash(file.Path))
					must(f.t, os.MkdirAll(filepath.Dir(target), 0755))
					must(f.t, os.WriteFile(target, f.contents[file.Path], os.FileMode(file.Mode)))
				}
			}
			if f.mutate != nil {
				f.mutate()
			}
			return nil, nil
		}
	}
	return nil, fmt.Errorf("unexpected command: %s %v", binary, args)
}
func must(t *testing.T, err error) {
	t.Helper()
	if err != nil {
		t.Fatal(err)
	}
}
func write(t *testing.T, root, name string, b []byte) {
	t.Helper()
	p := filepath.Join(root, filepath.FromSlash(name))
	must(t, os.MkdirAll(filepath.Dir(p), 0755))
	must(t, os.WriteFile(p, b, 0644))
}
func jsonFile(t *testing.T, root, name string, value any) Ref {
	t.Helper()
	b, err := json.Marshal(value)
	must(t, err)
	write(t, root, name, b)
	return Ref{name, digest(b)}
}
func fixture(t *testing.T, names ...string) (Installer, *fakeRunner) {
	t.Helper()
	root := t.TempDir()
	bundle := t.TempDir()
	write(t, root, "etc/os-release", []byte("ID=ubuntu\nVERSION_ID=\"26.04\"\n"))
	write(t, root, "etc/dpkg/dpkg.cfg.d/docker", []byte("path-exclude=/usr/share/doc/*\n"))
	must(t, os.MkdirAll(filepath.Join(root, "var/lib/dpkg/alternatives"), 0755))
	write(t, root, "usr/bin/ls", []byte("provider command"))
	f := &fakeRunner{t: t, root: root, bundle: bundle, installed: map[string]Installed{}, packages: map[string]Package{}, payloads: map[string]Payload{}, tars: map[string][]byte{}, contents: map[string][]byte{}, beforeDiff: map[string]string{}, afterDiff: map[string]string{}}
	m := Manifest{SchemaVersion: 1, BundleVersion: "0.1.1", Platform: Platform{"ubuntu", "26.04", "amd64"}, Families: []Family{}, Packages: []Package{}}
	q := Qualification{SchemaVersion: 1, BundleVersion: m.BundleVersion, Platform: m.Platform, Status: "qualified", Families: []QualifiedFamily{}}
	lock := jsonFile(t, bundle, "source-inputs.lock.json", map[string]string{"identity": "source lock"})
	q.SourceLockSHA256 = lock.SHA256
	keys := []string{}
	for family := range families {
		keys = append(keys, family)
	}
	sort.Strings(keys)
	for _, family := range keys {
		lockSHA := digest([]byte(family))
		prov := jsonFile(t, bundle, "provenance/"+family+"/provenance.json", map[string]string{"sourceLockSha256": lockSHA})
		m.Families = append(m.Families, Family{family, family, "2.0", prov})
		qf := QualifiedFamily{Name: family, Status: "qualified", ProvenanceSHA256: prov.SHA256}
		qf.NativeInput.LockSHA256 = lockSHA
		q.Families = append(q.Families, qf)
		for _, name := range families[family] {
			p := Package{Name: name, Family: family, Version: "2.0", Architecture: "amd64", Source: family}
			payload := Payload{SchemaVersion: 1, Package: name, Version: p.Version, Architecture: "amd64", Source: family, Files: []File{}, ELF: []ELF{}}
			var tb bytes.Buffer
			tw := tar.NewWriter(&tb)
			for _, filename := range []string{"usr/bin/fixture-" + name, "usr/share/doc/" + name + "/README"} {
				content := []byte("qualified-" + name + "-" + filename)
				file := File{Path: filename, Type: "file", SHA256: digest(content), Mode: 0644, UID: os.Geteuid(), GID: os.Getegid()}
				payload.Files = append(payload.Files, file)
				f.contents[filename] = content
				must(t, tw.WriteHeader(&tar.Header{Name: "./" + filename, Mode: 0644, Uid: file.UID, Gid: file.GID, Size: int64(len(content)), Typeflag: tar.TypeReg}))
				_, err := tw.Write(content)
				must(t, err)
			}
			must(t, tw.Close())
			f.tars[name] = tb.Bytes()
			p.Archive = Ref{"debs/" + name + ".deb", digest([]byte("archive-" + name))}
			write(t, bundle, p.Archive.Path, []byte("archive-"+name))
			p.Payload = jsonFile(t, bundle, "payload/"+name+".json", payload)
			m.Packages = append(m.Packages, p)
			f.packages[name] = p
			f.payloads[name] = payload
		}
	}
	m.Qualification = jsonFile(t, bundle, "qualification.json", q)
	jsonFile(t, bundle, "manifest.json", m)
	for _, name := range names {
		source := name
		if p, ok := f.packages[name]; ok {
			source = p.Source
		}
		f.installed[name] = Installed{Name: name, Version: "1.0", Architecture: "amd64", Source: source, SourceVersion: "1.0", Status: "installed"}
		if p, ok := f.payloads[name]; ok {
			write(t, root, p.Files[0].Path, []byte("original-"+name))
			f.beforeDiff[name] = "missing     /usr/share/doc/" + name + "/README\n"
		}
	}
	return Installer{bundle: bundle, root: root, run: f}, f
}
func TestExistingOnlyGNUConsumer(t *testing.T) {
	i, f := fixture(t, "libc6", "coreutils-from-gnu", "gnu-coreutils")
	r, err := i.Execute(true)
	must(t, err)
	if !reflect.DeepEqual(f.installedBatch, []string{"libc6"}) || !r.ProviderPreserved || !r.ConfigurationPreserved {
		t.Fatalf("wrong batch/receipt: %#v", r)
	}
	if _, exists := f.installed["rust-coreutils"]; exists {
		t.Fatal("Rust was added to a GNU consumer")
	}
	if !reflect.DeepEqual(r.BeforeMissingDocumentation, []string{"/usr/share/doc/libc6/README"}) || !reflect.DeepEqual(r.ExactPathIncludes, r.BeforeMissingDocumentation) {
		t.Fatal("missing docs were not explicitly restored")
	}
	for _, cmd := range f.commands {
		if strings.Contains(strings.Join(cmd, " "), "--install") && cmd[1] != "--no-act" {
			if !strings.Contains(strings.Join(cmd, " "), "--path-include=/usr/share/doc/libc6/README") {
				t.Fatal("exact path include missing")
			}
		}
	}
}
func TestUutilsProviderPreserved(t *testing.T) {
	i, f := fixture(t, "rust-coreutils", "coreutils-from-uutils", "gnu-coreutils")
	p := f.installed["coreutils-from-uutils"]
	p.PreDepends = "rust-coreutils (>> 0.1.0+git20250813), gnu-coreutils"
	f.installed[p.Name] = p
	_, err := i.Execute(true)
	must(t, err)
	if !reflect.DeepEqual(f.installedBatch, []string{"rust-coreutils"}) {
		t.Fatal("provider was installed")
	}
}
func TestRefuseMissingExactCompanion(t *testing.T) {
	i, f := fixture(t, "libc6", "libc6-dev")
	p := f.installed["libc6-dev"]
	p.Depends = "libc6 (= 1.0)"
	f.installed[p.Name] = p
	_, err := i.Execute(true)
	if err == nil || !strings.Contains(err.Error(), "companion") {
		t.Fatalf("expected companion refusal, got %v", err)
	}
	if f.installedBatch != nil {
		t.Fatal("installed despite missing companion")
	}
}
func TestTamperedArchiveStopsBeforeDpkg(t *testing.T) {
	i, f := fixture(t, "libc6")
	write(t, i.bundle, f.packages["jq"].Archive.Path, []byte("tampered unselected input"))
	_, err := i.Execute(true)
	if err == nil || !strings.Contains(err.Error(), "SHA256") {
		t.Fatalf("expected SHA refusal, got %v", err)
	}
	if f.installedBatch != nil {
		t.Fatal("installed tampered bundle")
	}
}
func TestPreexistingIntegrityFailures(t *testing.T) {
	for _, diff := range []string{"??5??????   /usr/bin/fixture-libc6\n", "missing     /usr/bin/fixture-libc6\n", "missing   c /etc/ld.so.conf\n", "missing     /usr/share/doc/other/README\n"} {
		t.Run(strings.TrimSpace(diff), func(t *testing.T) {
			i, f := fixture(t, "libc6")
			f.beforeDiff["libc6"] = diff
			_, err := i.Execute(true)
			if err == nil {
				t.Fatal("corruption accepted")
			}
			if f.installedBatch != nil {
				t.Fatal("installation reached")
			}
		})
	}
}
func TestMissingDocsRequireActualPathExclusion(t *testing.T) {
	i, f := fixture(t, "libc6")
	write(t, i.root, "etc/dpkg/dpkg.cfg.d/docker", []byte("# no exclusions\n"))
	_, err := i.Execute(true)
	if err == nil || f.installedBatch != nil {
		t.Fatal("unexplained missing file accepted")
	}
}
func TestRuntimePathExclusionRejected(t *testing.T) {
	i, f := fixture(t, "libc6")
	f.beforeDiff["libc6"] = ""
	write(t, i.root, "etc/dpkg/dpkg.cfg.d/docker", []byte("path-exclude=/usr/bin/*\n"))
	_, err := i.Execute(true)
	if err == nil || !strings.Contains(err.Error(), "runtime payload") || f.installedBatch != nil {
		t.Fatalf("runtime exclusion not rejected: %v", err)
	}
}
func TestDryRunFailureNoMutation(t *testing.T) {
	i, f := fixture(t, "libc6")
	f.dryFail = true
	_, err := i.Execute(true)
	if err == nil || f.installedBatch != nil {
		t.Fatal("failed dependency preflight mutated rootfs")
	}
}
func TestPostIntegrityAndConfigFailures(t *testing.T) {
	for _, kind := range []string{"dpkg", "payload", "config", "provider"} {
		t.Run(kind, func(t *testing.T) {
			i, f := fixture(t, "libc6", "coreutils-from-gnu")
			switch kind {
			case "dpkg":
				f.afterDiff["libc6"] = "??5?????? /usr/bin/fixture-libc6\n"
			case "payload":
				f.mutate = func() { write(t, i.root, "usr/bin/fixture-libc6", []byte("bad")) }
			case "config":
				f.mutate = func() { write(t, i.root, "etc/os-release", []byte("changed")) }
			case "provider":
				f.mutate = func() { write(t, i.root, "usr/bin/ls", []byte("switched")) }
			}
			_, err := i.Execute(true)
			if err == nil {
				t.Fatal("post-install corruption accepted")
			}
		})
	}
}
func TestInstalledVerifierIsReadOnly(t *testing.T) {
	i, f := fixture(t, "libc6")
	_, err := i.Execute(true)
	must(t, err)
	f.commands = nil
	_, err = i.Execute(false)
	must(t, err)
	for _, cmd := range f.commands {
		for _, arg := range cmd {
			if arg == "--install" || arg == "--no-act" {
				t.Fatal("verifier invoked installation")
			}
		}
	}
}
func TestArchiveReceiptAndTraversalRejection(t *testing.T) {
	i, f := fixture(t, "libc6")
	p := f.payloads["libc6"]
	p.Files[0].SHA256 = digest([]byte("wrong"))
	if err := validateArchive(f.tars["libc6"], p); err == nil {
		t.Fatal("payload mismatch accepted")
	}
	var b bytes.Buffer
	tw := tar.NewWriter(&b)
	must(t, tw.WriteHeader(&tar.Header{Name: "../escape", Mode: 0644, Size: 0, Typeflag: tar.TypeReg}))
	must(t, tw.Close())
	if _, _, err := inspectTar(b.Bytes()); err == nil {
		t.Fatal("tar traversal accepted")
	}
	_ = i
}
func TestCLIHasNoPathOverrides(t *testing.T) {
	for _, args := range [][]string{{}, {"--lock", "/tmp/x"}, {"--install-in-docker-build", "--verify-installed"}, {"--verify-installed", "/tmp/root"}} {
		if err := cli(args, &bytes.Buffer{}); err == nil {
			t.Fatalf("invalid CLI accepted: %v", args)
		}
	}
}
func TestDowngradeRejected(t *testing.T) {
	i, f := fixture(t, "libc6")
	p := f.installed["libc6"]
	p.Version = "3.0"
	f.installed[p.Name] = p
	_, err := i.Execute(true)
	if err == nil || !strings.Contains(err.Error(), "downgrade") || f.installedBatch != nil {
		t.Fatalf("downgrade accepted: %v", err)
	}
}
func TestHardlinkAndSymlinkTar(t *testing.T) {
	var b bytes.Buffer
	tw := tar.NewWriter(&b)
	must(t, tw.WriteHeader(&tar.Header{Name: "./usr/lib/a", Mode: 0644, Size: 3, Typeflag: tar.TypeReg}))
	_, err := tw.Write([]byte("abc"))
	must(t, err)
	must(t, tw.WriteHeader(&tar.Header{Name: "./usr/lib/b", Mode: 0644, Typeflag: tar.TypeLink, Linkname: "./usr/lib/a"}))
	must(t, tw.WriteHeader(&tar.Header{Name: "./usr/lib/c", Mode: 0777, Typeflag: tar.TypeSymlink, Linkname: "/usr/lib/a"}))
	must(t, tw.Close())
	files, _, err := inspectTar(b.Bytes())
	must(t, err)
	if len(files) != 3 || files[0].SHA256 != files[1].SHA256 || files[2].Target != "/usr/lib/a" {
		t.Fatal("hardlink/symlink payload receipt wrong")
	}
	b.Reset()
	tw = tar.NewWriter(&b)
	must(t, tw.WriteHeader(&tar.Header{Name: "./usr/lib/link", Mode: 0777, Typeflag: tar.TypeSymlink, Linkname: "/etc"}))
	must(t, tw.WriteHeader(&tar.Header{Name: "./usr/lib/link/evil", Mode: 0644, Size: 0, Typeflag: tar.TypeReg}))
	must(t, tw.Close())
	if _, _, err := inspectTar(b.Bytes()); err == nil {
		t.Fatal("archive path below symlink accepted")
	}
}
func TestNativeELFABIRejectsDroppedSymbols(t *testing.T) {
	const library = "usr/lib/x86_64-linux-gnu/libc.so.6"
	b, err := os.ReadFile("/" + library)
	must(t, err)
	e, err := inspectELF(library, b)
	must(t, err)
	if e.SONAME == nil || len(e.DefinedSymbols) == 0 {
		t.Fatal("native amd64 libc fixture lacks SONAME/exports")
	}
	original, err := inspectABI(library, b)
	must(t, err)
	changed := original
	changed.Exports = []abiSymbol{}
	if err := compatibleLibrary(original, changed, nil); err == nil || !strings.Contains(err.Error(), "dropped exported symbol") {
		t.Fatalf("ABI loss was not rejected: %v", err)
	}
}
