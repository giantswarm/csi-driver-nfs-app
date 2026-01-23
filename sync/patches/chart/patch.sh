#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

repo_dir=$(git rev-parse --show-toplevel) ; readonly repo_dir
script_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ) ; readonly script_dir
CHART_DIR="${repo_dir}/helm/csi-driver-nfs" ; readonly CHART_DIR
readonly script_dir_rel=".${script_dir#"${repo_dir}"}"

cd "${repo_dir}"

echo "Patching chart metadata"

set -x
# copy default Chart.yaml to the helm chart directory
cp "${script_dir}"/manifests/Chart.yaml "${CHART_DIR}/Chart.yaml"
{ set +x; } 2>/dev/null

CURRENT_CHART_VERSION=$(curl -s https://api.github.com/repos/giantswarm/csi-driver-nfs-app/releases/latest | jq -r .name)
# remove leading 'v' if present
CURRENT_CHART_VERSION="${CURRENT_CHART_VERSION#v}"

# we need to set the appVersion field in Chart.yaml to match the
# version being synced from upstream.

# get the upstream sync version from vendir.yml
UPSTREAM_CHART_VERSION=$(yq -r .directories[0].contents[0].git.ref ${repo_dir}/vendir.yml)
# strip leading 'v' if present
UPSTREAM_CHART_VERSION_STRIPPED="${UPSTREAM_CHART_VERSION#v}"

# set the upstream version in Chart.yaml (for appVersion field and upstream version annotation)
sed -i -E "s/UPSTREAM_CHART_VERSION/${UPSTREAM_CHART_VERSION_STRIPPED}/" "${CHART_DIR}/Chart.yaml"

# set the chart version in Chart.yaml
sed -i -E "s/CURRENT_CHART_VERSION/${CURRENT_CHART_VERSION}/" "${CHART_DIR}/Chart.yaml"
