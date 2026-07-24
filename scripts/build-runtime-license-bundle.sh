#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
component_file="$repo_root/release/runtime-components.tsv"
artifact_dir=${1:-}
output_dir=${2:-"$repo_root/dist/release"}
release_version="${PASTURESTACK_RELEASE_VERSION:-1.6.274}"
source_date_epoch="${SOURCE_DATE_EPOCH:-}"

if [ -z "$artifact_dir" ] || [ ! -d "$artifact_dir" ]; then
  echo 'usage: SOURCE_DATE_EPOCH=<epoch> scripts/build-runtime-license-bundle.sh <artifact-directory> [output-directory]' >&2
  exit 2
fi
if ! [[ "$source_date_epoch" =~ ^[0-9]+$ ]]; then
  echo 'SOURCE_DATE_EPOCH must be a non-negative integer' >&2
  exit 2
fi
if ! [[ "$release_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo 'PASTURESTACK_RELEASE_VERSION must use numeric x.y.z form' >&2
  exit 2
fi

artifact_dir=$(cd "$artifact_dir" && pwd)
mkdir -p "$output_dir"
output_dir=$(cd "$output_dir" && pwd)
workdir=$(mktemp -d "${TMPDIR:-/tmp}/pasturestack-runtime-licenses.XXXXXX")
cleanup()
{
  rm -rf "$workdir"
}
trap cleanup EXIT

bundle_name="pasturestack-runtime-licenses-${release_version}"
bundle_root="$workdir/$bundle_name"
mkdir -p "$bundle_root/source-legal" "$bundle_root/embedded-asset-legal"
cp "$component_file" "$bundle_root/SOURCES.tsv"

cat >"$bundle_root/README.md" <<'EOF'
# PastureStack Runtime License Bundle

This bundle accompanies the flat Runtime assets used to assemble the PastureStack Server image. It preserves legal, attribution, privacy, patent, and source-coordinate files from the exact public source commits listed in `SOURCES.tsv`, plus legal files already embedded in the distributed archives.

The `license_summary` column is a navigation aid, not a replacement for the included license texts and notices. Copyright and authorship remain with the respective upstream projects and contributors. PastureStack claims only its own changes and packaging work.

`source-legal/server` contains the Server repository's own license and attribution files from the checkout that built this bundle. The exact Server source commit and this bundle's SHA-256 are recorded in the release manifest.
EOF

mkdir -p "$bundle_root/source-legal/server"
for legal in LICENSE COPYRIGHT_DETAILS.md ORIGIN.md; do
  if [ -f "$repo_root/$legal" ]; then
    cp "$repo_root/$legal" "$bundle_root/source-legal/server/$legal"
  fi
done

is_legal_name()
{
  local upper
  upper=${1^^}
  case "$upper" in
    LICENSE*|LICENCE*|NOTICE*|COPYRIGHT*|PATENTS*|THIRD*PARTY*|PRIVACY*|ORIGIN*) return 0 ;;
    *) return 1 ;;
  esac
}

validate_member()
{
  local member=$1
  case "$member" in
    /*|../*|*/../*|*/..|..) printf 'unsafe archive member: %s\n' "$member" >&2; return 1 ;;
  esac
}

