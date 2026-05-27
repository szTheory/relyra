#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$ROOT"

PHASE_DIR=".planning/phases/45-post-publish-parity-verification"
VERSION="1.4.0"
RESULT="$PHASE_DIR/PARITY-RESULT.md"
LOG="$(mktemp)"
TMP_HEX="$(mktemp -d)"
CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "HEAD")"

cleanup() {
  rm -f "$LOG" "${LOG}.audit" "${LOG}.release"
  rm -rf "$TMP_HEX"
  git checkout "$CURRENT_BRANCH" --quiet 2>/dev/null || true
}
trap cleanup EXIT

git fetch --tags

set +e
mix verify.release_parity "$VERSION" 2>&1 | tee "$LOG"
PARITY_EXIT=$?
set -e

# Collect Hex tarball paths for test_support scan (best-effort)
TEST_SUPPORT_COUNT=0
if mix hex.package fetch relyra "$VERSION" --unpack -o "$TMP_HEX" >/dev/null 2>&1; then
  while IFS= read -r path; do
    if [[ "$path" == *test_support* ]]; then
      TEST_SUPPORT_COUNT=$((TEST_SUPPORT_COUNT + 1))
    fi
  done < <(find "$TMP_HEX" -type f | sed "s|^${TMP_HEX}/||")
fi

# Parse drift counts from parity log when present
ONLY_GIT_COUNT=0
ONLY_HEX_COUNT=0
ONLY_GIT_LIST="none"
ONLY_HEX_LIST="none"

if grep -q "files only in git tag" "$LOG"; then
  ONLY_GIT_COUNT=$(grep -oE '[0-9]+ files only in git tag' "$LOG" | head -1 | awk '{print $1}')
  ONLY_HEX_COUNT=$(grep -oE '[0-9]+ files only in Hex tarball' "$LOG" | head -1 | awk '{print $1}')
  ONLY_GIT_LIST=$(awk '/Only in git tag \(missing from Hex tarball\):/,/Only in Hex tarball/' "$LOG" | grep '^  ' | grep -v '(none)' | sed 's/^  //' | paste -sd ', ' - || echo "none")
  ONLY_HEX_LIST=$(awk '/Only in Hex tarball \(not in git tag\):/,/^$/' "$LOG" | grep '^  ' | grep -v '(none)' | sed 's/^  //' | paste -sd ', ' - || echo "none")
fi

# Hex API checksum (best-effort)
HEX_CHECKSUM="unavailable"
if command -v curl >/dev/null 2>&1; then
  HEX_CHECKSUM=$(curl -fsS "https://hex.pm/api/packages/relyra/releases/${VERSION}" 2>/dev/null | rg '"checksum":"([^"]+)"' -or '$1' 2>/dev/null | head -1 || echo "unavailable")
fi

# Local mix hex.build checksum at tag (informational)
LOCAL_CHECKSUM="unavailable"
LOCAL_TAR="relyra-${VERSION}.tar"
if git rev-parse "v${VERSION}" >/dev/null 2>&1; then
  git checkout "v${VERSION}" --quiet 2>/dev/null || true
  if mix hex.build --unpack >/dev/null 2>&1 && [[ -f "$LOCAL_TAR" ]]; then
    LOCAL_CHECKSUM=$(shasum -a 256 "$LOCAL_TAR" | awk '{print $1}')
  fi
  rm -rf "relyra-${VERSION}" "$LOCAL_TAR" 2>/dev/null || true
  git checkout "$CURRENT_BRANCH" --quiet 2>/dev/null || true
fi

set +e
mix hex.audit > "${LOG}.audit" 2>&1
HEX_AUDIT_EXIT=$?
set -e
HEX_AUDIT_SUMMARY=$(head -1 "${LOG}.audit" 2>/dev/null || echo "unavailable")

set +e
mix ci.release > "${LOG}.release" 2>&1
CI_RELEASE_EXIT=$?
set -e

GENERATED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

TEST_SUPPORT_RESULT="PASS"
if [[ "$TEST_SUPPORT_COUNT" -gt 0 ]]; then
  TEST_SUPPORT_RESULT="FAIL"
fi

VERDICT="**FAIL**"
VERDICT_REASON=""

if [[ "$PARITY_EXIT" -eq 0 && "$TEST_SUPPORT_COUNT" -eq 0 && "$HEX_AUDIT_EXIT" -eq 0 && "$CI_RELEASE_EXIT" -eq 0 ]]; then
  VERDICT="**PASS**"
  VERDICT_REASON="Path-set parity confirmed for relyra ${VERSION}; zero test_support paths in published tarball; mix hex.audit and mix ci.release both green."
else
  REASONS=()
  [[ "$PARITY_EXIT" -ne 0 ]] && REASONS+=("mix verify.release_parity exit ${PARITY_EXIT}")
  [[ "$TEST_SUPPORT_COUNT" -gt 0 ]] && REASONS+=("test_support paths in tarball: ${TEST_SUPPORT_COUNT}")
  [[ "$HEX_AUDIT_EXIT" -ne 0 ]] && REASONS+=("mix hex.audit exit ${HEX_AUDIT_EXIT}")
  [[ "$CI_RELEASE_EXIT" -ne 0 ]] && REASONS+=("mix ci.release exit ${CI_RELEASE_EXIT}")
  VERDICT_REASON="Blocking: $(IFS='; '; echo "${REASONS[*]}")."
fi

cat > "$RESULT" <<EOF
# Parity Result — relyra ${VERSION}

**Generated:** ${GENERATED_AT}
**Git tag:** v${VERSION}
**Hex version:** ${VERSION}

## Tarball checksums (informational)

| Source | SHA-256 |
|--------|---------|
| Hex API (\`hex.pm/api/.../releases/${VERSION}\`) | ${HEX_CHECKSUM} |
| Local \`mix hex.build\` at v${VERSION} | ${LOCAL_CHECKSUM} |

> Outer tar SHA256 may differ while package contents match. Pass/fail uses path-set diff, not outer bytes.

## Path-set parity

- \`mix verify.release_parity ${VERSION}\` exit code: ${PARITY_EXIT}
- Only in git: ${ONLY_GIT_COUNT} (${ONLY_GIT_LIST})
- Only in Hex: ${ONLY_HEX_COUNT} (${ONLY_HEX_LIST})

## test_support (TD-02 defense-in-depth)

- Published paths containing \`test_support\`: ${TEST_SUPPORT_COUNT}
- Result: ${TEST_SUPPORT_RESULT}

## Release metadata

- \`mix hex.audit\`: exit ${HEX_AUDIT_EXIT} — ${HEX_AUDIT_SUMMARY}
- \`mix ci.release\`: exit ${CI_RELEASE_EXIT}

## Verdict

${VERDICT}

${VERDICT_REASON}
EOF

echo "Wrote ${RESULT} — verdict: ${VERDICT}"
exit "$PARITY_EXIT"
