package main

import (
	"archive/tar"
	"bytes"
	"debug/elf"
	"fmt"
	"io"
	"reflect"
	"sort"
)

const amd64Loader = "ld-linux-x86-64.so.2"
const amd64LoaderPath = "usr/lib/x86_64-linux-gnu/ld-linux-x86-64.so.2"

type abiSymbol struct {
	Name, Version, Library string
	Binding                elf.SymBind
	Type                   elf.SymType
	Visibility             elf.SymVis
	Hidden                 bool
}
type abiELF struct {
	Metadata         ELF
	Imports, Exports []abiSymbol
}

// No public payload fields change: return bytes only after the complete tar,
// file/link metadata and ELF receipts have matched the SHA-bound payload.
func verifiedArchiveELFs(content []byte, payload Payload) (map[string][]byte, error) {
	if err := validateArchive(content, payload); err != nil {
		return nil, err
	}
	byDigest := map[string][]byte{}
	reader := tar.NewReader(bytes.NewReader(content))
	for {
		h, err := reader.Next()
		if err == io.EOF {
			break
		}
		if err != nil {
			return nil, err
		}
		if h.Typeflag != tar.TypeReg && h.Typeflag != tar.TypeRegA {
			continue
		}
		b, err := io.ReadAll(io.LimitReader(reader, (256<<20)+1))
		if err != nil {
			return nil, err
		}
		if len(b) > 256<<20 {
			return nil, fmt.Errorf("oversize verified archive file")
		}
		if bytes.HasPrefix(b, []byte("\x7fELF")) {
			byDigest[digest(b)] = b
		}
	}
	result := map[string][]byte{}
	for _, e := range payload.ELF {
		b, exists := byDigest[e.SHA256]
		if !exists {
			return nil, fmt.Errorf("verified ELF bytes are absent: %s", e.Path)
		}
		result[e.Path] = b // A tar hardlink uses the same already-verified bytes.
	}
	return result, nil
}

func inspectABI(name string, content []byte) (abiELF, error) {
	metadata, err := inspectELF(name, content)
	if err != nil {
		return abiELF{}, err
	}
	f, err := elf.NewFile(bytes.NewReader(content))
	if err != nil {
		return abiELF{}, err
	}
	defer f.Close()
	symbols, err := f.DynamicSymbols()
	if err != nil && err != elf.ErrNoSymbols {
		return abiELF{}, err
	}
	result := abiELF{Metadata: metadata, Imports: []abiSymbol{}, Exports: []abiSymbol{}}
	for _, s := range symbols {
		if s.Name == "" || elf.ST_BIND(s.Info) == elf.STB_LOCAL {
			continue
		}
		item := abiSymbol{s.Name, s.Version, s.Library, elf.ST_BIND(s.Info), elf.ST_TYPE(s.Info), elf.ST_VISIBILITY(s.Other), s.VersionIndex.IsHidden()}
		if s.Section == elf.SHN_UNDEF {
			result.Imports = append(result.Imports, item)
		} else {
			result.Exports = append(result.Exports, item)
		}
	}
	return result, nil
}

func difference(a, b []string) []string {
	known := map[string]bool{}
	for _, value := range b {
		known[value] = true
	}
	out := []string{}
	for _, value := range a {
		if !known[value] {
			out = append(out, value)
		}
	}
	sort.Strings(out)
	return out
}
func hasTLSExport(provider abiELF) bool {
	if provider.Metadata.ELFClass != 64 || provider.Metadata.Machine != 62 || provider.Metadata.SONAME == nil || *provider.Metadata.SONAME != amd64Loader {
		return false
	}
	for _, symbol := range provider.Exports {
		if symbol.Name == "__tls_get_addr" && symbol.Version == "GLIBC_2.3" && symbol.Binding == elf.STB_GLOBAL && symbol.Type == elf.STT_FUNC && symbol.Visibility == elf.STV_DEFAULT && !symbol.Hidden {
			return true
		}
	}
	return false
}

func sonameValue(value *string) string {
	if value == nil {
		return "<none>"
	}
	return *value
}

