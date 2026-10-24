package main

import (
	"os"
	"path/filepath"
	"testing"
)

func TestConfinedReadsRejectTraversalAndOutsideSymlinkParents(t *testing.T) {
	root, outside := t.TempDir(), t.TempDir()
	write(t, outside, "secret", []byte("outside bytes must not be read"))
	must(t, os.Symlink(outside, filepath.Join(root, "escape")))
	for _, name := range []string{"../secret", "/secret", "escape/secret"} {
		t.Run(name, func(t *testing.T) {
			if _, err := regularRead(root, name, 1024); err == nil {
				t.Fatal("bundle read escaped root")
			}
			if _, b, err := installedFile(root, File{Path: name}); err == nil || len(b) != 0 {
				t.Fatal("installed file read escaped root")
			}
		})
	}
}

func TestConfinedReadsPreserveRuntimeLinksAndBundleNoLinks(t *testing.T) {
	root := t.TempDir()
	write(t, root, "usr/lib/value", []byte("confined value"))
	must(t, os.Symlink("lib", filepath.Join(root, "usr/alias")))
	got, b, err := installedFile(root, File{Path: "usr/alias/value"})
	must(t, err)
	if got.SHA256 != digest([]byte("confined value")) || string(b) != "confined value" {
		t.Fatal("legitimate relative runtime symlink failed")
	}
	if _, err := regularRead(root, "usr/alias/value", 1024); err == nil {
		t.Fatal("bundle symlink parent was accepted")
	}
	must(t, os.Symlink("/usr/lib/value", filepath.Join(root, "usr/link")))
	got, b, err = installedFile(root, File{Path: "usr/link"})
	must(t, err)
	if got.Type != "symlink" || got.Target != "/usr/lib/value" || len(b) != 0 {
		t.Fatal("literal absolute final symlink was followed or changed")
	}
}

func TestConfinedOpenRejectsFinalSymlinkAndKeepsBounds(t *testing.T) {
	root := t.TempDir()
	write(t, root, "value", []byte("12345"))
	must(t, os.Symlink("value", filepath.Join(root, "link")))
	directory, err := os.OpenRoot(root)
	must(t, err)
	defer directory.Close()
	if file, err := openRegularInRoot(directory, "link"); err == nil {
		file.Close()
		t.Fatal("final symlink was followed by the confined regular open")
	}
	if _, err := regularRead(root, "value", 4); err == nil {
		t.Fatal("size bound was weakened")
	}
	b, err := regularRead(root, "value", 5)
	must(t, err)
	if string(b) != "12345" {
		t.Fatal("bounded legitimate read failed")
	}
}
