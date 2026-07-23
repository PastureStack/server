#!/bin/bash
set -Eeuo pipefail

cat >&2 <<'EOF'
PastureStack does not publish or build Windows agent images.

The original build path depended on an EOL Nano Server 2016 base image and
historical upstream Windows helper artifacts. That path is intentionally disabled so
source-public scans do not mistake it for a maintained image.

Linux hosts are maintained through PastureStack node-agent and system-service
images. Windows agent support requires a separate Windows Server test matrix,
modern Windows base image selection, signed driver/tool artifact ownership, and
legacy protocol validation before it can be reintroduced.
EOF

exit 1
