#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ) ; readonly SCRIPT_DIR
source "${SCRIPT_DIR}"/../../_helpers.sh

set -x
git apply "${SCRIPT_DIR}/_templates___crd-csi-snapshot.yaml.patch"
{ set +x; } 2>/dev/null
