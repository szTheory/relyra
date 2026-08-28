#!/usr/bin/env bash
# check_cve_assignment.sh — assert GHSA-jv46-xfwm-36j7 CVE assignment for RELYRA-2026-001.
#
# Usage:
#   scripts/check_cve_assignment.sh
#   GH_TOKEN=<token> scripts/check_cve_assignment.sh

set -euo pipefail

REPO="${GITHUB_REPOSITORY:-szTheory/relyra}"
GHSA="GHSA-jv46-xfwm-36j7"
EXPECTED_CVE="CVE-2026-49454"

cve_id="$(
  gh api "repos/${REPO}/security-advisories/${GHSA}" \
    --jq '.cve_id // empty'
)"

if [[ -z "$cve_id" ]]; then
  echo "ERROR: ${GHSA} has no CVE ID; expected ${EXPECTED_CVE}" >&2
  exit 1
fi

if [[ "$cve_id" != "$EXPECTED_CVE" ]]; then
  echo "ERROR: ${GHSA} has CVE ID ${cve_id}; expected ${EXPECTED_CVE}" >&2
  exit 1
fi

echo "${GHSA} has expected CVE ID ${EXPECTED_CVE}"
exit 0
