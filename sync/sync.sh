#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ) ; readonly SCRIPT_DIR
cd "${SCRIPT_DIR}/.."
source "${SCRIPT_DIR}"/_helpers.sh

# Test if required tooling is installed.
PROGRAMS=("yq" "jq" "vendir")
for program in "${PROGRAMS[@]}"; do
    if ! command -v "${program}" &> /dev/null; then
        echo "${program} not installed; aborting."
        exit 1
    fi
done

# Stage 1 sync - intermediate to the ./vendir folder
set -x
vendir sync
helm dependency update helm/csi-driver-nfs/
{ set +x; } 2>/dev/null

# Patches
./sync/patches/values/patch.sh
./sync/patches/chart/patch.sh
./sync/patches/helpers/patch.sh
./sync/patches/crd-csi-snapshot/patch.sh
./sync/patches/chart-label/patch.sh
