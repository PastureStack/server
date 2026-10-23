#!/usr/bin/env python3
"""Validate the exact published mount helper and its signed source binding."""
import copy
import json
import os
from pathlib import Path
import sys


def validate(expected, release, ref, tag, commit):
    assert release["draft"] is False and release.get("published_at")
    assert release["tag_name"] == "v" + expected["VERSION"]
    assets = [item for item in release["assets"] if item["name"] == expected["ASSET"]]
    assert len(assets) == 1
    asset = assets[0]
    assert asset["id"] == int(expected["ASSET_ID"])
    assert asset["size"] == int(expected["ASSET_SIZE"])
    assert asset["digest"] == "sha256:" + expected["SHA256"]
    assert ref["object"] == {"type": "tag", "sha": expected["TAG_OBJECT"],
                              "url": ref["object"]["url"]}
    assert tag["tag"] == "v" + expected["VERSION"]
    assert tag["verification"]["verified"] is True
    assert tag["object"]["type"] == "commit"
    assert tag["object"]["sha"] == expected["SOURCE"]
    assert commit["sha"] == expected["SOURCE"]
    assert commit["tree"]["sha"] == expected["TREE"]
    # GitHub's immutable flag is recorded, not retroactively required. The
    # signed tag object, source tree, asset identity and downloaded hash are pins.


def self_test():
    expected = dict(VERSION="1.0.12", ASSET="helper", ASSET_ID="1", ASSET_SIZE="2",
                    SHA256="a"*64, SOURCE="b"*40, TREE="c"*40, TAG_OBJECT="d"*40)
    release = dict(draft=False, immutable=False, published_at="now", tag_name="v1.0.12",
                   assets=[dict(name="helper", id=1, size=2, digest="sha256:"+"a"*64)])
    ref = dict(object=dict(type="tag", sha="d"*40, url="https://api.github.com/tag"))
    tag = dict(tag="v1.0.12", verification=dict(verified=True), object=dict(type="commit", sha="b"*40))
    commit = dict(sha="b"*40, tree=dict(sha="c"*40))
    validate(expected, release, ref, tag, commit)
    for target, mutate in (
        (0, lambda value: value["assets"][0].update(digest="sha256:"+"e"*64)),
        (2, lambda value: value["object"].update(sha="f"*40)),
        (0, lambda value: value.update(draft=True)),
        (2, lambda value: value["verification"].update(verified=False)),
    ):
        values = copy.deepcopy([release, ref, tag, commit])
        mutate(values[target])
        try:
            validate(expected, *values)
        except AssertionError:
            continue
        raise AssertionError("invalid helper release accepted")
    print("HELPER_RELEASE_GATE_TESTS_OK published_and_four_negative_controls")


if __name__ == "__main__":
    if sys.flags.optimize:
        raise RuntimeError("Security release verification must not run with Python optimization")
    if sys.argv[1:] == ["--self-test"]:
        self_test()
    else:
        root = Path(os.environ["RUNNER_TEMP"]) / "node-agent-evidence"
        expected = {name.removeprefix("MOUNT_PROPAGATION_"): value
                    for name, value in os.environ.items() if name.startswith("MOUNT_PROPAGATION_")}
        validate(expected, json.loads((root / "mount-release.json").read_text()),
                 json.loads((root / "mount-ref.json").read_text()),
                 json.loads((root / "mount-tag.json").read_text()),
                 json.loads((root / "mount-commit.json").read_text()))
        print("HELPER_RELEASE_IDENTITY_OK")
