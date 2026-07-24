#!/usr/bin/env bash
set -Eeuo pipefail

release_tag=${RELEASE_TAG:?RELEASE_TAG is required}
source_sha=${SOURCE_SHA:?SOURCE_SHA is required}
repository=${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}
run_id=${GITHUB_RUN_ID:?GITHUB_RUN_ID is required}
runner_temp=${RUNNER_TEMP:?RUNNER_TEMP is required}

expected_release_tag=v1.6.278
base_release_tag=v1.6.277
base_image_digest=sha256:075739b5ddf25805781a45cce10d183db2f31319ee53ec7e8fb781f5503e8b2e
catalog_release_tag=v0.20.7
catalog_version=0.20.7
catalog_source_commit=26bf62b24b4bf7893821f7a3f744f2e1d919411f
catalog_artifact_sha256=b195dd7f54fecc58e4af6942cd537b7deaaa7c659cfa97b3869e998e6b75fde3
runtime_license_version=1.6.278
runtime_license_sha256=317823d94aacb233fcc1827531bd45a4d0de54de0e75e53139bfdd7047c266e7
catalog_commit=025742e579efebb28d7ead2dc5e573138658d13e
trivy_version=0.72.0
trivy_archive_sha256=bbb64b9695866ce4a7a8f5c9592002c5961cab378577fa3f8a040df362b9b2ea

if [ "$repository" != PastureStack/server ]; then
  echo "Refusing release from unexpected repository: $repository" >&2
  exit 1
fi
if [ "$release_tag" != "$expected_release_tag" ]; then
  echo "Release tag must be $expected_release_tag" >&2
  exit 1
fi
if ! [[ "$source_sha" =~ ^[0-9a-f]{40}$ ]]; then
  echo 'SOURCE_SHA must be a full commit SHA' >&2
  exit 1
fi
test "$(git rev-parse HEAD)" = "$source_sha"
test -z "$(git status --short)"
test "$(git branch --show-current)" = ""
test "$(awk '$1 == "ENV" && $2 ~ /^CATTLE_RANCHER_SERVER_VERSION=/ { sub(/^[^=]+=/, "", $2); print $2; exit }' server/Dockerfile)" = "$release_tag"

if git ls-remote --exit-code --tags \
  "https://github.com/${repository}.git" \
  "refs/tags/${release_tag}" >/dev/null 2>&1; then
  echo "Tag already exists: $release_tag" >&2
  exit 1
fi
if gh release view "$release_tag" --repo "$repository" >/dev/null 2>&1; then
  echo "Release already exists: $release_tag" >&2
  exit 1
fi
if docker manifest inspect "ghcr.io/pasturestack/server:${release_tag}" >/dev/null 2>&1; then
  echo "Container tag already exists: $release_tag" >&2
  exit 1
fi

work_root="${runner_temp}/pasturestack-server-release-${run_id}"
case "$work_root" in
  "${runner_temp}"/pasturestack-server-release-*) ;;
  *) echo "Unsafe release work path: $work_root" >&2; exit 1 ;;
esac
test ! -e "$work_root"
mkdir -p "$work_root"
stage="$work_root/stage"
metadata="$work_root/metadata"
release_dir="$work_root/release"
tools_dir="$work_root/tools"
mkdir -p "$stage" "$metadata" "$release_dir" "$tools_dir"

artifact_server_pid=
smoke_containers=()
cleanup()
{
  local status=$?
  if [ -n "$artifact_server_pid" ]; then
    kill "$artifact_server_pid" >/dev/null 2>&1 || true
    wait "$artifact_server_pid" >/dev/null 2>&1 || true
  fi
  local container
  for container in "${smoke_containers[@]}"; do
    docker rm -fv "$container" >/dev/null 2>&1 || true
  done
  exit "$status"
}
trap cleanup EXIT

printf 'SERVER_RELEASE_PHASE source-gates\n'
bash scripts/check-server-source-gates.sh

