#!/usr/bin/env bash
set -Eeuo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
test "${GITHUB_REPOSITORY:-}" = PastureStack/server
test "${GITHUB_REF:-}" = refs/heads/main
test -z "$(git status --short)"
source_sha=$(git rev-parse HEAD)
test "$source_sha" = "$GITHUB_SHA"
evidence=${EVIDENCE_DIR:?EVIDENCE_DIR is required}
mkdir -p "$evidence"
printf '%s\n' "$source_sha" >"$evidence/source-revision.txt"

case "${COMPONENT:-}" in
  base) repository=ghcr.io/pasturestack/node-agent-base; version=v0.3.6 ;;
  agent) repository=ghcr.io/pasturestack/node-agent; version=v1.2.32 ;;
  *) echo 'Unsupported agent component' >&2; exit 1 ;;
esac
[[ "${PUBLISH:-false}" = true || "${PUBLISH:-false}" = false ]]
target="$repository:$version"
candidate="local/pasturestack-node-agent-${COMPONENT}:${GITHUB_RUN_ID}"
helper_container="pasturestack-agent-helper-${GITHUB_RUN_ID}"
scratch=$(mktemp -d)
cleanup() {
  docker rm -v "$helper_container" >/dev/null 2>&1 || true
  docker logout ghcr.io >/dev/null 2>&1 || true
  rm -rf "$scratch"
}
trap cleanup EXIT

if [[ "$COMPONENT" = base ]]; then
  # All values are constants from the reviewed source tree.
  source agent-base/release-inputs.env
  [[ "$MOUNT_PROPAGATION_VERSION" = 1.0.12 ]]
  [[ "$MOUNT_PROPAGATION_SHA256" =~ ^[0-9a-f]{64}$ ]]
  [[ "$MOUNT_PROPAGATION_ASSET" = mount-propagation-v1.0.12-linux-amd64 ]]
  export MOUNT_PROPAGATION_VERSION MOUNT_PROPAGATION_ASSET MOUNT_PROPAGATION_SHA256
  export MOUNT_PROPAGATION_ASSET_ID MOUNT_PROPAGATION_ASSET_SIZE MOUNT_PROPAGATION_SOURCE
  export MOUNT_PROPAGATION_TREE MOUNT_PROPAGATION_TAG_OBJECT
  gh api "repos/PastureStack/mount-propagation/releases/tags/v${MOUNT_PROPAGATION_VERSION}" >"$evidence/mount-release.json"
  gh api "repos/PastureStack/mount-propagation/git/ref/tags/v${MOUNT_PROPAGATION_VERSION}" >"$evidence/mount-ref.json"
  gh api "repos/PastureStack/mount-propagation/git/tags/${MOUNT_PROPAGATION_TAG_OBJECT}" >"$evidence/mount-tag.json"
  gh api "repos/PastureStack/mount-propagation/git/commits/${MOUNT_PROPAGATION_SOURCE}" >"$evidence/mount-commit.json"
  python3 scripts/check-agent-helper-release.py --self-test
  jq -n --slurpfile release "$evidence/mount-release.json" \
    --slurpfile ref "$evidence/mount-ref.json" --slurpfile tag "$evidence/mount-tag.json" \
    --slurpfile commit "$evidence/mount-commit.json" \
    '{release:$release[0],ref:$ref[0],tag:$tag[0],commit:$commit[0]}' \
    | python3 scripts/check-agent-helper-release.py
  curl --proto '=https' --proto-redir '=https' --fail --silent --show-error --location \
    --retry 3 --connect-timeout 15 --max-time 300 \
    --output "$scratch/share-mnt" \
    "https://github.com/PastureStack/mount-propagation/releases/download/v${MOUNT_PROPAGATION_VERSION}/${MOUNT_PROPAGATION_ASSET}"
  printf '%s  %s\n' "$MOUNT_PROPAGATION_SHA256" "$scratch/share-mnt" | sha256sum --check --strict
  test "$(wc -c <"$scratch/share-mnt")" -eq "$MOUNT_PROPAGATION_ASSET_SIZE"
  docker pull --platform linux/amd64 "$LEGACY_HELPER_IMAGE"
  docker create --name "$helper_container" "$LEGACY_HELPER_IMAGE" >/dev/null
  docker cp "$helper_container:/usr/bin/r" "$scratch/r"
  printf '%s  %s\n' "$LEGACY_HELPER_SHA256" "$scratch/r" | sha256sum --check --strict
  docker rm -v "$helper_container" >/dev/null
  (cd "$scratch" && sha256sum share-mnt r) >"$evidence/helper-inputs.sha256"
  cp agent-base/release-inputs.env "$evidence/"
  SHARE_MNT_BIN="$scratch/share-mnt" R_BIN="$scratch/r" IMAGE="$candidate" \
    bash agent-base/build-image.sh |& tee "$evidence/build.log"
