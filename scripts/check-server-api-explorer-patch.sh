#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

dockerfile=server/Dockerfile.api-explorer-patch
release_dockerfile=server/Dockerfile.web-compose-release
core_dockerfile=server/Dockerfile
build_script=server/build-api-explorer-patch-image.sh
publish_workflow=.github/workflows/publish-current-server.yml
cattle_script=server/artifacts/cattle.sh
coreutils_patch=server/patches/coreutils-CVE-2026-56391.patch
runtime_vex=server/security/openvex.json
runtime_vendor_pending=server/security/vendor-pending.json
vendor_pending_validator=scripts/validate-vendor-pending-findings.sh
release_notes=docs/releases/server-1.6.438.md
previous_release_notes=docs/releases/server-1.6.462.md
last_release_notes=docs/releases/server-1.6.463.md
prior_release_notes=docs/releases/server-1.6.466.md
current_release_notes=docs/releases/server-1.6.483.md
next_release_notes=docs/releases/server-1.6.494.md
published_current_release_notes=docs/releases/server-1.6.496.md
latest_published_release_notes=docs/releases/server-1.6.497.md
previous_published_release_notes=docs/releases/server-1.6.495.md
published_release_notes=docs/releases/server-1.6.482.md
official_image_reference=ghcr.io/pasturestack/server:v1.6.496@sha256:6c85435b3de8771e5adff0b247274e0f1b9fe9d66c8b91e07d55a444e5589678
host_api_repair=server/artifacts/repair-host-api-sha256.sh
host_api_check=scripts/check-server-host-api-package.sh
mfa_policy_smoke=scripts/test-mfa-policy-api.py

for path in "$dockerfile" "$release_dockerfile" "$core_dockerfile" "$build_script" "$publish_workflow" "$cattle_script" \
    "$coreutils_patch" "$runtime_vex" "$runtime_vendor_pending" \
    "$vendor_pending_validator" \
    "$release_notes" "$previous_release_notes" "$last_release_notes" "$prior_release_notes" "$published_release_notes" "$current_release_notes" "$host_api_repair" "$host_api_check" \
    "$mfa_policy_smoke" "$next_release_notes" "$published_current_release_notes" "$previous_published_release_notes" "$latest_published_release_notes"; do
    test -f "$path"
done

bash -n "$host_api_repair" "$host_api_check"

if grep -Eq '__WEB_CONSOLE_|__ORCHESTRATION_ENGINE_|PENDING_WEB[0-9]+_ARCHIVE_SHA256|PENDING_OFFICIAL_(SOURCE|ARCHIVE|BINARY|SQLITE_BINARY)' "$release_dockerfile" "$build_script"; then
    echo 'SERVER_COMPONENT_RELEASE_COORDINATES_PENDING' >&2
    exit 1
fi
if ! grep -Eq '^ARG WEB_CONSOLE_ARTIFACT_SHA256=[0-9a-f]{64}$' "$release_dockerfile" ||
   ! grep -Eq '^ARG WEB_CONSOLE_COMMIT=[0-9a-f]{40}$' "$release_dockerfile" ||
   ! grep -Eq '^web_console_artifact_sha256=\$\{WEB_CONSOLE_ARTIFACT_SHA256:-[0-9a-f]{64}\}$' "$build_script" ||
   ! grep -Eq '^web_console_commit=\$\{WEB_CONSOLE_COMMIT:-[0-9a-f]{40}\}$' "$build_script"; then
    echo 'SERVER_WEB_CONSOLE_1_6_177_COORDINATES_PENDING' >&2
    exit 1
fi
if grep -Eq '9f9de0ab54ef9ad8b4bb1dd7f08e6d4c5c1aa1373e02f231fdad5e27916695b1|584a548dc30f8d59bcc3f1c9aba17e7b26eff4ef' \
    "$release_dockerfile" "$build_script"; then
    echo 'SERVER_WEB_CONSOLE_1_6_150_COORDINATES_STALE' >&2
    exit 1
fi
if grep -Eq 'c8ff45db07d5db4599fbbaa6665f7bffe2977b09a907d493793f4becaa3c31d2|b3139aced7227eab97d6034a4d97440d5823265b' \
    "$release_dockerfile" "$build_script"; then
    echo 'SERVER_WEB_CONSOLE_1_6_149_COORDINATES_STALE' >&2
    exit 1
fi
if grep -Eq '3f4c3228cb0b406f7d87b8e5e0896ebdc8b16345183e96bcf54cae92a5fc4c49|26090af4366a0843b09c1ff5c91373f7a1be816e' \
    "$release_dockerfile" "$build_script"; then
    echo 'SERVER_WEB_CONSOLE_1_6_147_COORDINATES_STALE' >&2
    exit 1
fi
if grep -Eq '1489c69edfbb531f021ed34aca014bb17d70d8f1a2aacbddc3b3af8b7a317dd6|97e52e09569681f7452942d0775f0ddac2d5e67e' \
    "$release_dockerfile" "$build_script"; then
    echo 'SERVER_WEB_CONSOLE_1_6_146_COORDINATES_STALE' >&2
    exit 1
fi
if grep -Eq 'fa040adff35162fec11e6400180a913af9847db1798c6ead6111f539a4436e39|c130a081257b14d1a547ca13c3a16aa0d802d435' \
    "$release_dockerfile" "$build_script"; then
    echo 'SERVER_WEB_CONSOLE_1_6_145_COORDINATES_STALE' >&2
    exit 1
fi
if grep -Eq '906876dbac44d8644bd0481dc3d0eab19dd4098d930b20919bcd52b0bb607d91|e76706a13e24ebe6581719e8c5407f7a7b998bdc' \
    "$release_dockerfile" "$build_script"; then
    echo 'SERVER_WEB_CONSOLE_1_6_145_COORDINATES_STALE' >&2
    exit 1
fi
if grep -Fq '5c0c131900f55a6b9a1ab6e18603d8b4cfac4319e3f4ca9d7c2e2a7dd6001a32' \
    "$release_dockerfile" "$build_script" ||
   grep -Fq 'c6d288bdf99e107af3fa6db735ab996b01da729d' \
    "$release_dockerfile" "$build_script"; then
    echo 'SERVER_WEB_CONSOLE_1_6_144_COORDINATES_PENDING' >&2
    exit 1
fi

require_marker()
{
    local file=$1
    local marker=$2
    local code=$3
    if ! grep -Fq -- "$marker" "$file"; then
        printf '%s file=%s marker=%s\n' "$code" "$file" "$marker" >&2
        exit 1
    fi
}

for next_release_marker in \
    '# Server v1.6.494' \
    'Published Server artifact verified.' \
    '`c3b50ad6891ebbde4612e89dd5a1114bc731431c`' \
    'publication run `36704785404`' \
    'Orchestration Engine `v0.183.327`' \
    '`dce2f2473ffea1510fe10676a771eb1fe5d0b161`' \
    '`c6d4c3003a19db19d1be73e69aa52358a0a4166bf726cbefe7e2ab9ed5664b56`' \
    '`36701559252`' \
    'Web Console `1.6.160`' \
    'web-console-1.6.160.tar.gz' \
    '`63964fa3a6da5cbd452cdc1061c1e18340055362`' \
    '`705946b96e693c55a8ab5de3bc96b14020a52a050bf3992c302b9fb3c1408a51`' \
    'VERSION.txt=1.6.160' \
    'validation run `36702030007`'; do
    require_marker "$next_release_notes" "$next_release_marker" \
        SERVER_PUBLISHED_RELEASE_EVIDENCE_MISSING
done
for official_identity_doc in COMPATIBILITY.md "$published_current_release_notes"; do
    require_marker "$official_identity_doc" "$official_image_reference" \
        SERVER_OFFICIAL_IMMUTABLE_IMAGE_MISSING
done
require_marker "$published_current_release_notes" '# Server v1.6.496' \
    SERVER_CURRENT_RELEASE_NOTES_MISSING
require_marker docs/releases/server-1.6.491.md '# Server v1.6.491' \
    SERVER_PREVIOUS_RELEASE_NOTES_MISSING
require_marker docs/releases/server-1.6.487.md '# Server v1.6.487' \
    SERVER_LAST_PUBLISHED_RELEASE_NOTES_MISSING
require_marker COMPATIBILITY.md '## Server v1.6.514 published' SERVER_V514_COMPATIBILITY_MISSING
require_marker docs/README.md '[Server v1.6.514](releases/server-1.6.514.md)' SERVER_V514_INDEX_MISSING
require_marker docs/releases/server-1.6.514.md '# Server v1.6.514' SERVER_V514_RELEASE_NOTES_MISSING
require_marker docs/releases/server-1.6.514.md 'including API template IDs, may remap' SERVER_V514_ID_REMAP_CONTRACT_MISSING
require_marker COMPATIBILITY.md '## Server v1.6.516' SERVER_V516_COMPATIBILITY_MISSING
require_marker docs/README.md '[Server v1.6.516](releases/server-1.6.516.md)' SERVER_V516_INDEX_MISSING
require_marker docs/releases/server-1.6.516.md '# Server v1.6.516' SERVER_V516_RELEASE_NOTES_MISSING
require_marker docs/releases/server-1.6.516.md '## Repair' SERVER_V516_PENDING_ACCEPTANCE_MISSING

require_marker COMPATIBILITY.md \
    '## Server v1.6.513' \
    SERVER_V513_COMPATIBILITY_MISSING
require_marker docs/releases/server-1.6.513.md \
    'No migration or runtime patch is required.' \
    SERVER_V513_RELEASE_CONTRACT_MISSING
require_marker COMPATIBILITY.md \
    '## Server v1.6.512' \
    SERVER_V512_COMPATIBILITY_MISSING
require_marker docs/releases/server-1.6.512.md \
    'No migration or runtime patch is required.' \
    SERVER_V512_RELEASE_CONTRACT_MISSING
require_marker COMPATIBILITY.md \
    '## Server v1.6.511' \
    SERVER_V511_COMPATIBILITY_MISSING
require_marker docs/releases/server-1.6.511.md \
    'No migration or runtime patch is required.' \
    SERVER_V511_RELEASE_CONTRACT_MISSING
require_marker COMPATIBILITY.md \
    '## Server v1.6.510' \
    SERVER_V510_COMPATIBILITY_MISSING
require_marker docs/releases/server-1.6.510.md \
    'No migration or runtime patch is required.' \
    SERVER_V510_RELEASE_CONTRACT_MISSING
require_marker COMPATIBILITY.md \
    '## Server v1.6.509' \
    SERVER_V509_COMPATIBILITY_MISSING
require_marker docs/releases/server-1.6.509.md \
    'No migration or runtime patch is required.' \
    SERVER_V509_RELEASE_CONTRACT_MISSING
require_marker docs/README.md \
    '[Server v1.6.495](releases/server-1.6.495.md)' \
    SERVER_NEXT_DOC_INDEX_MISSING
require_marker docs/README.md \
    '[Server v1.6.496](releases/server-1.6.496.md)' \
    SERVER_PUBLISHED_DOC_INDEX_MISSING

check_server497_published_docs()
{
    local latest_notes=docs/releases/server-1.6.497.md
    local latest_image=ghcr.io/pasturestack/server:v1.6.497@sha256:1a1f05415e50d2ea337140d89063c6d7ae993140befa5aa79c5c83922990021d
    local published_marker
    require_marker COMPATIBILITY.md 'Published Server `v1.6.497`' \
        SERVER_PUBLISHED_497_COMPATIBILITY_MISSING
    require_marker docs/README.md '[Server v1.6.497](releases/server-1.6.497.md)' \
        SERVER_PUBLISHED_497_DOC_INDEX_MISSING
    python3 - <<'PY'
import pathlib
import re
import sys

image = "ghcr.io/pasturestack/server:v1.6.497@sha256:1a1f05415e50d2ea337140d89063c6d7ae993140befa5aa79c5c83922990021d"
source = "80d97523052aa86ec761ade8ec487c382a8d5e1d"
run = "36836319609"
run_url = "https://github.com/PastureStack/server/actions/runs/" + run


def reject(code, path):
    print(code + " file=" + path, file=sys.stderr)
    raise SystemExit(1)


def words(value):
    return re.escape(value).replace(r"\ ", r"\s+")


specs = (
    ("COMPATIBILITY.md", r"(?m)^Published Server `v1\.6\.497`[^\n]*$",
     r"(?m)^Published Server `v", None,
     "Published Server `v1.6.497` packages officially published Web Console `1.6.164`.",
     "The immutable image is", "from source", " and successful", "publication run"),
    ("docs/releases/server-1.6.497.md", r"(?m)^# Server v1\.6\.497[^\n]*$", None,
     "# Server v1.6.497", "Published Server `v1.6.497` is the immutable image",
     "Published Server `v1.6.497` is the immutable image", "from source", ".",
     "Official publication run"),
)
documents = {}
latest_sections = {}
for path, heading, end_heading, exact_heading, intro, image_lead, source_lead, source_end, run_lead in specs:
    text = pathlib.Path(path).read_text(encoding="utf-8")
    documents[path] = text
    starts = list(re.finditer(heading, text))
    if len(starts) != 1 or (exact_heading and starts[0].group() != exact_heading):
        reject("SERVER_PUBLISHED_497_STATUS_MISMATCH", path)
    start = starts[0]
    section_start = start.end() if exact_heading else start.start()
    section_end = len(text)
    if end_heading:
        end = re.search(end_heading, text[start.end():])
        if end:
            section_end = start.end() + end.start()
    section = text[section_start:section_end].lstrip()
    latest_sections[path] = section
    if not re.match(words(intro), section.lstrip()):
        reject("SERVER_PUBLISHED_497_STATUS_MISMATCH", path)
    publication_paragraph = re.split(r"\n\s*\n", section, maxsplit=1)[0]
    if re.search(r"candidate|source[- ]only|unpublished|publication\s+pending", publication_paragraph, re.I):
        reject("SERVER_PUBLISHED_497_CANDIDATE_STATUS_STALE", path)
    identity = (
        words(image_lead) + r"\s+`(?P<image>[^`\r\n]+)`,\s+"
        + words(source_lead) + r"\s+`(?P<source>[^`\r\n]+)`" + words(source_end)
        + r"\s+\[" + words(run_lead) + r"\s+`(?P<run>[^`\r\n]+)`\]\((?P<url>[^)\s]+)\)"
    )
    identities = list(re.finditer(identity, publication_paragraph))
    if len(identities) != 1:
        reject("SERVER_PUBLISHED_497_IDENTITY_CONTEXT_MISSING", path)
    actual = identities[0].groupdict()
    if actual["image"] != image:
        reject("SERVER_PUBLISHED_497_DIGEST_MISMATCH", path)
    if actual["source"] != source:
        reject("SERVER_PUBLISHED_497_SOURCE_MISMATCH", path)
    if actual["run"] != run or actual["url"] != run_url:
        reject("SERVER_PUBLISHED_497_RUN_MISMATCH", path)
    # Include the whole reference, so a valid digest prefix cannot hide a suffix.
    references = re.findall(r'''ghcr\.io/pasturestack/server:v1\.6\.497@[^\s`"'<>()\[\]{},;]+''', text)
    if any(reference != image for reference in references):
        reject("SERVER_PUBLISHED_497_DIGEST_MISMATCH", path)

documents["docs/README.md"] = pathlib.Path("docs/README.md").read_text(encoding="utf-8")
index_lines = [line for line in documents["docs/README.md"].splitlines()
               if "[Server v1.6.497](releases/server-1.6.497.md)" in line]
if len(index_lines) != 1 or " — published " not in index_lines[0]:
    reject("SERVER_PUBLISHED_497_STATUS_MISMATCH", "docs/README.md")
latest_sections["docs/README.md"] = index_lines[0]
for path, text in documents.items():
    if re.search(r"source[- ]only\s+assembly\s+candidate", latest_sections[path], re.I):
        reject("SERVER_PUBLISHED_497_CANDIDATE_STATUS_STALE", path)
    for line in text.splitlines():
        if (re.search(r"v1\.6\.497|Server497", line, re.I)
            and re.search(r"candidate|source[- ]only|publication\s+pending|unpublished|not\s+published", line, re.I)
        ):
            reject("SERVER_PUBLISHED_497_CANDIDATE_STATUS_STALE", path)
PY
    # This function verifies the historical 497 publication, not today's install target.
    require_marker COMPATIBILITY.md \
        'The recorded QA497 `8080` deployment ran `v1.6.497` / Web Console `1.6.164`;' \
        SERVER_PUBLISHED_497_QA_BOUNDARY_MISSING
    require_marker docs/README.md \
        'QA8080 now497/Web164 first start/restart passed; packaged native Receiver browser acceptance pending, broader matrix INCOMPLETE' \
        SERVER_PUBLISHED_497_QA_BOUNDARY_MISSING
    for published_marker in \
        '# Server v1.6.497' \
        'Published Server `v1.6.497` is the immutable image' \
        'Web Console `1.6.164`' \
        'c3c0779d930d4d0367ec0517166ca21f6b3dc6d4' \
        'eddb24c5561e0ad46519aa3e3e2704e932fc8e72' \
        '36831735186' \
        '763 actual case results' \
        'web-console-1.6.164.tar.gz' \
        '2,976,044 bytes' \
        '734898ac6ed2fe8774e5bb947988da9720a3a65aa0bb7ec09a89420adc0acc20' \
        '4b7c0d38fd529a7dc9ca36457a40b5afe8216ca595393e291a031b44ec73801e' \
        'Orchestration Engine remains `v0.183.328`' \
        'ad43f4b6790c359e248710a39bca2f776d70be62' \
        '184fb3d4a2b026560e1e60d7b444f693f79bff6c8220cc9354c1284012f6a683' \
        'WEB-INF/lib/hazelcast-5.7.5.jar' \
        '0f536a9c7bcd00f2369586fb6ca1606f7e45f3225e24795d10d38397051c8715' \
        'eight Medium plus six Low' \
        '58 raw findings and 14 exact vendor-pending package' \
        'six unique CVEs' \
        '2026-10-08' \
        'All 56 source/pin gates' \
        '26-layer build was flattened to one' \
        'all 34 MFA policy/API checks passed' \
        '1c0110de4bc4e513a78fb6e825b6d8b4da1e34dd851947bc93079d29fa990793' \
        'not a zero-CVE result' \
        'not promote historical HOLD receipts.' \
        'QA `8080` now runs the' \
        'immutable `v1.6.497` / Web Console `1.6.164` deployment; first start/restart passed.' \
        'Existing QA `8080` first start/restart returned `HTTP 200` / `pong` (10 and nine' \
        'attempts), with zero runtime-contract and tracked five-table DB-count' \
        'not a whole-database row comparison.' \
        'health is `null`, and no Docker `healthy` result is claimed.' \
        'immutable `v1.6.496` rollback is retained. The `v1.6.495` image and backups' \
        'remain retained; its obsolete stopped container was removed without deleting' \
        'data volumes.' \
        'Packaged native Receiver browser acceptance remains' \
        'pending; mobile, all-language/full-layout and the broader resource/role matrix' \
        'remain INCOMPLETE. No company-site deployment or full-site PASS is claimed.'; do
        require_marker "$latest_notes" "$published_marker" SERVER_PUBLISHED_497_SCOPE_EVIDENCE_MISSING
    done
}

check_server497_published_docs

# Install examples must follow the highest actually published numeric release;
# Install commands use numeric tags; digest identity stays in publication evidence.
python3 - <<'PY'
import pathlib
import re

readme = pathlib.Path('README.md').read_text(encoding='utf-8')
install_pattern = r'ghcr\.io/pasturestack/server:v[0-9]+\.[0-9]+\.[0-9]+'
image_pattern = install_pattern + r'@sha256:[0-9a-f]{64}'
reference_pattern = r'''ghcr\.io/pasturestack/server:[^\s`"'<>()\[\]{},;]+'''
current = re.search(r'(?ms)^## Current release\n(.*?)(?=^## |\Z)', readme)
tags = re.findall(r'https://github\.com/PastureStack/server/releases/tag/(v[0-9]+\.[0-9]+\.[0-9]+)(?=[)\s])', current[1] if current else '')
if len(tags) != 1:
    raise SystemExit('SERVER_LATEST_PUBLISHED_IDENTITY_MISSING')
tag = tags[0]
quick = re.search(r'(?ms)^## Quick start\n(.*?)(?=^## |\Z)', readme)
references = re.findall(r'ghcr\.io/pasturestack/server:[^\s`"<>]+', quick[1] if quick else '')
if len(references) != 2 or references[0] != references[1] or not re.fullmatch(install_pattern, references[0]):
    raise SystemExit('SERVER_LATEST_PUBLISHED_QUICK_START_MISMATCH')
