package main

import (
	"fmt"
	"os"
	"path/filepath"
	"reflect"
	"regexp"
	"sort"
	"strings"
)

type Installed struct{ Name, Version, Architecture, Source, SourceVersion, Status, Depends, PreDepends string }
type Runner interface {
	Run(string, ...string) ([]byte, error)
}
type Installer struct {
	bundle, root string
	run          Runner
}
type Receipt struct {
	SchemaVersion              int      `json:"schemaVersion"`
	BundleVersion              string   `json:"bundleVersion"`
	Status                     string   `json:"status"`
	Packages                   []string `json:"packages"`
	BeforeMissingDocumentation []string `json:"beforeMissingDocumentation"`
	ExactPathIncludes          []string `json:"exactPathIncludes"`
	ProviderPreserved          bool     `json:"providerPreserved,omitempty"`
	ConfigurationPreserved     bool     `json:"configurationPreserved,omitempty"`
}

func parseInventory(b []byte) (map[string]Installed, error) {
	result := map[string]Installed{}
	for _, line := range strings.Split(strings.TrimSuffix(string(b), "\n"), "\n") {
		if line == "" {
			continue
		}
		fields := strings.Split(line, "\t")
		if len(fields) != 8 {
			return nil, fmt.Errorf("malformed dpkg inventory")
		}
		name := strings.SplitN(fields[0], ":", 2)[0]
		if fields[5] != "installed" {
			if fields[5] == "not-installed" || fields[5] == "config-files" {
				continue
			}
			return nil, fmt.Errorf("package not fully configured: %s (%s)", fields[0], fields[5])
		}
		if _, duplicate := result[name]; duplicate {
			return nil, fmt.Errorf("multiarch duplicate package: %s", name)
		}
		result[name] = Installed{name, fields[1], fields[2], fields[3], fields[4], fields[5], fields[6], fields[7]}
	}
	return result, nil
}
func (i Installer) inventory() (map[string]Installed, error) {
	b, err := i.run.Run("/usr/bin/dpkg-query", "--show", "--showformat=${binary:Package}\t${Version}\t${Architecture}\t${source:Package}\t${source:Version}\t${db:Status-Status}\t${Depends}\t${Pre-Depends}\n")
	if err != nil {
		return nil, err
	}
	return parseInventory(b)
}
func (i Installer) platform() error {
	b, err := os.ReadFile(filepath.Join(i.root, "etc/os-release"))
	if err != nil {
		return err
	}
	fields := map[string]string{}
	for _, line := range strings.Split(string(b), "\n") {
		k, v, ok := strings.Cut(line, "=")
		if ok {
			fields[k] = strings.Trim(v, "\"'")
		}
	}
	if fields["ID"] != "ubuntu" || fields["VERSION_ID"] != "26.04" {
		return fmt.Errorf("only Ubuntu 26.04 rootfs is supported")
	}
	b, err = i.run.Run("/usr/bin/dpkg", "--print-architecture")
	if err != nil {
		return err
	}
	if strings.TrimSpace(string(b)) != "amd64" {
		return fmt.Errorf("only native amd64 is supported")
	}
	return nil
}
func parseControl(b []byte) (map[string]string, error) {
	result := map[string]string{}
	last := ""
	for _, line := range strings.Split(strings.TrimSuffix(string(b), "\n"), "\n") {
		if strings.HasPrefix(line, " ") || strings.HasPrefix(line, "\t") {
			if last == "" {
				return nil, fmt.Errorf("invalid control continuation")
			}
			result[last] += " " + strings.TrimSpace(line)
			continue
		}
		key, value, ok := strings.Cut(line, ":")
		if !ok || key == "" {
			return nil, fmt.Errorf("invalid control field")
		}
		if _, duplicate := result[key]; duplicate {
			return nil, fmt.Errorf("duplicate control field")
		}
		last = key
		result[key] = strings.TrimSpace(value)
	}
	return result, nil
}
func (i Installer) archive(p Package, payload Payload) error {
	archive := filepath.Join(i.bundle, filepath.FromSlash(p.Archive.Path))
	b, err := i.run.Run("/usr/bin/dpkg-deb", "--field", archive)
	if err != nil {
		return err
	}
	c, err := parseControl(b)
	if err != nil {
		return err
	}
	source := c["Source"]
	if source == "" && p.Name == p.Source {
		source = p.Source
	}
	if c["Package"] != p.Name || c["Version"] != p.Version || c["Architecture"] != p.Architecture || (source != p.Source && source != p.Source+" ("+p.Version+")") {
		return fmt.Errorf("archive control identity mismatch: %s", p.Name)
	}
	b, err = i.run.Run("/usr/bin/dpkg-deb", "--fsys-tarfile", archive)
	if err != nil {
		return err
	}
	return validateArchive(b, payload)
}