// The only permitted NEEDED addition is the supported amd64 loader's exact TLS
// resolver. This is an ELF/platform rule and has no application/package names.
func compatibleLibrary(old, new abiELF, providers func() (abiELF, abiELF, error)) error {
	name := new.Metadata.Path
	if !reflect.DeepEqual(old.Metadata.SONAME, new.Metadata.SONAME) {
		return fmt.Errorf("library SONAME changed: %s old=%q new=%q", name, sonameValue(old.Metadata.SONAME), sonameValue(new.Metadata.SONAME))
	}
	type exportKey struct {
		Name, Version string
		Hidden        bool
	}
	available := map[exportKey]bool{}
	for _, s := range new.Exports {
		available[exportKey{s.Name, s.Version, s.Hidden}] = true
	}
	for _, s := range old.Exports {
		if !available[exportKey{s.Name, s.Version, s.Hidden}] {
			return fmt.Errorf("library dropped exported symbol %s@%s: %s", s.Name, s.Version, name)
		}
	}
	removed := difference(old.Metadata.Needed, new.Metadata.Needed)
	added := difference(new.Metadata.Needed, old.Metadata.Needed)
	if len(removed) > 0 {
		return fmt.Errorf("library NEEDED removed: %s old=%v new=%v removed=%v", name, old.Metadata.Needed, new.Metadata.Needed, removed)
	}
	if len(added) == 0 {
		return nil
	}
	if old.Metadata.ELFClass != 64 || old.Metadata.Machine != 62 || new.Metadata.ELFClass != 64 || new.Metadata.Machine != 62 || len(added) != 1 || added[0] != amd64Loader {
		return fmt.Errorf("library NEEDED addition is unsupported: %s old=%v new=%v added=%v", name, old.Metadata.Needed, new.Metadata.Needed, added)
	}
	original := map[abiSymbol]bool{}
	for _, s := range old.Imports {
		original[s] = true
	}
	delta := []abiSymbol{}
	for _, s := range new.Imports {
		if !original[s] {
			delta = append(delta, s)
		}
	}
	expected := abiSymbol{Name: "__tls_get_addr", Version: "GLIBC_2.3", Library: amd64Loader, Binding: elf.STB_GLOBAL, Type: elf.STT_FUNC, Visibility: elf.STV_DEFAULT}
	if len(delta) != 1 || delta[0] != expected {
		return fmt.Errorf("library TLS import delta is unsupported: %s newImports=%v", name, delta)
	}
	if providers == nil {
		return fmt.Errorf("qualified and installed amd64 loader evidence is missing: %s", name)
	}
	installed, qualified, err := providers()
	if err != nil {
		return err
	}
	if !hasTLSExport(installed) || !hasTLSExport(qualified) {
		return fmt.Errorf("installed/qualified loader lacks public __tls_get_addr@GLIBC_2.3: %s", name)
	}
	return nil
}

func checkABI(root string, p Payload, qualified map[string][]byte) error {
	providers := func() (abiELF, abiELF, error) {
		b, exists := qualified[amd64LoaderPath]
		if !exists {
			return abiELF{}, abiELF{}, fmt.Errorf("qualified amd64 loader bytes are absent")
		}
		next, err := inspectABI(amd64LoaderPath, b)
		if err != nil {
			return abiELF{}, abiELF{}, err
		}
		_, b, err = installedFile(root, File{Path: amd64LoaderPath})
		if err != nil {
			return abiELF{}, abiELF{}, err
		}
		current, err := inspectABI(amd64LoaderPath, b)
		return current, next, err
	}
	for _, candidate := range p.ELF {
		if candidate.SONAME == nil {
			continue
		}
		b, exists := qualified[candidate.Path]
		if !exists || digest(b) != candidate.SHA256 {
			return fmt.Errorf("qualified ABI ELF bytes mismatch: %s", candidate.Path)
		}
		next, err := inspectABI(candidate.Path, b)
		if err != nil {
			return err
		}
		if !reflect.DeepEqual(next.Metadata, candidate) {
			return fmt.Errorf("qualified ABI metadata mismatch: %s", candidate.Path)
		}
		_, b, err = installedFile(root, File{Path: candidate.Path})
		if err != nil {
			return err
		}
		current, err := inspectABI(candidate.Path, b)
		if err != nil {
			return err
		}
		if err = compatibleLibrary(current, next, providers); err != nil {
			return err
		}
	}
	return nil
}
