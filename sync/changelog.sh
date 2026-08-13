#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ) ; readonly SCRIPT_DIR
source "${SCRIPT_DIR}"/_helpers.sh

# this script is deliberately not called by sync.sh; the sync diff check runs
# sync.sh on every pull request and it must not rewrite the changelog.

CHANGELOG="${REPO_DIR}/CHANGELOG.md" ; readonly CHANGELOG

# get the upstream sync version from vendir.yml
UPSTREAM_SYNC_VERSION=$(yq -r .directories[0].contents[0].git.ref "${REPO_DIR}"/vendir.yml) ; readonly UPSTREAM_SYNC_VERSION

readonly ENTRY_PREFIX="- Update upstream whereabouts chart to "
ENTRY="${ENTRY_PREFIX}${UPSTREAM_SYNC_VERSION}." ; readonly ENTRY

echo "Adding changelog entry: ${ENTRY}"

TMP_FILE=$(mktemp) ; readonly TMP_FILE

# add the entry to the top of the Unreleased section. running this twice with the
# same version must not change the file, otherwise the sync workflow loops.
awk -v entry="${ENTRY}" -v prefix="${ENTRY_PREFIX}" '
# print a line, but never two blank lines in a row
function out(line) {
    if (line == "") {
        if (prev_blank) { return }
        prev_blank = 1
    } else {
        prev_blank = 0
    }
    print line
}
$0 == "## [Unreleased]" {
    out($0) ; out("") ; out("### Changed") ; out("") ; out(entry)
    in_unreleased = 1
    next
}
# the next release heading ends the Unreleased section
in_unreleased && /^## \[/ { in_unreleased = 0 }
# drop the heading we just printed and the entry from any previous run
in_unreleased && $0 == "### Changed" { next }
in_unreleased && index($0, prefix) == 1 { next }
{ out($0) }
' "${CHANGELOG}" > "${TMP_FILE}"

# keep the mode of the existing file
cat "${TMP_FILE}" > "${CHANGELOG}"
rm "${TMP_FILE}"
