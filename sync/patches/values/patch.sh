#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

repo_dir=$(git rev-parse --show-toplevel) ; readonly repo_dir
script_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ) ; readonly script_dir
VALUES_YAML="${repo_dir}/helm/csi-driver-nfs/values.yaml" ; readonly VALUES_YAML

cd "${repo_dir}"

readonly script_dir_rel=".${script_dir#"${repo_dir}"}"

set -x
git apply "${script_dir_rel}/_values.yaml.patch"

# Some changes to values.yaml cannot be applied using the patch file as the
# changes are too close to each other in file and the patch file does not
# contain enough context for the patch to apply cleanly. Instead we make those
# changes manually after the base patch has been applied.

sed -i 's/baseRepo:.*$/baseRepo: gsoci.azurecr.io/g' "${VALUES_YAML}"
sed -i 's|registry.k8s.io/sig-storage/|/giantswarm/|g' "${VALUES_YAML}"
sed -i 's|/sig-storage/|/giantswarm/|g' "${VALUES_YAML}"

{ set +x; } 2>/dev/null
