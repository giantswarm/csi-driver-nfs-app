#!/usr/bin/env bash

set -e
set -u
set -o pipefail

# root dir of the git repository
REPO_DIR=$(git rev-parse --show-toplevel) ; readonly repo_dir

SCRIPT_DIR_REL=".${SCRIPT_DIR#"${REPO_DIR}"}" ; readonly SCRIPT_DIR

# root dir of the generated helm chart
CHART_DIR="${REPO_DIR}/helm/csi-driver-nfs" ; readonly CHART_DIR

# root dir of the vendir synced chart
VENDIR_SYNC_DIR="${REPO_DIR}/vendor/csi-driver-nfs/charts/latest/csi-driver-nfs" ; readonly VENDIR_SYNC_DIR
