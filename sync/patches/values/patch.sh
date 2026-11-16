#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ) ; readonly SCRIPT_DIR
source "${SCRIPT_DIR}"/../../_helpers.sh

set -x
git apply "${SCRIPT_DIR}/_values.yaml.patch"

# Some changes to values.yaml cannot be applied using the patch file as the
# changes are too close to each other in the file and the patch file does not
# contain enough context for the patch to apply cleanly. Instead we make those
# changes manually after the base patch has been applied.

sed -i 's/baseRepo:.*$/baseRepo: gsoci.azurecr.io/g' "${VALUES_YAML}"
sed -i 's|registry.k8s.io/sig-storage/|/giantswarm/|g' "${VALUES_YAML}"
sed -i 's|/sig-storage/|/giantswarm/|g' "${VALUES_YAML}"
{ set +x; } 2>/dev/null

# Generate schema.
echo "Generating values schema..."
if ! helm plugin list | grep -q values-schema-json; then
  helm plugin install https://github.com/losisin/helm-values-schema-json.git --verify=false || true
fi
helm schema -f "${VALUES_YAML}" -o "${CHART_DIR}"/values.schema.json