var exactDependency = regexp.MustCompile(`(?:^|[,|])\s*([a-z0-9][a-z0-9+.-]*)(?::[a-z0-9-]+)?\s*\(=\s*([^()]+)\)`)

func companions(installed map[string]Installed, selected []Package) error {
	versions := map[string]string{}
	for _, p := range selected {
		versions[p.Name] = p.Version
	}
	for name, p := range installed {
		if _, upgraded := versions[name]; upgraded {
			continue
		}
		for _, match := range exactDependency.FindAllStringSubmatch(p.Depends+","+p.PreDepends, -1) {
			if target, upgraded := versions[match[1]]; upgraded && target != strings.TrimSpace(match[2]) {
				return fmt.Errorf("installed companion %s requires %s (= %s); matching companion archive is absent", name, match[1], strings.TrimSpace(match[2]))
			}
		}
	}
	return nil
}

type pathRule struct {
	pattern string
	include bool
}

func (i Installer) pathRules() ([]pathRule, error) {
	paths := []string{filepath.Join(i.root, "etc/dpkg/dpkg.cfg")}
	extra, err := filepath.Glob(filepath.Join(i.root, "etc/dpkg/dpkg.cfg.d/*"))
	if err != nil {
		return nil, err
	}
	sort.Strings(extra)
	paths = append(paths, extra...)
	rules := []pathRule{}
	for _, p := range paths {
		info, err := os.Lstat(p)
		if os.IsNotExist(err) {
			continue
		}
		if err != nil {
			return nil, err
		}
		if !info.Mode().IsRegular() {
			return nil, fmt.Errorf("dpkg configuration is not a regular file: %s", p)
		}
		b, err := os.ReadFile(p)
		if err != nil {
			return nil, err
		}
		for _, line := range strings.Split(string(b), "\n") {
			line = strings.TrimSpace(strings.SplitN(line, "#", 2)[0])
			line = strings.TrimPrefix(line, "--")
			for _, kind := range []string{"path-exclude", "path-include"} {
				if strings.HasPrefix(line, kind+"=") || strings.HasPrefix(line, kind+" ") {
					pattern := strings.TrimSpace(strings.TrimPrefix(strings.TrimPrefix(line, kind), "="))
					if !strings.HasPrefix(pattern, "/") || strings.ContainsAny(pattern, "\x00\r\n") {
						return nil, fmt.Errorf("invalid dpkg path rule")
					}
					rules = append(rules, pathRule{pattern, kind == "path-include"})
				}
			}
		}
	}
	return rules, nil
}

// dpkg's pathname filters use '*' across '/' (unlike filepath.Match).
func excluded(name string, rules []pathRule) bool {
	exclude := false
	for _, rule := range rules {
		pattern := "^"
		for _, c := range rule.pattern {
			switch c {
			case '*':
				pattern += ".*"
			case '?':
				pattern += "."
			default:
				pattern += regexp.QuoteMeta(string(c))
			}
		}
		pattern += "$"
		if regexp.MustCompile(pattern).MatchString("/" + name) {
			exclude = !rule.include
		}
	}
	return exclude
}
func documentation(name, pkg string) bool {
	return name == "usr/share/doc/"+pkg || strings.HasPrefix(name, "usr/share/doc/"+pkg+"/") || strings.HasPrefix(name, "usr/share/man/") || strings.HasPrefix(name, "usr/share/info/")
}

var missingLine = regexp.MustCompile(`^missing\s+(/\S+)$`)

