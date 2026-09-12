#!/usr/bin/env python3
"""Flatten a tested Server rootfs while preserving its Docker runtime contract.

The Server release inherits a long compatibility-patch chain.  The classic
overlay2 store cannot register an image with that many lower layers.  This
script changes packaging only: it imports the exact exported rootfs and
reapplies, then compares, every runtime configuration field used by the image.
"""

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path


def docker_json(reference):
    return json.loads(
        subprocess.check_output(
            ["docker", "image", "inspect", reference], text=True
        )
    )[0]


def instruction_value(value):
    return json.dumps(value, ensure_ascii=True, separators=(",", ":"))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("source_image")
    parser.add_argument("rootfs_tar")
    parser.add_argument("target_image")
    args = parser.parse_args()

    source_match = re.fullmatch(
        r"local/pasturestack/server-layered:(v[0-9]+\.[0-9]+\.[0-9]+-[0-9]+)",
        args.source_image,
    )
    target_match = re.fullmatch(
        r"local/pasturestack/server:(v[0-9]+\.[0-9]+\.[0-9]+-[0-9]+)",
        args.target_image,
    )
    rootfs = Path(args.rootfs_tar)
    if (
        not source_match
        or not target_match
        or source_match.group(1) != target_match.group(1)
        or not rootfs.is_absolute()
        or rootfs.name != "server-layered-rootfs.tar"
        or rootfs.is_symlink()
        or not rootfs.is_file()
    ):
        raise SystemExit("Expected one matching CI release pair and its regular rootfs tar")

    source = docker_json(args.source_image)
    if source["Os"] != "linux" or source["Architecture"] != "amd64":
        raise SystemExit("Only the reviewed linux/amd64 Server image is supported")
    config = source["Config"]
    if config.get("OnBuild") or config.get("Shell") or config.get("Healthcheck"):
        raise SystemExit("Unhandled image configuration; extend and verify this tool first")

    changes = []
    for item in config.get("Env") or []:
        key, separator, value = item.partition("=")
        if not separator or not re.fullmatch(r"[A-Za-z_][A-Za-z_0-9]*", key):
            raise SystemExit("Invalid environment variable name in source image")
        changes.append("ENV " + key + "=" + instruction_value(value))
    for port in sorted(config.get("ExposedPorts") or {}):
        changes.append("EXPOSE " + port)
    for key, value in sorted((config.get("Labels") or {}).items()):
        changes.append("LABEL " + key + "=" + instruction_value(value))
    if config.get("User"):
        changes.append("USER " + instruction_value(config["User"]))
    if config.get("WorkingDir"):
        changes.append("WORKDIR " + instruction_value(config["WorkingDir"]))
    if config.get("Volumes"):
        changes.append("VOLUME " + instruction_value(sorted(config["Volumes"])))
    if config.get("Entrypoint"):
        changes.append("ENTRYPOINT " + instruction_value(config["Entrypoint"]))
    if config.get("Cmd"):
        changes.append("CMD " + instruction_value(config["Cmd"]))
    if config.get("StopSignal"):
        changes.append("STOPSIGNAL " + config["StopSignal"])

    command = ["docker", "image", "import", "--platform", "linux/amd64"]
    for change in changes:
        command.extend(["--change", change])
    command.extend([str(rootfs), args.target_image])
    subprocess.run(command, check=True, stdout=subprocess.DEVNULL)

    target = docker_json(args.target_image)
    # ArgsEscaped is an image-serialization hint for Windows command parsing;
    # the release is Linux-only. Every other field, including any future field
    # this script did not expect, must match rather than silently disappear.
    keys = (set(config) | set(target["Config"])) - {"ArgsEscaped"}
    mismatches = sorted(
        key for key in keys if config.get(key) != target["Config"].get(key)
    )
    if mismatches:
        raise SystemExit("Flattened image configuration differs: " + ", ".join(mismatches))
    layers = len(target["RootFS"]["Layers"])
    if layers != 1:
        raise SystemExit(f"Expected one rootfs layer, got {layers}")
    if target["Os"] != source["Os"] or target["Architecture"] != source["Architecture"]:
        raise SystemExit("Flattened image platform differs")
    print(f"SERVER_IMAGE_FLATTEN_OK source_layers={len(source['RootFS']['Layers'])} target_layers={layers} config=identical platform=linux/amd64")


if __name__ == "__main__":
    try:
        main()
    except subprocess.CalledProcessError as error:
        print(f"Docker command failed with exit code {error.returncode}", file=sys.stderr)
        sys.exit(error.returncode)
