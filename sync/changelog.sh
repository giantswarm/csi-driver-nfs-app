#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ) ; readonly SCRIPT_DIR
source "${SCRIPT_DIR}"/_helpers.sh

# this script is deliberately not called by sync.sh; the sync diff check runs
# sync.sh on every pull request and it must not rewrite the changelog.

CHANGELOG="${REPO_DIR}/CHANGELOG.md" ; readonly CHANGELOG

# get the upstream name from the vendir path, unless _helpers.sh sets UPSTREAM_NAME
if [[ -z "${UPSTREAM_NAME:-}" ]]; then
    UPSTREAM_NAME=$(yq -r .directories[0].contents[0].path "${REPO_DIR}"/vendir.yml) ; readonly UPSTREAM_NAME
fi

# get the upstream sync version from vendir.yml. the upstream is either a git
# repository or a GitHub release.
UPSTREAM_SYNC_VERSION=$(yq -r '.directories[0].contents[0] | .git.ref // .githubRelease.tag // error("no git ref or githubRelease tag in vendir.yml")' "${REPO_DIR}"/vendir.yml) ; readonly UPSTREAM_SYNC_VERSION

ENTRY="- Update upstream ${UPSTREAM_NAME} chart to ${UPSTREAM_SYNC_VERSION}." ; readonly ENTRY

# running this twice with the same version must not change the file, otherwise
# the sync workflow loops. existing entries are never changed or removed.
if grep -qxF -- "${ENTRY}" "${CHANGELOG}"; then
    echo "Changelog entry already present: ${ENTRY}"
    exit 0
fi

echo "Adding changelog entry: ${ENTRY}"

# find out if the Unreleased section already has a Changed heading
HAS_CHANGED=$(awk '
$0 == "## [Unreleased]" { in_unreleased = 1 ; next }
in_unreleased && /^## \[/ { exit }
in_unreleased && $0 == "### Changed" { print 1 ; exit }
' "${CHANGELOG}") ; readonly HAS_CHANGED

TMP_FILE=$(mktemp) ; readonly TMP_FILE

# add the entry to the end of the Changed list in the Unreleased section. if the
# Changed heading does not exist, add it in alphabetical order of the headings.
awk -v entry="${ENTRY}" -v has_changed="${HAS_CHANGED}" '
# print the entry after the last line of the Changed list, then the blank lines
# that followed that line
function add_entry() {
    if (!n_items) { print "" }
    print entry
    for (; n_blank > 0; n_blank--) { print "" }
    in_changed = 0
}
# print the Changed heading and the entry
function add_section() {
    if (!prev_blank) { print "" }
    print "### Changed" ; print "" ; print entry
}
# a link reference, such as "[Unreleased]: https://...", ends the section
{ is_link = /^\[[^]]*\]: / }
# the next heading or link reference ends the Changed list
in_changed && (/^#/ || is_link) { add_entry() }
# hold blank lines until we know if more list lines follow
in_changed && $0 == "" { n_blank++ ; next }
in_changed {
    for (; n_blank > 0; n_blank--) { print "" }
    n_items = 1
}
$0 == "## [Unreleased]" { print ; in_unreleased = 1 ; next }
# add the Changed heading before the first heading which comes after it in
# alphabetical order, or at the end of the Unreleased section
in_unreleased && has_changed == "" && (/^## \[/ || is_link || (/^### / && $0 > "### Changed")) {
    add_section() ; print ""
    in_unreleased = 0
}
# the next release heading or a link reference ends the Unreleased section
in_unreleased && (/^## \[/ || is_link) { in_unreleased = 0 }
# only the first Changed heading in the Unreleased section gets the entry
in_unreleased && $0 == "### Changed" { in_changed = 1 ; in_unreleased = 0 }
{ print ; prev_blank = ($0 == "") }
END {
    if (in_changed) { add_entry() }
    if (in_unreleased && has_changed == "") { add_section() }
}
' "${CHANGELOG}" > "${TMP_FILE}"

# keep the mode of the existing file
cat "${TMP_FILE}" > "${CHANGELOG}"
rm "${TMP_FILE}"