printf 'SERVER_RELEASE_PHASE stage-assets\n'
base_url="https://github.com/PastureStack/server/releases/download/${base_release_tag}"
catalog_url="https://github.com/PastureStack/catalog-service/releases/download/${catalog_release_tag}"
curl -fsSL --retry 5 --retry-all-errors --retry-delay 2 \
  -o "$work_root/base-allowlist.txt" "${base_url}/release-asset-allowlist.txt"
curl -fsSL --retry 5 --retry-all-errors --retry-delay 2 \
  -o "$work_root/base-SHA256SUMS" "${base_url}/SHA256SUMS"
test "$(wc -l <"$work_root/base-allowlist.txt")" -eq 34

old_catalog_asset=catalog-service-0.20.7.tar.xz
old_license_asset=pasturestack-runtime-licenses-1.6.277.tar.xz
while IFS= read -r asset; do
  test -n "$asset"
  case "$asset" in
    "$old_catalog_asset"|"$old_license_asset") continue ;;
  esac
  expected="$(awk -v name="$asset" '$2 == name { print $1 }' "$work_root/base-SHA256SUMS")"
  test -n "$expected"
  curl -fsSL --retry 5 --retry-all-errors --retry-delay 2 \
    -o "$stage/$asset" "$base_url/$asset"
  printf '%s  %s\n' "$expected" "$stage/$asset" | sha256sum --check
done <"$work_root/base-allowlist.txt"

catalog_asset="catalog-service-${catalog_version}.tar.xz"
curl -fsSL --retry 5 --retry-all-errors --retry-delay 2 \
  -o "$stage/$catalog_asset" "$catalog_url/$catalog_asset"
printf '%s  %s\n' "$catalog_artifact_sha256" "$stage/$catalog_asset" |
  sha256sum --check

catalog_date="$(gh api \
  "repos/PastureStack/catalog-service/git/commits/${catalog_source_commit}" \
  --jq '.committer.date')"
license_epoch="$(date --date "$catalog_date" +%s)"
SOURCE_DATE_EPOCH="$license_epoch" \
PASTURESTACK_RELEASE_VERSION="$runtime_license_version" \
  scripts/build-runtime-license-bundle.sh "$stage" "$work_root/license-output"
license_asset="pasturestack-runtime-licenses-${runtime_license_version}.tar.xz"
mv "$work_root/license-output/$license_asset" "$stage/$license_asset"
printf '%s  %s\n' "$runtime_license_sha256" "$stage/$license_asset" |
  sha256sum --check

{
  grep -Fvx "$old_catalog_asset" "$work_root/base-allowlist.txt" |
    grep -Fvx "$old_license_asset"
  printf '%s\n' "$catalog_asset" "$license_asset"
} | LC_ALL=C sort >"$stage/release-asset-allowlist.txt"
test "$(wc -l <"$stage/release-asset-allowlist.txt")" -eq 34
test "$(sort "$stage/release-asset-allowlist.txt" | uniq | wc -l)" -eq 34

(
  cd "$stage"
  while IFS= read -r asset; do
    test -s "$asset"
    sha256sum "$asset"
  done <release-asset-allowlist.txt >SHA256SUMS
  sha256sum --check SHA256SUMS >/dev/null
)

test "$(awk -F '\t' '$2 == "catalog-service" { print $1 }' release/runtime-components.tsv)" = "$catalog_asset"
test "$(awk -F '\t' '$2 == "catalog-service" { print $4 }' release/runtime-components.tsv)" = "$catalog_source_commit"

printf 'SERVER_RELEASE_PHASE build-reproducible-images\n'
python3 -m http.server 18776 --bind 127.0.0.1 --directory "$stage" \
  >"$work_root/artifact-server.log" 2>&1 &
artifact_server_pid=$!
for _ in $(seq 1 30); do
  if curl -fsS "http://127.0.0.1:18776/SHA256SUMS" >/dev/null; then
    break
  fi
  sleep 1
done
curl -fsS "http://127.0.0.1:18776/SHA256SUMS" >/dev/null

