#!/usr/bin/env bash
# check_cve_assignment.sh — query GHSA-jv46-xfwm-36j7 CVE assignment for RELYRA-2026-001.
#
# Usage:
#   scripts/check_cve_assignment.sh
#   GH_TOKEN=<token> scripts/check_cve_assignment.sh

set -euo pipefail

REPO="${GITHUB_REPOSITORY:-szTheory/relyra}"
GHSA="GHSA-jv46-xfwm-36j7"

cve_id="$(
  gh api "repos/${REPO}/security-advisories/${GHSA}" \
    --jq '.cve_id // empty'
)"

if [[ -n "$cve_id" ]]; then
  echo "CVE assigned: ${cve_id}"
  echo "Backfill docs/advisories/2026-001-xmldsig-signature-not-verified.md"
  exit 1
fi

echo "CVE still pending for ${GHSA}"
exit 0