image = references[0]
notes_path = 'docs/releases/server-' + tag[1:] + '.md'
if image != 'ghcr.io/pasturestack/server:' + tag or '(' + notes_path + ')' not in current[1]:
    raise SystemExit('SERVER_LATEST_PUBLISHED_QUICK_START_MISMATCH')
performance = pathlib.Path('docs/performance/README.md').read_text(encoding='utf-8')
performance_references = re.findall(r'ghcr\.io/pasturestack/server:[^\s`"<>]+', performance)
if performance_references != [image]:
    raise SystemExit('SERVER_LATEST_PUBLISHED_PERFORMANCE_MISMATCH')
notes = pathlib.Path(notes_path).read_text(encoding='utf-8')
compat = pathlib.Path('COMPATIBILITY.md').read_text(encoding='utf-8')
published = [reference for reference in re.findall(reference_pattern, compat)
             if re.fullmatch(image_pattern, reference)]
if not published:
    raise SystemExit('SERVER_LATEST_PUBLISHED_IDENTITY_MISSING')
latest_tag = max((reference.split('@')[0].rsplit(':', 1)[1] for reference in published),
                 key=lambda value: tuple(map(int, value[1:].split('.'))))
if tag != latest_tag or not re.search(r'(?m)^# Server ' + re.escape(tag) + r'[ \t]*$', notes):
    raise SystemExit('SERVER_LATEST_PUBLISHED_QUICK_START_MISMATCH')
publication_identity = None
for text in (notes, compat):
    identities = [reference for reference in re.findall(reference_pattern, text)
                  if reference.startswith('ghcr.io/pasturestack/server:' + tag + '@')]
    if not identities or any(not re.fullmatch(image_pattern, reference) for reference in identities):
        raise SystemExit('SERVER_LATEST_PUBLISHED_QUICK_START_MISMATCH')
    if publication_identity is None:
        publication_identity = identities[0]
    if any(reference != publication_identity for reference in identities):
        raise SystemExit('SERVER_LATEST_PUBLISHED_QUICK_START_MISMATCH')
print('SERVER_LATEST_PUBLISHED_QUICK_START_OK release=' + tag)
PY
python3 scripts/test-published-install-gate.py
python3 scripts/test-current-server-packaging-contract.py

require_marker docs/releases/server-1.6.498.md '# Server v1.6.498' \
    SERVER_GENERIC_OBJECT_PATCH_NOTES_MISSING
require_marker docs/releases/server-1.6.498.md 'No migration or runtime patch is required.' \
    SERVER_GENERIC_OBJECT_PATCH_BOUNDARY_MISSING
require_marker docs/releases/server-1.6.500.md '# Server v1.6.500' \
    SERVER_IMPORTED_CONTAINER_NAME_NOTES_MISSING
require_marker docs/releases/server-1.6.500.md 'No migration or runtime patch is required.' \
    SERVER_IMPORTED_CONTAINER_NAME_MIGRATION_BOUNDARY_MISSING
require_marker COMPATIBILITY.md 'Server `v1.6.500` packages Engine `v0.183.331`' \
    SERVER_IMPORTED_CONTAINER_NAME_COMPATIBILITY_MISSING
require_marker docs/releases/server-1.6.501.md '# Server v1.6.501' \
    SERVER_HOST_NAME_LAYOUT_NOTES_MISSING
require_marker docs/releases/server-1.6.501.md 'No migration or runtime patch is required.' \
    SERVER_HOST_NAME_LAYOUT_MIGRATION_BOUNDARY_MISSING
require_marker COMPATIBILITY.md 'Server `v1.6.501` packages Web Console `1.6.165`' \
    SERVER_HOST_NAME_LAYOUT_COMPATIBILITY_MISSING
for low_role_snapshot_hash in \
    7f274219e8dd9c6d750a408a6edec1448b564f4b16ba2204c425c5b45cec2233 \
    f854ba99260f29e324ab7446a8592996946038920ac9bcf17689d98d1ebc5e51; do
    require_marker "$release_dockerfile" "$low_role_snapshot_hash" SERVER_LOW_ROLE_FROZEN_SCHEMA_BUILD_GATE_MISSING
    require_marker "$build_script" "$low_role_snapshot_hash" SERVER_LOW_ROLE_FROZEN_SCHEMA_RUNTIME_GATE_MISSING
done

require_marker "$release_dockerfile" \
    'grep -F '\''"volume.isNative" : "r"'\'' >/dev/null' \
    SERVER_VOLUME_NATIVE_READ_ONLY_BUILD_GATE_MISSING
require_marker "$build_script" \
    'grep -F "\"volume.isNative\" : \"r\"" >/dev/null' \
    SERVER_VOLUME_NATIVE_READ_ONLY_RUNTIME_GATE_MISSING