else
  grep -Eq '^FROM ghcr.io/pasturestack/node-agent-base:v0\.3\.6@sha256:[0-9a-f]{64}$' agent/Dockerfile
  grep -Fq 'org.opencontainers.image.version="v1.2.32"' agent/Dockerfile
  IMAGE="$candidate" bash agent/build-image.sh |& tee "$evidence/build.log"
fi

test "$(docker image inspect "$candidate" --format '{{index .Config.Labels "org.opencontainers.image.version"}}')" = "$version"
test "$(docker image inspect "$candidate" --format '{{index .Config.Labels "org.opencontainers.image.revision"}}')" = "$source_sha"
local_id=$(docker image inspect "$candidate" --format '{{.Id}}')
docker image inspect "$candidate" >"$evidence/image-inspect.json"
docker run --rm --network none --entrypoint cat "$candidate" \
  /usr/share/pasturestack/python-builder-packages.tsv >"$evidence/builder-packages.tsv"
docker run --rm --network none --entrypoint dpkg-query "$candidate" \
  -W -f='${binary:Package}\t${Version}\n' >"$evidence/runtime-packages.tsv"
python3 - "$evidence" <<'PY'
from pathlib import Path
import json, sys
root = Path(sys.argv[1])
def packages(name):
    return dict(line.split('\t', 1) for line in (root / name).read_text().splitlines())
builder, runtime = packages('builder-packages.tsv'), packages('runtime-packages.tsv')
common = builder.keys() & runtime.keys()
assert all(builder[name] == runtime[name] for name in common), 'builder/runtime package drift'
for package, version in {'libssl3t64:amd64': '3.5.5-1ubuntu3.7', 'curl': '8.18.0-1ubuntu2.8',
                         'libc6:amd64': '2.43-2ubuntu2.4', 'ca-certificates': '20260816ubuntu0.26.04.1'}.items():
    assert runtime.get(package) == version, (package, runtime.get(package), version)
report = {'builder_packages': len(builder), 'runtime_packages': len(runtime),
          'common_packages_same_versions': len(common), 'expected_security_packages': True}
(root / 'package-comparison.json').write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps(report))
PY
docker run --rm --network none --entrypoint /bin/bash "$candidate" -ec \
  'ldd "$(python3 -c "import _ssl; print(_ssl.__file__)")"; curl --version' \
  >"$evidence/python-ssl-linkage.txt"
docker run --rm --network none --entrypoint /bin/bash "$candidate" -ec \
  'test "$(dpkg-query -W ca-certificates | cut -f2)" = 20260816ubuntu0.26.04.1; docker --version | grep -Fx "Docker version 29.9.2, build a82e528"; printf "6c71cfe71faff949a602946a4df4799b563232e79d0b8b6fd343d0ef081c9621  /usr/bin/docker\n" | sha256sum -c -; test -s /usr/bin/share-mnt; test -x /usr/bin/r' \
  |& tee "$evidence/runtime-tools.txt"
docker run --rm --network none --entrypoint cat "$candidate" /usr/bin/docker >"$scratch/docker-cli"
go version -m "$scratch/docker-cli" | tee "$evidence/docker-cli-go-version.txt"
head -1 "$evidence/docker-cli-go-version.txt" | grep -F 'go1.26.10'
docker run --rm --network none --entrypoint python3 \
  -e PYTHONDONTWRITEBYTECODE=1 -v "$PWD:/source:ro" -w /source "$candidate" \
  scripts/check-agent-python-runtime.py |& tee "$evidence/python-tls-registration.json"
docker run --rm --network none --entrypoint python3 \
  -e PYTHONDONTWRITEBYTECODE=1 -v "$PWD:/source:ro" -w /source "$candidate" \
  scripts/check-agent-control-plane-url.py |& tee "$evidence/control-plane-url-tests.txt"
docker run --rm --network none --entrypoint bash \
  -e PYTHONDONTWRITEBYTECODE=1 -v "$PWD:/source:ro" -w /source "$candidate" \
  tools/pip-security-overlay/verify-pip-runtime.sh |& tee "$evidence/pip-overlay-runtime.txt"
