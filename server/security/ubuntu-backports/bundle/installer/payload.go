package main

import (
	"archive/tar"
	"bytes"
	"debug/elf"
	"fmt"
	"io"
	"os"
	"path"
	"path/filepath"
	"reflect"
	"sort"
	"strings"
)

func unique(values []string) []string {
	sort.Strings(values)
	out := []string{}
	for _, v := range values {
		if len(out) == 0 || out[len(out)-1] != v {
			out = append(out, v)
		}
	}
	return out
}
func inspectELF(name string, content []byte) (ELF, error) {
	e := ELF{Path: name, SHA256: digest(content), ELFClass: 64, Machine: 62, Needed: []string{}, DefinedSymbols: []string{}}
	f, err := elf.NewFile(bytes.NewReader(content))
	if err != nil {
		return e, err
	}
	defer f.Close()
	if f.Class != elf.ELFCLASS64 || f.Machine != elf.EM_X86_64 || f.Data != elf.ELFDATA2LSB {
		return e, fmt.Errorf("non-amd64 ELF: %s", name)
	}
	soname, err := f.DynString(elf.DT_SONAME)
	if err != nil {
		return e, err
	}
	if len(soname) > 1 {
		return e, fmt.Errorf("multiple SONAMEs")
	}
	if len(soname) == 1 {
		e.SONAME = &soname[0]
	}
	e.Needed, err = f.ImportedLibraries()
	if err != nil {
		return e, err
	}
	e.Needed = unique(e.Needed)
	symbols, err := f.DynamicSymbols()
	if err != nil && err != elf.ErrNoSymbols {
		return e, err
	}
	for _, s := range symbols {
		if s.Section != elf.SHN_UNDEF && elf.ST_BIND(s.Info) != elf.STB_LOCAL && s.Name != "" {
			e.DefinedSymbols = append(e.DefinedSymbols, strings.SplitN(s.Name, "@", 2)[0])
		}
	}
	e.DefinedSymbols = unique(e.DefinedSymbols)
	return e, nil
}