require_marker "$release_dockerfile" \
    'grep -aF '\''createIdentity'\'' "${web_root}"/assets/*.js >/dev/null' \
    SERVER_WEB_CREATE_IDENTITY_BUILD_GATE_MISSING
require_marker "$release_dockerfile" \
    'grep -aF '\''hasRecord'\'' "${web_root}"/assets/*.js >/dev/null' \
    SERVER_WEB_CANONICAL_RECORD_BUILD_GATE_MISSING
require_marker "$build_script" \
    'grep -aF "createIdentity" "${web_root}"/assets/*.js >/dev/null' \
    SERVER_WEB_CREATE_IDENTITY_RUNTIME_GATE_MISSING
require_marker "$build_script" \
    'grep -aF "hasRecord" "${web_root}"/assets/*.js >/dev/null' \
    SERVER_WEB_CANONICAL_RECORD_RUNTIME_GATE_MISSING
require_marker docs/releases/server-1.6.508.md '# Server v1.6.508' \
    SERVER_CREATE_RESPONSE_ORDER_NOTES_MISSING
require_marker docs/releases/server-1.6.508.md 'No migration or runtime patch is required.' \
    SERVER_CREATE_RESPONSE_ORDER_BOUNDARY_MISSING
require_marker COMPATIBILITY.md 'Server `v1.6.508` 已正式發布，封裝 Web Console `1.6.171`。' \
    SERVER_CREATE_RESPONSE_ORDER_COMPATIBILITY_MISSING

for published_current_release_marker in \
    '# Server v1.6.495' \
    'Web Console `1.6.161`' \
    'Orchestration Engine remains `v0.183.327`' \
    'KEY_REQUIRED' \
    'no resource write was dispatched' \
    'No authentication, session, OIDC, MFA, permission, API status, database,' \
    'Scoped owner/member browser checks'; do
    require_marker "$previous_published_release_notes" "$published_current_release_marker" \
        SERVER_CERTIFICATE_METADATA_PATCH_EVIDENCE_MISSING
done
for published_release_marker in \
    '# Server v1.6.496' \
    'Published Server artifact verified.' \
    'd8e0e898b08aae45e040eb085936d11de14027fb' \
    'publication run `36821096323`' \
    'Web Console `1.6.162`' \
    'web-console-1.6.162.tar.gz' \
    '46501e31071b3d74595aea91908876eec32b7fd6' \
    '9c5b34d2cdf7ad354e1dab199795b12e5de119e47dc342547d5cdc84c7911581' \
    'Orchestration Engine `v0.183.328`' \
    'ad43f4b6790c359e248710a39bca2f776d70be62' \
    '184fb3d4a2b026560e1e60d7b444f693f79bff6c8220cc9354c1284012f6a683' \
    'WEB-INF/lib/hazelcast-5.7.5.jar' \
    '0f536a9c7bcd00f2369586fb6ca1606f7e45f3225e24795d10d38397051c8715' \
    'not evidence of' \
    'backend POST or PUT authorization' \
    'does not claim mobile acceptance' \
    'HOLD receipts remain HOLD.' \
    'resource/role matrix remains INCOMPLETE' \
    'Isolated QA496 deployment and two scoped desktop observations passed' \
    'five tracked `account`, `credential`,' \
    'count preservation, not a whole-database row comparison' \
    'no Docker `healthy` result is claimed' \
    'zero-write observations, not backend-write authorization' \
    'Host statistics remained connecting' \
    'right-side table was not fully reviewed' \
    'body rendering was not accepted' \
    'full-layout acceptance' \
    'Mobile and all-language acceptance remain pending' \
    'ef3e411485a7bb9b759a9a6a27f29987c3f7c5f7e95a5fddd9615f0f706ef73b' \
    '8283f2ec75cfc82aaf894d2fa183d9451d6746dbb93a2ca6cc3d87cfbf4159c3' \
    '0973ef57b70acf2ca2e5f2fd3b7f51e07dd839dd03a657d199ba71a62162f736' \
    '34 MFA' \
    '58 raw findings and 14 exact' \
    'eight Medium and six Low'; do
    require_marker "$published_current_release_notes" "$published_release_marker" \
        SERVER_WEB_CONSOLE_PUBLISHED_SCOPE_EVIDENCE_MISSING
done

for mfa_policy_contract_marker in \
    "check('oidc-project-member-schema-options'" \
    "verify_session_bound_token('/v1', normal_token, normal_session" \
    "verify_session_bound_token('/v2-beta', v2_login['jwt'], v2_session" \
    "assert isinstance(issued_token, str) and issued_token" \
    "'authProvider': 'mfa'" \
    "'clientSessionId': v2_session" \
    "check('v2-mfa-session-generation-preserved'" \
    "check(label + '-mismatched-delete-preserves-token'" \
    "check(label + '-matching-delete-revokes-token'" \
    "check(label + '-repeated-delete-is-idempotent'"; do
    require_marker "$mfa_policy_smoke" "$mfa_policy_contract_marker" \
        SERVER_MFA_POLICY_RUNTIME_CONTRACT_MISSING
done

require_marker "$release_dockerfile" \
    'ARG BASE_IMAGE=ghcr.io/pasturestack/server:v1.6.460@sha256:c855af8aea232dacc5bb6df68e2271d482c68b53c43ab0c108ec19118f5ab403' \
    SERVER_INCREMENTAL_RELEASE_BASE_MISSING
require_marker "$release_dockerfile" \
    'ARG SERVER_RELEASE_TAG=v1.6.519' \
    SERVER_INCREMENTAL_RELEASE_DEFAULT_MISSING
require_marker "$release_dockerfile" \
    'org.opencontainers.image.version="${SERVER_RELEASE_TAG}"' \
    SERVER_INCREMENTAL_RELEASE_VERSION_MISSING
require_marker "$release_dockerfile" \
    'org.opencontainers.image.base.name="ghcr.io/pasturestack/server:v1.6.460"' \
    SERVER_INCREMENTAL_RELEASE_BASE_NAME_MISSING
require_marker "$release_dockerfile" \
    'org.opencontainers.image.base.digest="sha256:c855af8aea232dacc5bb6df68e2271d482c68b53c43ab0c108ec19118f5ab403"' \
    SERVER_INCREMENTAL_RELEASE_BASE_DIGEST_MISSING
require_marker "$release_dockerfile" \
    'ENV CATTLE_RANCHER_SERVER_VERSION=${SERVER_RELEASE_TAG}' \
    SERVER_INCREMENTAL_RELEASE_RUNTIME_VERSION_MISSING
require_marker "$release_dockerfile" \
    'COPY --from=release_artifacts /out/host-api.tar.gz /usr/share/cattle/artifacts/host-api-${HOST_API_VERSION}.tar.gz' \
    SERVER_HOST_API_SHA256_PACKAGE_MISSING
require_marker "$release_dockerfile" \
    'repair-host-api-sha256' \
    SERVER_HOST_API_REPAIR_MISSING
require_marker "$publish_workflow" \
    'bash source/scripts/check-server-host-api-package.sh' \
    SERVER_HOST_API_RELEASE_CHECK_MISSING
for release_host_marker in \
    'ARG HOST_API_VERSION=0.38.5' \
    'ARG HOST_API_PACKAGE_MODE=producer' \
    'ARG HOST_API_RELEASE_BASE_URL=https://github.com/PastureStack/host-api/releases/download' \
    'ARG HOST_API_RELEASE_TAG=v0.38.5' \
    'ARG HOST_API_COMMIT=84754fe8bc79027d0c72f492923c47861aa74b99' \
    'ARG HOST_API_PACKAGE_ID=84754fe8bc79027d0c72f492923c4786' \
    'ARG HOST_API_ARCHIVE_SHA256=ba111038695aa03a82c51d60944bbbdbbec30bb269051ba29fa21d46ada17179' \
    'ARG HOST_API_BINARY_SHA256=fda5080d6cfec0a4c1e9daf15b43cea2dce7ffb116c8292ff0f3547c8fb371f7' \
    'ARG HOST_API_APPLY_SHA256=8a21f63099832afb571755011bbcf8d97710994a50c419b20700cbc31efced0f' \
    'verify-host-api-package /out/host-api.tar.gz'; do
    require_marker "$release_dockerfile" "$release_host_marker" \
        SERVER_HOST_API_PRODUCER_IDENTITY_MISSING
done
require_marker "$publish_workflow" \
    'bash source/server/artifacts/verify-host-api-package.sh' \
    SERVER_HOST_API_PRODUCER_RELEASE_CHECK_MISSING
require_marker "$release_dockerfile" \
    'ARG WEB_CONSOLE_RELEASE_TAG=1.6.181' \
    SERVER_INCREMENTAL_WEB_CONSOLE_VERSION_MISSING
require_marker "$release_dockerfile" \
    'ARG WEB_CONSOLE_ARTIFACT=web-console-1.6.181.tar.gz' \
    SERVER_INCREMENTAL_WEB_CONSOLE_ARTIFACT_MISSING
require_marker "$release_dockerfile" \
    'ARG WEB_CONSOLE_ARTIFACT_SHA256=db50f1f4f413ccbc6d9b2c3337e1979fb5ed4688f86978b885a48f30af342ad1' \
    SERVER_INCREMENTAL_WEB_CONSOLE_HASH_MISSING
require_marker "$release_dockerfile" \
    'ARG WEB_CONSOLE_COMMIT=9f2869e08161db6550892039aea4ccf2c8a8016b' \
    SERVER_INCREMENTAL_WEB_CONSOLE_COMMIT_MISSING
require_marker "$release_dockerfile" \
    "grep -aF 'hostsPage.permissionDenied'" \
    SERVER_INCREMENTAL_WEB_CONSOLE_PERMISSION_MARKER_MISSING
require_marker "$release_dockerfile" \
    '"hostsPage.permissionDenied":"您沒有權限在此環境中新增主機。"' \
    SERVER_INCREMENTAL_WEB_CONSOLE_ZH_TW_PERMISSION_MESSAGE_MISSING
require_marker "$build_script" \
    'web_console_commit=${WEB_CONSOLE_COMMIT:-9f2869e08161db6550892039aea4ccf2c8a8016b}' \
    SERVER_INCREMENTAL_WEB_CONSOLE_BUILD_COMMIT_MISSING
require_marker "$build_script" \
    'web_console_release_tag=${WEB_CONSOLE_RELEASE_TAG:-1.6.181}' \
    SERVER_INCREMENTAL_WEB_CONSOLE_BUILD_VERSION_MISSING
require_marker "$build_script" \
    'web_console_artifact=${WEB_CONSOLE_ARTIFACT:-web-console-1.6.181.tar.gz}' \
    SERVER_INCREMENTAL_WEB_CONSOLE_BUILD_ARTIFACT_MISSING
require_marker "$build_script" \
    'web_console_artifact_sha256=${WEB_CONSOLE_ARTIFACT_SHA256:-db50f1f4f413ccbc6d9b2c3337e1979fb5ed4688f86978b885a48f30af342ad1}' \
    SERVER_INCREMENTAL_WEB_CONSOLE_BUILD_HASH_MISSING
require_marker "$release_dockerfile" \
    'ARG CATALOG_SERVICE_VERSION=0.20.13' \
    SERVER_INCREMENTAL_CATALOG_VERSION_MISSING
require_marker "$build_script" \
    'catalog_service_version=${CATALOG_SERVICE_VERSION:-0.20.13}' \
    SERVER_INCREMENTAL_CATALOG_BUILD_VERSION_MISSING
require_marker "$release_dockerfile" \
    'ARG CATALOG_SERVICE_COMMIT=4c39c73a8131ba06e9ff0aaec3b95cc27e049324' \
    SERVER_INCREMENTAL_CATALOG_COMMIT_MISSING
require_marker "$build_script" \
    'catalog_service_commit=${CATALOG_SERVICE_COMMIT:-4c39c73a8131ba06e9ff0aaec3b95cc27e049324}' \
    SERVER_INCREMENTAL_CATALOG_BUILD_COMMIT_MISSING
require_marker "$release_dockerfile" \
    'ARG CATALOG_SERVICE_ARCHIVE_SHA256=29626181cb8489b016e5975ffaddc00b2a32d290b1c0066e833d27fa7a5edf83' \
    SERVER_INCREMENTAL_CATALOG_ARCHIVE_SHA256_MISSING
require_marker "$build_script" \
    'catalog_service_archive_sha256=${CATALOG_SERVICE_ARCHIVE_SHA256:-29626181cb8489b016e5975ffaddc00b2a32d290b1c0066e833d27fa7a5edf83}' \
    SERVER_INCREMENTAL_CATALOG_BUILD_ARCHIVE_SHA256_MISSING
require_marker "$release_dockerfile" \
    'ARG CATALOG_SERVICE_BINARY_SHA256=7224c76e5643130dee047e3f1888ce6845d024307bec74d72eebdc4baeae1aea' \
    SERVER_INCREMENTAL_CATALOG_BINARY_SHA256_MISSING
require_marker "$build_script" \
    'catalog_service_binary_sha256=${CATALOG_SERVICE_BINARY_SHA256:-7224c76e5643130dee047e3f1888ce6845d024307bec74d72eebdc4baeae1aea}' \
    SERVER_INCREMENTAL_CATALOG_BUILD_BINARY_SHA256_MISSING
require_marker "$release_dockerfile" \
    'ARG CATALOG_SERVICE_SQLITE_BINARY_SHA256=4aeda3e1ee1ca4c57f26938f3ef27651f9c8c129ee12957642960d22b95034ce' \
    SERVER_INCREMENTAL_CATALOG_SQLITE_BINARY_SHA256_MISSING
require_marker "$build_script" \
    'catalog_service_sqlite_binary_sha256=${CATALOG_SERVICE_SQLITE_BINARY_SHA256:-4aeda3e1ee1ca4c57f26938f3ef27651f9c8c129ee12957642960d22b95034ce}' \
    SERVER_INCREMENTAL_CATALOG_BUILD_SQLITE_BINARY_SHA256_MISSING
require_marker "$release_dockerfile" \
    'ARG CATALOG_SERVICE_LICENSE_SHA256=0d542e0c8804e39aa7f37eb00da5a762149dc682d7829451287e11b938e94594' \
    SERVER_INCREMENTAL_CATALOG_LICENSE_SHA256_MISSING
require_marker "$build_script" \
    'catalog_service_license_sha256=${CATALOG_SERVICE_LICENSE_SHA256:-0d542e0c8804e39aa7f37eb00da5a762149dc682d7829451287e11b938e94594}' \
    SERVER_INCREMENTAL_CATALOG_BUILD_LICENSE_SHA256_MISSING
for catalog_release_marker in \
    'COPY --chmod=0755 artifacts/fetch-server-component.sh /usr/local/bin/fetch-server-component' \
    '"catalog-service-${CATALOG_SERVICE_VERSION}.tar.xz" "${CATALOG_SERVICE_ARCHIVE_SHA256}" "${catalog_archive}";' \
    '"catalog-service-${CATALOG_SERVICE_VERSION}-LICENSE.txt" "${CATALOG_SERVICE_LICENSE_SHA256}" /out/catalog-service-licenses/LICENSE.txt;' \
    'for catalog_hash in "${CATALOG_SERVICE_ARCHIVE_SHA256}" "${CATALOG_SERVICE_BINARY_SHA256}" "${CATALOG_SERVICE_SQLITE_BINARY_SHA256}" "${CATALOG_SERVICE_LICENSE_SHA256}"; do' \
    'printf '"'"'./\n./catalog-service\n./catalog-service-sqlite\n'"'"' | cmp - "${catalog_listing}";' \
    'tar --no-same-owner --no-same-permissions -xJf "${catalog_archive}" -C /out/catalog-service' \
    'go version -m "/out/catalog-service/${catalog_binary}" | grep -F "vcs.revision=${CATALOG_SERVICE_COMMIT}"' \
    'go version -m "/out/catalog-service/${catalog_binary}" | grep -F '"'"'vcs.modified=false'"'"'' \
    'echo "${CATALOG_SERVICE_LICENSE_SHA256}  /out/catalog-service-licenses/LICENSE.txt" | sha256sum -c -' \
    'install -m 0755 /out/catalog-service/catalog-service /out/runtime-bin/catalog-service.real;' \
    'install -m 0755 /out/catalog-service/catalog-service-sqlite /out/runtime-bin/catalog-service-sqlite;' \
    'echo "${CATALOG_SERVICE_BINARY_SHA256}  /usr/bin/catalog-service.real" | sha256sum -c -' \
    'echo "${CATALOG_SERVICE_SQLITE_BINARY_SHA256}  /usr/bin/catalog-service-sqlite" | sha256sum -c -' \
    'echo "${CATALOG_SERVICE_LICENSE_SHA256}  /usr/share/licenses/pasturestack/catalog-service/LICENSE.txt" | sha256sum -c -' \
    'grep -Fx "Release source commit: ${CATALOG_SERVICE_COMMIT}"'; do
    require_marker "$release_dockerfile" "$catalog_release_marker" \
        SERVER_INCREMENTAL_CATALOG_RELEASE_CONTRACT_MISSING
done
for catalog_build_marker in \
    '[[ "$catalog_service_license_sha256" =~ ^[0-9a-f]{64}$ ]]' \
    '--build-arg "CATALOG_SERVICE_LICENSE_SHA256=${catalog_service_license_sha256}"' \
    'echo "${PASTURESTACK_CATALOG_SERVICE_BINARY_SHA256}  /usr/bin/catalog-service.real" | sha256sum -c -' \
    'echo "${PASTURESTACK_CATALOG_SERVICE_SQLITE_BINARY_SHA256}  /usr/bin/catalog-service-sqlite" | sha256sum -c -' \
    '"${catalog_service_license_sha256}  /usr/share/licenses/pasturestack/catalog-service/LICENSE.txt"' \
    'catalog_service=%s catalog_service_commit=%s catalog_service_archive_sha256=%s catalog_service_binary_sha256=%s catalog_service_sqlite_binary_sha256=%s'; do
    require_marker "$build_script" "$catalog_build_marker" \
        SERVER_INCREMENTAL_CATALOG_BUILD_CONTRACT_MISSING
done

# Active incremental producer/toolchain contracts are distinct from the historical base patch below.
for incremental_producer_marker in \
    'ARG HOST_PROVISIONER_VERSION=0.39.8' \
    'ARG HOST_PROVISIONER_COMMIT=385e5b536c108f17fdfcdec84c01750a5be5ab1c' \
    'ARG HOST_PROVISIONER_ARCHIVE_SHA256=d775f36a613b1a486a5e60d6ad61fdbd1ebb4bd22422cbb6dcb70fdd7c4abf0c' \
    'ARG HOST_PROVISIONER_BINARY_SHA256=1d37e20a7a1cf4f3e36036a15ff7699ef22cd8809fd14a20892034dd054fd1fc' \
    'ARG SECRET_DELIVERY_API_VERSION=0.3.2' \
    'ARG SECRET_DELIVERY_API_COMMIT=f9c3f933f14e43dc63074d45a3044b693ec1e573' \
    'ARG SECRET_DELIVERY_API_ARCHIVE_SHA256=ca9ab0bfddbcad84b6c1a865af8ad82fcc56cb43dcca1da240ed11a5d24cbdb2' \
    'ARG SECRET_DELIVERY_API_BINARY_SHA256=b5e01b7e65aeee3b456fe043142b5e70f4039ee89ffd437648368ff63e6042b6' \
    'ARG USAGE_TELEMETRY_AGENT_VERSION=0.4.2' \
    'ARG USAGE_TELEMETRY_AGENT_COMMIT=40f9af7ca932fedacdb87e30b4ef1c60a4a7444e' \
    'ARG USAGE_TELEMETRY_AGENT_ARCHIVE_SHA256=5ce031c84f76b3e62dafdb04fb4ed014aa1921e83be056c2d5dd712acbce25a8' \
    'ARG USAGE_TELEMETRY_AGENT_BINARY_SHA256=e62a21270142181315293d7e11482288ffe8fc4d91cc8fe07dacc90b461f3709' \
    'ARG COMPOSE_EXECUTOR_COMMIT=88e991e823f06d2334c07d5370595aae3c48ee99' \
    'ARG COMPOSE_EXECUTOR_ARCHIVE_SHA256=5ff465601930218f531885a384f231d969033e4cef794ce33d16bfe24e5c1c81'; do
    require_marker "$release_dockerfile" "$incremental_producer_marker" \
        SERVER_INCREMENTAL_RUNTIME_PRODUCER_PIN_MISSING
done
for incremental_producer_build_marker in \
    'host_provisioner_version=${HOST_PROVISIONER_VERSION:-0.39.8}' \
    'host_provisioner_commit=${HOST_PROVISIONER_COMMIT:-385e5b536c108f17fdfcdec84c01750a5be5ab1c}' \
    'host_provisioner_archive_sha256=${HOST_PROVISIONER_ARCHIVE_SHA256:-d775f36a613b1a486a5e60d6ad61fdbd1ebb4bd22422cbb6dcb70fdd7c4abf0c}' \
    'host_provisioner_binary_sha256=${HOST_PROVISIONER_BINARY_SHA256:-1d37e20a7a1cf4f3e36036a15ff7699ef22cd8809fd14a20892034dd054fd1fc}' \
    'secret_delivery_api_version=${SECRET_DELIVERY_API_VERSION:-0.3.2}' \
    'secret_delivery_api_commit=${SECRET_DELIVERY_API_COMMIT:-f9c3f933f14e43dc63074d45a3044b693ec1e573}' \
    'secret_delivery_api_archive_sha256=${SECRET_DELIVERY_API_ARCHIVE_SHA256:-ca9ab0bfddbcad84b6c1a865af8ad82fcc56cb43dcca1da240ed11a5d24cbdb2}' \
    'secret_delivery_api_binary_sha256=${SECRET_DELIVERY_API_BINARY_SHA256:-b5e01b7e65aeee3b456fe043142b5e70f4039ee89ffd437648368ff63e6042b6}' \
    'usage_telemetry_agent_version=${USAGE_TELEMETRY_AGENT_VERSION:-0.4.2}' \
    'usage_telemetry_agent_commit=${USAGE_TELEMETRY_AGENT_COMMIT:-40f9af7ca932fedacdb87e30b4ef1c60a4a7444e}' \
    'usage_telemetry_agent_archive_sha256=${USAGE_TELEMETRY_AGENT_ARCHIVE_SHA256:-5ce031c84f76b3e62dafdb04fb4ed014aa1921e83be056c2d5dd712acbce25a8}' \
    'usage_telemetry_agent_binary_sha256=${USAGE_TELEMETRY_AGENT_BINARY_SHA256:-e62a21270142181315293d7e11482288ffe8fc4d91cc8fe07dacc90b461f3709}' \
    'compose_executor_version=${COMPOSE_EXECUTOR_VERSION:-0.14.37}' \
    'compose_executor_commit=${COMPOSE_EXECUTOR_COMMIT:-88e991e823f06d2334c07d5370595aae3c48ee99}' \
    'compose_executor_archive_sha256=${COMPOSE_EXECUTOR_ARCHIVE_SHA256:-5ff465601930218f531885a384f231d969033e4cef794ce33d16bfe24e5c1c81}' \
    'compose_executor_binary_sha256=${COMPOSE_EXECUTOR_BINARY_SHA256:-a9bf9f0f77e914fe557d3e178a73c31526b0ca0adc4afbf17bf68d8d75c7ee27}'; do
    require_marker "$build_script" "$incremental_producer_build_marker" \
        SERVER_INCREMENTAL_RUNTIME_PRODUCER_BUILD_PIN_MISSING
done
for incremental_producer_runtime_marker in \
    'COPY --chmod=0755 artifacts/verify-runtime-producer.sh /usr/local/bin/verify-runtime-producer' \
    'verify-runtime-producer "$component" "$version" "$commit" "/tmp/${artifact}" "$binary_sha" "/out/$component";' \
    'install -m 0755 /out/host-provisioner/host-provisioner /out/runtime-bin/host-provisioner.real;' \
    'cp -a /out/host-provisioner-licenses /out/runtime-licenses/host-provisioner;' \
    'install -m 0755 /out/secret-delivery-api/secret-delivery-api /out/runtime-bin/secret-delivery-api;' \
    'cp -a /out/secret-delivery-api-licenses /out/runtime-licenses/secret-delivery-api;' \
    'install -m 0755 /out/usage-telemetry-agent/usage-telemetry-agent /out/runtime-bin/usage-telemetry-agent;' \
    'cp -a /out/usage-telemetry-agent-licenses /out/runtime-licenses/usage-telemetry-agent;' \
    'echo "${HOST_PROVISIONER_BINARY_SHA256}  /usr/bin/host-provisioner.real" | sha256sum -c -;' \
    '/usr/bin/host-provisioner.real -v | grep -F "${HOST_PROVISIONER_VERSION}" >/dev/null;' \
    'test -s /usr/share/licenses/pasturestack/host-provisioner/LICENSE;' \
    'test -s /usr/share/licenses/pasturestack/host-provisioner/ORIGIN.md;' \
    'test "$(find /usr/share/licenses/pasturestack/host-provisioner/licenses -type f | wc -l)" -eq 35;' \
    'echo "${SECRET_DELIVERY_API_BINARY_SHA256}  /usr/bin/secret-delivery-api" | sha256sum -c -;' \
    '/usr/bin/secret-delivery-api --version | grep -F "v${SECRET_DELIVERY_API_VERSION}" >/dev/null;' \
    'test "$(readlink -f /usr/bin/secrets-api)" = /usr/bin/secret-delivery-api;' \
    'echo "${USAGE_TELEMETRY_AGENT_BINARY_SHA256}  /usr/bin/usage-telemetry-agent" | sha256sum -c -;' \
    '/usr/bin/usage-telemetry-agent --version | grep -F "usage-telemetry-agent ${USAGE_TELEMETRY_AGENT_VERSION} (" >/dev/null;' \
    'test "$(readlink -f /usr/bin/telemetry)" = /usr/bin/usage-telemetry-agent;' \
    'test ! -e "${license_dir}/${component}";' \
    'grep -Fx '"'"'Go compiler: 1.27.2'"'"' "${license_dir}/SERVER-PRODUCER-SOURCES.txt" >/dev/null;' \
    'test -s "${license_dir}/${component}-${suffix}";' \
    'test -s /usr/share/licenses/pasturestack/usage-telemetry-agent/usage-telemetry-agent-PRIVACY.md;'; do
    require_marker "$release_dockerfile" "$incremental_producer_runtime_marker" \
        SERVER_INCREMENTAL_RUNTIME_PRODUCER_GUARD_MISSING
done
for incremental_go_marker in \
    'ARG ARTIFACT_HELPER_IMAGE=golang:1.27.2-bookworm@sha256:5cf287a799e6b94384bad13d16b14904c531f51ba65792237e122ce42b392f61' \
    'test "$(go version | awk '"'"'{print $3}'"'"')" = go1.27.2;' \
    'ENV PASTURESTACK_RUNTIME_GO_VERSION=1.27.2' \
    'ENV PASTURESTACK_CONSOLE_BROKER_GO_VERSION=1.27.2' \
    'ARG ENGINE_READONLY_SCHEMA_SHA256=7f274219e8dd9c6d750a408a6edec1448b564f4b16ba2204c425c5b45cec2233' \
    'ARG ENGINE_RESTRICTED_SCHEMA_SHA256=f854ba99260f29e324ab7446a8592996946038920ac9bcf17689d98d1ebc5e51'; do
    require_marker "$release_dockerfile" "$incremental_go_marker" \
        SERVER_INCREMENTAL_GO_OR_FROZEN_SCHEMA_MISSING
done
for incremental_go_build_marker in \
    'PASTURESTACK_RUNTIME_GO_VERSION=1.27.2' \
    'PASTURESTACK_CONSOLE_BROKER_GO_VERSION=1.27.2' \
    'grep -aF "go1.27.2" "${binary}" >/dev/null' \
    'runtime_go=1.27.2' \
    'engine_readonly_schema_sha256=${ENGINE_READONLY_SCHEMA_SHA256:-7f274219e8dd9c6d750a408a6edec1448b564f4b16ba2204c425c5b45cec2233}' \
    'engine_restricted_schema_sha256=${ENGINE_RESTRICTED_SCHEMA_SHA256:-f854ba99260f29e324ab7446a8592996946038920ac9bcf17689d98d1ebc5e51}'; do
    require_marker "$build_script" "$incremental_go_build_marker" \
        SERVER_INCREMENTAL_GO_OR_FROZEN_SCHEMA_BUILD_MISSING
done

for incremental_input_marker in \
    '"$orchestration_engine_artifact|$orchestration_engine_artifact_sha256"' \
    '"$web_console_artifact|$web_console_artifact_sha256"' \
    '"websocket-proxy-${websocket_proxy_version}-linux-amd64.tar.xz|$websocket_proxy_archive_sha256"' \
    '"host-api-${host_api_version}.tar.gz|$host_api_archive_sha256"' \
    '"node-agent-${node_agent_version}.tar.gz|$node_agent_archive_sha256"' \
    '"host-provisioner-${host_provisioner_version}-linux-amd64.tar.xz|$host_provisioner_archive_sha256"' \
    '"secret-delivery-api-${secret_delivery_api_version}-linux-amd64.tar.xz|$secret_delivery_api_archive_sha256"' \
    '"usage-telemetry-agent-${usage_telemetry_agent_version}-linux-amd64.tar.xz|$usage_telemetry_agent_archive_sha256"' \
    '"catalog-service-${catalog_service_version}.tar.xz|$catalog_service_archive_sha256"' \
    '"catalog-service-${catalog_service_version}-LICENSE.txt|$catalog_service_license_sha256"' \
    '"authentication-service-${authentication_service_version}-linux-amd64.tar.xz|$authentication_service_archive_sha256"' \
    '"webhook-automation-service-${webhook_automation_service_version}-linux-amd64.tar.xz|$webhook_automation_service_archive_sha256"' \
    '"compose-executor-${compose_executor_version}-linux-amd64.gz|$compose_executor_archive_sha256"' \
    '"vsphere-cli-bundle-${vsphere_cli_bundle_version}-linux-amd64.tar.xz|$vsphere_cli_bundle_archive_sha256"' \
    '[[ "$actual_components" == "$expected_components" ]]' \
    'printf '"'"'%s  %s\n'"'"' "$component_sha256" "$component_directory/$component_name" | sha256sum -c -'; do
    require_marker "$build_script" "$incremental_input_marker" \
        SERVER_INCREMENTAL_EXACT_COMPONENT_INPUT_MISSING
done

for incremental_layout_marker in \
    'install -m 0755 /out/catalog-service/catalog-service /out/runtime-bin/catalog-service.real;' \
    'install -m 0755 /out/catalog-service/catalog-service-sqlite /out/runtime-bin/catalog-service-sqlite;' \
    'install -m 0755 /out/authentication-service/authentication-service /out/runtime-bin/authentication-service.real;' \
    'install -m 0755 /out/websocket-proxy/websocket-proxy /out/runtime-bin/websocket-proxy.real;' \
    'install -m 0755 /out/webhook-automation-service/webhook-automation-service /out/runtime-bin/webhook-automation-service;' \
    'install -m 0755 /out/compose-executor /out/runtime-bin/compose-executor.real;' \
    'install -m 0755 /out/vsphere-cli-bundle/govc /out/runtime-bin/govc;' \
    'install -m 0755 /out/host-provisioner/host-provisioner /out/runtime-bin/host-provisioner.real;' \
    'install -m 0755 /out/secret-delivery-api/secret-delivery-api /out/runtime-bin/secret-delivery-api;' \
    'install -m 0755 /out/usage-telemetry-agent/usage-telemetry-agent /out/runtime-bin/usage-telemetry-agent;' \
    'cp -a /out/catalog-service-licenses /out/runtime-licenses/catalog-service;' \
    'cp -a /out/host-provisioner-licenses /out/runtime-licenses/host-provisioner;' \
    'cp -a /out/secret-delivery-api-licenses /out/runtime-licenses/secret-delivery-api;' \
    'cp -a /out/usage-telemetry-agent-licenses /out/runtime-licenses/usage-telemetry-agent;' \
    '/out/webhook-automation-service/webhook-automation-service-COMPATIBILITY.md' \
    '/out/webhook-automation-service/webhook-automation-service-LICENSES.txt' \
    '/out/webhook-automation-service/webhook-automation-service-SOURCES.txt' \
    '/out/webhook-automation-service/webhook-automation-service-THIRD-PARTY-NOTICES.md' \
    '/out/runtime-licenses/webhook-automation-service/' \
    '/out/vsphere-cli-bundle/vsphere-cli-bundle-LICENSES.txt' \
    '/out/vsphere-cli-bundle/vsphere-cli-bundle-SOURCES.txt' \
    '/out/vsphere-cli-bundle/vsphere-cli-bundle-THIRD-PARTY-NOTICES.txt' \
    '/out/runtime-licenses/vsphere-cli-bundle/' \
    'COPY --from=release_artifacts --chmod=0755 /out/runtime-bin/ /usr/bin/' \
    'COPY --from=release_artifacts /out/runtime-licenses/ /usr/share/licenses/pasturestack/' \
    'test "$(find /out/runtime-bin -mindepth 1 -maxdepth 1 -type f | wc -l)" -eq 10;' \
    'test "$(find /out/runtime-licenses -mindepth 1 -maxdepth 1 -type d | wc -l)" -eq 6;' \
    'test -z "$(find /out/runtime-bin /out/runtime-licenses -type l -print -quit)"'; do
    require_marker "$release_dockerfile" "$incremental_layout_marker" \
        SERVER_INCREMENTAL_RUNTIME_LAYOUT_MISSING
done

for validation_label in \
    formNameDescription.name.label \
    formNameDescription.description.label \
    newSecret.value.label \
    newSecret.name.editHelp \
    inputCertificate.cert.label \
    inputCertificate.key.label \
    certificatesPage.encryptedKeyError \
    registriesPage.new.form.custom.labelText \
    registriesPage.new.form.username.labelText \
    registriesPage.new.form.password.labelText; do
    require_marker "$release_dockerfile" "$validation_label" \
        SERVER_WEB_CONSOLE_RELEASE_VALIDATION_LABEL_GATE_MISSING
    require_marker "$build_script" "$validation_label" \
        SERVER_WEB_CONSOLE_IMAGE_VALIDATION_LABEL_GATE_MISSING
done
require_marker "$release_dockerfile" \
    'grep -F "\"${validation_label}\":" "${locale_file}"' \
    SERVER_WEB_CONSOLE_RELEASE_LOCALE_KEY_CHECK_MISSING
require_marker "$build_script" \
    'grep -F "\"${validation_label}\":" "${locale_file}"' \
    SERVER_WEB_CONSOLE_IMAGE_LOCALE_KEY_CHECK_MISSING
require_marker "$build_script" \
    'hostsPage.permissionDenied' \
    SERVER_INCREMENTAL_WEB_CONSOLE_RUNTIME_PERMISSION_GATE_MISSING
for route_permission_file in "$release_dockerfile" "$build_script"; do
    require_marker "$route_permission_file" \
        'growl-mount' \
        SERVER_WEB_CONSOLE_IN_FLOW_NOTICE_MOUNT_GATE_MISSING
    require_marker "$route_permission_file" \
        '#growl-mount .jGrowl.top-right {' \
        SERVER_WEB_CONSOLE_IN_FLOW_NOTICE_CSS_GATE_MISSING
    require_marker "$route_permission_file" \
        'grep -Fx "  position: static;"' \
        SERVER_WEB_CONSOLE_IN_FLOW_NOTICE_POSITION_GATE_MISSING
    require_marker "$route_permission_file" \
        'grep -F -A 2 ".jGrowl.top-right {"' \
        SERVER_WEB_CONSOLE_GROWL_NAV_OFFSET_GATE_MISSING
    require_marker "$route_permission_file" \
        'grep -Fx "  top: 45px;"' \
        SERVER_WEB_CONSOLE_GROWL_NAV_OFFSET_VALUE_MISSING
    require_marker "$route_permission_file" \
        'grep -F -A 4 ".jGrowl .jGrowl-closer {"' \
        SERVER_WEB_CONSOLE_GROWL_VIEWPORT_WIDTH_GATE_MISSING
    require_marker "$route_permission_file" \
        'grep -Fx "  max-width: calc(100vw - 20px);"' \
        SERVER_WEB_CONSOLE_GROWL_VIEWPORT_WIDTH_VALUE_MISSING
    require_marker "$route_permission_file" \
        'for permission_key in routePermission.title routePermission.denied routePermission.updateDenied; do' \
        SERVER_WEB_CONSOLE_ROUTE_PERMISSION_LOCALE_GATE_MISSING
    for route_permission_marker in \
        routePermission.title \
        routePermission.denied \
        routePermission.updateDenied \
        '無法執行此操作' \
        '您沒有權限在此環境中建立此資源。' \
        '您沒有權限在此環境中更新此資源。'; do
        require_marker "$route_permission_file" "$route_permission_marker" \
            SERVER_WEB_CONSOLE_ROUTE_PERMISSION_NOTICE_GATE_MISSING
    done
done
if grep -Fq 'ffb000508cb08a149e34633121aec25f4dab022967c1f4cdf917260061f0dace' \
    "$release_dockerfile" "$build_script"; then
    echo SERVER_INCREMENTAL_WEB_CONSOLE_STALE_HASH >&2
    exit 1
fi
if grep -Eq 'dacf7353a1e72e933ac883c3e4c5521e12bb9017706475a7d94f2803c5b5b216|238cdd1638c308baa5052e033c070cf0c7b9a314' \
    "$release_dockerfile" "$build_script"; then
    echo SERVER_WEB_CONSOLE_1_6_141_COORDINATES_PENDING >&2
    exit 1
fi
for release_proxy_marker in \
    'ARG WEBSOCKET_PROXY_VERSION=0.23.15' \
    'ARG WEBSOCKET_PROXY_COMMIT=1928f602b66443cdab40c8cdb450c811548d2749' \
    'ARG WEBSOCKET_PROXY_ARCHIVE_SHA256=4657338973f672f6ae4d6e5510d06e811b9951afea1baa27a9caa3034e487f2a' \
    'ARG WEBSOCKET_PROXY_BINARY_SHA256=9111d5a569b6326d7cd71fc3384251d9684972492a22e1e9dbbb9863019fbaaa' \
    'tar --no-same-owner --no-same-permissions -xJf "${websocket_archive}"' \
    'install -m 0755 /out/websocket-proxy/websocket-proxy /out/runtime-bin/websocket-proxy.real;' \
    '/usr/bin/websocket-proxy.real --help 2>&1 | grep -F -- '\''-platform-public-origin'\'''; do
    require_marker "$release_dockerfile" "$release_proxy_marker" \
        SERVER_INCREMENTAL_WEBSOCKET_PROXY_REPLACEMENT_MISSING
done
for release_proxy_build_marker in \
    'websocket_proxy_commit=${WEBSOCKET_PROXY_COMMIT:-1928f602b66443cdab40c8cdb450c811548d2749}' \
    'websocket_proxy_archive_sha256=${WEBSOCKET_PROXY_ARCHIVE_SHA256:-4657338973f672f6ae4d6e5510d06e811b9951afea1baa27a9caa3034e487f2a}' \
    'websocket_proxy_binary_sha256=${WEBSOCKET_PROXY_BINARY_SHA256:-9111d5a569b6326d7cd71fc3384251d9684972492a22e1e9dbbb9863019fbaaa}' \
    'PASTURESTACK_WEBSOCKET_PROXY_BINARY_SHA256="${websocket_proxy_binary_sha256}"' \
    'echo "${PASTURESTACK_WEBSOCKET_PROXY_BINARY_SHA256}  /usr/bin/websocket-proxy.real" | sha256sum -c -'; do
    require_marker "$build_script" "$release_proxy_build_marker" \
        SERVER_INCREMENTAL_WEBSOCKET_PROXY_RUNTIME_IDENTITY_MISSING
done
for release_webhook_marker in \
    'ARG WEBHOOK_AUTOMATION_SERVICE_VERSION=0.10.4' \
    'ARG WEBHOOK_AUTOMATION_SERVICE_COMMIT=400118b893843d2a7d7c65cc70c3449d76c4a8d8' \
    'ARG WEBHOOK_AUTOMATION_SERVICE_ARCHIVE_SHA256=49c4579829a04e758045fae02a5a9fca12bb0ba3af0d5e979cf9eb97f23a88a9' \
    'ARG WEBHOOK_AUTOMATION_SERVICE_BINARY_SHA256=98c7faea665b7eb95206b8c73a6f47d644c5d2d0eae53f274f6a15faf5205744' \
    'LC_ALL=C sort "${webhook_listing}" | cmp "${webhook_expected}" -' \
    'tar --no-same-owner --no-same-permissions -xJf "${webhook_archive}"' \
    'install -m 0755 /out/webhook-automation-service/webhook-automation-service /out/runtime-bin/webhook-automation-service;' \
    'test "$(readlink -f /usr/bin/webhook-service)" = /usr/bin/webhook-automation-service'; do
    require_marker "$release_dockerfile" "$release_webhook_marker" \
        SERVER_INCREMENTAL_WEBHOOK_REPLACEMENT_MISSING
done
for release_webhook_build_marker in \
    'webhook_automation_service_version=${WEBHOOK_AUTOMATION_SERVICE_VERSION:-0.10.4}' \
    'webhook_automation_service_commit=${WEBHOOK_AUTOMATION_SERVICE_COMMIT:-400118b893843d2a7d7c65cc70c3449d76c4a8d8}' \
    'webhook_automation_service_archive_sha256=${WEBHOOK_AUTOMATION_SERVICE_ARCHIVE_SHA256:-49c4579829a04e758045fae02a5a9fca12bb0ba3af0d5e979cf9eb97f23a88a9}' \
    'webhook_automation_service_binary_sha256=${WEBHOOK_AUTOMATION_SERVICE_BINARY_SHA256:-98c7faea665b7eb95206b8c73a6f47d644c5d2d0eae53f274f6a15faf5205744}' \
    'WEBHOOK_AUTOMATION_SERVICE_ARCHIVE_SHA256=${webhook_automation_service_archive_sha256}' \
    '98c7faea665b7eb95206b8c73a6f47d644c5d2d0eae53f274f6a15faf5205744  /usr/bin/webhook-automation-service' \
    'PASTURESTACK_WEBHOOK_AUTOMATION_SERVICE_VERSION="${webhook_automation_service_version}"'; do
    require_marker "$build_script" "$release_webhook_build_marker" \
        SERVER_INCREMENTAL_WEBHOOK_BUILD_GATE_MISSING
done
require_marker "$release_dockerfile" \
    'ARG COMPOSE_EXECUTOR_VERSION=0.14.37' \
    SERVER_INCREMENTAL_COMPOSE_VERSION_MISSING
require_marker "$release_dockerfile" \
    'ARG COMPOSE_EXECUTOR_BINARY_SHA256=a9bf9f0f77e914fe557d3e178a73c31526b0ca0adc4afbf17bf68d8d75c7ee27' \
    SERVER_INCREMENTAL_COMPOSE_HASH_MISSING
require_marker "$release_dockerfile" \
    'tar --no-same-owner --no-same-permissions -xzf "${web_archive}"' \
    SERVER_INCREMENTAL_WEB_CONSOLE_SAFE_EXTRACTION_MISSING
require_marker "$release_dockerfile" \
    'COPY --from=release_artifacts /out/web-console/ /tmp/pasturestack-web-console/' \
    SERVER_INCREMENTAL_WEB_CONSOLE_COPY_MISSING
require_marker "$release_dockerfile" \
    'install -m 0755 /out/compose-executor /out/runtime-bin/compose-executor.real;' \
    SERVER_INCREMENTAL_COMPOSE_COPY_MISSING
require_marker "$release_dockerfile" \
    'COPY --from=console_broker_build --chmod=0755 /out/pasturestack-console-broker /usr/bin/pasturestack-console-broker' \
    SERVER_INCREMENTAL_CONSOLE_BROKER_COPY_MISSING
require_marker "$release_dockerfile" \
    'go test ./...' \
    SERVER_INCREMENTAL_CONSOLE_BROKER_TEST_MISSING
require_marker server/console-broker/broker.go \
    'headers.Set("Origin", sessionDialOrigin(target))' \
    SERVER_CONSOLE_BROKER_INTERNAL_ORIGIN_BINDING_MISSING
require_marker server/console-broker/broker_test.go \
    'TestSessionCreationRebindsBrowserOriginToInternalDialOrigin' \
    SERVER_CONSOLE_BROKER_INTERNAL_ORIGIN_TEST_MISSING
require_marker server/console-broker/broker.go \
    'status != http.StatusUnauthorized || attempt == b.config.SessionDialAttempts' \
    SERVER_CONSOLE_BROKER_BACKEND_RETRY_BOUNDARY_MISSING
require_marker server/console-broker/broker_test.go \
    'TestSessionCreationRetriesBackendRegistrationRace' \
    SERVER_CONSOLE_BROKER_BACKEND_RETRY_TEST_MISSING
require_marker server/console-broker/broker_test.go \
    'TestSessionCreationBackendRetryIsBounded' \
    SERVER_CONSOLE_BROKER_BACKEND_RETRY_LIMIT_TEST_MISSING
for broker_cache_marker in \
    'isPlatformAPIPath(response.Request.URL.Path)' \
    'response.Header.Set("Cache-Control", "private, no-store")' \
    'response.Header.Set("Pragma", "no-cache")' \
    'response.Header.Set("Expires", "0")' \
    'response.Header.Del("Age")'; do
    require_marker server/console-broker/broker.go "$broker_cache_marker" \
        SERVER_CONSOLE_BROKER_PRIVATE_CACHE_POLICY_MISSING
done
require_marker server/console-broker/broker_test.go \
    'TestPlatformAPIResponsesCannotBeSharedCached' \
    SERVER_CONSOLE_BROKER_PRIVATE_CACHE_POLICY_TEST_MISSING
require_marker server/console-broker/broker_test.go \
    'TestStaticAssetCachePolicyIsPreserved' \
    SERVER_CONSOLE_BROKER_STATIC_CACHE_POLICY_TEST_MISSING
require_marker "$release_dockerfile" \
    'test "${compose_version_output}" = "compose-executor version ${COMPOSE_EXECUTOR_VERSION}"' \
    SERVER_INCREMENTAL_COMPOSE_VERSION_GATE_MISSING
require_marker "$release_dockerfile" \
    'footer .footer-dropdown .dropdown-menu' \
    SERVER_INCREMENTAL_FOOTER_MENU_GATE_MISSING
require_marker "$release_dockerfile" \
    '.form-resources .resource-host-guidance' \
    SERVER_INCREMENTAL_RESOURCE_GUIDANCE_GATE_MISSING
require_marker "$release_dockerfile" \
    '"formResources.addUlimit":"新增限制"' \
    SERVER_INCREMENTAL_TRANSLATION_GATE_MISSING
for write_permission_key in \
    containersPage.permissionDenied \
    hookPage.receiver.permissionDenied \
    hookPage.receiver.editPermissionDenied; do
    require_marker "$release_dockerfile" "$write_permission_key" \
        SERVER_WEB_CONSOLE_WRITE_PERMISSION_IMAGE_GATE_MISSING
    require_marker "$build_script" "$write_permission_key" \
        SERVER_WEB_CONSOLE_WRITE_PERMISSION_BUILD_GATE_MISSING
done
require_marker "$build_script" \
    'for locale_file in "${web_root}"/translations/*.json; do' \
    SERVER_WEB_CONSOLE_WRITE_PERMISSION_LOCALE_GATE_MISSING
require_marker "$release_dockerfile" \
    '"viewEditProject.error.projectUnavailable":"找不到此環境' \
    SERVER_ENVIRONMENT_ACCESS_TRANSLATION_GATE_MISSING
require_marker "$release_dockerfile" \
    '"viewEditProject.error.membersNotSaved":"成員變更未完成' \
    SERVER_ENVIRONMENT_MEMBER_SAVE_TRANSLATION_GATE_MISSING
require_marker "$release_dockerfile" \
    '"viewEditProject.error.loadFailed":"暫時無法載入環境資料' \
    SERVER_ENVIRONMENT_LOAD_FAILURE_TRANSLATION_GATE_MISSING
require_marker "$release_dockerfile" \
    '"viewEditProject.error.projectFailed":"環境設定未儲存：伺服器暫時無法處理' \
    SERVER_ENVIRONMENT_SAVE_FAILURE_TRANSLATION_GATE_MISSING
require_marker "$release_dockerfile" \
    '"resourceLoadError.stackUnavailable":"找不到此應用堆疊' \
    SERVER_STACK_ACCESS_TRANSLATION_GATE_MISSING
require_marker "$release_dockerfile" \
    '"resourceLoadError.accountsUnavailable":"無法載入帳號資料' \
    SERVER_ACCOUNT_ACCESS_TRANSLATION_GATE_MISSING
for load_marker in \
    resourceLoadError.serviceUnavailable \
    resourceLoadError.serviceFailed \
    resourceLoadError.secretsUnavailable \
    resourceLoadError.secretsFailed; do
    require_marker "$release_dockerfile" "$load_marker" \
        SERVER_WEB_CONSOLE_RESOURCE_LOAD_ARCHIVE_GATE_MISSING
    require_marker "$build_script" "$load_marker" \
        SERVER_WEB_CONSOLE_RESOURCE_LOAD_IMAGE_GATE_MISSING
done
for load_gate_file in "$release_dockerfile" "$build_script"; do
    require_marker "$load_gate_file" \
        'serviceUnavailable serviceFailed secretsUnavailable secretsFailed' \
        SERVER_WEB_CONSOLE_RESOURCE_LOAD_LOCALE_GATE_MISSING
done
require_marker "$release_dockerfile" \
    '"resourceLoadError.serviceUnavailable":"找不到此服務' \
    SERVER_SERVICE_ACCESS_TRANSLATION_GATE_MISSING
require_marker "$release_dockerfile" \
    '"resourceLoadError.secretsUnavailable":"無法載入機密資料' \
    SERVER_SECRETS_ACCESS_TRANSLATION_GATE_MISSING
require_marker "$build_script" \
    'resourceLoadError.serviceUnavailable' \
    SERVER_SERVICE_ACCESS_RUNTIME_GATE_MISSING
require_marker "$build_script" \
    'resourceLoadError.secretsUnavailable' \
    SERVER_SECRETS_ACCESS_RUNTIME_GATE_MISSING
require_marker "$build_script" \
    'viewEditProject.error.projectUnavailable' \
    SERVER_ENVIRONMENT_ACCESS_RUNTIME_GATE_MISSING
require_marker "$build_script" \
    'viewEditProject.error.membersNotSaved' \
    SERVER_ENVIRONMENT_MEMBER_SAVE_RUNTIME_GATE_MISSING
require_marker "$build_script" \
    'viewEditProject.error.loadFailed' \
    SERVER_ENVIRONMENT_LOAD_FAILURE_RUNTIME_GATE_MISSING
require_marker "$build_script" \
    'viewEditProject.error.projectFailed' \
    SERVER_ENVIRONMENT_SAVE_FAILURE_RUNTIME_GATE_MISSING
require_marker "$build_script" \
    'inputIdentity.error.forbidden' \
    SERVER_IDENTITY_SEARCH_RUNTIME_GATE_MISSING
require_marker "$build_script" \
    'resourceLoadError.stackUnavailable' \
    SERVER_STACK_ACCESS_RUNTIME_GATE_MISSING
require_marker "$build_script" \
    '--file server/Dockerfile.web-compose-release' \
    SERVER_INCREMENTAL_RELEASE_BUILD_PATH_MISSING
require_marker "$build_script" \
    'image=${IMAGE:-pasturestack-validation/server:v1.6.519}' \
    SERVER_INCREMENTAL_RELEASE_BUILD_VERSION_MISSING
require_marker "$build_script" \
    'server_release_tag=${SERVER_RELEASE_TAG:-v1.6.519}' \
    SERVER_INCREMENTAL_RELEASE_BUILD_DEFAULT_MISSING
require_marker "$build_script" \
    'CATTLE_RANCHER_SERVER_VERSION="${server_release_tag}"' \
    SERVER_INCREMENTAL_RELEASE_BUILD_RUNTIME_VERSION_MISSING
for release_engine_marker in \
    'ARG ORCHESTRATION_ENGINE_RELEASE_TAG=v0.183.334' \
    'ARG ORCHESTRATION_ENGINE_ARTIFACT=cattle.jar' \
    'ARG ORCHESTRATION_ENGINE_ARTIFACT_SHA256=b0e3608b21ce405cdaf2f74699442b9420844384055f85acf88cfeb638600490' \
    'ARG ORCHESTRATION_ENGINE_COMMIT=91f44685953f7cc72344a21cb47ca235c0bce53f' \
    'COPY --from=release_artifacts /out/orchestration-engine.jar /tmp/orchestration-engine.jar' \
    'ARG ORCHESTRATION_ENGINE_VERSION=0.183.334' \
    'grep -Fx "Implementation-Version: ${ORCHESTRATION_ENGINE_VERSION}"' \
    'cattle-resources-${ORCHESTRATION_ENGINE_VERSION}.jar' \
    'cattle-app-config-${ORCHESTRATION_ENGINE_VERSION}.jar' \
    'WEB-INF/lib/hazelcast-5\.7\.5\.jar' \
    'freemarker-2\.3\.35\.jar' \
    'ENV CATTLE_CATTLE_VERSION=${ORCHESTRATION_ENGINE_RELEASE_TAG}' \
    'schema/token/token-auth.json' \
    '"token.clientSessionId": "cro"' \
    'for frozen_token_schema in base superadmin token' \
    'schema/v1/${frozen_token_schema}.ser' \
    'META-INF/cattle/iaas-api/defaults.properties' \
    'auth.service.external.id.types=github_user,github_org,github_team,shibboleth_user,shibboleth_group,ldap_user,ldap_group,oidc_user,oidc_group' \
    'schema/base/projectMember.json' \
    'for oidc_type in oidc_user oidc_group' \
    'ENV PASTURESTACK_ORCHESTRATION_ENGINE_COMMIT=${ORCHESTRATION_ENGINE_COMMIT}' \
    'ENV PASTURESTACK_ORCHESTRATION_ENGINE_ARTIFACT_SHA256=${ORCHESTRATION_ENGINE_ARTIFACT_SHA256}'; do
    require_marker "$release_dockerfile" "$release_engine_marker" \
        SERVER_INCREMENTAL_ENGINE_REPLACEMENT_MISSING
done
for release_engine_build_marker in \
    'orchestration_engine_release_tag=${ORCHESTRATION_ENGINE_RELEASE_TAG:-v0.183.334}' \
    'orchestration_engine_artifact=${ORCHESTRATION_ENGINE_ARTIFACT:-cattle.jar}' \
    'orchestration_engine_artifact_sha256=${ORCHESTRATION_ENGINE_ARTIFACT_SHA256:-b0e3608b21ce405cdaf2f74699442b9420844384055f85acf88cfeb638600490}' \
    'orchestration_engine_commit=${ORCHESTRATION_ENGINE_COMMIT:-91f44685953f7cc72344a21cb47ca235c0bce53f}' \
    'CATTLE_CATTLE_VERSION="${orchestration_engine_release_tag}"' \
    'cattle-resources-${ORCHESTRATION_ENGINE_VERSION}.jar' \
    'test "${hazelcast_entry}" = "WEB-INF/lib/hazelcast-5.7.5.jar"'; do
    require_marker "$build_script" "$release_engine_build_marker" \
        SERVER_INCREMENTAL_ENGINE_BUILD_COORDINATE_MISSING
done
if grep -Fq 'ARG ORCHESTRATION_ENGINE_ARTIFACT_SHA256=8483db0b4f2fe71ce527ba97bfb3caea14096ec356124ecef9aa1e7853c8553e' "$release_dockerfile" \
    || grep -Fq 'ARG ORCHESTRATION_ENGINE_COMMIT=268469153c299987bd42e288dd68bb62af91002e' "$release_dockerfile" \
    || grep -Fq 'orchestration_engine_artifact_sha256=${ORCHESTRATION_ENGINE_ARTIFACT_SHA256:-8483db0b4f2fe71ce527ba97bfb3caea14096ec356124ecef9aa1e7853c8553e}' "$build_script" \
    || grep -Fq 'orchestration_engine_commit=${ORCHESTRATION_ENGINE_COMMIT:-268469153c299987bd42e288dd68bb62af91002e}' "$build_script"; then
    echo 'SERVER_ENGINE_0_183_321_COORDINATES_PENDING' >&2
    exit 1
fi
if grep -Eq '9ce9358d91ff002c0b64a8c1efd037b26f43ccbe11508a1446760f3baffcb564|60aabb3b3c95ab2ed62535a49606a287e037f2fe' \
    "$release_dockerfile" "$build_script"; then
    echo SERVER_ENGINE_0_183_327_COORDINATES_PENDING >&2
    exit 1
fi
for release_auth_marker in \
    'ARG AUTHENTICATION_SERVICE_RELEASE_BASE_URL=https://github.com/PastureStack/authentication-service/releases/download' \
    'ARG AUTHENTICATION_SERVICE_VERSION=0.4.43' \
    'ARG AUTHENTICATION_SERVICE_COMMIT=cae736f377019bd9743648a8e9aa469a0e21b5e0' \
    'ARG AUTHENTICATION_SERVICE_ARCHIVE_SHA256=e9218771af8dd68323c8c6fdab149c40a3ad02da9ff23f8aad6f0b2977740273' \
    'ARG AUTHENTICATION_SERVICE_BINARY_SHA256=fe11eec4b31b43863b49a582b1dbbe309eae08fb78adc150037981174f0622da' \
    'Authentication Service archive may not contain links' \
    'install -m 0755 /out/authentication-service/authentication-service /out/runtime-bin/authentication-service.real;' \
    'ENV PASTURESTACK_AUTHENTICATION_SERVICE_COMMIT=${AUTHENTICATION_SERVICE_COMMIT}' \
    'grep -aF "${marker}" /usr/bin/authentication-service.real'; do
    require_marker "$release_dockerfile" "$release_auth_marker" \
        SERVER_INCREMENTAL_AUTHENTICATION_SERVICE_REPLACEMENT_MISSING
done
for release_auth_build_marker in \
    'authentication_service_version=${AUTHENTICATION_SERVICE_VERSION:-0.4.43}' \
    'authentication_service_commit=${AUTHENTICATION_SERVICE_COMMIT:-cae736f377019bd9743648a8e9aa469a0e21b5e0}' \
    'authentication_service_archive_sha256=${AUTHENTICATION_SERVICE_ARCHIVE_SHA256:-e9218771af8dd68323c8c6fdab149c40a3ad02da9ff23f8aad6f0b2977740273}' \
    'authentication_service_binary_sha256=${AUTHENTICATION_SERVICE_BINARY_SHA256:-fe11eec4b31b43863b49a582b1dbbe309eae08fb78adc150037981174f0622da}' \
    '--build-arg "AUTHENTICATION_SERVICE_VERSION=${authentication_service_version}"' \
    'PASTURESTACK_AUTHENTICATION_SERVICE_COMMIT="${authentication_service_commit}"' \
    'fe11eec4b31b43863b49a582b1dbbe309eae08fb78adc150037981174f0622da  /usr/bin/authentication-service.real' \
    '/usr/bin/authentication-service.real --version | grep -F "0.4.43"'; do
    require_marker "$build_script" "$release_auth_build_marker" \
        SERVER_INCREMENTAL_AUTHENTICATION_SERVICE_BUILD_GATE_MISSING
done
for oidc_policy_contract_marker in \
    'oidcAccessPolicyUpdate' \
    '"requestDigest"' \
    'LocalRecoveryRequired' \
    'MfaConfirmationRequired' \
    'InvalidAllowedIdentity'; do
    require_marker "$release_dockerfile" "$oidc_policy_contract_marker" \
        SERVER_INCREMENTAL_OIDC_POLICY_CONTRACT_MISSING
    require_marker "$build_script" "$oidc_policy_contract_marker" \
        SERVER_INCREMENTAL_OIDC_POLICY_RUNTIME_GATE_MISSING
done
require_marker "$release_dockerfile" \
    'supported.docker.range=~v1.12.3 || ~v1.13.0 || ~v17.03.0 || ~v17.06.0 || ~v17.09.0 || ~v17.12.0 || ~v18.03.0 || ~v18.06.0 || ~v18.09.0 || ~v19.03.2 || v24.0.9 || >=v29.4.1 <=v29.7.2 || v29.8.0' \
    SERVER_INCREMENTAL_ENGINE_DOCKER_RANGE_MISSING
require_marker "$release_dockerfile" \
    'newest.docker.version=v29.8.0' \
    SERVER_INCREMENTAL_ENGINE_NEWEST_DOCKER_MISSING
require_marker "$build_script" \
    "supported_docker_range='~v1.12.3 || ~v1.13.0 || ~v17.03.0 || ~v17.06.0 || ~v17.09.0 || ~v17.12.0 || ~v18.03.0 || ~v18.06.0 || ~v18.09.0 || ~v19.03.2 || v24.0.9 || >=v29.4.1 <=v29.7.2 || v29.8.0'" \
    SERVER_INCREMENTAL_BUILD_DOCKER_RANGE_MISSING
require_marker "$build_script" \
    'newest_docker_version=v29.8.0' \
    SERVER_INCREMENTAL_BUILD_NEWEST_DOCKER_MISSING
require_marker "$release_dockerfile" \
    'if [ "${new_web_root}" != "${old_web_root}" ]; then' \
    SERVER_INCREMENTAL_ENGINE_ROOT_REUSE_BRANCH_MISSING
require_marker "$release_dockerfile" \
    'test -d "${new_web_root}/WEB-INF/lib"' \
    SERVER_INCREMENTAL_ENGINE_ROOT_REUSE_VALIDATION_MISSING
if grep -Fq -- 'test "${new_web_root}" != "${old_web_root}"' "$release_dockerfile"; then
    echo 'SERVER_INCREMENTAL_ENGINE_ROOT_REUSE_BLOCKED' >&2
    exit 1
fi

for release_vsphere_marker in \
    'ARG VSPHERE_CLI_BUNDLE_VERSION=0.55.3' \
    'ARG VSPHERE_CLI_BUNDLE_COMMIT=f48ab9fd9990132c85845fc162186a04f1e0418d' \
    'ARG VSPHERE_CLI_BUNDLE_ARCHIVE_SHA256=31be702e515741686e2c665d387562e5e993c5d2ffbdb2d614ed287243b166e4' \
    'ARG GOVC_BINARY_SHA256=d3c4f4fab44403ec4110743b52da99f5ce3d7e3773c4661db8a87dec3ead8990' \
    'install -m 0755 /out/vsphere-cli-bundle/govc /out/runtime-bin/govc;' \
    'ENV PASTURESTACK_VSPHERE_CLI_BUNDLE_VERSION=${VSPHERE_CLI_BUNDLE_VERSION}' \
    'ENV PASTURESTACK_GOVC_BINARY_SHA256=${GOVC_BINARY_SHA256}'; do
    require_marker "$release_dockerfile" "$release_vsphere_marker" \
        SERVER_INCREMENTAL_VSPHERE_REPLACEMENT_MISSING
done
for release_vsphere_build_marker in \
    'vsphere_cli_bundle_version=${VSPHERE_CLI_BUNDLE_VERSION:-0.55.3}' \
    'vsphere_cli_bundle_commit=${VSPHERE_CLI_BUNDLE_COMMIT:-f48ab9fd9990132c85845fc162186a04f1e0418d}' \
    'vsphere_cli_bundle_archive_sha256=${VSPHERE_CLI_BUNDLE_ARCHIVE_SHA256:-31be702e515741686e2c665d387562e5e993c5d2ffbdb2d614ed287243b166e4}' \
    'govc_binary_sha256=${GOVC_BINARY_SHA256:-d3c4f4fab44403ec4110743b52da99f5ce3d7e3773c4661db8a87dec3ead8990}' \
    'echo "${PASTURESTACK_GOVC_BINARY_SHA256}  /usr/bin/govc" | sha256sum -c -' \
    'test "$(/usr/bin/govc version)" = "govc ${PASTURESTACK_VSPHERE_CLI_BUNDLE_VERSION}"' \
    'grep -Fx "Security dependency: golang.org/x/text v0.41.0"'; do
    require_marker "$build_script" "$release_vsphere_build_marker" \
        SERVER_INCREMENTAL_VSPHERE_BUILD_OR_READBACK_MISSING
done
require_marker "$release_dockerfile" \
    'Security dependency: golang.org/x/text v0.41.0' \
    SERVER_INCREMENTAL_VSPHERE_FIXED_DEPENDENCY_MISSING
require_marker "$build_script" \
    '[[ "$orchestration_engine_release_tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]' \
    SERVER_INCREMENTAL_ENGINE_NUMERIC_TAG_GATE_MISSING
require_marker "$build_script" \
    '[[ "$vsphere_cli_bundle_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]' \
    SERVER_INCREMENTAL_VSPHERE_NUMERIC_VERSION_GATE_MISSING

require_marker "$dockerfile" \
    'ARG BASE_IMAGE=ghcr.io/pasturestack/server:v1.6.364@sha256:98ace6dd822f883f2f161f8e7c3191d45cc1f1aef6d2cb6de281cfb1d93237e5' \
    SERVER_API_EXPLORER_PATCH_BASE_NOT_CURRENT
require_marker "$dockerfile" \
    'ARG UBUNTU_SNAPSHOT=20260910T100000Z' \
    SERVER_API_EXPLORER_PATCH_UBUNTU_SNAPSHOT_NOT_CURRENT
for bootstrap_dockerfile in "$dockerfile" "$core_dockerfile"; do
    require_marker "$bootstrap_dockerfile" \
        'https://security.ubuntu.com/ubuntu/pool/main/c/ca-certificates/ca-certificates_20260601~26.04.1_all.deb' \
        SERVER_CA_CERTIFICATES_OFFICIAL_BOOTSTRAP_SOURCE_MISSING
    require_marker "$bootstrap_dockerfile" \
        'ADD --checksum=sha256:6077d27c6b6f8b23590cb01ff877ed8c804a67a5442cc32b5a33da10d2bd0e90' \
        SERVER_CA_CERTIFICATES_BOOTSTRAP_HASH_MISSING
done
if grep -Fq 'https://launchpad.net/ubuntu/+archive/primary/+files/' \
    "$dockerfile" "$core_dockerfile"; then
    echo 'SERVER_CA_CERTIFICATES_MUTABLE_BOOTSTRAP_SOURCE_BLOCKED' >&2
    exit 1
fi
if grep -Fq '/pool/main/c/ca-certificates/ca-certificates_20260601~26.04.1_all.deb' \
    "$dockerfile" "$core_dockerfile" && \
   grep -Fq 'https://snapshot.ubuntu.com/ubuntu/' \
    "$dockerfile" "$core_dockerfile"; then
    if grep -F 'https://snapshot.ubuntu.com/ubuntu/' \
        "$dockerfile" "$core_dockerfile" | \
       grep -Fq '/pool/main/c/ca-certificates/'; then
        echo 'SERVER_CA_CERTIFICATES_SNAPSHOT_POOL_BOOTSTRAP_BLOCKED' >&2
        exit 1
    fi
fi
require_marker "$dockerfile" \
    'org.opencontainers.image.version="v1.6.428"' \
    SERVER_API_EXPLORER_PATCH_VERSION_MISSING
require_marker "$dockerfile" \
    'ENV CATTLE_RANCHER_SERVER_VERSION=v1.6.428' \
    SERVER_API_EXPLORER_PATCH_RUNTIME_VERSION_MISSING
require_marker "$dockerfile" \
    'ARG SUPPORTED_DOCKER_RANGE="~v1.12.3 || ~v1.13.0 || ~v17.03.0 || ~v17.06.0 || ~v17.09.0 || ~v17.12.0 || ~v18.03.0 || ~v18.06.0 || ~v18.09.0 || ~v19.03.2 || v24.0.9 || >=v29.4.1 <=v29.7.2"' \
    SERVER_DOCKER_29_COMPATIBILITY_RANGE_MISSING
require_marker "$dockerfile" \
    'jar --update --file "${app_config_jar}" --date="${source_date_iso}"' \
    SERVER_DOCKER_SUPPORT_RUNTIME_PATCH_MISSING
require_marker "$build_script" \
    "supported_docker_range='~v1.12.3 || ~v1.13.0 || ~v17.03.0 || ~v17.06.0 || ~v17.09.0 || ~v17.12.0 || ~v18.03.0 || ~v18.06.0 || ~v18.09.0 || ~v19.03.2 || v24.0.9 || >=v29.4.1 <=v29.7.2 || v29.8.0'" \
    SERVER_DOCKER_SUPPORT_IMAGE_GATE_MISSING
require_marker "$build_script" \
    'newest_docker_version=v29.8.0' \
    SERVER_DOCKER_SUPPORT_IMAGE_GATE_MISSING
require_marker "$dockerfile" \
    'ENV DEFAULT_CATTLE_LB_INSTANCE_IMAGE=ghcr.io/pasturestack/load-balancer-service:v0.9.27' \
    SERVER_API_EXPLORER_PATCH_LB_IMAGE_MISSING
require_marker "$dockerfile" \
    'ENV DEFAULT_CATTLE_LB_INSTANCE_IMAGE_UUID=docker:ghcr.io/pasturestack/load-balancer-service:v0.9.27' \
    SERVER_API_EXPLORER_PATCH_LB_IMAGE_UUID_MISSING
require_marker "$dockerfile" \
    'ENV CATTLE_API_UI_VERSION=1.1.18' \
    SERVER_API_EXPLORER_PATCH_API_VERSION_MISSING
require_marker "$dockerfile" \
    'ARG API_EXPLORER_ARTIFACT_SHA256=92b718c46163018ea40c008ac552911f0eb610647377725405f4046dcd411f2c' \
    SERVER_API_EXPLORER_PATCH_HASH_MISSING
require_marker "$dockerfile" \
    'ARG API_EXPLORER_COMMIT=3b1c39e8a116f58649d94233a384a0362c02b43e' \
    SERVER_API_EXPLORER_PATCH_COMMIT_MISSING
require_marker "$dockerfile" \
    'ARG ORCHESTRATION_ENGINE_RELEASE_TAG=v0.183.298' \
    SERVER_ORCHESTRATION_RELEASE_TAG_MISSING
require_marker "$dockerfile" \
    'ARG ORCHESTRATION_ENGINE_ARTIFACT=orchestration-engine-0.183.298.jar' \
    SERVER_ORCHESTRATION_RELEASE_ARTIFACT_MISSING
require_marker "$dockerfile" \
    'ARG ORCHESTRATION_ENGINE_ARTIFACT_SHA256=cf7cd9c9948cabe242d6e9659f4fa60cdf645ef775b855b9876b765a9386b7f1' \
    SERVER_ORCHESTRATION_RELEASE_HASH_MISSING
require_marker "$dockerfile" \
    'ARG ORCHESTRATION_ENGINE_COMMIT=f95ac014dba0931c62aa5ae3d8cc25f5c5921285' \
    SERVER_ORCHESTRATION_RELEASE_COMMIT_MISSING
require_marker "$dockerfile" \
    'ENV CATTLE_CATTLE_VERSION=v0.183.298' \
    SERVER_ORCHESTRATION_RUNTIME_VERSION_MISSING
require_marker "$dockerfile" \
    'grep -Fx '\''Implementation-Version: 0.183.298'\'' >/dev/null' \
    SERVER_ORCHESTRATION_MANIFEST_GATE_MISSING
require_marker "$dockerfile" \
    'WEB-INF/lib/hazelcast-5\.7\.4\.jar' \
    SERVER_DISTRIBUTED_CACHE_RUNTIME_GATE_MISSING
require_marker "$build_script" \
    '0f536a9c7bcd00f2369586fb6ca1606f7e45f3225e24795d10d38397051c8715  /tmp/hazelcast.jar' \
    SERVER_DISTRIBUTED_CACHE_RUNTIME_HASH_GATE_MISSING
require_marker "$build_script" \
    'image_orchestration' \
    SERVER_ORCHESTRATION_IMAGE_HASH_GATE_MISSING
require_marker "$dockerfile" \
    'COPY patches/db/core-124.xml /tmp/pasturestack-server-overlays/db/core-124.xml' \
    SERVER_CATALOG_PINNED_COMMIT_OVERLAY_MISSING
require_marker "$dockerfile" \
    'java -cp ".:${new_web_root}/WEB-INF/lib/*" PatchV1GlobalSubscribe verify' \
    SERVER_GLOBAL_SUBSCRIBE_SCHEMA_OVERLAY_MISSING
for hardware_schema_dockerfile in "$dockerfile" "$release_dockerfile"; do
    require_marker "$hardware_schema_dockerfile" \
        'java -cp ".:${new_web_root}/WEB-INF/lib/*" PatchV1GlobalSubscribe verify-hardware' \
        SERVER_FROZEN_V1_HARDWARE_SCHEMA_GATE_MISSING
done
require_marker server/patches/PatchV1GlobalSubscribe.java \
    'FROZEN_V1_HARDWARE_SCHEMAS_OK' \
    SERVER_FROZEN_V1_HARDWARE_SCHEMA_VALIDATOR_MISSING
require_marker "$dockerfile" \
    'test "$(readlink -f /usr/share/cattle/war)" = "${new_web_root}"' \
    SERVER_ORCHESTRATION_EXPLODED_ROOT_BINDING_MISSING
require_marker "$dockerfile" \
    'web_console_stage=/tmp/pasturestack-web-console' \
    SERVER_WEB_CONSOLE_PRESERVATION_STAGE_MISSING
require_marker "$dockerfile" \
    'cp -a "${old_web_root}/${static_path}" "${web_console_stage}/${static_path}"' \
    SERVER_WEB_CONSOLE_PRESERVATION_COPY_MISSING
require_marker "$dockerfile" \
    'test -z "$(find "${web_console_stage}" -type l -print -quit)"' \
    SERVER_WEB_CONSOLE_PRESERVATION_SYMLINK_GATE_MISSING
require_marker "$dockerfile" \
    'ARG WEB_CONSOLE_RELEASE_TAG=1.6.116' \
    SERVER_WEB_CONSOLE_RELEASE_TAG_MISSING
require_marker "$dockerfile" \
    'ARG WEB_CONSOLE_ARTIFACT=web-console-1.6.116.tar.gz' \
    SERVER_WEB_CONSOLE_RELEASE_ARTIFACT_MISSING
require_marker "$dockerfile" \
    'ARG WEB_CONSOLE_ARTIFACT_SHA256=c48a5921476b7f543f56bb12908c75ac76ae5d441aa86a7bbf70b2c98d4faf41' \
    SERVER_WEB_CONSOLE_RELEASE_HASH_MISSING
require_marker "$dockerfile" \
    'ARG WEB_CONSOLE_COMMIT=7c2300ec5342d416382e5bf9442db493e8a648b4' \
    SERVER_WEB_CONSOLE_RELEASE_COMMIT_MISSING
require_marker "$dockerfile" \
    'tar --no-same-owner --no-same-permissions -xzf "${archive}" -C "${stage}"' \
    SERVER_WEB_CONSOLE_SAFE_EXTRACTION_MISSING
require_marker "$dockerfile" \
    'grep -aF "${marker}" "${ui_entry}"' \
    SERVER_WEB_CONSOLE_AUDIT_FILTER_MARKER_GATE_MISSING
require_marker "$dockerfile" \
    'ui/utils/bootstrap-runtime' \
    SERVER_WEB_CONSOLE_BOOTSTRAP_MODULE_GATE_MISSING
require_marker "$dockerfile" \
    'window.bootstrap=' \
    SERVER_WEB_CONSOLE_BOOTSTRAP_GLOBAL_GATE_MISSING
require_marker "$dockerfile" \
    'ember-basic-dropdown-wormhole' \
    SERVER_WEB_CONSOLE_DROPDOWN_DESTINATION_GATE_MISSING
require_marker "$dockerfile" \
    'basic-dropdown-wormhole' \
    SERVER_WEB_CONSOLE_DROPDOWN_COMPONENT_GATE_MISSING
require_marker "$dockerfile" \
    'audit-date-picker' \
    SERVER_WEB_CONSOLE_AUDIT_CALENDAR_GATE_MISSING
require_marker "$dockerfile" \
    'service-log-filter-panel' \
    SERVER_WEB_CONSOLE_SERVICE_LOG_FILTER_GATE_MISSING
require_marker "$dockerfile" \
    'service.instance.restart' \
    SERVER_WEB_CONSOLE_SERVICE_RESTART_EVENT_GATE_MISSING
require_marker "$dockerfile" \
    'footer .footer-dropdown .dropdown-menu' \
    SERVER_WEB_CONSOLE_FOOTER_MENU_BOUNDARY_GATE_MISSING
require_marker "$dockerfile" \
    '.form-resources .resource-host-guidance' \
    SERVER_WEB_CONSOLE_RESOURCE_GUIDANCE_GATE_MISSING
require_marker "$dockerfile" \
    '"formResources.addUlimit":"新增限制"' \
    SERVER_WEB_CONSOLE_ADD_ULIMIT_TRANSLATION_GATE_MISSING
require_marker "$build_script" \
    'grep -F "\"formResources.addUlimit\":\"新增限制\""' \
    SERVER_WEB_CONSOLE_BUILD_ADD_ULIMIT_TRANSLATION_GATE_MISSING
require_marker "$build_script" \
    'pasturestack-compose version ${PASTURESTACK_COMPOSE_EXECUTOR_VERSION}' \
    SERVER_COMPOSE_EXECUTOR_CONTAINER_VERSION_GATE_MISSING
require_marker "$dockerfile" \
    'table.audit-log-results-table[data-resizable-columns=true]:not(.table-column-measuring) > thead > th.audit-log-auth-ip-heading' \
    SERVER_WEB_CONSOLE_AUDIT_AUTH_IP_HEADER_GATE_MISSING
require_marker "$dockerfile" \
    "grep -F '篩選稽核日誌'" \
    SERVER_WEB_CONSOLE_ZH_TW_FILTER_GATE_MISSING
require_marker "$dockerfile" \
    "grep -F '篩選服務日誌'" \
    SERVER_WEB_CONSOLE_ZH_TW_SERVICE_FILTER_GATE_MISSING
require_marker "$dockerfile" \
    "grep -F '開始時間必須早於結束時間'" \
    SERVER_WEB_CONSOLE_ZH_TW_RANGE_GATE_MISSING
require_marker "$dockerfile" \
    'for locale in de-de fa-ir fil-ph fr-fr hu-hu ja-jp ko-kr pt-br ru-ru uk-ua zh-hans zh-tw' \
    SERVER_WEB_CONSOLE_ALL_LOCALE_FILTER_GATE_MISSING
require_marker "$dockerfile" \
    '"auditLogsPage.filterBuilder.title":"Filter audit logs"' \
    SERVER_WEB_CONSOLE_ENGLISH_FILTER_REJECTION_MISSING
require_marker "$dockerfile" \
    '"auditLogsPage.filterBuilder.timeDialog.calendar.today":"Today"' \
    SERVER_WEB_CONSOLE_LOCALIZED_CALENDAR_GATE_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_WEB_CONSOLE_PACKAGE=${WEB_CONSOLE_RELEASE_TAG}' \
    SERVER_WEB_CONSOLE_RUNTIME_VERSION_MISSING
require_marker "$build_script" \
    'PASTURESTACK_WEB_CONSOLE_ARTIFACT_SHA256="${web_console_artifact_sha256}"' \
    SERVER_WEB_CONSOLE_RUNTIME_HASH_GATE_MISSING
require_marker "$build_script" \
    'test "$(cat "${web_root}/VERSION.txt")" = "${WEB_CONSOLE_RELEASE_TAG}"' \
    SERVER_WEB_CONSOLE_RUNTIME_VERSION_GATE_MISSING
require_marker "$release_dockerfile" \
    "grep -aF 'pod-empty-message text-center text-muted'" \
    SERVER_WEB_CONSOLE_EMPTY_MESSAGE_MARKUP_GATE_MISSING
require_marker "$release_dockerfile" \
    "grep -F -A 3 '.pods .pod-empty-message {'" \
    SERVER_WEB_CONSOLE_EMPTY_MESSAGE_CSS_GATE_MISSING
require_marker "$build_script" \
    'grep -aF "pod-empty-message text-center text-muted" "${ui_entry}"' \
    SERVER_WEB_CONSOLE_RUNTIME_EMPTY_MESSAGE_MARKUP_GATE_MISSING
require_marker "$build_script" \
    'grep -F -A 3 ".pods .pod-empty-message {"' \
    SERVER_WEB_CONSOLE_RUNTIME_EMPTY_MESSAGE_CSS_GATE_MISSING
require_marker "$build_script" \
    'grep -aF "dropdown-menu project-menu" "${ui_entry}"' \
    SERVER_WEB_CONSOLE_SWITCHER_MARKUP_GATE_MISSING
require_marker "$build_script" \
    '! grep -aF "dropdown-menu-end project-menu" "${ui_entry}"' \
    SERVER_WEB_CONSOLE_STALE_SWITCHER_ANCHOR_GATE_MISSING
require_marker "$build_script" \
    'max-width: calc(100vw - 68px);' \
    SERVER_WEB_CONSOLE_SWITCHER_VIEWPORT_GATE_MISSING
require_marker "$build_script" \
    'overflow-wrap: anywhere;' \
    SERVER_WEB_CONSOLE_SWITCHER_WRAP_GATE_MISSING
require_marker "$build_script" \
    'grep -Fx "  left: 0;"' \
    SERVER_WEB_CONSOLE_LTR_SWITCHER_ANCHOR_GATE_MISSING
require_marker "$build_script" \
    'grep -Fx "  right: 0;"' \
    SERVER_WEB_CONSOLE_RTL_SWITCHER_ANCHOR_GATE_MISSING
require_marker "$build_script" \
    'html[dir=rtl] .fail-whale .error {' \
    SERVER_WEB_CONSOLE_RTL_FAIL_DIRECTION_GATE_MISSING
require_marker "$build_script" \
    'test "$(/usr/bin/compose-executor.real --version)" =' \
    SERVER_COMPOSE_EXECUTOR_RUNTIME_VERSION_GATE_MISSING
require_marker "$build_script" \
    'grep -F "開始時間必須早於結束時間"' \
    SERVER_WEB_CONSOLE_RUNTIME_ZH_TW_RANGE_GATE_MISSING
require_marker "$build_script" \
    'for locale in de-de fa-ir fil-ph fr-fr hu-hu ja-jp ko-kr pt-br ru-ru uk-ua zh-hans zh-tw' \
    SERVER_WEB_CONSOLE_RUNTIME_ALL_LOCALE_FILTER_GATE_MISSING
require_marker "$build_script" \
    'auditLogsPage.filterBuilder.title\":\"Filter audit logs' \
    SERVER_WEB_CONSOLE_RUNTIME_ENGLISH_FILTER_REJECTION_MISSING
require_marker "$build_script" \
    'grep -aF "ui/utils/bootstrap-runtime" "${ui_entry}"' \
    SERVER_WEB_CONSOLE_RUNTIME_MODULE_GATE_MISSING
require_marker "$build_script" \
    'grep -aF "window.bootstrap=" "${ui_entry}"' \
    SERVER_WEB_CONSOLE_RUNTIME_GLOBAL_GATE_MISSING
if grep -F 'grep -aF "bs.collapse"' "$build_script" >/dev/null; then
    echo SERVER_WEB_CONSOLE_DORMANT_VENDOR_RUNTIME_GATE_PRESENT
    exit 1
fi
require_marker "$build_script" \
    'grep -F "pasturestack-catalog-pinned-commit"' \
    SERVER_CATALOG_PINNED_COMMIT_IMAGE_GATE_MISSING
require_marker "$release_dockerfile" \
    'ENV PASTURESTACK_CATALOG_COMMIT=b6b658888fce50d3ec217eb4eba0f26ab0113baf' \
    SERVER_CATALOG_VERSION_LABEL_COMMIT_MISSING
require_marker "$release_dockerfile" \
    '"pinnedCommit":"b6b658888fce50d3ec217eb4eba0f26ab0113baf"' \
    SERVER_CATALOG_VERSION_LABEL_URL_MISSING
require_marker "$build_script" \
    'PASTURESTACK_CATALOG_COMMIT=b6b658888fce50d3ec217eb4eba0f26ab0113baf' \
    SERVER_CATALOG_VERSION_LABEL_IMAGE_GATE_MISSING
for previous_release_marker in \
    '# Server v1.6.462' \
    '`5cba85d3ab954c416b86910f760f987ec2bfc526`' \
    '`a278904a10ce757510ed516507bd3926b02bab42a52a27bd153ff5e94e2998aa`' \
    '`222552c4b1fad095a5b55756cdca8e02b088ba04`' \
    '`74ac55939399873eeb9ab0813ca193e373ccf2bdde3e3d884d5491b4d0b7608e`' \
    '`082af08ce90d7cb9b043452c177c8f60a0c36d52f0797e24baaa37d7c1e087b4`' \
    '`5589ef8fda68ae56e1afd64096965d452ee8a17e`' \
    '`f14d22036a0a88d6a8d669700506bba680fc7605bbca2b337e345c5cd71500fb`' \
    '`feaabe4bba85cbe119c98a79a27abb4510401fc051f34d02aa7b48d69bdbe746`' \
    '`e082033ba3c12b5f5cfcae93ff1d6f50d5440d07`' \
    '## Atomic shared Default membership' \
    '## Zero-environment and account administration' \
    '## Permission-matrix boundary' \
    '## Immutable component coordinates' \
    '## Verification and SBOM identity' \
    '100-iteration deterministic lock barrier' \
    'exact sets' \
    'canonical OCI purl' \
    'display-only' \
    '`noaccess`' \
    '536 passing browser tests'; do
    require_marker "$previous_release_notes" "$previous_release_marker" \
        SERVER_PREVIOUS_RELEASE_NOTES_IDENTITY_MISSING
done
for v479_qa_marker in \
    '## Post-release isolated QA finding' \
    'Registry Add failed its UI check for the superadministrator, owner, member, and' \
    'schema cache used a lower-case ID' \
    'failed Registry flow caused no resource writes'; do
    require_marker docs/releases/server-1.6.479.md "$v479_qa_marker" \
        SERVER_V479_REGISTRY_QA_FAILURE_RECORD_MISSING
done
for historical_v480_marker in \
    '# Server v1.6.480' \
    'published signed Server source' \
    'browser and write matrix has not yet been accepted on `8080`'; do
    require_marker docs/releases/server-1.6.480.md "$historical_v480_marker" \
        SERVER_V480_PUBLICATION_RECORD_MISSING
done
for published_release_marker in \
    '# Server v1.6.482' \
    '`26090af4366a0843b09c1ff5c91373f7a1be816e`' \
    '`3f4c3228cb0b406f7d87b8e5e0896ebdc8b16345183e96bcf54cae92a5fc4c49`' \
    '`3d909952d31e8577793acb7e402e10b883e1c8a6`' \
    'ghcr.io/pasturestack/server@sha256:e3ac65290f17981201a6cf2857e0f6def3eb79974746bc7110357fd87869a609' \
    'injected `503` error and successful retry'; do
    require_marker "$published_release_notes" "$published_release_marker" \
        SERVER_V482_PUBLICATION_RECORD_MISSING
done
for current_release_marker in \
    '# Server v1.6.483' \
    '`v0.183.326` and the other component coordinates' \
    'Web Console `1.6.149`' \
    '`66160dfc1d9d134d1c9c85b4f2908c3f07f99365`' \
    '`6427120ef0047deb0c436a5cd9167a9afb3a2fb3075123b50340ec1216a5fe81`' \
    '`b3139aced7227eab97d6034a4d97440d5823265b`' \
    '`c8ff45db07d5db4599fbbaa6665f7bffe2977b09a907d493793f4becaa3c31d2`' \
    '`VERSION.txt=1.6.149`' \
    'only `description`' \
    'six-role permission' \
    'No production deployment'; do
    require_marker "$current_release_notes" "$current_release_marker" \
        SERVER_CURRENT_RELEASE_NOTES_IDENTITY_MISSING
done
for current_readme_marker in \
    '## Current release' \
    '## Quick start' \
    'Use the published numeric' \
    'keep all three named volumes' \
    '[performance settings](docs/performance/README.md)' \
    '## Upgrade and rollback' \
    'Back up the database and volumes, test a restore' \
    '[upgrade guide](docs/upgrades/README.md)' \
    'Do not replace existing volumes with new empty ones or run `docker compose down -v`.' \
    'rollback may require restoring matching data' \
    '[GitHub Releases](https://github.com/PastureStack/server/releases)' \
    '[release notes](docs/releases)'; do
    require_marker README.md "$current_readme_marker" \
        SERVER_CURRENT_README_IDENTITY_MISSING
done
for historical_v481_marker in \
    '# Server v1.6.481' \
    'This release assembles Web Console `1.6.146`' \
    'fields are Secret name, description, and value; Certificate name, description,' \
    '`9c6914cda01a48dda4fb38f62d1a3f0c4db10be8`'; do
    require_marker docs/releases/server-1.6.481.md "$historical_v481_marker" \
        SERVER_V481_PUBLICATION_RECORD_MISSING
done
require_marker COMPATIBILITY.md 'non-admin mutations owner-scoped.' \
    SERVER_CURRENT_COMPATIBILITY_CONTRACT_MISSING
require_marker docs/README.md \
    '[Server v1.6.483](releases/server-1.6.483.md)' \
    SERVER_CURRENT_DOC_INDEX_MISSING
require_marker docs/README.md \
    '[Server v1.6.482](releases/server-1.6.482.md)' \
    SERVER_V482_DOC_INDEX_MISSING
require_marker docs/README.md \
    '[Server v1.6.481](releases/server-1.6.481.md)' \
    SERVER_V481_DOC_INDEX_MISSING
require_marker docs/README.md \
    '[Server v1.6.480](releases/server-1.6.480.md)' \
    SERVER_V480_DOC_INDEX_MISSING
require_marker docs/hosts/README.md \
    'PastureStack Server `v1.6.483` recognizes' \
    SERVER_CURRENT_HOST_DOC_MISSING
# The performance install image is checked against the latest published tag above.
for current_compatibility_marker in \
    'Server `v1.6.483` packages Web Console `1.6.149`.' \
    'only `description` is submitted on save' \
    'resource formats are unchanged from `v1.6.482`' \
    'The published `v1.6.482` release changes only Web Console packaging to' \
    '`1.6.147`.' \
    'Service Edit sends just `name`, `description`, and `scale` instead' \
    'The published `v1.6.481` release consumes Orchestration Engine `v0.183.326`' \
    'Web Console package `1.6.146`' \
    'ghcr.io/pasturestack/server@sha256:013eb045ed669344a67b8ac85d2ce56193abb74f34628281dec503dced8ab415' \
    'the isolated `8080` browser and six-role write matrix remains pending' \
    'Engine `v0.183.321` excludes inactive or removed project-member rows' \
    'Engine `v0.183.320` checks project-member collection requests' \
    'Engine `v0.183.319` makes shared-Default reconciliation atomic.' \
    'single `adminProject` Default' \
    'effective per-project schema' \
    'local administrator recovery path' \
    'Webhook Automation Service `v0.10.3`' \
    'Web Console `1.6.139` reads project schema methods' \
    'Web Console `1.6.140` shows' \
    'its frozen `/v1` non-admin user schema omits the field' \
    'Orchestration Engine `v0.183.326` restores the read-only' \
    'Web Console `1.6.141` gives the same localized denial' \
    'Web Console `1.6.142` keeps server-issued Receiver URLs' \
    'Web Console `1.6.143` constructs a new private ProjectTemplate' \
    'Web Console `1.6.144` introduced create-capability checks' \
    'Web Console `1.6.145` resolves create' \
    'projectTemplate.isPublic' \
    'Web Console `1.6.135` requests the full active environment collection' \
    'Web Console `1.6.136` bounds the environment-switcher menu' \
    'Web Console `1.6.137` lets empty pod-list messages wrap' \
    'revalidates a stored environment selection' \
    '404 falls back to an available environment' \
    '401 and 5xx errors remain visible' \
    'cached records cannot keep a revoked environment' \
    'preserves the active environment and its loaded schema' \
    'a permitted direct URL still works' \
    'membership on each request' \
    'Web Console `1.6.133` applies the active project' \
    'shared-Default reconciliation atomic' \
    'valid empty state' \
    'Authentication Service `v0.4.42`' \
    'RSVP-based adapter' \
    'standard `Authorization: Bearer` value' \
    'schema creation' \
    'stable deduplicated order' \
    '`unrestricted` is represented with an empty allowlist' \
    'Legacy provider settings are imported only'; do
    require_marker COMPATIBILITY.md "$current_compatibility_marker" \
        SERVER_CURRENT_COMPATIBILITY_CONTRACT_MISSING
done
require_marker "$dockerfile" \
    'COPY --chmod=0755 patches/websocket-proxy-wrapper.sh /usr/bin/websocket-proxy' \
    SERVER_WEBSOCKET_PROXY_ROUTING_WRAPPER_INSTALL_MISSING
require_marker "$build_script" \
    'websocket_wrapper_sha256=$(sha256sum server/patches/websocket-proxy-wrapper.sh' \
    SERVER_WEBSOCKET_PROXY_ROUTING_WRAPPER_HASH_GATE_MISSING
require_marker "$dockerfile" \
    'ARG GO_BUILDER_IMAGE=golang:1.27.0-bookworm@sha256:ded31c68586d2e49e760acc2e65a884b23d032e9bbbed0ae0c55abd3fcaf4452' \
    SERVER_RUNTIME_GO_BUILDER_NOT_CURRENT
require_marker "$dockerfile" \
    'ENV PASTURESTACK_RUNTIME_GO_VERSION=1.27.0' \
    SERVER_RUNTIME_GO_VERSION_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_UBUNTU_SECURITY_REFRESH=2026-09-10' \
    SERVER_UBUNTU_SECURITY_REFRESH_MISSING
require_marker "$dockerfile" \
    'ARG UBUNTU_SECURITY_IMAGE=ubuntu:26.04@sha256:2260313b31c8c011cd2eebe728008efac1b3982be73eb71348ea2648d2c0e09b' \
    SERVER_UBUNTU_SECURITY_IMAGE_NOT_PINNED
require_marker "$dockerfile" \
    'ARG GLIBC_PACKAGE_VERSION=2.43-2ubuntu2.4' \
    SERVER_GLIBC_PACKAGE_VERSION_MISSING
require_marker "$dockerfile" \
    'ARG PERL_PACKAGE_VERSION=5.40.1-7ubuntu0.3' \
    SERVER_PERL_PACKAGE_VERSION_MISSING
require_marker "$dockerfile" \
    'COPY --from=ubuntu_security_packages /out/tar /usr/bin/tar' \
    SERVER_UBUNTU_SECURITY_BOOTSTRAP_TAR_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_GLIBC_CVE_2026_18374_FIX=not-in-execute-path' \
    SERVER_GLIBC_FIX_AUTHORITY_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_GLIBC_PACKAGE_VERSION=${GLIBC_PACKAGE_VERSION}' \
    SERVER_GLIBC_IMAGE_VERSION_ENV_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_PERL_PACKAGE_VERSION=${PERL_PACKAGE_VERSION}' \
    SERVER_PERL_IMAGE_VERSION_ENV_MISSING
for official_package_marker in \
    '"curl=${CURL_PACKAGE_VERSION}"' \
    '"libcurl3t64-gnutls=${CURL_PACKAGE_VERSION}"' \
    '"libcurl4t64=${CURL_PACKAGE_VERSION}"' \
    '"libc6=${GLIBC_PACKAGE_VERSION}"' \
    '"libc-bin=${GLIBC_PACKAGE_VERSION}"' \
    '"libc-gconv-modules-extra=${GLIBC_PACKAGE_VERSION}"' \
    '"libperl5.40=${PERL_PACKAGE_VERSION}"' \
    '"perl=${PERL_PACKAGE_VERSION}"' \
    '"perl-base=${PERL_PACKAGE_VERSION}"' \
    '"perl-modules-5.40=${PERL_PACKAGE_VERSION}"'; do
    require_marker "$dockerfile" "$official_package_marker" \
        SERVER_UBUNTU_OFFICIAL_SECURITY_PACKAGE_GATE_MISSING
done
for security_dockerfile in "$dockerfile"; do
    require_marker "$security_dockerfile" \
        'ARG UBUNTU_SNAPSHOT=20260910T100000Z' \
        SERVER_UBUNTU_SECURITY_SNAPSHOT_MISSING
    require_marker "$security_dockerfile" \
        'ARG CURL_PACKAGE_VERSION=8.18.0-1ubuntu2.5' \
        SERVER_UBUNTU_CURL_PACKAGE_VERSION_MISSING
    require_marker "$security_dockerfile" \
        'ARG GLIBC_PACKAGE_VERSION=2.43-2ubuntu2.4' \
        SERVER_UBUNTU_GLIBC_PACKAGE_VERSION_MISSING
    require_marker "$security_dockerfile" \
        'ARG PERL_PACKAGE_VERSION=5.40.1-7ubuntu0.3' \
        SERVER_UBUNTU_PERL_PACKAGE_VERSION_MISSING
    require_marker "$security_dockerfile" \
        'ENV PASTURESTACK_CURL_PACKAGE_VERSION=${CURL_PACKAGE_VERSION}' \
        SERVER_CURL_IMAGE_VERSION_ENV_MISSING
    require_marker "$security_dockerfile" \
        'ENV PASTURESTACK_GLIBC_CVE_2026_18374_FIX=not-in-execute-path' \
        SERVER_GLIBC_EXECUTION_PATH_AUTHORITY_MISSING
    require_marker "$security_dockerfile" \
        'dpkg -i packages/*.deb' \
        SERVER_UBUNTU_SECURITY_FINAL_INSTALL_MISSING
done
if grep -Eq 'ubuntu_security_packages|pasturestack-ubuntu-security|UBUNTU_SNAPSHOT' \
    "$release_dockerfile"; then
    echo 'SERVER_INCREMENTAL_RELEASE_REBUILDS_UNCHANGED_UBUNTU_PACKAGES' >&2
    exit 1
fi
for release_curl_security_marker in \
    'FROM ${UBUNTU_SECURITY_IMAGE} AS runtime_security_packages' \
    'ARG UBUNTU_RUNTIME_SECURITY_SNAPSHOT=20261002T000000Z' \
    'ARG CURL_PACKAGE_VERSION=8.18.0-1ubuntu2.7' \
    'ARG OPENSSL_PACKAGE_VERSION=3.5.5-1ubuntu3.7' \
    'Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg' \
    'Acquire::AllowInsecureRepositories "false"' \
    'APT::Get::AllowUnauthenticated "false"' \
    'COPY --from=runtime_security_packages /out/ /tmp/pasturestack-runtime-security/' \
    'sha256sum -c SHA256SUMS' \
    'dpkg -i packages/*.deb' \
    'test "$(dpkg-query -W -f=' \
    'ENV PASTURESTACK_CURL_SECURITY_SNAPSHOT=${UBUNTU_RUNTIME_SECURITY_SNAPSHOT}' \
    '"openssl=${OPENSSL_PACKAGE_VERSION}"' \
    '"libssl3t64=${OPENSSL_PACKAGE_VERSION}"' \
    '"openssl-provider-legacy=${OPENSSL_PACKAGE_VERSION}"' \
    'dpkg-deb --extract "${package_file}" /tmp/openssl-runtime' \
    'sha256sum packages/*.deb tar openssl-runtime.sha256 libdbi-perl-runtime.sha256 freetype-runtime.sha256 libpng-runtime.sha256 > SHA256SUMS' \
    'sha256sum -c /usr/share/pasturestack/security/openssl-runtime.sha256' \
    'ENV PASTURESTACK_OPENSSL_VERSION=3.5.5' \
    'ENV PASTURESTACK_OPENSSL_PACKAGE_VERSION=${OPENSSL_PACKAGE_VERSION}' \
    'ENV PASTURESTACK_OPENSSL_SECURITY_SNAPSHOT=${UBUNTU_RUNTIME_SECURITY_SNAPSHOT}'; do
    require_marker "$release_dockerfile" "$release_curl_security_marker" \
        SERVER_INCREMENTAL_CURL_SECURITY_REFRESH_MISSING
done
for release_libdbi_security_marker in \
    'ARG LIBDBI_PERL_PACKAGE_VERSION=1.647-1ubuntu0.26.04.3' \
    'apt-get download "libdbi-perl=${LIBDBI_PERL_PACKAGE_VERSION}"' \
    'dpkg-deb --extract "${package_file}" /tmp/libdbi-perl-runtime' \
    'usr/lib/x86_64-linux-gnu/perl5/5.40/DBI.pm' \
    'usr/lib/x86_64-linux-gnu/perl5/5.40/auto/DBI/DBI.so' \
    'test "$(wc -l < /out/libdbi-perl-runtime.sha256)" -eq 2' \
    'sha256sum -c /usr/share/pasturestack/security/libdbi-perl-runtime.sha256' \
    'ENV PASTURESTACK_LIBDBI_PERL_PACKAGE_VERSION=${LIBDBI_PERL_PACKAGE_VERSION}'; do
    require_marker "$release_dockerfile" "$release_libdbi_security_marker" \
        SERVER_LIBDBI_PERL_OFFICIAL_SECURITY_REFRESH_MISSING
done
for runtime_libdbi_security_marker in \
    'PASTURESTACK_LIBDBI_PERL_PACKAGE_VERSION=1.647-1ubuntu0.26.04.3' \
    'sha256sum -c /usr/share/pasturestack/security/libdbi-perl-runtime.sha256' \
    'test "$(wc -l < /usr/share/pasturestack/security/libdbi-perl-runtime.sha256)" -eq 2' \
    'Unexpected DBI runtime version'; do
    require_marker "$build_script" "$runtime_libdbi_security_marker" \
        SERVER_LIBDBI_PERL_RUNTIME_GATE_MISSING
done
for release_freetype_security_marker in \
    'ARG FREETYPE_PACKAGE_VERSION=2.14.2+dfsg-1ubuntu0.2' \
    'ADD --checksum=sha256:6d7d532b7d0c57639deb3b228f1f0d786cf5305d613ef7df9ba76c776a0f8373' \
    'https://security.ubuntu.com/ubuntu/pool/main/f/freetype/libfreetype6_2.14.2+dfsg-1ubuntu0.2_amd64.deb' \
    'test "$(dpkg-deb -f /tmp/libfreetype6.deb Package)" = libfreetype6' \
    'test "$(dpkg-deb -f /tmp/libfreetype6.deb Version)" = "${FREETYPE_PACKAGE_VERSION}"' \
    'test "$(dpkg-deb -f /tmp/libfreetype6.deb Architecture)" = amd64' \
    'libfreetype6)" = "${FREETYPE_PACKAGE_VERSION}"' \
    'dpkg-deb --extract /tmp/libfreetype6.deb /tmp/freetype-runtime' \
    'sha256sum usr/lib/x86_64-linux-gnu/libfreetype.so.6 > /out/freetype-runtime.sha256' \
    'test "$(wc -l < /out/freetype-runtime.sha256)" -eq 1' \
    'sha256sum -c /usr/share/pasturestack/security/freetype-runtime.sha256' \
    'test "$(readlink -f /usr/lib/x86_64-linux-gnu/libfreetype.so.6)" = /usr/lib/x86_64-linux-gnu/libfreetype.so.6.20.5' \
    'ldd -r /usr/lib/x86_64-linux-gnu/libfreetype.so.6 2>&1' \
    'ENV PASTURESTACK_FREETYPE_PACKAGE_VERSION=${FREETYPE_PACKAGE_VERSION}'; do
    require_marker "$release_dockerfile" "$release_freetype_security_marker" \
        SERVER_FREETYPE_OFFICIAL_SECURITY_REFRESH_MISSING
done
for runtime_freetype_security_marker in \
    'PASTURESTACK_FREETYPE_PACKAGE_VERSION=2.14.2+dfsg-1ubuntu0.2' \
    'libfreetype6)" = 2.14.2+dfsg-1ubuntu0.2' \
    'sha256sum -c /usr/share/pasturestack/security/freetype-runtime.sha256' \
    'test "$(wc -l < /usr/share/pasturestack/security/freetype-runtime.sha256)" -eq 1' \
    'test "$(readlink -f /usr/lib/x86_64-linux-gnu/libfreetype.so.6)" = /usr/lib/x86_64-linux-gnu/libfreetype.so.6.20.5' \
    '/usr/lib/x86_64-linux-gnu/libfreetype.so.6; do'; do
    require_marker "$build_script" "$runtime_freetype_security_marker" \
        SERVER_FREETYPE_RUNTIME_GATE_MISSING
done
for release_libpng_security_marker in \
    'ARG LIBPNG_PACKAGE_VERSION=1.6.57-1ubuntu0.1' \
    'ADD --checksum=sha256:f24a7f7c0428d74e33ea934696987b7336ec0962f212535185f0493792e7536e' \
    'https://security.ubuntu.com/ubuntu/pool/main/libp/libpng1.6/libpng16-16t64_1.6.57-1ubuntu0.1_amd64.deb' \
    'test "$(dpkg-deb -f /tmp/libpng16.deb Package)" = libpng16-16t64' \
    'test "$(dpkg-deb -f /tmp/libpng16.deb Version)" = "${LIBPNG_PACKAGE_VERSION}"' \
    'test "$(dpkg-deb -f /tmp/libpng16.deb Architecture)" = amd64' \
    'dpkg-deb --extract /tmp/libpng16.deb /tmp/libpng-runtime' \
    'sha256sum usr/lib/x86_64-linux-gnu/libpng16.so.16 > /out/libpng-runtime.sha256' \
    'sha256sum -c /usr/share/pasturestack/security/libpng-runtime.sha256' \
    'ldd -r /usr/lib/x86_64-linux-gnu/libpng16.so.16 2>&1' \
    'ENV PASTURESTACK_LIBPNG_PACKAGE_VERSION=${LIBPNG_PACKAGE_VERSION}'; do
    require_marker "$release_dockerfile" "$release_libpng_security_marker" \
        SERVER_LIBPNG_OFFICIAL_SECURITY_REFRESH_MISSING
done
for runtime_libpng_security_marker in \
    'PASTURESTACK_LIBPNG_PACKAGE_VERSION=1.6.57-1ubuntu0.1' \
    'libpng16-16t64)" = 1.6.57-1ubuntu0.1' \
    'test "$(wc -l < /usr/share/pasturestack/security/libpng-runtime.sha256)" -eq 1' \
    'sha256sum -c /usr/share/pasturestack/security/libpng-runtime.sha256' \
    'ldd -r /usr/lib/x86_64-linux-gnu/libpng16.so.16 2>&1'; do
    require_marker "$build_script" "$runtime_libpng_security_marker" \
        SERVER_LIBPNG_RUNTIME_GATE_MISSING
done
require_marker "$build_script" \
    'PASTURESTACK_CURL_SECURITY_SNAPSHOT=20261002T000000Z' \
    SERVER_CURL_IMAGE_SNAPSHOT_GATE_MISSING
require_marker "$build_script" \
    'PASTURESTACK_CURL_PACKAGE_VERSION=8.18.0-1ubuntu2.7' \
    SERVER_CURL_IMAGE_VERSION_GATE_MISSING
require_marker "$build_script" \
    'PASTURESTACK_GLIBC_PACKAGE_VERSION=2.43-2ubuntu2.4' \
    SERVER_GLIBC_IMAGE_VERSION_GATE_MISSING
require_marker "$build_script" \
    'PASTURESTACK_PERL_PACKAGE_VERSION=5.40.1-7ubuntu0.3' \
    SERVER_PERL_IMAGE_VERSION_GATE_MISSING
for runtime_reachability_marker in \
    '/usr/share/cattle/cattle.sh' \
    '/usr/share/cattle/cattle.jar' \
    '/service/mysql/run' \
    'pack_ip_mreq_source|Storable|SX_HOOK|,ccs=' \
    'A Server runtime entrypoint reaches a reviewed Perl or glibc fopen mode vulnerability'; do
    require_marker "$build_script" "$runtime_reachability_marker" \
        SERVER_RUNTIME_REACHABILITY_GATE_MISSING
done
require_marker "$release_notes" \
    'CVE-2026-8932' \
    SERVER_RELEASE_NOTES_CURL_FIX_MISSING
require_marker "$release_notes" \
    '2.43-2ubuntu2.4' \
    SERVER_RELEASE_NOTES_GLIBC_FIX_MISSING
require_marker "$release_notes" \
    'needing evaluation for Resolute' \
    SERVER_RELEASE_NOTES_GLIBC_APPLICABILITY_BOUNDARY_MISSING
require_marker "$dockerfile" \
    'coreutils-from-gnu coreutils-from-uutils- rust-coreutils-' \
    SERVER_GNU_COREUTILS_SWITCH_MISSING
require_marker "$dockerfile" \
    '! dpkg-query -W rust-coreutils' \
    SERVER_RUST_COREUTILS_ABSENCE_GATE_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_COREUTILS_PROVIDER=gnu' \
    SERVER_COREUTILS_PROVIDER_IDENTITY_MISSING
require_marker "$dockerfile" \
    'ARG COREUTILS_SHA256=2033b8a3049c06bff49a9e3cea72bdf4683bcd0cbeb975211dd56dbaf8b736ae' \
    SERVER_COREUTILS_SOURCE_HASH_MISSING
require_marker "$dockerfile" \
    'https://ftp.gnu.org/gnu/coreutils/coreutils-${COREUTILS_VERSION}.tar.gz' \
    SERVER_COREUTILS_PRIMARY_SOURCE_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_COREUTILS_UNIQ_VERSION=9.11' \
    SERVER_COREUTILS_UNIQ_VERSION_MISSING
require_marker "$dockerfile" \
    'ARG COREUTILS_UNIQ_FIX_COMMIT=d64e35a8a4c0e4608321433e0d84d917e4e36371' \
    SERVER_COREUTILS_UNIQ_FIX_COMMIT_MISSING
require_marker "$dockerfile" \
    'ARG COREUTILS_UNIQ_PATCH_SHA256=7c0a1b74325caf05fe0021b26dcde6b19560ea04388f18386cacc4e8bb436efd' \
    SERVER_COREUTILS_UNIQ_FIX_HASH_MISSING
require_marker "$dockerfile" \
    'git apply --check --no-index /src/coreutils-CVE-2026-56391.patch' \
    SERVER_COREUTILS_UNIQ_FIX_APPLICATION_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_COREUTILS_UNIQ_FIX=d64e35a8a4c0e4608321433e0d84d917e4e36371' \
    SERVER_COREUTILS_UNIQ_FIX_IDENTITY_MISSING
test "$(sha256sum "$coreutils_patch" | awk '{print $1}')" = \
    7c0a1b74325caf05fe0021b26dcde6b19560ea04388f18386cacc4e8bb436efd
require_marker "$coreutils_patch" \
    'Upstream-Commit: d64e35a8a4c0e4608321433e0d84d917e4e36371' \
    SERVER_COREUTILS_UNIQ_PATCH_PROVENANCE_MISSING
require_marker "$release_notes" \
    'd64e35a8a4c0e4608321433e0d84d917e4e36371' \
    SERVER_RELEASE_NOTES_UNIQ_FIX_MISSING
require_marker "$release_notes" \
    'unmatched vulnerability at any severity remains a release blocker.' \
    SERVER_RELEASE_NOTES_VEX_BOUNDARY_MISSING
require_marker "$release_notes" \
    'CVE-2026-75803' \
    SERVER_RELEASE_NOTES_OPENSSL_FIX_MISSING
require_marker "$release_notes" \
    'CVE-2026-53910' \
    SERVER_RELEASE_NOTES_DIFF3_CLOSURE_MISSING
require_marker "$dockerfile" \
    'ARG NODE_AGENT_VERSION=0.13.27' \
    SERVER_HARDWARE_AGENT_VERSION_MISSING
require_marker "$dockerfile" \
    'ARG NODE_AGENT_LINUX_ARTIFACT_SHA256=0cbf93ef6f90db8c5f6b8cf7d63c99f452b8fc43e93097a21cdb5bcc3007d475' \
    SERVER_HARDWARE_AGENT_LINUX_HASH_MISSING
require_marker "$dockerfile" \
    'ARG NODE_AGENT_WINDOWS_ARTIFACT_SHA256=b6a56f8833c31bc224b7baf20ceb1a252c027021efbe6265c1906f8478d7c2fa' \
    SERVER_HARDWARE_AGENT_WINDOWS_HASH_MISSING
require_marker "$dockerfile" \
    'export CATTLE_AGENT_PACKAGE_PYTHON_AGENT_URL=/usr/share/cattle/artifacts/${agent_linux}' \
    SERVER_HARDWARE_AGENT_EFFECTIVE_URL_MISSING
require_marker server/build-api-explorer-patch-image.sh \
    'test "$CATTLE_AGENT_PACKAGE_PYTHON_AGENT_URL" = "/usr/share/cattle/artifacts/node-agent-${NODE_AGENT_VERSION}.tar.gz"' \
    SERVER_HARDWARE_AGENT_EFFECTIVE_URL_NOT_VERIFIED
require_marker "$dockerfile" \
    'ARG ZLIB_SHA256=bb329a0a2cd0274d05519d61c667c062e06990d72e125ee2dfa8de64f0119d16' \
    SERVER_ZLIB_SOURCE_HASH_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_ZLIB_VERSION=1.3.2' \
    SERVER_ZLIB_VERSION_MISSING
require_marker "$dockerfile" \
    'ARG OPENSSL_VERSION=3.5.8' \
    SERVER_OPENSSL_SOURCE_VERSION_MISSING
require_marker "$dockerfile" \
    'ARG OPENSSL_SHA256=a8f84a39918ec6415ce765d9b429d313ba97b8143169c172e734b9514464f5b2' \
    SERVER_OPENSSL_SOURCE_HASH_MISSING
require_marker "$dockerfile" \
    'make test TESTS=test_evp_extra' \
    SERVER_OPENSSL_TARGETED_TEST_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_OPENSSL_VERSION=3.5.8' \
    SERVER_OPENSSL_RUNTIME_IDENTITY_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_DIFF3_HARDENING=removed' \
    SERVER_DIFF3_REMOVAL_IDENTITY_MISSING
require_marker "$build_script" \
    'openssl version | grep -E "^OpenSSL 3\\.5\\.5 .*\\(Library: OpenSSL 3\\.5\\.5 "' \
    SERVER_OPENSSL_IMAGE_VERSION_GATE_MISSING
for openssl_image_marker in \
    'PASTURESTACK_OPENSSL_PACKAGE_VERSION=3.5.5-1ubuntu3.7' \
    'PASTURESTACK_OPENSSL_SECURITY_SNAPSHOT=20261002T000000Z' \
    'sha256sum -c /usr/share/pasturestack/security/openssl-runtime.sha256' \
    'test "$(wc -l < /usr/share/pasturestack/security/openssl-runtime.sha256)" -eq 7' \
    'ldd -r "$target"' \
    'openssl dgst -provider default -provider legacy -md4'; do
    require_marker "$build_script" "$openssl_image_marker" \
        SERVER_OPENSSL_OFFICIAL_PACKAGE_GATE_MISSING
done
test -f scripts/test-server-openssl-tls.sh
bash -n scripts/test-server-openssl-tls.sh
require_marker "$build_script" '< scripts/test-server-openssl-tls.sh' \
    SERVER_OPENSSL_TLS_COMPATIBILITY_GATE_MISSING
require_marker "$build_script" 'docker run --rm -i --network none --entrypoint bash "$image" -s' \
    SERVER_OPENSSL_TLS_STDIN_GATE_MISSING
require_marker "$build_script" \
    'test "$(openssl version -d)" = "OPENSSLDIR: \"/usr/lib/ssl\""' \
    SERVER_OPENSSL_IMAGE_OPENSSLDIR_GATE_MISSING
require_marker "$build_script" \
    'test "$(openssl version -e)" = "ENGINESDIR: \"/usr/lib/x86_64-linux-gnu/engines-3\""' \
    SERVER_OPENSSL_IMAGE_ENGINESDIR_GATE_MISSING
require_marker "$build_script" \
    'test "$(openssl version -m)" = "MODULESDIR: \"/usr/lib/x86_64-linux-gnu/ossl-modules\""' \
    SERVER_OPENSSL_IMAGE_MODULESDIR_GATE_MISSING
require_marker "$build_script" \
    'ldd /usr/bin/curl | grep -F "/usr/lib/x86_64-linux-gnu/libssl.so.3"' \
    SERVER_OPENSSL_CURL_LINKAGE_GATE_MISSING
require_marker "$dockerfile" \
    'version_at_least openssl 3.5.5-1ubuntu3.4' \
    SERVER_OPENSSL_FIXED_VERSION_GATE_MISSING
for fixed_package_gate in \
    'version_at_least gnu-coreutils 9.7-3ubuntu2.1' \
    'version_at_least bsdutils 1:2.41.3-3ubuntu2.2' \
    'version_at_least libblkid1 2.41.3-3ubuntu2.2' \
    'version_at_least libmount1 2.41.3-3ubuntu2.2' \
    'version_at_least libsmartcols1 2.41.3-3ubuntu2.2' \
    'version_at_least libuuid1 2.41.3-3ubuntu2.2' \
    'version_at_least login 1:4.16.0-2+really2.41.3-3ubuntu2.2' \
    'version_at_least mount 2.41.3-3ubuntu2.2' \
    'version_at_least util-linux 2.41.3-3ubuntu2.2'; do
    require_marker "$dockerfile" "$fixed_package_gate" \
        SERVER_UBUNTU_FIXED_VERSION_GATE_MISSING
    require_marker "$build_script" "$fixed_package_gate" \
        SERVER_UBUNTU_RUNTIME_VERSION_GATE_MISSING
done
require_marker "$dockerfile" \
    'ENV PASTURESTACK_SSH_CLIENT_HARDENING=client-removed' \
    SERVER_SSH_CLIENT_REMOVAL_IDENTITY_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_PRIVILEGED_MOUNT_HELPERS=removed' \
    SERVER_MOUNT_HELPER_REMOVAL_IDENTITY_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_CONTAINER_SOURCE_BUILD_MODE=removed' \
    SERVER_SOURCE_BUILD_MODE_REMOVAL_IDENTITY_MISSING
for removed_path in \
    /usr/bin/eu-readelf \
    /usr/bin/eu-strip \
    /usr/bin/diff3 \
    /usr/bin/getfattr \
    /usr/bin/gpgv \
    /usr/bin/p11-kit \
    /usr/bin/setfattr \
    /usr/bin/unexpand \
    /usr/lib/git-core/git-http-push \
    /usr/lib/x86_64-linux-gnu/libexpat.so.1 \
    /usr/lib/x86_64-linux-gnu/libexpat.so.1.11.2 \
    /usr/libexec/p11-kit/p11-kit-server \
    /etc/login.defs \
    /etc/subgid \
    /etc/subuid; do
    require_marker "$dockerfile" "$removed_path" \
        SERVER_RUNTIME_VULNERABLE_PATH_REMOVAL_MISSING
    require_marker "$build_script" "$removed_path" \
        SERVER_RUNTIME_VULNERABLE_PATH_VALIDATION_MISSING
done
require_marker "$build_script" \
    'find /usr/bin /usr/sbin /usr/share/cattle -xdev -type f -perm /0111 -print0' \
    SERVER_RUNTIME_LIBGCRYPT_EXECUTABLE_AUDIT_MISSING
require_marker "$build_script" \
    'find /run -xdev -type s -path "*p11-kit*"' \
    SERVER_RUNTIME_P11_KIT_SOCKET_AUDIT_MISSING
require_marker "$dockerfile" \
    '/usr/lib/systemd/systemd-journald' \
    SERVER_JOURNALD_REMOVAL_GATE_MISSING
require_marker "$dockerfile" \
    '/usr/share/cattle/install_cattle_binaries' \
    SERVER_RUNTIME_INSTALLER_REMOVAL_GATE_MISSING
require_marker "$cattle_script" \
    'CATTLE_MASTER source-build mode has been removed' \
    SERVER_SOURCE_BUILD_MODE_REJECTION_MISSING
require_marker "$dockerfile" \
    "git --version | grep -Fx 'git version 2.53.0'" \
    SERVER_CATALOG_GIT_RUNTIME_GATE_MISSING
require_marker "$build_script" \
    'test "$(git --version)" = "git version 2.53.0"' \
    SERVER_CATALOG_GIT_IMAGE_VALIDATION_MISSING
require_marker "$dockerfile" \
    "! ldconfig -p | grep -F 'libexpat.so'" \
    SERVER_RUNTIME_EXPAT_LINKER_GATE_MISSING
require_marker "$build_script" \
    '! ldconfig -p | grep -Fq "libexpat.so"' \
    SERVER_RUNTIME_EXPAT_IMAGE_VALIDATION_MISSING
if grep -Eq '(^|[[:space:]])(git clone|git -C|apt-get install|tar xzf)([[:space:]]|$)' "$cattle_script"; then
    echo 'SERVER_SOURCE_BUILD_TOOLING_REMAINS' >&2
    exit 1
fi
while IFS='|' read -r marker code; do
    require_marker "$dockerfile" "$marker" "$code"
done <<'EOF'
ARG AUTHENTICATION_SERVICE_VERSION=0.4.42|SERVER_AUTHENTICATION_SERVICE_VERSION_MISSING
ARG AUTHENTICATION_SERVICE_BINARY_SHA256=feaabe4bba85cbe119c98a79a27abb4510401fc051f34d02aa7b48d69bdbe746|SERVER_AUTHENTICATION_SERVICE_HASH_MISSING
ARG CATALOG_SERVICE_VERSION=0.20.11|SERVER_CATALOG_SERVICE_VERSION_MISSING
ARG CATALOG_SERVICE_BINARY_SHA256=ccfc75831678df31f58b327b3177da6f40d31603ab329af7bdf700a8513ea329|SERVER_CATALOG_SERVICE_HASH_MISSING
ARG COMPOSE_EXECUTOR_VERSION=0.14.36|SERVER_COMPOSE_EXECUTOR_VERSION_MISSING
ARG COMPOSE_EXECUTOR_BINARY_SHA256=1f542ee2dd76c7af06bc5f056c381d7e77aecaeac40f8d897df6df24a9902c0d|SERVER_COMPOSE_EXECUTOR_HASH_MISSING
ARG HOST_PROVISIONER_VERSION=0.39.7|SERVER_HOST_PROVISIONER_VERSION_MISSING
ARG HOST_PROVISIONER_BINARY_SHA256=bce26b98133d3f5d4ecaddba26179ed8e14e5b260b38dee5f9e4383cbfbc855a|SERVER_HOST_PROVISIONER_HASH_MISSING
ARG SECRET_DELIVERY_API_VERSION=0.3.1|SERVER_SECRET_DELIVERY_API_VERSION_MISSING
ARG SECRET_DELIVERY_API_BINARY_SHA256=fbdd12862e1cfe3c957f492ae81c4c1c5658357502bd322febbbe209496929be|SERVER_SECRET_DELIVERY_API_HASH_MISSING
ARG USAGE_TELEMETRY_AGENT_VERSION=0.4.1|SERVER_USAGE_TELEMETRY_AGENT_VERSION_MISSING
ARG USAGE_TELEMETRY_AGENT_BINARY_SHA256=f18ed969b8b5959293fdbcd55d2e28846372ab87c9348fbb315a9a490bf85ad4|SERVER_USAGE_TELEMETRY_AGENT_HASH_MISSING
ARG WEBHOOK_AUTOMATION_SERVICE_VERSION=0.10.1|SERVER_WEBHOOK_AUTOMATION_SERVICE_VERSION_MISSING
ARG WEBHOOK_AUTOMATION_SERVICE_BINARY_SHA256=07e807c3f66e7e75e7a45073eabbd041a74b5727e315aee96f00e5b6a801ccc5|SERVER_WEBHOOK_AUTOMATION_SERVICE_HASH_MISSING
ARG WEBSOCKET_PROXY_VERSION=0.23.14|SERVER_WEBSOCKET_PROXY_VERSION_MISSING
ARG WEBSOCKET_PROXY_COMMIT=3b5788bdc52f4edab0097a3d97afccf138c64089|SERVER_WEBSOCKET_PROXY_COMMIT_MISSING
ARG WEBSOCKET_PROXY_ARCHIVE_SHA256=c55108c3dbfd8e6579fc768a1988920db83c6f605ca1284b60edf92ae8d0160e|SERVER_WEBSOCKET_PROXY_ARCHIVE_HASH_MISSING
ARG WEBSOCKET_PROXY_BINARY_SHA256=efd0c78779a620b4b0f74a10eb3f3edd8886e8d23f22dc4624d8e9971085a26d|SERVER_WEBSOCKET_PROXY_HASH_MISSING
ARG VSPHERE_CLI_BUNDLE_VERSION=0.55.2|SERVER_VSPHERE_CLI_BUNDLE_VERSION_MISSING
ARG VSPHERE_CLI_BUNDLE_COMMIT=c4b27e87aa0dacce432a2c6108ee0752319e6d5b|SERVER_VSPHERE_CLI_BUNDLE_COMMIT_MISSING
ARG VSPHERE_CLI_BUNDLE_ARCHIVE_SHA256=bebcc1c0275072ac40b5bc9b80f914c40a7f0431fffebc2c06fe34a34c33a57c|SERVER_VSPHERE_CLI_BUNDLE_ARCHIVE_HASH_MISSING
ARG GOVC_BINARY_SHA256=f8c7d82a614655c83ee119e3f170a302a9b35d9ca7efd13bbc226df2d68e5d31|SERVER_GOVC_HASH_MISSING
EOF
require_marker "$dockerfile" \
    'tar --no-same-owner --no-same-permissions -xzf' \
    SERVER_API_EXPLORER_PATCH_SAFE_EXTRACTION_MISSING
require_marker "$dockerfile" \
    'test ! -e "${stage}/js/bootstrap.js"' \
    SERVER_API_EXPLORER_PATCH_BOOTSTRAP_JS_REJECTION_MISSING
require_marker "$dockerfile" \
    'pasturestack:modal:shown' \
    SERVER_API_EXPLORER_PATCH_MODAL_GATE_MISSING
require_marker "$dockerfile" \
    'data-pasturestack-toggle' \
    SERVER_API_EXPLORER_PATCH_DROPDOWN_GATE_MISSING
require_marker "$dockerfile" \
    'licenses/inherited-vendor/LICENSE-async-0.9.0' \
    SERVER_API_EXPLORER_PATCH_LEGAL_GATE_MISSING
require_marker "$build_script" \
    'runtime_go=1.27.2' \
    SERVER_RUNTIME_GO_GATE_MISSING
require_marker "$build_script" \
    'orchestration_updated=1' \
    SERVER_ORCHESTRATION_UPDATE_GATE_MISSING
require_marker "$build_script" \
    'wrappers_pinned=1' \
    SERVER_WRAPPER_REGRESSION_GATE_MISSING
require_marker "$build_script" \
    'launcher_wrapper_sha256=57b6422dc4a51d4c5448306a4efad182517ed1622bba1257df3c270c5c23ee47' \
    SERVER_WRAPPER_HASH_GATE_MISSING
require_marker "$build_script" \
    'audit_log_filters=1' \
    SERVER_API_EXPLORER_PATCH_WEB_CONSOLE_REGRESSION_GATE_MISSING

require_marker "$dockerfile" \
    'org.opencontainers.image.base.digest="sha256:98ace6dd822f883f2f161f8e7c3191d45cc1f1aef6d2cb6de281cfb1d93237e5"' \
    SERVER_API_EXPLORER_PATCH_BASE_DIGEST_MISSING
require_marker "$build_script" \
    'ghcr.io/pasturestack/server:v1.6.460@sha256:c855af8aea232dacc5bb6df68e2271d482c68b53c43ab0c108ec19118f5ab403' \
    SERVER_API_EXPLORER_PATCH_BUILD_BASE_DIGEST_MISSING

if grep -RInE '(^|[^[:alnum:]])[A-Za-z]:\\Users\\|/home/[^/[:space:]]+/|(^|[^[:digit:]])10[.][[:digit:]]{1,3}[.][[:digit:]]{1,3}[.][[:digit:]]{1,3}([^[:digit:]]|$)|[[:alnum:]._%+-]+@[[:alnum:].-]+[.][[:alpha:]]{2,}' \
    "$dockerfile" "$build_script"; then
    echo 'SERVER_API_EXPLORER_PATCH_PRIVATE_MARKER' >&2
    exit 1
fi

bash -n "$build_script"
bash -n "$vendor_pending_validator"
python3 - "$mfa_policy_smoke" <<'PY'
import ast
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
PY

for oidc_policy_smoke_marker in \
    "policy_purpose = 'oidcAccessPolicyUpdate'" \
    "'operation': 'consumeSecurityConfirmation'" \
    "'bound-policy-confirmation-consumed'" \
    "'bound-policy-confirmation-replay-rejected'" \
    "'oidc-source-change-stable-recovery-error'" \
    "recovery_required['code'] == 'LocalRecoveryRequired'" \
    "'oidc-invalid-principal-stable-error'" \
    "invalid_identity['code'] == 'InvalidAllowedIdentity'"; do
    require_marker "$mfa_policy_smoke" "$oidc_policy_smoke_marker" \
        SERVER_OIDC_POLICY_API_SMOKE_MISSING
done

jq -e '
  .["@context"] == "https://openvex.dev/ns/v0.2.0"
  and .["@id"] == "https://github.com/PastureStack/server/security/openvex/v1.6.519"
  and (.statements | length) == 51
  and ([.statements[].vulnerability.name] | length == (unique | length))
  and ([.statements[] | select(.status == "fixed") | .vulnerability.name] | sort)
      == ["CVE-2024-52005","CVE-2026-12087","CVE-2026-13221","CVE-2026-18798","CVE-2026-27171","CVE-2026-56391","CVE-2026-57432","CVE-2026-57433","CVE-2026-75803","CVE-2026-8932"]
  and ([.statements[] | select(.status == "not_affected") | .vulnerability.name] | sort)
      == ["CVE-2024-2236","CVE-2024-56433","CVE-2025-1352","CVE-2025-1376","CVE-2025-66382","CVE-2026-13757","CVE-2026-18374","CVE-2026-18477","CVE-2026-18508","CVE-2026-27456","CVE-2026-3184","CVE-2026-32776","CVE-2026-32777","CVE-2026-32778","CVE-2026-40228","CVE-2026-41080","CVE-2026-45186","CVE-2026-50219","CVE-2026-53910","CVE-2026-54371","CVE-2026-56131","CVE-2026-56132","CVE-2026-56392","CVE-2026-56403","CVE-2026-56404","CVE-2026-56405","CVE-2026-56406","CVE-2026-56407","CVE-2026-56408","CVE-2026-56409","CVE-2026-56410","CVE-2026-56411","CVE-2026-56412","CVE-2026-56855","CVE-2026-57062","CVE-2026-66046","CVE-2026-72522","CVE-2026-76641","CVE-2026-76957","CVE-2026-78662","GO-2026-5932"]
  and ([.statements[] | select(.status == "under_investigation") | .vulnerability.name] | sort)
      == []
  and all(.statements[]; (.products | length) > 0)
  and all(.statements[].products[]; (.["@id"] | startswith("pkg:") and (contains("*") | not)))
  and all(.statements[] | select(.status == "not_affected");
          (.justification | type) == "string" and (.impact_statement | length) > 20)
' "$runtime_vex" >/dev/null

vendor_pending_fixture=$(mktemp)
trap 'rm -f "$vendor_pending_fixture"' EXIT
jq -r '
  . as $root
  | .findings[] as $finding
  | $finding.packages[]
  | [$finding.severity, $finding.vulnerabilityId, .name, .installedVersion,
     "", $root.policy.trivyTarget]
  | @tsv
' "$runtime_vendor_pending" | LC_ALL=C sort -u >"$vendor_pending_fixture"
bash "$vendor_pending_validator" "$runtime_vendor_pending" \
    "$vendor_pending_fixture" v1.6.519 >/dev/null
bash scripts/test-vendor-pending-findings.sh >/dev/null
rm -f "$vendor_pending_fixture"
trap - EXIT

for marker in \
    'release_tag:' \
    '.features["containerd-snapshotter"] = true' \
    "grep -F 'io.containerd.snapshotter.v1'" \
    'PASTURESTACK_BUILD_NO_CACHE=1 IMAGE="$LAYERED_CANDIDATE_IMAGE"' \
    'SERVER_LAYERED_BUILD_OK base_layers=%s source_layers=%s maximum=32 base=v1.6.460' \
    'python3 source/scripts/flatten-server-image.py' \
    'SERVER_IMAGE_FLATTEN_OK' \
    'SERVER_REGISTRY_LAYER_OK release=%s layers=1' \
    'PROXY_PLATFORM_PUBLIC_ORIGIN=https://stack.example.test' \
    'https://stack.example.test/v2-beta/schemas' \
    'assert_public_proxy_contract before-restart' \
    'first_contract_attempts="$public_proxy_contract_attempts"' \
    'assert_public_proxy_contract after-restart' \
    'restart_contract_attempts="$public_proxy_contract_attempts"' \
    'for private_api_attempt in $(seq 1 60); do' \
    '"$response_code" =~ ^(200|401|403)$' \
    'Private API contract did not converge during ${phase}' \
    'attempts=%s' \
    'reverse-proxy-before-restart.txt' \
    'reverse-proxy-after-restart.txt' \
    'docker restart "$CANDIDATE_NAME"' \
    'python3 source/scripts/test-mfa-policy-api.py' \
    'mfa-policy-api-smoke.txt' \
    'ghcr.io/aquasecurity/trivy:0.74.0@sha256:62b1e65e8869bc4b4c6aa4fa2b21595256c7c2f6018a9d9ad61caf87187c1969' \
    'server.openvex.json' \
    'server.vendor-pending.json' \
    'validate-vendor-pending-findings.sh' \
    'server-security-scan-raw.json' \
    '--vex /evidence/server.openvex.json' \
    'server-vulnerabilities-raw.tsv' \
    'server-vulnerabilities-unresolved.tsv' \
    'vendor-pending-summary.txt' \
    'SERVER_SECURITY_GATE_OK untracked=0 vendor_pending=%s critical_high=0 fixed_available=0 secrets=0' \
    'server-secrets.tsv' \
    'server.cdx.json' \
    'image_purl="pkg:oci/server@sha256%3A${digest_sha256}?repository_url=ghcr.io%2Fpasturestack%2Fserver&tag=${RELEASE_TAG}"' \
    '.metadata.component.type == "container"' \
    '.metadata.component.name == "ghcr.io/pasturestack/server"' \
    '.metadata.component.version == $release' \
    '.metadata.component.purl == $purl' \
    '.metadata.component["bom-ref"] == $purl' \
    '(.metadata.component.hashes | length) == 1' \
    '.metadata.component.hashes[0].alg == "SHA-256"' \
    '.metadata.component.hashes[0].content == $digest' \
    '([.dependencies[]? | select(.ref == $purl)] | length) == 1' \
    'sbom-identity.txt' \
    'SERVER_SBOM_IDENTITY_OK release=%s image=%s digest=%s purl=%s' \
    'test -s "$release_notes"' \
    'actions/attest@1e69f48acb82d1966a394da916b4c1698aa569d6 # v4.2.2' \
    'gh release create "$RELEASE_TAG"'; do
    require_marker "$publish_workflow" "$marker" \
        SERVER_CURRENT_PUBLISH_WORKFLOW_GATE_MISSING
done

if grep -Fq '="$(assert_public_proxy_contract' "$publish_workflow"; then
    printf '%s file=%s\n' SERVER_CURRENT_PUBLISH_WORKFLOW_PROXY_CONTRACT_COMMAND_SUBSTITUTION "$publish_workflow" >&2
    exit 1
fi

release_upload_block=$(sed -n '/gh release create "\$RELEASE_TAG"/,/^$/p' "$publish_workflow")
if grep -Fq '"$evidence/server-secrets.tsv"' <<<"$release_upload_block"; then
    printf '%s file=%s\n' SERVER_CURRENT_PUBLISH_WORKFLOW_EMPTY_SECRET_ASSET_UPLOAD "$publish_workflow" >&2
    exit 1
fi

release_checksum_block=$(sed -n '/^[[:space:]]*sha256sum \\/,/^[[:space:]]*>SHA256SUMS/p' "$publish_workflow")
if grep -Fq 'server-secrets.tsv' <<<"$release_checksum_block"; then
    printf '%s file=%s\n' SERVER_CURRENT_PUBLISH_WORKFLOW_EMPTY_SECRET_CHECKSUM_ENTRY "$publish_workflow" >&2
    exit 1
fi
for release_readback_contract in \
    'release-assets-expected.tsv' \
    'release-assets-published.tsv' \
    '.assets[] | [.name, .digest] | @tsv' \
    'diff -u'; do
    if ! grep -Fq "$release_readback_contract" "$publish_workflow"; then
        printf '%s token=%s file=%s\n' \
            SERVER_CURRENT_PUBLISH_WORKFLOW_RELEASE_READBACK_MISSING \
            "$release_readback_contract" "$publish_workflow" >&2
        exit 1
    fi
done

printf 'SERVER_API_EXPLORER_PATCH_OK release=v1.6.519 base=v1.6.460 engine=0.183.334 web_console=1.6.181 catalog_service=0.20.13 webhook_automation_service=0.10.4 authentication_service=0.4.43 curl=8.18.0-1ubuntu2.7 freemarker=2.3.35 artifact_scan=required vendor_pending=exact-set role_matrix=qa-required locale_layout=qa-required\n'