func beforeVerify(output []byte, p Package, payload Payload, rules []pathRule) ([]string, error) {
	allowed := map[string]bool{}
	for _, f := range payload.Files {
		if documentation(f.Path, p.Name) && excluded(f.Path, rules) {
			allowed["/"+f.Path] = true
		}
	}
	missing := []string{}
	for _, line := range strings.Split(strings.TrimSuffix(string(output), "\n"), "\n") {
		if line == "" {
			continue
		}
		match := missingLine.FindStringSubmatch(line)
		if match == nil || !allowed[match[1]] {
			return nil, fmt.Errorf("pre-existing package integrity difference: %s: %s", p.Name, line)
		}
		missing = append(missing, match[1])
	}
	return unique(missing), nil
}
func (i Installer) audit() error {
	b, err := i.run.Run("/usr/bin/dpkg", "--audit")
	if err != nil {
		return err
	}
	if strings.TrimSpace(string(b)) != "" {
		return fmt.Errorf("dpkg audit is not clean: %s", b)
	}
	return nil
}

// Config files and provider selection are immutable across installation. Only
// ld.so.cache is generated by the required libc trigger; it is not host config.
func (i Installer) snapshot(installed map[string]Installed) (map[string]string, error) {
	result := map[string]string{}
	add := func(name string) error {
		if name == "etc/ld.so.cache" {
			return nil
		}
		p, err := rootPath(i.root, name)
		if err != nil {
			return err
		}
		info, err := os.Lstat(p)
		if os.IsNotExist(err) {
			result[name] = "absent"
			return nil
		}
		if err != nil {
			return err
		}
		if info.IsDir() {
			return nil
		}
		f, _, err := installedFile(i.root, File{Path: name})
		if err != nil {
			return err
		}
		result[name] = fmt.Sprintf("%s:%04o:%d:%d:%s:%s", f.Type, f.Mode, f.UID, f.GID, f.SHA256, f.Target)
		return nil
	}
	for _, dir := range []string{"etc", "var/lib/dpkg/alternatives"} {
		err := filepath.WalkDir(filepath.Join(i.root, dir), func(p string, d os.DirEntry, err error) error {
			if os.IsNotExist(err) {
				return nil
			}
			if err != nil {
				return err
			}
			if d.IsDir() {
				return nil
			}
			name, err := filepath.Rel(i.root, p)
			if err != nil {
				return err
			}
			return add(filepath.ToSlash(name))
		})
		if err != nil {
			return nil, err
		}
	}
	for _, name := range []string{"var/lib/dpkg/diversions", "var/lib/dpkg/statoverride"} {
		if err := add(name); err != nil {
			return nil, err
		}
	}
	for _, provider := range []string{"coreutils-from-uutils", "coreutils-from-gnu", "gnu-coreutils", "coreutils"} {
		p, ok := installed[provider]
		if !ok {
			continue
		}
		result["provider-package:"+provider] = fmt.Sprintf("%#v", p)
		b, err := i.run.Run("/usr/bin/dpkg-query", "--listfiles", provider)
		if err != nil {
			return nil, err
		}
		for _, name := range strings.Split(string(b), "\n") {
			if strings.HasPrefix(name, "/usr/bin/") || strings.HasPrefix(name, "/bin/") {
				if err := add(strings.TrimPrefix(name, "/")); err != nil {
					return nil, err
				}
			}
		}
	}
	return result, nil
}
func unchangedInventory(before, after map[string]Installed, selected []Package) error {
	if len(before) != len(after) {
		return fmt.Errorf("installation changed package set")
	}
	chosen := map[string]Package{}
	for _, p := range selected {
		chosen[p.Name] = p
	}
	for name, old := range before {
		now, exists := after[name]
		if !exists {
			return fmt.Errorf("package removed: %s", name)
		}
		if p, ok := chosen[name]; ok {
			if now.Version != p.Version || now.Architecture != p.Architecture || now.Source != p.Source || now.SourceVersion != p.Version || now.Status != "installed" {
				return fmt.Errorf("installed package identity mismatch: %s", name)
			}
		} else if old != now {
			return fmt.Errorf("unselected package changed: %s", name)
		}
	}
	return nil
}
func (i Installer) Execute(install bool) (Receipt, error) {
	r := Receipt{SchemaVersion: 1, BundleVersion: "0.1.0", Packages: []string{}, BeforeMissingDocumentation: []string{}, ExactPathIncludes: []string{}}
	if err := i.platform(); err != nil {
		return r, err
	}
	m, payloads, err := loadManifest(i.bundle)
	if err != nil {
		return r, err
	}
	installed, err := i.inventory()
	if err != nil {
		return r, err
	}
	if err = i.audit(); err != nil {
		return r, err
	}
	selected := []Package{}
	for _, p := range m.Packages {
		old, exists := installed[p.Name]
		if !exists {
			continue
		}
		if old.Architecture != "amd64" || old.Source != p.Source {
			return r, fmt.Errorf("unexpected installed source/architecture: %s", p.Name)
		}
		if !install && old.Version != p.Version {
			return r, fmt.Errorf("installed version is not qualified: %s", p.Name)
		}
		if _, err = i.run.Run("/usr/bin/dpkg", "--compare-versions", old.Version, "le", p.Version); err != nil {
			return r, fmt.Errorf("refuse downgrade: %s", p.Name)
		}
		if err = i.archive(p, payloads[p.Name]); err != nil {
			return r, err
		}
		selected = append(selected, p)
		r.Packages = append(r.Packages, p.Name)
	}
	if len(selected) == 0 {
		return r, fmt.Errorf("no existing qualified packages selected")
	}
	if err = companions(installed, selected); err != nil {
		return r, err
	}
	if !install {
		for _, p := range selected {
			if err = verifyPayload(i.root, payloads[p.Name]); err != nil {
				return r, err
			}
			out, e := i.run.Run("/usr/bin/dpkg", "--verify", p.Name)
			if e != nil || len(out) != 0 {
				return r, fmt.Errorf("post-install dpkg verification failed: %s: %s", p.Name, out)
			}
		}
		r.Status = "verified"
		return r, nil
	}
	rules, err := i.pathRules()
	if err != nil {
		return r, err
	}
	includes := []string{}
	for _, p := range selected {
		out, e := i.run.Run("/usr/bin/dpkg", "--verify", p.Name)
		if e != nil && len(out) == 0 {
			return r, e
		}
		missing, err := beforeVerify(out, p, payloads[p.Name], rules)
		if err != nil {
			return r, err
		}
		r.BeforeMissingDocumentation = append(r.BeforeMissingDocumentation, missing...)
		for _, f := range payloads[p.Name].Files {
			if excluded(f.Path, rules) {
				if !documentation(f.Path, p.Name) {
					return r, fmt.Errorf("dpkg excludes a runtime payload path: %s", f.Path)
				}
				includes = append(includes, "/"+f.Path)
			}
		}
		if err = checkABI(i.root, payloads[p.Name]); err != nil {
			return r, err
		}
	}
	r.BeforeMissingDocumentation = unique(r.BeforeMissingDocumentation)
	r.ExactPathIncludes = unique(includes)
	before, err := i.snapshot(installed)
	if err != nil {
		return r, err
	}
	archives := []string{}
	for _, p := range selected {
		archives = append(archives, filepath.Join(i.bundle, filepath.FromSlash(p.Archive.Path)))
	}
	dry := append([]string{"--no-act", "--install"}, archives...)
	if _, err = i.run.Run("/usr/bin/dpkg", dry...); err != nil {
		return r, fmt.Errorf("dependency preflight: %w", err)
	}
	args := []string{}
	for _, p := range r.ExactPathIncludes {
		args = append(args, "--path-include="+p)
	}
	args = append(args, "--install")
	args = append(args, archives...)
	if _, err = i.run.Run("/usr/bin/dpkg", args...); err != nil {
		return r, fmt.Errorf("batch installation: %w", err)
	}
	after, err := i.inventory()
	if err != nil {
		return r, err
	}
	if err = unchangedInventory(installed, after, selected); err != nil {
		return r, err
	}
	if err = i.audit(); err != nil {
		return r, err
	}
	now, err := i.snapshot(after)
	if err != nil {
		return r, err
	}
	if !reflect.DeepEqual(before, now) {
		return r, fmt.Errorf("provider or host configuration changed")
	}
	for _, p := range selected {
		if err = verifyPayload(i.root, payloads[p.Name]); err != nil {
			return r, err
		}
		out, e := i.run.Run("/usr/bin/dpkg", "--verify", p.Name)
		if e != nil || len(out) != 0 {
			return r, fmt.Errorf("post-install dpkg verification failed: %s: %s", p.Name, out)
		}
	}
	r.Status = "installed-and-verified"
	r.ProviderPreserved = true
	r.ConfigurationPreserved = true
	return r, nil
}
