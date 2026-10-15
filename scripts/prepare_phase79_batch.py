#!/usr/bin/env python3
"""Build or verify hash-bound, inert Phase 79 protection artifacts locally."""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import os
import pathlib
import sys
import tempfile
from typing import Any


ROOT = pathlib.Path(__file__).resolve().parents[1]
PHASE_DIR = ".planning/phases/79-adopter-ready-closeout"
CAPTURE_KEYS = {
    "schema", "version", "observed_at", "repository", "ref", "main_sha",
    "capture_status", "capture_errors", "source_digest", "sources", "resource",
    "writable_payload",
}
INVENTORY_KEYS = {
    "schema", "version", "observed_at", "repository", "observation", "collection",
    "sources", "local", "github",
}
OUTPUTS = {
    "desired": "79-PROTECTION-DESIRED.json",
    "rollback": "79-PROTECTION-ROLLBACK.json",
    "batch": "79-REMOTE-BATCH.md",
}
EXPECTED_CHECK = "fleet-proxy-e2e"
EXPECTED_WORKFLOWS = [
    ".github/workflows/security-gates.yml",
    ".github/workflows/fleet-proxy-e2e.yml",
]


class BuilderError(Exception):
    pass


def load_module(name: str, path: pathlib.Path) -> Any:
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise BuilderError(f"cannot load validator {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


CAPTURE = load_module("phase79_capture", ROOT / "scripts/capture_phase79_protection.py")
INVENTORY = load_module("phase79_inventory", ROOT / "scripts/collect_phase79_inventory.py")


def encoded(value: Any) -> bytes:
    return (json.dumps(value, indent=2, sort_keys=True, ensure_ascii=False) + "\n").encode()


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def read_json(path: pathlib.Path, label: str) -> tuple[Any, bytes]:
    try:
        raw = path.read_bytes()
        value = json.loads(raw)
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise BuilderError(f"invalid {label} JSON: {exc}") from exc
    if not isinstance(value, dict):
        raise BuilderError(f"{label} must be a JSON object")
    return value, raw


def validate_inputs(capture: dict, inventory: dict) -> list[str]:
    errors: list[str] = []
    if set(capture) != CAPTURE_KEYS:
        errors.append("capture has missing or unknown top-level fields")
    else:
        errors.extend(CAPTURE.validate_capture(capture))
    if set(inventory) != INVENTORY_KEYS:
        errors.append("inventory has missing or unknown top-level fields")
    else:
        errors.extend(INVENTORY.validate_receipt(inventory))
    return list(dict.fromkeys(errors))


def target(capture: dict, inventory: dict) -> dict:
    observation = inventory.get("observation", {})
    return {
        "repository": inventory.get("repository", {}).get("name"),
        "ref": observation.get("ref"),
        "main_sha": observation.get("main_sha"),
        "observed_at": inventory.get("observed_at"),
        "capture_sha": capture.get("main_sha"),
    }


def add_expected_check(resource: dict, app_id: int) -> dict:
    current = json.loads(json.dumps(resource))
    checks = current["required_status_checks"]["checks"]
    contexts = current["required_status_checks"]["contexts"]
    if any(row.get("context") == EXPECTED_CHECK for row in checks):
        raise BuilderError("fleet-proxy-e2e is already present; required delta is not exact")
    checks.append({"app_id": app_id, "context": EXPECTED_CHECK})
    checks.sort(key=lambda row: row["context"])
    contexts.append(EXPECTED_CHECK)
    contexts.sort()
    return current


def inventory_projection(resource: dict) -> dict:
    """Normalize the composite source shape to the inventory's REST shape."""
    projected = json.loads(json.dumps(resource))
    for key in (
        "enforce_admins", "required_signatures", "required_linear_history",
        "allow_force_pushes", "allow_deletions", "block_creations",
        "required_conversation_resolution", "lock_branch", "allow_fork_syncing",
    ):
        if type(projected.get(key)) is bool:
            projected[key] = {"enabled": projected[key]}
    reviews = projected.get("required_pull_request_reviews")
    if isinstance(reviews, dict):
        # GraphQL is authoritative for this extra allowlist; the inventory's
        # REST projection cannot independently represent the GraphQL-only field.
        reviews.pop("bypass_pull_request_allowances", None)
        restrictions = reviews.get("dismissal_restrictions")
        if isinstance(restrictions, dict):
            reviews["dismissal_restrictions"] = actor_projection(restrictions)
    restrictions = projected.get("restrictions")
    if isinstance(restrictions, dict):
        projected["restrictions"] = actor_projection(restrictions)
    return projected


def actor_projection(value: dict) -> dict:
    fields = {"users": "login", "teams": "slug", "apps": "slug"}
    return {
        collection: [({identity: item} if isinstance(item, str) else item) for item in value[collection]]
        for collection, identity in fields.items()
    }


def artifacts(capture: dict, capture_bytes: bytes, inventory: dict, inventory_bytes: bytes) -> dict[str, bytes]:
    validation_errors = validate_inputs(capture, inventory)
    capture_sha, inventory_sha = sha256(capture_bytes), sha256(inventory_bytes)
    observed = target(capture, inventory)
    same_target = (
        capture.get("repository") == observed["repository"] == "szTheory/relyra"
        and capture.get("ref") == observed["ref"] == "refs/heads/main"
        and isinstance(observed["main_sha"], str)
        and capture.get("main_sha") == observed["main_sha"]
        and inventory.get("observation", {}).get("revalidated_sha") == observed["main_sha"]
    )
    if not same_target:
        validation_errors.append("capture and inventory do not bind the same stable main SHA")

    protection = inventory.get("github", {}).get("branch_protection", {})
    if protection.get("capture_status") != capture.get("capture_status"):
        validation_errors.append("inventory and composite capture status disagree")
    if capture.get("resource") is not None and protection.get("resource") != inventory_projection(capture["resource"]):
        validation_errors.append("inventory and composite capture resources disagree")

    complete = (
        not validation_errors
        and capture.get("capture_status") == "complete"
        and capture.get("capture_errors") == []
    )
    inventory_errors = protection.get("capture_errors", [])
    reason_parts = validation_errors + list(capture.get("capture_errors", []))
    if inventory_errors and inventory_errors != capture.get("capture_errors", []):
        reason_parts.extend(f"inventory REST observation: {item}" for item in inventory_errors)
    reason = "; ".join(dict.fromkeys(reason_parts))
    if not reason and not complete:
        reason = "composite protection capture is incomplete"

    resource = capture.get("writable_payload") if complete else None
    app_ids = capture.get("sources", {}).get("fleet_check_run", {}).get("app_ids", [])
    if complete and (
        not isinstance(app_ids, list)
        or len(app_ids) != 1
        or type(app_ids[0]) is not int
        or app_ids[0] <= 0
    ):
        complete = False
        resource = None
        reason = "current-SHA fleet-proxy-e2e GitHub App association is missing or ambiguous"

    desired_payload = add_expected_check(resource, app_ids[0]) if complete else None
    rollback_payload = resource if complete else None
    output_status = "ready" if complete else "blocked"
    base = {
        "source_capture_path": "79-PROTECTION-CAPTURE.json",
        "source_capture_sha256": capture_sha,
        "source_capture_digest": capture.get("source_digest"),
        "source_capture_status": capture.get("capture_status"),
        "source_capture_errors": capture.get("capture_errors", []),
        "source_inventory_path": "79-INVENTORY.json",
        "source_inventory_sha256": inventory_sha,
        "source_inventory_capture_errors": inventory_errors,
        "target": {key: observed[key] for key in ("repository", "ref", "main_sha", "observed_at")},
    }
    rest_approval = capture.get("sources", {}).get("review_subresource", {}).get("configuration", {}).get("required_approving_review_count")
    graphql_rule = capture.get("sources", {}).get("graphql", {}).get("branch_protection", {}).get("rule", {})
    missing_settings = sorted(
        {"required_pull_request_reviews", "restrictions"}
        - set(capture.get("sources", {}).get("parent_protection", {}).get("configuration", {}))
    )
    desired = {
        "schema": "phase79-protection-desired", "version": 1, "status": output_status,
        "payload_available": complete, "desired_payload": desired_payload,
        "expected_delta": {"status_check_context": EXPECTED_CHECK,
                           "app_id_source": "current-SHA fleet-proxy-e2e check run"},
        "observed_rest_approval_count": rest_approval,
        "observed_graphql_approval_count": graphql_rule.get("requiredApprovingReviewCount"),
        "observed_graphql_requires_approving_reviews": graphql_rule.get("requiresApprovingReviews"),
        "reason": None if complete else reason,
        **base,
    }
    rollback = {
        "schema": "phase79-protection-rollback", "version": 1, "status": output_status,
        "payload_available": complete, "rollback_payload": rollback_payload,
        "source_endpoint": "composite protection capture", "reason": None if complete else reason,
        "required_missing_settings": missing_settings,
        **base,
    }
    desired_bytes, rollback_bytes = encoded(desired), encoded(rollback)
    desired_sha, rollback_sha = sha256(desired_bytes), sha256(rollback_bytes)
    if complete:
        batch = f"""# Phase 79 Remote Batch: Inert Exact Protection Proposal

**Status:** exact local payloads verified; no remote operation was executed.

- **Target:** `{observed['repository']}@{observed['ref']}`
- **Captured main SHA:** `{observed['main_sha']}`
- **Capture SHA-256:** `{capture_sha}`
- **Inventory SHA-256:** `{inventory_sha}`
- **Desired record:** `79-PROTECTION-DESIRED.json`, SHA-256 `{desired_sha}`
- **Rollback record:** `79-PROTECTION-ROLLBACK.json`, SHA-256 `{rollback_sha}`
- **Canonical workflow targets:** `{EXPECTED_WORKFLOWS[0]}`, `{EXPECTED_WORKFLOWS[1]}`
- **Only proposed protection delta:** add required context `{EXPECTED_CHECK}` using current-SHA GitHub App ID `{app_ids[0]}`.

## Exact update and read-back contract

The desired record is the complete writable protection object derived from the consistent captured state. The rollback record reproduces every captured writable setting byte-for-byte at the JSON-value level. A future, separately planned action must re-read `refs/heads/main` and the full protection configuration immediately before writing, abort on any target or hash drift, update only the target's protection resource, then re-read the complete resource and assert exact equality with the desired payload. Failure of any preflight or read-back requires restoring the captured rollback state and verifying it.

This batch is inert. It contains no approval, dispatch instruction, or authorization to write. Any later mutation requires a distinct plan with a target-and-hash-bound blocking approval gate.
"""
    else:
        batch = f"""# Phase 79 Remote Batch: No Action Proposed

**Status:** no mutation proposed; no command was executed.

- **Target repository:** `szTheory/relyra`
- **Target ref/resource:** `refs/heads/main` branch protection
- **Observed main SHA:** `{observed['main_sha']}`
- **Observed at:** `{observed['observed_at']}`
- **Composite capture status:** `{capture.get('capture_status')}`
- **Composite capture SHA-256:** `{capture_sha}`
- **Composite source digest:** `{capture.get('source_digest')}`
- **Inventory SHA-256:** `{inventory_sha}`
- **Desired record:** `79-PROTECTION-DESIRED.json`, SHA-256 `{desired_sha}`
- **Rollback record:** `79-PROTECTION-ROLLBACK.json`, record SHA-256 `{rollback_sha}`
- **Canonical workflow targets:** `{EXPECTED_WORKFLOWS[0]}`, `{EXPECTED_WORKFLOWS[1]}` (inventory only)

## Why there is no proposal

{reason}. Both derived records have null payloads. No exact remote batch or approval signal is available.

## Authorization boundary

No GitHub write or workflow dispatch was prepared or executed. This record grants no permission to mutate the target. Any later operation needs a complete source-consistent capture and inventory, exact payload and rollback hashes, a distinct target-and-hash approval checkpoint, immediate preflight, and automated read-back that proves its postcondition.
"""
    return {OUTPUTS["desired"]: desired_bytes, OUTPUTS["rollback"]: rollback_bytes,
            OUTPUTS["batch"]: batch.encode()}


def write_outputs(directory: pathlib.Path, files: dict[str, bytes]) -> None:
    directory.mkdir(parents=True, exist_ok=True)
    temps: list[tuple[pathlib.Path, pathlib.Path]] = []
    try:
        for name, content in files.items():
            target_path = directory / name
            if target_path.is_symlink():
                raise BuilderError(f"refusing symlink output: {target_path}")
            fd, temporary = tempfile.mkstemp(prefix=f".{name}.", suffix=".tmp", dir=directory)
            tmp_path = pathlib.Path(temporary)
            with os.fdopen(fd, "wb") as stream:
                stream.write(content)
                stream.flush()
                os.fsync(stream.fileno())
            temps.append((tmp_path, target_path))
        for tmp_path, target_path in temps:
            os.replace(tmp_path, target_path)
    finally:
        for tmp_path, _ in temps:
            try:
                tmp_path.unlink()
            except FileNotFoundError:
                pass


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--capture", type=pathlib.Path, required=True)
    parser.add_argument("--inventory", type=pathlib.Path, required=True)
    parser.add_argument("--output-dir", type=pathlib.Path, required=True)
    parser.add_argument("--verify", action="store_true")
    args = parser.parse_args()
    try:
        capture, capture_bytes = read_json(args.capture, "protection capture")
        inventory, inventory_bytes = read_json(args.inventory, "inventory")
        try:
            expected = artifacts(capture, capture_bytes, inventory, inventory_bytes)
        except (AttributeError, IndexError, KeyError, TypeError) as exc:
            raise BuilderError("malformed capture or inventory shape") from exc
        if args.verify:
            for name, content in expected.items():
                actual_path = args.output_dir / name
                if not actual_path.is_file() or actual_path.is_symlink() or actual_path.read_bytes() != content:
                    raise BuilderError(f"artifact missing, altered, or stale: {actual_path}")
            print(f"valid Phase 79 batch artifacts: {capture['capture_status']} ({capture.get('main_sha')})")
            return 0
        write_outputs(args.output_dir, expected)
        print(f"wrote Phase 79 batch artifacts: {capture['capture_status']} ({capture.get('main_sha')})")
        return 0
    except (BuilderError, OSError) as exc:
        print(f"Phase 79 batch blocked: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