// Parse the archive without extracting it. All non-directory entries, including
// hardlinks and symlinks, must exactly match the qualified payload receipt.
func inspectTar(content []byte) ([]File, []ELF, error) {
	t := tar.NewReader(bytes.NewReader(content))
	files := map[string]File{}
	blobs := map[string][]byte{}
	links := map[string]string{}
	dirs := map[string]bool{}
	var total int64
	count := 0
	for {
		h, err := t.Next()
		if err == io.EOF {
			break
		}
		if err != nil {
			return nil, nil, err
		}
		name := strings.TrimSuffix(strings.TrimPrefix(h.Name, "./"), "/")
		if name == "" && h.Typeflag == tar.TypeDir {
			continue
		}
		count++
		total += h.Size
		if count > 30000 || h.Size < 0 || total > 1<<30 || !safeRelative(name) || h.Uid < 0 || h.Gid < 0 || h.Mode < 0 || h.Mode > 07777 {
			return nil, nil, fmt.Errorf("unsafe/unbounded tar entry %q", h.Name)
		}
		if _, ok := files[name]; ok || dirs[name] {
			return nil, nil, fmt.Errorf("duplicate tar path %s", name)
		}
		f := File{Path: name, Mode: uint32(h.Mode), UID: h.Uid, GID: h.Gid}
		switch h.Typeflag {
		case tar.TypeDir:
			dirs[name] = true
			continue
		case tar.TypeReg, tar.TypeRegA:
			b, err := io.ReadAll(io.LimitReader(t, 256<<20+1))
			if err != nil {
				return nil, nil, err
			}
			if len(b) > 256<<20 {
				return nil, nil, fmt.Errorf("oversize payload file")
			}
			f.Type = "file"
			f.SHA256 = digest(b)
			blobs[name] = b
		case tar.TypeSymlink:
			if h.Linkname == "" || strings.ContainsAny(h.Linkname, "\x00\r\n") {
				return nil, nil, fmt.Errorf("invalid symlink")
			}
			f.Type = "symlink"
			f.Target = h.Linkname
		case tar.TypeLink:
			target := strings.TrimPrefix(h.Linkname, "./")
			if !safeRelative(target) {
				return nil, nil, fmt.Errorf("unsafe hardlink")
			}
			f.Type = "file"
			links[name] = target
		default:
			return nil, nil, fmt.Errorf("special payload entry: %s", name)
		}
		files[name] = f
	}
	for len(links) > 0 {
		progress := false
		for name, target := range links {
			if b, ok := blobs[target]; ok {
				blobs[name] = b
				f := files[name]
				f.SHA256 = digest(b)
				files[name] = f
				delete(links, name)
				progress = true
			}
		}
		if !progress {
			return nil, nil, fmt.Errorf("unresolved/cyclic hardlink")
		}
	}
	result := []File{}
	elfs := []ELF{}
	cached := map[string]ELF{}
	for name, f := range files {
		for parent := path.Dir(name); parent != "."; parent = path.Dir(parent) {
			if files[parent].Type == "symlink" {
				return nil, nil, fmt.Errorf("payload entry below symlink: %s", name)
			}
		}
		result = append(result, f)
		if b := blobs[name]; f.Type == "file" && bytes.HasPrefix(b, []byte("\x7fELF")) {
			e, ok := cached[f.SHA256]
			if !ok {
				var err error
				e, err = inspectELF(name, b)
				if err != nil {
					return nil, nil, err
				}
				cached[f.SHA256] = e
			}
			e.Path = name
			elfs = append(elfs, e)
		}
	}
	sort.Slice(result, func(i, j int) bool { return result[i].Path < result[j].Path })
	sort.Slice(elfs, func(i, j int) bool { return elfs[i].Path < elfs[j].Path })
	return result, elfs, nil
}
func validateArchive(content []byte, p Payload) error {
	files, elfs, err := inspectTar(content)
	if err != nil {
		return err
	}
	if !reflect.DeepEqual(files, p.Files) || !reflect.DeepEqual(elfs, p.ELF) {
		return fmt.Errorf("archive differs from qualified payload/ELF receipt: %s", p.Package)
	}
	return nil
}
func rootPath(root, name string) (string, error) {
	if !safeRelative(name) {
		return "", fmt.Errorf("unsafe rootfs path %q", name)
	}
	p := filepath.Join(root, filepath.FromSlash(name))
	parent, err := filepath.EvalSymlinks(filepath.Dir(p))
	if err != nil {
		return "", err
	}
	rel, err := filepath.Rel(root, parent)
	if err != nil || rel == ".." || strings.HasPrefix(rel, ".."+string(filepath.Separator)) {
		return "", fmt.Errorf("rootfs symlink escapes root")
	}
	return filepath.Join(parent, filepath.Base(p)), nil
}
func installedFile(root string, expected File) (File, []byte, error) {
	f := File{Path: expected.Path}
	p, err := rootPath(root, expected.Path)
	if err != nil {
		return f, nil, err
	}
	info, err := os.Lstat(p)
	if err != nil {
		return f, nil, err
	}
	f.Mode, f.UID, f.GID, err = fileOwnership(info)
	if err != nil {
		return f, nil, err
	}
	if info.Mode()&os.ModeSymlink != 0 {
		f.Type = "symlink"
		f.Target, err = os.Readlink(p)
		return f, nil, err
	}
	if !info.Mode().IsRegular() || info.Size() > 256<<20 {
		return f, nil, fmt.Errorf("special/unbounded installed file: %s", p)
	}
	f.Type = "file"
	b, err := os.ReadFile(p)
	if err != nil {
		return f, nil, err
	}
	f.SHA256 = digest(b)
	return f, b, nil
}
func verifyPayload(root string, p Payload) error {
	elfs := map[string]ELF{}
	for _, e := range p.ELF {
		elfs[e.Path] = e
	}
	for _, expected := range p.Files {
		got, b, err := installedFile(root, expected)
		if err != nil {
			return err
		}
		if got != expected {
			return fmt.Errorf("installed payload metadata/content differs: %s", expected.Path)
		}
		if e, ok := elfs[expected.Path]; ok {
			actual, err := inspectELF(expected.Path, b)
			if err != nil {
				return err
			}
			if !reflect.DeepEqual(actual, e) {
				return fmt.Errorf("installed ELF differs: %s", e.Path)
			}
		}
	}
	return nil
}
func checkABI(root string, p Payload) error {
	for _, candidate := range p.ELF {
		if candidate.SONAME == nil {
			continue
		}
		_, b, err := installedFile(root, File{Path: candidate.Path})
		if err != nil {
			return err
		}
		old, err := inspectELF(candidate.Path, b)
		if err != nil {
			return err
		}
		if !reflect.DeepEqual(old.SONAME, candidate.SONAME) || !reflect.DeepEqual(old.Needed, candidate.Needed) {
			return fmt.Errorf("library SONAME/NEEDED changed: %s", candidate.Path)
		}
		available := map[string]bool{}
		for _, symbol := range candidate.DefinedSymbols {
			available[symbol] = true
		}
		for _, symbol := range old.DefinedSymbols {
			if !available[symbol] {
				return fmt.Errorf("library dropped exported symbol %s: %s", symbol, candidate.Path)
			}
		}
	}
	return nil
}