docker run --rm --network none --entrypoint python3 \
  -e PYTHONDONTWRITEBYTECODE=1 -v "$PWD:/source:ro" -w /source "$candidate" \
  tools/pip-security-overlay/check-pip-vendor-slice.py >"$evidence/pip-vendor-slice.json"
python3 tools/pip-security-overlay/test-pip-vex.py |& tee "$evidence/pip-vex-negative-controls.txt"
docker run --rm --entrypoint python3 "$candidate" -c \
  'import json, urllib.request; r=urllib.request.urlopen("https://pypi.org/pypi/pip/26.2.2/json", timeout=30); assert r.status == 200; assert json.load(r)["info"]["version"] == "26.2.2"; print("OFFICIAL_PYPI_TLS_OK")' \
  |& tee "$evidence/public-tls.txt"

trivy=ghcr.io/aquasecurity/trivy:0.74.0@sha256:62b1e65e8869bc4b4c6aa4fa2b21595256c7c2f6018a9d9ad61caf87187c1969
docker pull "$trivy"
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$evidence:/evidence" "$trivy" image --format cyclonedx \
  --output /evidence/image.cdx.json "$candidate"
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$evidence:/evidence" "$trivy" image --scanners vuln,secret --list-all-pkgs --format json \
  --output /evidence/image-security.json "$candidate"
python3 tools/pip-security-overlay/filter-pip-vendor-findings.py \
  --raw "$evidence/image-security.json" --proof "$evidence/pip-vendor-slice.json" \
  --output "$evidence/image-security-effective.json" --vex "$evidence/image.vex.json" \
  --subject "urn:sha256:${local_id#sha256:}"
python3 - "$evidence" <<'PY'
import json, pathlib, sys
root = pathlib.Path(sys.argv[1])
scan = json.loads((root / 'image-security-effective.json').read_text())
vulns = [v for r in scan.get('Results', []) for v in r.get('Vulnerabilities', [])]
secrets = [s for r in scan.get('Results', []) for s in r.get('Secrets', [])]
blocking = [v for v in vulns if v.get('Severity') in ('CRITICAL', 'HIGH') or v.get('FixedVersion')]
summary = {'critical_high_or_vendor_fixed': len(blocking), 'secrets': len(secrets),
           'vendor_unfixed_medium_low': len(vulns) - len(blocking)}
(root / 'security-summary.json').write_text(json.dumps(summary, indent=2) + '\n')
print(json.dumps(summary))
assert not blocking and not secrets, 'Agent image security gate failed; inspect raw report'
assert json.loads((root / 'image.cdx.json').read_text())['bomFormat'] == 'CycloneDX'
PY

if [[ "$PUBLISH" = true ]]; then
  if docker manifest inspect "$target" >"$scratch/existing.json" 2>"$scratch/manifest-error.txt"; then
    echo "Immutable version already exists: $target" >&2
    exit 1
  fi
  grep -Eiq 'manifest unknown|no such manifest' "$scratch/manifest-error.txt" || {
    echo 'Could not prove the target version is absent' >&2; exit 1;
  }
  printf '%s' "$REGISTRY_TOKEN" | docker login ghcr.io --username "$GITHUB_ACTOR" --password-stdin >/dev/null
  docker tag "$candidate" "$target"
  docker push "$target" | tee "$evidence/push.log"
  digest=$(docker buildx imagetools inspect "$target" --format '{{.Manifest.Digest}}')
  [[ "$digest" =~ ^sha256:[0-9a-f]{64}$ ]]
  docker logout ghcr.io >/dev/null
  # This readback is anonymous, by immutable digest, and must be the tested image.
  docker pull "$repository@$digest"
  test "$(docker image inspect "$repository@$digest" --format '{{.Id}}')" = "$local_id"
  python3 tools/pip-security-overlay/filter-pip-vendor-findings.py \
    --raw "$evidence/image-security.json" --proof "$evidence/pip-vendor-slice.json" \
    --output "$evidence/image-security-effective.json" --vex "$evidence/image.vex.json" \
    --subject "https://ghcr.io/v2/${repository#ghcr.io/}/manifests/$digest"
  printf 'repository=%s\nversion=%s\nsource=%s\ndigest=%s\nimage_id=%s\n' \
    "$repository" "$version" "$source_sha" "$digest" "$local_id" | tee "$evidence/published.txt"
  printf 'repository=%s\ndigest=%s\n' "$repository" "$digest" >>"$GITHUB_OUTPUT"
fi
(
  cd "$evidence"
  find . -maxdepth 1 -type f ! -name SHA256SUMS -printf '%f\0' | LC_ALL=C sort -z | xargs -0 sha256sum >SHA256SUMS
)
