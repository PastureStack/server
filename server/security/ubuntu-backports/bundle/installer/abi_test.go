package main

import (
	"archive/tar"
	"bytes"
	"debug/elf"
	"os"
	"strings"
	"testing"
)

func tlsABIControl() (abiELF, abiELF, abiELF, abiELF) {
	soname := "libcomponent.so.1"
	base := abiELF{Metadata: ELF{Path: "usr/lib/component.so.1", ELFClass: 64, Machine: 62, SONAME: &soname, Needed: []string{"libc.so.6", "libm.so.6"}},
		Imports: []abiSymbol{{Name: "malloc", Version: "GLIBC_2.2.5", Library: "libc.so.6", Binding: elf.STB_GLOBAL, Type: elf.STT_FUNC}},
		Exports: []abiSymbol{{Name: "component_api", Version: "COMPONENT_1", Binding: elf.STB_GLOBAL, Type: elf.STT_FUNC}}}
	next := base
	next.Metadata.Needed = []string{"libc.so.6", "libm.so.6", amd64Loader}
	next.Imports = append(append([]abiSymbol{}, base.Imports...), abiSymbol{Name: "__tls_get_addr", Version: "GLIBC_2.3", Library: amd64Loader, Binding: elf.STB_GLOBAL, Type: elf.STT_FUNC})
	loaderName := amd64Loader
	provider := abiELF{Metadata: ELF{Path: amd64LoaderPath, ELFClass: 64, Machine: 62, SONAME: &loaderName}, Exports: []abiSymbol{{Name: "__tls_get_addr", Version: "GLIBC_2.3", Binding: elf.STB_GLOBAL, Type: elf.STT_FUNC}}}
	return base, next, provider, provider
}
func TestExactPlatformTLSAddition(t *testing.T) {
	old, next, installed, qualified := tlsABIControl()
	calls := 0
	must(t, compatibleLibrary(old, next, func() (abiELF, abiELF, error) { calls++; return installed, qualified, nil }))
	if calls != 1 {
		t.Fatal("loader evidence was not checked")
	}
	must(t, compatibleLibrary(old, old, nil))
}
func TestPlatformTLSRejectsOtherABIDrift(t *testing.T) {
	for _, kind := range []string{"unknown-needed", "drop-needed", "no-tls", "wrong-tls-version", "wrong-tls-library", "weak-tls", "extra-weak-loader-import", "missing-providers", "wrong-installed-version", "wrong-qualified-version", "hidden-provider", "wrong-loader-soname", "changed-soname", "drop-export", "changed-export-version", "hidden-export-version", "wrong-machine"} {
		t.Run(kind, func(t *testing.T) {
			old, next, current, qualified := tlsABIControl()
			next.Exports = append([]abiSymbol{}, old.Exports...)
			current.Exports = append([]abiSymbol{}, current.Exports...)
			qualified.Exports = append([]abiSymbol{}, qualified.Exports...)
			provider := func() (abiELF, abiELF, error) { return current, qualified, nil }
			switch kind {
			case "unknown-needed":
				next.Metadata.Needed = append(next.Metadata.Needed, "libunknown.so.9")
			case "drop-needed":
				next.Metadata.Needed = []string{"libc.so.6", amd64Loader}
			case "no-tls":
				next.Imports = next.Imports[:1]
			case "wrong-tls-version":
				next.Imports[1].Version = "GLIBC_2.4"
			case "wrong-tls-library":
				next.Imports[1].Library = "libc.so.6"
			case "weak-tls":
				next.Imports[1].Binding = elf.STB_WEAK
			case "extra-weak-loader-import":
				next.Imports = append(next.Imports, abiSymbol{Name: "other_loader_function", Version: "GLIBC_2.3", Library: amd64Loader, Binding: elf.STB_WEAK, Type: elf.STT_FUNC})
			case "missing-providers":
				provider = nil
			case "wrong-installed-version":
				current.Exports[0].Version = "GLIBC_2.4"
			case "wrong-qualified-version":
				qualified.Exports[0].Version = "GLIBC_2.4"
			case "hidden-provider":
				qualified.Exports[0].Visibility = elf.STV_HIDDEN
			case "wrong-loader-soname":
				name := "ld-other.so.1"
				qualified.Metadata.SONAME = &name
			case "changed-soname":
				name := "libcomponent.so.2"
				next.Metadata.SONAME = &name
			case "drop-export":
				next.Exports = nil
			case "changed-export-version":
				next.Exports[0].Version = "COMPONENT_2"
			case "hidden-export-version":
				next.Exports[0].Hidden = true
			case "wrong-machine":
				next.Metadata.Machine = 183
			}
			if err := compatibleLibrary(old, next, provider); err == nil {
				t.Fatalf("accepted %s", kind)
			}
		})
	}
}
func TestInspectABIUsesRealVersionedLoaderExports(t *testing.T) {
	b, err := os.ReadFile("/" + amd64LoaderPath)
	must(t, err)
	provider, err := inspectABI(amd64LoaderPath, b)
	must(t, err)
	if !hasTLSExport(provider) {
		t.Fatal("actual amd64 loader versioned export was not parsed")
	}
	for _, s := range provider.Exports {
		if s.Name == "__tls_get_addr" && s.Version == "GLIBC_2.3" {
			return
		}
	}
	t.Fatal("missing versioned TLS definition")
}
func TestVerifiedArchiveELFBytesAndHardlinks(t *testing.T) {
	b, err := os.ReadFile("/" + amd64LoaderPath)
	must(t, err)
	var archive bytes.Buffer
	tw := tar.NewWriter(&archive)
	must(t, tw.WriteHeader(&tar.Header{Name: "./usr/lib/loader", Typeflag: tar.TypeReg, Size: int64(len(b)), Mode: 0755}))
	_, err = tw.Write(b)
	must(t, err)
	must(t, tw.WriteHeader(&tar.Header{Name: "./usr/lib/alias", Typeflag: tar.TypeLink, Linkname: "./usr/lib/loader", Mode: 0755}))
	must(t, tw.Close())
	files, elfs, err := inspectTar(archive.Bytes())
	must(t, err)
	payload := Payload{Files: files, ELF: elfs}
	images, err := verifiedArchiveELFs(archive.Bytes(), payload)
	must(t, err)
	if len(images) != 2 || !bytes.Equal(images["usr/lib/alias"], b) || !bytes.Equal(images["usr/lib/loader"], b) {
		t.Fatal("verified ELF/hardlink data was not carried through")
	}
	payload.ELF[0].SHA256 = digest([]byte("unqualified"))
	if images, err := verifiedArchiveELFs(archive.Bytes(), payload); err == nil || images != nil {
		t.Fatal("unqualified bytes were returned")
	}
}
func TestCheckABIRequiresVerifiedBytes(t *testing.T) {
	b, err := os.ReadFile("/" + amd64LoaderPath)
	must(t, err)
	e, err := inspectELF(amd64LoaderPath, b)
	must(t, err)
	if err := checkABI("/", Payload{ELF: []ELF{e}}, map[string][]byte{}); err == nil || !strings.Contains(err.Error(), "qualified ABI ELF bytes mismatch") {
		t.Fatalf("missing byte evidence accepted: %v", err)
	}
	must(t, checkABI("/", Payload{ELF: []ELF{e}}, map[string][]byte{amd64LoaderPath: b}))
}