source_date_epoch="$(git show -s --format=%ct "$source_sha")"
export PASTURESTACK_ARTIFACT_BASE_URL=http://127.0.0.1:18776
export PASTURESTACK_SERVER_REVISION="$source_sha"
export SOURCE_DATE_EPOCH="$source_date_epoch"

image_a="pasturestack-validation/server:${release_tag}-a"
image_b="pasturestack-validation/server:${release_tag}-b"
IMAGE="$image_a" server/build-runtime-hotfix-image.sh
IMAGE="$image_b" server/build-runtime-hotfix-image.sh
image_id_a="$(docker image inspect "$image_a" --format '{{.Id}}')"
image_id_b="$(docker image inspect "$image_b" --format '{{.Id}}')"
test "$image_id_a" = "$image_id_b"
test "$(docker image inspect "$image_a" --format '{{index .Config.Labels "org.opencontainers.image.version"}}')" = "$release_tag"
test "$(docker image inspect "$image_a" --format '{{index .Config.Labels "org.opencontainers.image.revision"}}')" = "$source_sha"
test "$(docker run --rm --entrypoint /usr/bin/catalog-service.real "$image_a" --version)" = "$catalog_release_tag"
test "$(docker run --rm --entrypoint sh "$image_a" -ec \
  "awk -F '\t' -v commit='$catalog_source_commit' '\$2 == \"catalog-service\" && \$4 == commit { found = 1 } END { exit !found }' /usr/share/licenses/pasturestack-runtime/SOURCES.tsv")" = ""

base_catalog_sha="$(docker run --rm --entrypoint sha256sum \
  "ghcr.io/pasturestack/server:${base_release_tag}@${base_image_digest}" \
  /usr/bin/catalog-service.real | awk '{print $1}')"
new_catalog_sha="$(docker run --rm --entrypoint sha256sum "$image_a" \
  /usr/bin/catalog-service.real | awk '{print $1}')"
test "$base_catalog_sha" = "$new_catalog_sha"

