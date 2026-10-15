#!/usr/bin/env python3
"""Verify a maintainer's exact Phase 79 scope-disposition response."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path

from prepare_phase79_filtered_candidate import validate_receipt


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def review_recommendations(path: Path) -> dict[str, str]:
    recommendations: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.startswith("| `") or line.startswith("| `Exact path"):
            continue
        cells = line.split("|")
        if len(cells) < 4:
            raise ValueError("malformed scope-review table row")
        item_path = cells[1].strip().strip("`")
        match = re.search(r"\*\*(include|exclude)\*\* \(pending\)", cells[2])
        if not item_path or not match or item_path in recommendations:
            raise ValueError(f"invalid or duplicate review row for {item_path!r}")
        recommendations[item_path] = match.group(1)
    return recommendations


def verify(phase_dir: Path) -> dict[str, object]:
    # Reuse the independently pinned schema, frozen identities, normalized response,
    # and exact 30/25 recommendation-map contract before the legacy Git diff checks.
    accepted, receipt_evidence = validate_receipt(phase_dir)
    packet_path = phase_dir / "79-SCOPE-REVIEW-PACKET.json"
    review_path = phase_dir / "79-SCOPE-DISPOSITION-REVIEW.md"
    receipt_path = phase_dir / "79-SCOPE-DISPOSITIONS.json"
    packet = json.loads(packet_path.read_text(encoding="utf-8"))
    receipt = json.loads(receipt_path.read_text(encoding="utf-8"))
    recommendations = review_recommendations(review_path)
    evidence = receipt.get("evidence", {})

    if receipt.get("schema") != "relyra.phase79.scope-dispositions.v1":
        raise ValueError("unexpected scope-disposition schema")
    if receipt.get("approval") != "accepted_recommendations":
        raise ValueError("receipt does not record acceptance of the recommendations")
    if receipt.get("decision") != "accepted_recommendations_with_exclusions":
        raise ValueError("receipt decision does not preserve the accepted exclusions")
    if evidence.get("base_sha") != packet.get("base_sha"):
        raise ValueError("base SHA differs from the frozen packet")
    if evidence.get("source_sha") != packet.get("source_sha"):
        raise ValueError("source SHA differs from the frozen packet")
    if evidence.get("source_tree_sha") != packet.get("source_tree_sha"):
        raise ValueError("tree SHA differs from the frozen packet")
    if evidence.get("packet_path") != ".planning/phases/79-adopter-ready-closeout/79-SCOPE-REVIEW-PACKET.json":
        raise ValueError("accepted receipt does not point to the immutable scope review packet")
    if evidence.get("packet_sha256") != sha256(packet_path) or receipt_evidence != evidence:
        raise ValueError("packet digest differs from the accepted receipt")
    if evidence.get("review_sha256") != sha256(review_path):
        raise ValueError("review digest differs from the accepted receipt")

    packet_paths = packet.get("unclassified_paths", [])
    rows = receipt.get("paths", [])
    accepted_from_receipt: dict[str, str] = {}
    accepted_ordered: list[tuple[str, str]] = []
    for row in rows:
        item_path = row.get("path")
        disposition = row.get("disposition")
        if row.get("accepted") is not True or item_path in accepted_from_receipt:
            raise ValueError(f"path decision is unaccepted or duplicated: {item_path!r}")
        accepted_from_receipt[item_path] = disposition
        accepted_ordered.append((item_path, disposition))

    if len(packet_paths) != 55 or len(set(packet_paths)) != 55:
        raise ValueError("frozen packet does not contain 55 unique unclassified paths")
    if set(recommendations) != set(packet_paths):
        raise ValueError("review path set differs from the frozen packet")
    if accepted_ordered != list(recommendations.items()):
        raise ValueError("accepted path map differs byte-for-byte from the ordered review recommendations")

    include_count = sum(value == "include" for value in accepted_from_receipt.values())
    exclude_count = sum(value == "exclude" for value in accepted_from_receipt.values())
    if (include_count, exclude_count) != (30, 25):
        raise ValueError(f"expected 30 include and 25 exclude decisions; got {include_count}/{exclude_count}")
    if receipt.get("counts") != {"total": 55, "include": 30, "exclude": 25}:
        raise ValueError("recorded decision counts do not match the exact map")
    if receipt.get("candidate_status") != "blocked_requires_candidate_boundary_redesign":
        raise ValueError("excluded paths were not recorded as a candidate-boundary blocker")
    if receipt.get("response", {}).get("text") != (
        "Okay can you automatically follow your recommendations to do all that resolve and complete stuff?"
    ):
        raise ValueError("receipt does not preserve the maintainer's exact response")
    if not receipt.get("response", {}).get("normalized_decision"):
        raise ValueError("receipt does not state the normalized scope decision")
    if (
        packet.get("schema") != "phase79-scope-review-packet"
        or packet.get("version") != 1
        or packet.get("status") != "blocked"
        or packet.get("supersedes_packet_sha256") != "76ea68d9b04825512587a7fbaee8097d17cd9a62d7763787beb899ef0b1106b7"
        or packet.get("commit_count") != 612
        or packet.get("diff_path_count") != 351
    ):
        raise ValueError("frozen packet commit/path counts differ from the reviewed provenance")

    root = phase_dir.resolve().parents[2]
    diff_result = subprocess.run(
        ["git", "diff", "--name-only", "-z", packet["base_sha"], packet["source_sha"]],
        cwd=root,
        check=True,
        capture_output=True,
    )
    net_paths = {
        item.decode("utf-8") for item in diff_result.stdout.split(b"\0") if item
    }
    excluded_paths = {
        item_path for item_path, disposition in accepted_from_receipt.items() if disposition == "exclude"
    }
    in_net_diff = excluded_paths & net_paths
    historical_only = excluded_paths - net_paths
    provenance = receipt.get("exclusion_provenance", {})
    if len(in_net_diff) != 21 or len(historical_only) != 4:
        raise ValueError("excluded path count differs from the frozen Git diff evidence")
    if provenance != {"in_net_diff": 21, "historical_only": 4}:
        raise ValueError("recorded exclusion/provenance counts differ from Git evidence")

    return {
        "valid": True,
        "candidate_status": "blocked",
        "base_sha": packet["base_sha"],
        "source_sha": packet["source_sha"],
        "source_tree_sha": packet["source_tree_sha"],
        "counts": {"total": 55, "include": include_count, "exclude": exclude_count},
        "blocker": receipt.get("blocker"),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--phase-dir", type=Path, required=True)
    args = parser.parse_args()
    try:
        result = verify(args.phase_dir)
    except (OSError, ValueError, KeyError, TypeError, json.JSONDecodeError) as exc:
        print(json.dumps({"valid": False, "error": str(exc)}, sort_keys=True), file=sys.stderr)
        return 1
    print(json.dumps(result, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
