#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ) ; readonly dir
cd "${dir}/.."

# Stage 1 sync - intermediate to the ./vendir folder
set -x
vendir sync
helm dependency update helm/csi-driver-nfs/
{ set +x; } 2>/dev/null

# Patches
./sync/patches/values/patch.sh
./sync/patches/chart/patch.sh
./sync/patches/helpers/patch.sh
./sync/patches/csi-nfs-node/patch.sh
