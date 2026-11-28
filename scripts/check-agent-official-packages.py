"""Verify that only the approved Ubuntu security revisions changed after backport qualification."""
import json
import sys
from pathlib import Path

PACKAGES = {
    "libc6": "2.43-2ubuntu2.7",
    "libc-bin": "2.43-2ubuntu2.7",
    "libc-gconv-modules-extra": "2.43-2ubuntu2.7",
    "libbrotli1": "1.2.0-3ubuntu0.1",
    "libexpat1": "2.7.4-1ubuntu0.3",
    "libgssapi-krb5-2": "1.22.1-2ubuntu4.3",
    "libk5crypto3": "1.22.1-2ubuntu4.3",
    "libkrb5-3": "1.22.1-2ubuntu4.3",
    "libkrb5support0": "1.22.1-2ubuntu4.3",
    "libpcap0.8t64": "1.10.6-1ubuntu1.2",
}
PREFIX = "pkg:deb/ubuntu/"


def os_packages(path):
    report = json.loads(path.read_bytes())
    if report.get("bomFormat") != "CycloneDX":
        raise ValueError("CycloneDX SBOM required")
    packages = {}
    for component in report["components"]:
        purl = component.get("purl", "")
        if not purl.startswith(PREFIX):
            continue
        name = component["name"]
        if name in packages:
            raise ValueError("Duplicate Ubuntu package: " + name)
        packages[name] = (component["version"], purl)
    return packages


def verify(before, after):
    if not PACKAGES.keys() <= before.keys() or before.keys() != after.keys():
        raise ValueError("Installed Ubuntu package set changed")
    for name, original in before.items():
        version = PACKAGES.get(name)
        expected = (version, f"{PREFIX}{name}@{version}?arch=amd64&distro=ubuntu-26.04") if version else original
        if after[name] != expected:
            raise ValueError("Unexpected Ubuntu package identity: " + name)


if __name__ == "__main__":
    before, after = map(Path, sys.argv[1:])
    verify(os_packages(before), os_packages(after))
    print("AGENT_OFFICIAL_PACKAGES_SBOM_CLOSURE_OK")
