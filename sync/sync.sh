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
./sync/patches/csi-nfs-node/patch.sh

# Store diffs
rm -f ./diffs/*
for f in $(git --no-pager diff --no-exit-code --no-color --no-index vendor/csi-driver-nfs/charts/latest helm --name-only) ; do
        [[ "$f" == "helm/csi-driver-nfs/Chart.yaml" ]] && continue
        [[ "$f" == "helm/csi-driver-nfs/values.yaml" ]] && continue
        [[ "$f" =~ ^helm/csi-driver-nfs/charts/.* ]] && continue
        set +e
        set -x
        git --no-pager diff --no-exit-code --no-color --no-index "vendor/csi-driver-nfs/charts/latest/${f#"helm/"}" "${f}" \
                > "./diffs/${f//\//__}.patch" # ${f//\//__} replaces all "/" with "__"
        ret=$?
        { set +x; } 2>/dev/null
        set -e
        if [ $ret -ne 0 ] && [ $ret -ne 1 ] ; then
                exit $ret
        fi
done
