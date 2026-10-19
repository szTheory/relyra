#!/usr/bin/env bash
# Release publish gate (SEED-004 item 7): publish only a tree that already
# passed the required `ci-gate` check, instead of re-running qa/ci.security.
#
# Usage: GH_REPO=owner/repo scripts/check_release_ci_gate.sh <40-hex commit sha>
#
# Passes when the newest GitHub Actions `ci-gate` check run succeeded on:
#   1. the release commit itself, or
#   2. the head of the merged PR whose merge commit is the release commit,
#      and that head has a byte-identical git tree. This fallback applies
#      only when the release commit has no ci-gate run at all.
# Release Please PRs are merged with GITHUB_TOKEN, and that push does not
# trigger security-gates, so case 2 is the normal release path. A failed,
# cancelled, skipped or missing ci-gate fails closed; a pending one is
# polled for up to RELEASE_GATE_WAIT_SECONDS (default 1800).
set -euo pipefail

sha="${1:-}"
repo="${GH_REPO:-}"
wait_seconds="${RELEASE_GATE_WAIT_SECONDS:-1800}"
poll_seconds="${RELEASE_GATE_POLL_SECONDS:-30}"

if [[ ! "$sha" =~ ^[0-9a-f]{40}$ ]]; then
  echo "release gate: expected a full 40-hex commit sha, got '${sha}'" >&2
  exit 2
fi

if [[ ! "$repo" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; then
  echo "release gate: GH_REPO must be owner/repo" >&2
  exit 2
fi

# Prints success, pending, missing, or the failing conclusion.
gate_state() {
  gh api "repos/${repo}/commits/$1/check-runs?check_name=ci-gate&per_page=100" --jq '
    [.check_runs[] | select(.name == "ci-gate" and .app.slug == "github-actions")]
    | sort_by(.id) | last
    | if . == null then "missing"
      elif .status != "completed" then "pending"
      else (.conclusion // "missing") end'
}

await_gate() {
  local commit="$1" state waited=0
  while true; do
    state="$(gate_state "$commit")"
    if [[ "$state" != "pending" || "$waited" -ge "$wait_seconds" ]]; then
      printf '%s' "$state"
      return 0
    fi
    echo "release gate: ci-gate pending on ${commit}; waiting" >&2
    sleep "$poll_seconds"
    waited=$((waited + poll_seconds))
  done
}

direct="$(await_gate "$sha")"
if [[ "$direct" == "success" ]]; then
  echo "release gate: ci-gate succeeded on release commit ${sha}"
  exit 0
fi

# A ci-gate that ran on the release commit and did not succeed is final; only
# a commit with no ci-gate at all may fall back to its merged PR head.
if [[ "$direct" != "missing" ]]; then
  echo "release gate: ci-gate on release commit ${sha} is '${direct}'" >&2
  exit 1
fi

head="$(gh api "repos/${repo}/commits/${sha}/pulls" --jq \
  "[.[] | select(.merged_at != null and .merge_commit_sha == \"${sha}\")] | if length == 1 then .[0].head.sha else \"\" end")"

if [[ ! "$head" =~ ^[0-9a-f]{40}$ ]]; then
  echo "release gate: ci-gate on ${sha} is '${direct}' and it is not the merge commit of exactly one merged PR" >&2
  exit 1
fi

release_tree="$(git rev-parse "${sha}^{tree}")"
head_tree="$(git rev-parse "${head}^{tree}" 2>/dev/null || true)"

if [[ "$release_tree" != "$head_tree" ]]; then
  echo "release gate: merged PR head ${head} tree '${head_tree}' differs from release tree ${release_tree}" >&2
  exit 1
fi

via_pr="$(await_gate "$head")"
if [[ "$via_pr" == "success" ]]; then
  echo "release gate: ci-gate succeeded on merged PR head ${head} with the identical tree ${release_tree}"
  exit 0
fi

echo "release gate: ci-gate on merged PR head ${head} is '${via_pr}'" >&2
exit 1
