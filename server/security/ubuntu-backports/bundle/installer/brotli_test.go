package main

import (
	"reflect"
	"strings"
	"testing"
)

func TestBrotliExistingOnlyAndCompanion(t *testing.T) {
	for _, present := range []bool{false, true} {
		names := []string{"libc6", "coreutils-from-gnu", "gnu-coreutils"}
		if present {
			names = append(names, "libbrotli1")
		}
		i, f := fixture(t, names...)
		r, err := i.Execute(true)
		must(t, err)
		expected := []string{"libc6"}
		if present {
			expected = []string{"libbrotli1", "libc6"}
		}
		if !reflect.DeepEqual(r.Packages, expected) || r.BundleVersion != "0.1.1" || !r.ProviderPreserved {
			t.Fatalf("unexpected existing-only result: %#v", r)
		}
		if _, exists := f.installed["libbrotli1"]; exists != present {
			t.Fatal("Brotli package presence changed")
		}
	}
	i, f := fixture(t, "libbrotli1", "libbrotli-dev")
	p := f.installed["libbrotli-dev"]
	p.Depends = "libbrotli1 (= 1.0)"
	f.installed[p.Name] = p
	_, err := i.Execute(true)
	if err == nil || !strings.Contains(err.Error(), "matching companion archive is absent") || f.installedBatch != nil {
		t.Fatalf("missing exact-version development companion was accepted: %v", err)
	}
}