declare -A fetched_components=()
while IFS=$'\t' read -r asset component repository commit license_summary; do
  if [ "$asset" = "asset" ]; then
    continue
  fi
  test -n "$asset" && test -n "$component" && test -n "$repository" && test -n "$commit" && test -n "$license_summary"
  [[ "$asset" =~ ^[A-Za-z0-9._+-]+$ ]]
  [[ "$component" =~ ^[a-z0-9-]+$ ]]
  [[ "$repository" =~ ^https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]
  [[ "$commit" =~ ^[0-9a-f]{40}$ ]]
  test -f "$artifact_dir/$asset"

  if [ -n "${fetched_components[$component]:-}" ]; then
    continue
  fi
  fetched_components[$component]=1

  source_archive="$workdir/${component}-${commit}.tar.gz"
  source_extract="$workdir/source-${component}"
  mkdir -p "$source_extract"
  curl -fsSL --retry 5 --retry-all-errors --retry-delay 2 --connect-timeout 10 --max-time 300 \
    -o "$source_archive" "${repository}/archive/${commit}.tar.gz"
  if tar -tzf "$source_archive" | grep -E '(^/|(^|/)\.\.(/|$))' >/dev/null; then
    printf 'unsafe source archive: %s@%s\n' "$repository" "$commit" >&2
    exit 1
  fi
  tar -xzf "$source_archive" -C "$source_extract"
  mapfile -t roots < <(find "$source_extract" -mindepth 1 -maxdepth 1 -type d -print)
  if [ "${#roots[@]}" -ne 1 ]; then
    printf 'unexpected source archive roots: %s@%s count=%s\n' "$repository" "$commit" "${#roots[@]}" >&2
    exit 1
  fi
  source_root=${roots[0]}
  legal_count=0
  while IFS= read -r -d '' source_file; do
    base=${source_file##*/}
    if ! is_legal_name "$base"; then
      continue
    fi
    relative=${source_file#"$source_root"/}
    validate_member "$relative"
    destination="$bundle_root/source-legal/$component/$relative"
    mkdir -p "$(dirname "$destination")"
    cp "$source_file" "$destination"
    legal_count=$((legal_count + 1))
  done < <(find "$source_root" -type f -print0)
  if [ "$component" = orchestration-engine ]; then
    hazelcast_provenance="$source_root/third-party/HAZELCAST.md"
    test -f "$hazelcast_provenance"
    mkdir -p "$bundle_root/source-legal/$component/third-party"
    cp "$hazelcast_provenance" \
      "$bundle_root/source-legal/$component/third-party/HAZELCAST.md"
    legal_count=$((legal_count + 1))
  fi
  if [ "$legal_count" -eq 0 ]; then
    printf 'no legal files found: %s@%s\n' "$repository" "$commit" >&2
    exit 1
  fi
done <"$component_file"

copy_tar_legal()
{
  local archive=$1
  local asset=$2
  local compression=$3
  local list_args=()
  local extract_args=()
  if [ "$compression" = xz ]; then
    list_args=(-tJf)
    extract_args=(-xOJf)
  else
    list_args=(-tzf)
    extract_args=(-xOzf)
  fi
  while IFS= read -r member; do
    clean_member=${member#./}
    validate_member "$clean_member"
    if ! is_legal_name "${clean_member##*/}"; then
      continue
    fi
    destination="$bundle_root/embedded-asset-legal/$asset/$clean_member"
    mkdir -p "$(dirname "$destination")"
    tar "${extract_args[@]}" "$archive" "$member" >"$destination"
  done < <(tar "${list_args[@]}" "$archive")
}

copy_zip_legal()
{
  local archive=$1
  local asset=$2
  while IFS= read -r member; do
    clean_member=${member#./}
    validate_member "$clean_member"
    if ! is_legal_name "${clean_member##*/}"; then
      continue
    fi
    destination="$bundle_root/embedded-asset-legal/$asset/$clean_member"
    mkdir -p "$(dirname "$destination")"
    unzip -p "$archive" "$member" >"$destination"
  done < <(unzip -Z1 "$archive")
}

copy_nested_zip_legal()
{
  local archive=$1
  local asset=$2
  local nested_member
  while IFS= read -r nested_member; do
    local clean_nested=${nested_member#./}
    validate_member "$clean_nested"
    case "$clean_nested" in
      *.jar) ;;
      *) continue ;;
    esac

    local nested_archive
    nested_archive=$(mktemp "$workdir/nested-jar.XXXXXX")
    unzip -p "$archive" "$nested_member" >"$nested_archive"
    if ! unzip -tqq "$nested_archive" >/dev/null; then
      printf 'invalid nested JAR: %s member=%s\n' "$asset" "$clean_nested" >&2
      rm -f "$nested_archive"
      exit 1
    fi

    local legal_member
    while IFS= read -r legal_member; do
      local clean_legal=${legal_member#./}
      validate_member "$clean_legal"
      case "$clean_legal" in
        */) continue ;;
      esac
      if ! is_legal_name "${clean_legal##*/}"; then
        continue
      fi
      local destination="$bundle_root/embedded-asset-legal/$asset/nested/$clean_nested/$clean_legal"
      mkdir -p "$(dirname "$destination")"
      unzip -p "$nested_archive" "$legal_member" >"$destination"
    done < <(unzip -Z1 "$nested_archive")
    rm -f "$nested_archive"
  done < <(unzip -Z1 "$archive")
}

while IFS=$'\t' read -r asset component repository commit license_summary; do
  if [ "$asset" = "asset" ]; then
    continue
  fi
  archive="$artifact_dir/$asset"
  case "$asset" in
    *.tar.xz) copy_tar_legal "$archive" "$asset" xz ;;
    *.tar.gz) copy_tar_legal "$archive" "$asset" gz ;;
    *.zip) copy_zip_legal "$archive" "$asset" ;;
    *.jar)
      copy_zip_legal "$archive" "$asset"
      copy_nested_zip_legal "$archive" "$asset"
      ;;
  esac
done <"$component_file"

(
  cd "$bundle_root"
  find . -type f ! -name FILES.sha256 -print0 | sort -z | xargs -0 sha256sum >FILES.sha256
)

output="$output_dir/${bundle_name}.tar.xz"
temporary="$output.tmp"
rm -f "$temporary"
XZ_OPT=-9e tar --sort=name --mtime="@${source_date_epoch}" --owner=0 --group=0 --numeric-owner \
  --pax-option=delete=atime,delete=ctime -cJf "$temporary" -C "$workdir" "$bundle_name"
mv "$temporary" "$output"
printf 'RUNTIME_LICENSE_BUNDLE_OK path=%s sha256=%s component_count=%s asset_count=%s\n' \
  "$output" "$(sha256sum "$output" | awk '{print $1}')" "${#fetched_components[@]}" "$(($(wc -l <"$component_file") - 1))"
