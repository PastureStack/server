package main

import (
	"reflect"
	"testing"
)

func TestExcludedTranslationIsRestoredOnlyWithPayloadAndRule(t *testing.T) {
	const name = "usr/share/locale/ar/LC_MESSAGES/p11-kit.mo"
	p := Package{Name: "p11-kit"}
	payload := Payload{Files: []File{{Path: name, Type: "file", Mode: 0644}}}
	rules := []pathRule{{pattern: "/usr/share/locale/*"}}
	missing := []byte("missing     /" + name + "\n")
	got, err := beforeVerify(missing, p, payload, rules)
	must(t, err)
	if !reflect.DeepEqual(got, []string{"/" + name}) {
		t.Fatal("excluded message catalog was not explicitly recorded")
	}
	if _, err := beforeVerify(missing, p, payload, nil); err == nil {
		t.Fatal("missing translation without an exclusion was accepted")
	}
	if _, err := beforeVerify(missing, p, Payload{}, rules); err == nil {
		t.Fatal("missing translation outside the selected payload was accepted")
	}
	if _, err := beforeVerify([]byte("??5??????   /"+name+"\n"), p, payload, rules); err == nil {
		t.Fatal("modified translation content was accepted")
	}
	payload.ELF = []ELF{{Path: name}}
	if _, err := beforeVerify(missing, p, payload, rules); err == nil {
		t.Fatal("non-executable ELF disguised as a message catalog was accepted")
	}
}

func TestMessageCatalogRuleDoesNotPermitRuntimeExclusions(t *testing.T) {
	for _, file := range []File{
		{Path: "usr/share/locale/ar/LC_MESSAGES/p11-kit.mo", Type: "file", Mode: 0755},
		{Path: "usr/share/locale/ar/LC_MESSAGES/p11-kit.mo", Type: "symlink", Mode: 0777},
		{Path: "usr/share/locale/ar/LC_MESSAGES/p11-kit.so", Type: "file", Mode: 0644},
		{Path: "usr/share/locale/ar/p11-kit.mo", Type: "file", Mode: 0644},
		{Path: "usr/share/locale/ar/LC_MESSAGES/nested/p11-kit.mo", Type: "file", Mode: 0644},
		{Path: "usr/lib/x86_64-linux-gnu/libp11-kit.so.0", Type: "file", Mode: 0644},
		{Path: "usr/bin/p11-kit", Type: "file", Mode: 0755},
	} {
		if restorablePackageData(file, "p11-kit", nil) {
			t.Errorf("runtime or noncatalog path was accepted: %#v", file)
		}
	}
}