wait_for_server()
{
  local port=$1
  local container=$2
  for _ in $(seq 1 300); do
    if [ "$(curl -fsS --connect-timeout 2 --max-time 5 \
      "http://127.0.0.1:${port}/ping" 2>/dev/null || true)" = pong ]; then
      return 0
    fi
    sleep 1
  done
  docker logs --tail 300 "$container" >&2 || true
  return 1
}

wait_for_catalog()
{
  local port=$1
  local container=$2
  local response="$work_root/catalog-${container}.json"
  local ipsec_response="$work_root/catalog-ipsec-${container}.json"
  for _ in $(seq 1 180); do
    if curl -fsS --connect-timeout 2 --max-time 10 \
      "http://127.0.0.1:${port}/v1-catalog/templates?limit=-1" \
      -o "$response" 2>/dev/null &&
      jq -e '(.data // []) | length == 6' "$response" >/dev/null &&
      curl --globoff -fsS --connect-timeout 2 --max-time 10 \
        "http://127.0.0.1:${port}/v1-catalog/templates/pasturestack:infra*ipsec-overlay:1" \
        -o "$ipsec_response" 2>/dev/null &&
      jq -e '
        .id == "pasturestack:infra*ipsec-overlay:1" and
        (.files["docker-compose.yml.tpl"] // "") as $compose |
        ($compose | contains(
          "ghcr.io/pasturestack/ipsec-vxlan-overlay-network:v0.14.26"
        )) and
        ($compose | contains("  overlay-network:")) and
        ($compose | contains("  cni-driver:")) and
        (($compose | contains("@sha256:")) | not)
      ' "$ipsec_response" >/dev/null; then
      return 0
    fi
    sleep 1
  done
  test -f "$response" && cat "$response" >&2
  test -f "$ipsec_response" && cat "$ipsec_response" >&2
  docker logs --tail 300 "$container" >&2 || true
  return 1
}

smoke_image()
{
  local image=$1
  local container=$2
  local port=$3
  smoke_containers+=("$container")
  docker run -d \
    --name "$container" \
    --publish "127.0.0.1:${port}:8080" \
    "$image" >/dev/null
  wait_for_server "$port" "$container"
  wait_for_catalog "$port" "$container"
  docker restart "$container" >/dev/null
  wait_for_server "$port" "$container"
  wait_for_catalog "$port" "$container"
  test "$(docker inspect "$container" --format '{{.RestartCount}}')" = 0
  docker rm -fv "$container" >/dev/null
}

smoke_image "$image_a" pasturestack-server-local-smoke 18080

printf 'SERVER_RELEASE_PHASE security-scan\n'
trivy_archive="$tools_dir/trivy.tar.gz"
curl -fsSL --retry 5 --retry-all-errors --retry-delay 2 \
  -o "$trivy_archive" \
  "https://github.com/aquasecurity/trivy/releases/download/v${trivy_version}/trivy_${trivy_version}_Linux-64bit.tar.gz"
printf '%s  %s\n' "$trivy_archive_sha256" "$trivy_archive" | sha256sum --check
tar -xzf "$trivy_archive" -C "$tools_dir" trivy
test "$("$tools_dir/trivy" --version | awk 'NR == 1 { print $2 }')" = "$trivy_version"
export TRIVY_CACHE_DIR="$work_root/trivy-cache"

"$tools_dir/trivy" image \
  --scanners vuln,secret \
  --severity HIGH,CRITICAL \
  --ignore-unfixed \
  --exit-code 1 \
  --format json \
  --output "$metadata/trivy.json" \
  "$image_a"
test "$(jq '[.Results[]?.Vulnerabilities[]?] | length' "$metadata/trivy.json")" -eq 0
test "$(jq '[.Results[]?.Secrets[]?] | length' "$metadata/trivy.json")" -eq 0

"$tools_dir/trivy" image \
  --format spdx-json \
  --output "$metadata/sbom.spdx.json" \
  "$image_a"
test "$(jq -r '.spdxVersion' "$metadata/sbom.spdx.json")" = SPDX-2.3
sbom_packages="$(jq '(.packages // []) | length' "$metadata/sbom.spdx.json")"
test "$sbom_packages" -gt 0

printf 'SERVER_RELEASE_PHASE publish-image\n'
printf '%s' "$GH_TOKEN" |
  docker login ghcr.io --username "$GITHUB_ACTOR" --password-stdin >/dev/null
target_image="ghcr.io/pasturestack/server:${release_tag}"
docker tag "$image_a" "$target_image"
docker push "$target_image" >"$work_root/image-push.log"
docker buildx imagetools inspect "$target_image" >"$work_root/image-inspect.txt"
docker buildx imagetools inspect --raw "$target_image" >"$work_root/image-manifest.json"
image_digest="$(sed -n 's/^Digest:[[:space:]]*//p' "$work_root/image-inspect.txt" | head -n 1)"
[[ "$image_digest" =~ ^sha256:[0-9a-f]{64}$ ]]
jq -e '.schemaVersion == 2 and (.layers | length) > 0' \
  "$work_root/image-manifest.json" >/dev/null

docker logout ghcr.io >/dev/null
docker image rm "$target_image" "$image_a" "$image_b" >/dev/null
anonymous_image="ghcr.io/pasturestack/server@${image_digest}"
docker pull "$anonymous_image" >"$work_root/anonymous-pull.log"
test "$(docker image inspect "$anonymous_image" --format '{{index .Config.Labels "org.opencontainers.image.version"}}')" = "$release_tag"
test "$(docker image inspect "$anonymous_image" --format '{{index .Config.Labels "org.opencontainers.image.revision"}}')" = "$source_sha"
smoke_image "$anonymous_image" pasturestack-server-anonymous-smoke 18081
image_size="$(docker image inspect "$anonymous_image" --format '{{.Size}}')"

printf 'SERVER_RELEASE_PHASE assemble-release\n'
bash scripts/build-third-party-notices.sh \
  "$stage/$license_asset" \
  "$metadata/THIRD-PARTY-NOTICES.txt" \
  "$runtime_license_version"

cp "$stage/release-asset-allowlist.txt" "$release_dir/"
cp "$stage/SHA256SUMS" "$release_dir/"
cp "$metadata/sbom.spdx.json" "$release_dir/"
cp "$metadata/THIRD-PARTY-NOTICES.txt" "$release_dir/"
while IFS= read -r asset; do
  cp "$stage/$asset" "$release_dir/$asset"
done <"$stage/release-asset-allowlist.txt"
test "$(find "$release_dir" -maxdepth 1 -type f | wc -l)" -eq 38

asset_records="$work_root/assets.ndjson"
: >"$asset_records"
asset_json()
{
  local path=$1
  local kind=$2
  jq -cn \
    --arg name "$(basename "$path")" \
    --arg kind "$kind" \
    --arg sha256 "$(sha256sum "$path" | awk '{print $1}')" \
    --argjson sizeBytes "$(stat -c '%s' "$path")" \
    '{name:$name,kind:$kind,sha256:$sha256,sizeBytes:$sizeBytes}' \
    >>"$asset_records"
}
while IFS= read -r asset; do
  asset_json "$release_dir/$asset" runtime-asset
done <"$release_dir/release-asset-allowlist.txt"
asset_json "$release_dir/release-asset-allowlist.txt" asset-allowlist
asset_json "$release_dir/SHA256SUMS" runtime-checksums
asset_json "$release_dir/sbom.spdx.json" sbom
asset_json "$release_dir/THIRD-PARTY-NOTICES.txt" legal-index
test "$(wc -l <"$asset_records")" -eq 38

created="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
downstream_commit_count="$(git rev-list --count e780d3416460277ec56d77ac367dacbf564669a9..HEAD)"
jq -Sn \
  --slurpfile assets "$asset_records" \
  --arg release "$release_tag" \
  --arg created "$created" \
  --arg sourceCommit "$source_sha" \
  --arg imageDigest "$image_digest" \
  --arg catalogServiceRelease "$catalog_release_tag" \
  --arg catalogServiceCommit "$catalog_source_commit" \
  --arg catalogServiceArtifactSha256 "$catalog_artifact_sha256" \
  --arg catalogCommit "$catalog_commit" \
  --arg baseRelease "$base_release_tag" \
  --arg baseDigest "$base_image_digest" \
  --argjson imageSize "$image_size" \
  --argjson downstreamCommitCount "$downstream_commit_count" \
  --argjson sbomPackages "$sbom_packages" \
  '{
    schemaVersion: 1,
    release: $release,
    created: $created,
    supersedes: {
      release: $baseRelease,
      reason: "enforces semantic version tags for operational images and updates the IPsec Catalog topology"
    },
    source: {
      repository: "https://github.com/PastureStack/server",
      commit: $sourceCommit,
      upstreamRepository: "https://github.com/rancher/rancher",
      upstreamBoundary: "e780d3416460277ec56d77ac367dacbf564669a9",
      downstreamCommitCount: $downstreamCommitCount
    },
    containerImages: [{
      reference: ("ghcr.io/pasturestack/server:" + $release),
      digest: $imageDigest,
      platform: "linux/amd64",
      sizeBytes: $imageSize,
      ociRevision: $sourceCommit,
      baseRelease: $baseRelease,
      baseDigest: $baseDigest
    }],
    releaseAssetCount: 39,
    recordedAssetCount: 38,
    assets: $assets,
    validation: {
      imageBuilds: 2,
      reproducibleImage: true,
      sourceGates: 41,
      localFreshStartup: true,
      localRestart: true,
      anonymousPublicPull: true,
      anonymousFreshStartup: true,
      anonymousRestart: true,
      catalogPinnedCommit: $catalogCommit,
      catalogTemplateCount: 6,
      catalogService: {
        release: $catalogServiceRelease,
        commit: $catalogServiceCommit,
        artifactSha256: $catalogServiceArtifactSha256,
        emptyIndexRecovery: true
      },
      vulnerabilities: {
        actionableCritical: 0,
        actionableHigh: 0
      },
      secrets: 0,
      sbomPackages: $sbomPackages
    }
  }' >"$release_dir/release-manifest.json"
test "$(jq '.assets | length' "$release_dir/release-manifest.json")" -eq 38
test "$(find "$release_dir" -maxdepth 1 -type f | wc -l)" -eq 39

if grep -I -E -q \
  '(^|[^0-9])(10[.]|192[.]168[.]|172[.](1[6-9]|2[0-9]|3[01])[.])[0-9]+' \
  "$release_dir/release-manifest.json" \
  "$release_dir/THIRD-PARTY-NOTICES.txt" \
  "$release_dir/release-asset-allowlist.txt" \
  "$release_dir/SHA256SUMS"; then
  echo 'Private network coordinate found in release metadata' >&2
  exit 1
fi

release_notes="$work_root/release-notes.md"
cat >"$release_notes" <<EOF_NOTES
# PastureStack Server ${release_tag}

This release removes digest-qualified operational image references and updates the reviewed IPsec Catalog topology.

## Immutable coordinates

- Server source: \`${source_sha}\`
- Server image: \`ghcr.io/pasturestack/server:${release_tag}\`
- Verification digest: \`${image_digest}\`
- Catalog templates: \`${catalog_commit}\`
- Catalog Service: \`${catalog_release_tag}\` @ \`${catalog_source_commit}\`
- Catalog Service artifact SHA-256: \`${catalog_artifact_sha256}\`

## Run

\`\`\`sh
docker run -d \\
  --name pasturestack-server \\
  --restart unless-stopped \\
  -p 8080:8080 \\
  ghcr.io/pasturestack/server:${release_tag}
\`\`\`

## Validation

- All 41 Server source gates passed.
- Two clean focused builds produced the same image digest.
- Fresh startup, six-template Catalog availability, tag-only IPsec topology, restart recovery, anonymous public pull, and a second fresh startup all passed.
- Catalog, Compose, API, and web-console image fields use semantic version tags; the digest above is verification evidence only.
- Actionable High/Critical vulnerabilities: 0.
- Detected secrets: 0.
- The exact SPDX SBOM, checksums, source coordinates, Runtime license bundle, and third-party notices are attached.

PastureStack is an independent community effort to preserve, audit, and modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by Rancher Labs or SUSE.
EOF_NOTES

printf 'SERVER_RELEASE_PHASE publish-release\n'
mapfile -d '' release_assets < <(
  find "$release_dir" -maxdepth 1 -type f -print0 | sort -z
)
gh release create "$release_tag" \
  "${release_assets[@]}" \
  --repo "$repository" \
  --target "$source_sha" \
  --title "PastureStack Server ${release_tag}" \
  --notes-file "$release_notes" \
  --draft

test "$(gh release view "$release_tag" --repo "$repository" \
  --json isDraft,assets,targetCommitish \
  --jq '[.isDraft, (.assets | length), .targetCommitish] | @tsv')" = \
  $'true\t39\t'"$source_sha"
gh release edit "$release_tag" \
  --repo "$repository" \
  --draft=false \
  --latest
test "$(gh release view "$release_tag" --repo "$repository" \
  --json isDraft,isPrerelease,assets \
  --jq '[.isDraft, .isPrerelease, (.assets | length)] | @tsv')" = \
  $'false\tfalse\t39'

public_base="https://github.com/PastureStack/server/releases/download/${release_tag}"
curl -fsSL --retry 5 --retry-all-errors --retry-delay 2 \
  -o "$work_root/public-SHA256SUMS" "$public_base/SHA256SUMS"
cmp "$release_dir/SHA256SUMS" "$work_root/public-SHA256SUMS"
curl -fsSL --retry 5 --retry-all-errors --retry-delay 2 \
  -o "$work_root/public-catalog.tar.xz" "$public_base/$catalog_asset"
printf '%s  %s\n' "$catalog_artifact_sha256" "$work_root/public-catalog.tar.xz" |
  sha256sum --check

printf 'SERVER_GITHUB_RELEASE_OK release=%s source=%s image=%s assets=39 catalog_templates=6\n' \
  "$release_tag" "$source_sha" "$image_digest"
