#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ) ; readonly SCRIPT_DIR
source "${SCRIPT_DIR}"/../../_helpers.sh

cd "${REPO_DIR}"

HELPERS_FILE="${CHART_DIR}/templates/_helpers.tpl"

# The upstream helm.sh/chart helper cuts "<name>-<version>" at 63 characters and trims one "-". A long
# chart version (branch builds, OCI "<tag>+<digest>") can leave the cut ending in ".", "_" or "--.",
# which is not a valid label value. Trim the whole run of "-", "." and "_".
# This chart uses "{{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}" with no trunc, so replace it
# with the truncated and trimmed form.
set -x
sed -i -E '
  s/"\{\{ \.Chart\.Name \}\}-\{\{ \.Chart\.Version \| replace "\+" "_" \}\}"/{{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimAll "-._" | quote }}/
  /\.Chart\.Version/ {
    /trunc 63/ {
      /trimAll/! {
        s/trunc 63([[:space:]]*\|[[:space:]]*trimSuffix[[:space:]]*"[-._]")*/trunc 63 | trimAll "-._"/
      }
    }
  }
' "${HELPERS_FILE}"
{ set +x; } 2>/dev/null

# check that the expected expression is in the helpers file
if ! grep -Eq '\.Chart\.Version.*trunc 63.*trimAll "-\._"' "${HELPERS_FILE}"; then
  echo "ERROR: Expected trimAll expression not found in ${HELPERS_FILE}" >&2
  exit 1
fi

if grep -E '\.Chart\.Version.*trunc 63' "${HELPERS_FILE}" |
    grep -Eq 'trimSuffix "[-._]"'; then
  echo "ERROR: Old trimSuffix filters remain in ${HELPERS_FILE}" >&2
  exit 1
fi
