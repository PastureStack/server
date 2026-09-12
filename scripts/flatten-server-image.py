#!/usr/bin/env python3
"""Encode and verify metadata for a single-layer Server release image.

Docker operations stay in the release workflow, which owns exact image names
and paths. This tool only transforms Docker's JSON image-inspect input into
NUL-delimited Dockerfile metadata instructions, then verifies the result.
"""

import json
import sys


def instruction_value(value):
    if not isinstance(value, str) or any(ord(char) < 32 for char in value):
        raise SystemExit("Image metadata contains a control character")
    return json.dumps(value, ensure_ascii=True, separators=(",", ":"))


def validate_source(image):
    if image["Os"] != "linux" or image["Architecture"] != "amd64":
        raise SystemExit("Only the reviewed linux/amd64 Server image is supported")
    config = image["Config"]
    if config.get("OnBuild") or config.get("Shell") or config.get("Healthcheck"):
        raise SystemExit("Unhandled image configuration; extend and verify this tool first")
    return config


def changes(image):
    config = validate_source(image)
    result = []
    for item in config.get("Env") or []:
        key, separator, value = item.partition("=")
        if (
            not separator or not key or not key.isascii()
            or not (key[0].isalpha() or key[0] == "_")
            or not all(char.isalnum() or char == "_" for char in key[1:])
        ):
            raise SystemExit("Invalid environment variable name in source image")
        result.append("ENV " + key + "=" + instruction_value(value))
    for port in sorted(config.get("ExposedPorts") or {}):
        number, separator, protocol = port.partition("/")
        if (
            not separator or protocol not in {"tcp", "udp", "sctp"}
            or not number.isascii() or not number.isdecimal()
            or len(number) > 5 or not 0 < int(number) <= 65535
        ):
            raise SystemExit("Invalid exposed port in source image")
        result.append("EXPOSE " + port)
    for key, value in sorted((config.get("Labels") or {}).items()):
        if (
            not key or not key.isascii()
            or not all(char.isalnum() or char in "_.-" for char in key)
        ):
            raise SystemExit("Invalid label name in source image")
        result.append("LABEL " + key + "=" + instruction_value(value))
    if config.get("User"):
        result.append("USER " + instruction_value(config["User"]))
    if config.get("WorkingDir"):
        result.append("WORKDIR " + instruction_value(config["WorkingDir"]))
    if config.get("Volumes"):
        paths = sorted(config["Volumes"])
        if not all(path.startswith("/") for path in paths):
            raise SystemExit("Invalid volume path in source image")
        result.append("VOLUME " + json.dumps(paths, separators=(",", ":")))
    if config.get("Entrypoint"):
        result.append("ENTRYPOINT " + json.dumps(config["Entrypoint"], separators=(",", ":")))
    if config.get("Cmd"):
        result.append("CMD " + json.dumps(config["Cmd"], separators=(",", ":")))
    if config.get("StopSignal"):
        result.append("STOPSIGNAL " + instruction_value(config["StopSignal"]))
    return result


def verify(source, target):
    config = validate_source(source)
    # ArgsEscaped only affects Windows command parsing. All other config
    # fields, including fields added in future images, must remain identical.
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
    print(
        "SERVER_IMAGE_FLATTEN_OK "
        f"source_layers={len(source['RootFS']['Layers'])} "
        f"target_layers={layers} config=identical platform=linux/amd64"
    )


def main():
    if len(sys.argv) != 2 or sys.argv[1] not in {"changes", "verify"}:
        raise SystemExit("Usage: flatten-server-image.py changes|verify < docker-image-inspect.json")
    images = json.load(sys.stdin)
    if sys.argv[1] == "changes":
        if len(images) != 1:
            raise SystemExit("Expected exactly one source image")
        for item in changes(images[0]):
            sys.stdout.buffer.write(item.encode("utf-8") + b"\0")
    else:
        if len(images) != 2:
            raise SystemExit("Expected source and flattened image")
        verify(images[0], images[1])


if __name__ == "__main__":
    main()
