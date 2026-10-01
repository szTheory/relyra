#!/usr/bin/env python3
"""Verify Phase 79 publication, GitHub transaction, CI, and closeout evidence.

Fixture mode consumes one bounded JSON observation named after the requested
stage. Live stages use git/gh reads and write only local evidence receipts;
remote mutations are reachable only from result stages with a packet-bound
approval record.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import pathlib
import re
import subprocess
import sys
import tempfile
import time
from typing import Any
from urllib.parse import quote


ROOT = pathlib.Path(__file__).resolve().parents[1]
PHASE_NAME = "79-adopter-ready-closeout"
REPOSITORY = "szTheory/relyra"
MAIN_REF = "refs/heads/main"
MAIN_BRANCH = "main"
FLEET_CONTEXT = "fleet-proxy-e2e"
EXPECTED_CI_WORKFLOWS = {
    ".github/workflows/security-gates.yml",
    ".github/workflows/fleet-proxy-e2e.yml",
}
EXPECTED_STAGES = {
    "publication",
    "pr-preflight",
    "pr-result",
    "merge-preflight",
    "merge-result",
    "ci-preflight",
    "ci-result",
    "protection-result",
    "closeout",
}
MAX_JSON_BYTES = 8 * 1024 * 1024


class TransactionError(Exception):
    pass


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def encoded(value: Any) -> bytes:
    return (json.dumps(value, indent=2, sort_keys=True, ensure_ascii=False) + "\n").encode()


def read_json(path: pathlib.Path, label: str) -> tuple[dict[str, Any], bytes]:
    try:
        if path.is_symlink() or not path.is_file():
            raise TransactionError(f"{label} must be a regular, non-symlink file: {path}")
        raw = path.read_bytes()
        if len(raw) > MAX_JSON_BYTES:
            raise TransactionError(f"{label} exceeds the {MAX_JSON_BYTES}-byte limit")
        value = json.loads(raw)
    except TransactionError:
        raise
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise TransactionError(f"cannot read {label}: {exc}") from exc
    if not isinstance(value, dict):
        raise TransactionError(f"{label} must be a JSON object")
    return value, raw


def write_json(path: pathlib.Path, value: dict[str, Any]) -> bytes:
    path.parent.mkdir(parents=True, exist_ok=True)
    payload = encoded(value)
    fd, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    try:
        with os.fdopen(fd, "wb") as handle:
            handle.write(payload)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary, path)
    finally:
        try:
            os.unlink(temporary)
        except FileNotFoundError:
            pass
    return payload


def run(argv: list[str], *, cwd: pathlib.Path = ROOT, timeout: int = 120) -> str:
    try:
        result = subprocess.run(
            argv,
            cwd=cwd,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            timeout=timeout,
            check=False,
            env={**os.environ, "GIT_TERMINAL_PROMPT": "0"},
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        raise TransactionError(f"command failed to run: {pathlib.Path(argv[0]).name}: {exc}") from exc
    if result.returncode:
        detail = result.stdout[-4000:].strip()
        raise TransactionError(
            f"command exited {result.returncode}: {' '.join(argv[:4])}"
            + (f"\n{detail}" if detail else "")
        )
    return result.stdout.strip()


def gh_json(path: str, *, method: str = "GET", fields: dict[str, str] | None = None) -> Any:
    command = ["gh", "api", "--method", method, path]
    for key, value in (fields or {}).items():
        command.extend(["-f", f"{key}={value}"])
    raw = run(command, timeout=45)
    try:
        return json.loads(raw)
    except json.JSONDecodeError as exc:
        raise TransactionError(f"GitHub returned invalid JSON for {path}") from exc


def gh_optional(path: str) -> Any | None:
    result = subprocess.run(
        ["gh", "api", path], cwd=ROOT, stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=45,
        check=False, env={**os.environ, "GIT_TERMINAL_PROMPT": "0"},
    )
    if result.returncode and ("HTTP 404" in result.stdout or "Not Found" in result.stdout):
        return None
    if result.returncode:
        raise TransactionError(f"GitHub read failed for {path}: {result.stdout[-2000:].strip()}")
    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError as exc:
        raise TransactionError(f"GitHub returned invalid JSON for {path}") from exc


def gh_paginated(path: str, key: str, *, max_pages: int = 20) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for page in range(1, max_pages + 1):
        separator = "&" if "?" in path else "?"
        value = gh_json(f"{path}{separator}per_page=100&page={page}")
        page_rows = value.get(key) if isinstance(value, dict) else None
        if not isinstance(page_rows, list) or any(not isinstance(item, dict) for item in page_rows):
            raise TransactionError(f"GitHub returned an incomplete {key} page")
        rows.extend(page_rows)
        if len(page_rows) < 100:
            return rows
    raise TransactionError(f"GitHub {key} inventory exceeded the {max_pages * 100}-row bound")


def approval_digest(value: dict[str, Any]) -> str:
    return sha256(encoded(value))


def ci_packet_digest(packet: dict[str, Any]) -> str:
    payload = {key: value for key, value in packet.items() if key not in {"approval", "packet_sha256"}}
    return approval_digest(payload)


def validate_ci_dispatch_packet(packet: dict[str, Any]) -> None:
    if (
        packet.get("schema") != "phase79-ci-dispatch-packet"
        or packet.get("version") != 1
        or packet.get("target", {}).get("repository") != REPOSITORY
        or packet.get("target", {}).get("ref") != MAIN_REF
        or packet.get("packet_sha256") != ci_packet_digest(packet)
    ):
        raise TransactionError("CI dispatch packet identity or digest is malformed")
    validate_sha(packet.get("target", {}).get("sha"), "CI dispatch packet target SHA")
    observed = packet.get("observed_evidence")
    enabled = observed.get("enabled_workflows") if isinstance(observed, dict) else None
    if not isinstance(enabled, list) or len(enabled) != len(EXPECTED_CI_WORKFLOWS):
        raise TransactionError("CI dispatch packet must bind both canonical owner workflow IDs")
    enabled_by_path: dict[str, int] = {}
    for item in enabled:
        if (
            not isinstance(item, dict)
            or item.get("path") not in EXPECTED_CI_WORKFLOWS
            or item.get("state") != "active"
            or not positive_int(item.get("id"))
            or item.get("path") in enabled_by_path
            or item["id"] in enabled_by_path.values()
        ):
            raise TransactionError("CI dispatch packet owner workflow registry is ambiguous")
        enabled_by_path[item["path"]] = item["id"]
    missing = packet.get("missing_owner_runs")
    dispatch = packet.get("dispatch")
    if (
        not isinstance(missing, list)
        or missing != sorted(set(missing))
        or any(path not in enabled_by_path for path in missing)
        or not isinstance(dispatch, dict)
        or dispatch.get("action") != "workflow_dispatch"
        or dispatch.get("ref") != MAIN_BRANCH
        or dispatch.get("performed") is not False
        or dispatch.get("workflows") != missing
    ):
        raise TransactionError("CI dispatch scope is not the exact canonical missing owner workflow set")
    expected_requests = [
        {
            "workflow_id": enabled_by_path[path],
            "path": path,
            "endpoint": f"repos/{REPOSITORY}/actions/workflows/{enabled_by_path[path]}/dispatches",
            "method": "POST",
            "body": {"ref": MAIN_BRANCH},
        }
        for path in missing
    ]
    if dispatch.get("requests") != expected_requests:
        raise TransactionError("CI dispatch requests differ from the exact approved workflow/ref scope")
    lanes = packet.get("lane_states")
    expected = expected_lanes()
    if (
        not isinstance(lanes, dict)
        or set(lanes) != set(expected)
        or any(value not in {"passed", "absent", "ambiguous_or_incomplete", "failed_or_pending"} for value in lanes.values())
    ):
        raise TransactionError("CI dispatch lane snapshot is malformed or incomplete")
    all_passed = all(value == "passed" for value in lanes.values())
    if packet.get("status") == "no_action":
        if missing or not all_passed or expected_requests:
            raise TransactionError("no-action CI packet requires all nine passing lanes and no missing owner")
    elif packet.get("status") == "pending":
        if not missing and all_passed:
            raise TransactionError("pending CI packet has no remaining owner work")
    else:
        raise TransactionError("CI dispatch packet has an unsupported state")


def fixture_json(directory: pathlib.Path, stage: str) -> dict[str, Any]:
    path = directory / f"{stage}.json"
    # The fixture root is explicit, owned by the caller, and never searched recursively.
    return read_json(path, f"{stage} fixture")[0]


def phase_path(phase_dir: pathlib.Path, name: str) -> pathlib.Path:
    return phase_dir / name


def expected_lanes() -> dict[str, dict[str, Any]]:
    path = ROOT / ".planning/phases/79-adopter-ready-closeout/79-INVENTORY.json"
    inventory, _ = read_json(path, "Phase 79 inventory")
    lanes = inventory.get("github", {}).get("mandatory_lanes")
    if not isinstance(lanes, dict) or len(lanes) != 9:
        raise TransactionError("the committed inventory must define exactly nine mandatory lanes")
    owners: dict[str, dict[str, Any]] = {}
    for lane, record in lanes.items():
        lane_owners = record.get("owners") if isinstance(record, dict) else None
        if not isinstance(lane, str) or not isinstance(lane_owners, list) or len(lane_owners) != 1:
            raise TransactionError("mandatory lane ownership is missing or ambiguous")
        owner = lane_owners[0]
        if owner not in {"security-gates.yml", "fleet-proxy-e2e.yml"}:
            raise TransactionError(f"unexpected mandatory workflow owner for {lane}")
        check_names = record.get("check_names")
        if not isinstance(check_names, list) or not check_names or any(not isinstance(item, str) for item in check_names):
            raise TransactionError(f"mandatory lane check names are missing for {lane}")
        owners[lane] = {"owner": f".github/workflows/{owner}", "check_names": sorted(set(check_names))}
    if {item["owner"] for item in owners.values()} != {".github/workflows/security-gates.yml"}:
        raise TransactionError("the nine mandatory lanes must be owned by security-gates.yml")
    return owners


def validate_sha(value: Any, label: str) -> str:
    if not isinstance(value, str) or not re.fullmatch(r"[0-9a-f]{40}", value):
        raise TransactionError(f"{label} must be a full lowercase Git SHA")
    return value


def positive_int(value: Any) -> bool:
    return type(value) is int and value > 0


def validate_ci_observation(
    observation: dict[str, Any],
) -> tuple[str, str, list[str], dict[str, dict[str, Any]]]:
    repository = observation.get("repository")
    ref = observation.get("ref")
    main_sha = validate_sha(observation.get("main_sha"), "observed main SHA")
    if repository != REPOSITORY or ref != MAIN_REF:
        raise TransactionError("CI observation must target szTheory/relyra refs/heads/main")

    lanes = expected_lanes()
    enabled = observation.get("enabled_workflows")
    if not isinstance(enabled, list):
        raise TransactionError("enabled_workflows must be an array of live workflow identities")
    enabled_paths: list[str] = []
    enabled_ids: set[int] = set()
    for item in enabled:
        if not isinstance(item, dict) or item.get("state") != "active":
            continue
        path = item.get("path")
        if isinstance(path, str):
            enabled_paths.append(path)
        workflow_id = item.get("id")
        if not positive_int(workflow_id) or workflow_id in enabled_ids:
            raise TransactionError("enabled owner workflow identity is missing or ambiguous")
        enabled_ids.add(workflow_id)
    if set(enabled_paths) != EXPECTED_CI_WORKFLOWS or len(enabled_paths) != len(EXPECTED_CI_WORKFLOWS):
        raise TransactionError("both canonical CI owner workflows must be enabled exactly once")

    workflow_runs = observation.get("workflow_runs")
    workflow_jobs = observation.get("workflow_jobs")
    check_runs = observation.get("check_runs")
    if not all(isinstance(value, list) for value in (workflow_runs, workflow_jobs, check_runs)):
        raise TransactionError(
            "CI observation must include bounded workflow_runs, workflow_jobs, and check_runs arrays"
        )
    run_by_id: dict[int, dict[str, Any]] = {}
    for run_record in workflow_runs:
        if not isinstance(run_record, dict):
            raise TransactionError("workflow run identity is malformed")
        if run_record.get("head_sha") != main_sha or run_record.get("head_branch") != MAIN_BRANCH:
            raise TransactionError("workflow run does not belong to the observed main SHA/ref")
        if run_record.get("path") not in EXPECTED_CI_WORKFLOWS:
            raise TransactionError("workflow run is not owned by a canonical CI workflow")
        run_id = run_record.get("id")
        attempt = run_record.get("attempt")
        if (
            not positive_int(run_id)
            or run_id in run_by_id
            or not positive_int(attempt)
        ):
            raise TransactionError("workflow run identity is missing, invalid, or ambiguous")
        run_by_id[run_id] = run_record
    job_by_id: dict[int, dict[str, Any]] = {}
    for job in workflow_jobs:
        if not isinstance(job, dict):
            raise TransactionError("workflow job identity is malformed")
        job_id = job.get("id")
        run_id = job.get("workflow_run_id")
        if (
            not positive_int(job_id)
            or job_id in job_by_id
            or run_id not in run_by_id
        ):
            raise TransactionError("workflow job identity is missing, invalid, or ambiguous")
        job_by_id[job_id] = job
    if not isinstance(observation, dict):
        raise TransactionError("CI observation is malformed")
    check_ids: set[int] = set()
    all_check_names = {name for lane in lanes.values() for name in lane["check_names"]} | {FLEET_CONTEXT}
    for check in check_runs:
        if not isinstance(check, dict):
            raise TransactionError("check-run identity is malformed")
        if check.get("head_sha") != main_sha:
            raise TransactionError("check run does not belong to the observed main SHA")
        name = check.get("name")
        if name in all_check_names:
            expected_owner = next((lane["owner"] for lane in lanes.values() if name in lane["check_names"]), ".github/workflows/fleet-proxy-e2e.yml")
            if check.get("workflow_path") != expected_owner:
                raise TransactionError(f"check {name} is attributed to the wrong canonical workflow")
            check_id = check.get("id")
            if not positive_int(check_id) or check_id in check_ids:
                raise TransactionError(f"check {name} has a missing or ambiguous check-run identity")
            check_ids.add(check_id)
            workflow_run_id = check.get("workflow_run_id")
            job_id = check.get("workflow_job_id")
            run_record = run_by_id.get(workflow_run_id)
            job_record = job_by_id.get(job_id)
            if (
                run_record is None
                or run_record.get("path") != expected_owner
                or run_record.get("head_sha") != main_sha
            ):
                raise TransactionError(f"check {name} does not join to its owning workflow run")
            if (
                job_record is None
                or job_record.get("workflow_run_id") != workflow_run_id
                or not positive_int(job_id)
            ):
                raise TransactionError(f"check {name} does not join to a job in its owner run")
    counts: dict[str, int] = {}
    for check in check_runs:
        if check.get("name") in all_check_names:
            counts[check["name"]] = counts.get(check["name"], 0) + 1
    ambiguous = sorted(name for name, count in counts.items() if count > 1)
    if ambiguous:
        raise TransactionError("ambiguous duplicate check identities: " + ", ".join(ambiguous))

    fleet = observation.get("fleet_context")
    if not isinstance(fleet, dict) or fleet.get("name") != FLEET_CONTEXT or fleet.get("sha") != main_sha:
        raise TransactionError("fleet context evidence must be bound to the observed main SHA")
    if fleet.get("state") not in {"absent", "failed", "pending", "passed"}:
        raise TransactionError("fleet context state is invalid")
    return repository, ref, enabled_paths, lanes


def ci_missing(
    observation: dict[str, Any], lanes: dict[str, dict[str, Any]]
) -> tuple[list[str], dict[str, str]]:
    main_sha = observation["main_sha"]
    runs_by_id = {item["id"]: item for item in observation["workflow_runs"]}
    jobs_by_id = {item["id"]: item for item in observation["workflow_jobs"]}
    runs_by_path = {path: [item for item in observation["workflow_runs"] if item["path"] == path] for path in EXPECTED_CI_WORKFLOWS}
    missing_workflows: list[str] = []
    lane_states: dict[str, str] = {}
    for lane, lane_info in sorted(lanes.items()):
        checks = [
            item for item in observation["check_runs"]
            if item.get("name") in lane_info["check_names"] and item.get("head_sha") == main_sha
            and item.get("workflow_path") == lane_info["owner"]
        ]
        by_name = {name: [item for item in checks if item.get("name") == name] for name in lane_info["check_names"]}
        if any(len(rows) != 1 for rows in by_name.values()):
            lane_states[lane] = "absent" if all(not rows for rows in by_name.values()) else "ambiguous_or_incomplete"
        elif all(
            rows[0].get("status") == "completed"
            and rows[0].get("conclusion") == "success"
            and jobs_by_id[rows[0]["workflow_job_id"]].get("status")
            == "completed"
            and jobs_by_id[rows[0]["workflow_job_id"]].get("conclusion")
            == "success"
            and runs_by_id[rows[0]["workflow_run_id"]].get("status")
            == "completed"
            and runs_by_id[rows[0]["workflow_run_id"]].get("conclusion")
            == "success"
            for rows in by_name.values()
        ):
            lane_states[lane] = "passed"
        else:
            lane_states[lane] = "failed_or_pending"
    security_owner = ".github/workflows/security-gates.yml"
    if not runs_by_path[security_owner] or any(state != "passed" for state in lane_states.values()):
        missing_workflows.append(security_owner)
    fleet_state = observation["fleet_context"].get("state")
    fleet = observation["fleet_context"]
    fleet_ids = (fleet.get("workflow_run_id"), fleet.get("workflow_job_id"), fleet.get("check_run_id"))
    fleet_run = runs_by_id.get(fleet.get("workflow_run_id"))
    fleet_job = jobs_by_id.get(fleet.get("workflow_job_id"))
    fleet_check = next(
        (item for item in observation["check_runs"] if item.get("id") == fleet.get("check_run_id")),
        None,
    )
    fleet_identity_passed = (
        all(positive_int(value) for value in fleet_ids)
        and fleet_run is not None
        and fleet_run.get("path") == ".github/workflows/fleet-proxy-e2e.yml"
        and fleet_job is not None
        and fleet_job.get("workflow_run_id") == fleet.get("workflow_run_id")
        and fleet_check is not None
        and fleet_check.get("workflow_run_id") == fleet.get("workflow_run_id")
        and fleet_check.get("workflow_job_id") == fleet.get("workflow_job_id")
        and fleet_check.get("status") == "completed"
        and fleet_check.get("conclusion") == "success"
        and fleet_job.get("status") == "completed"
        and fleet_job.get("conclusion") == "success"
        and fleet_run.get("status") == "completed"
        and fleet_run.get("conclusion") == "success"
    )
    if fleet_state != "passed" or not fleet_identity_passed:
        missing_workflows.append(".github/workflows/fleet-proxy-e2e.yml")
    return sorted(set(missing_workflows)), lane_states


def previous_receipts(phase_dir: pathlib.Path) -> dict[str, dict[str, Any]]:
    names = {
        "publication": "79-PUBLICATION-PACKET.json",
        "pr": "79-PR-TRANSACTION.json",
        "merge": "79-MERGE-RECEIPT.json",
    }
    found: dict[str, dict[str, Any]] = {}
    for key, name in names.items():
        path = phase_path(phase_dir, name)
        if path.exists():
            found[key] = read_json(path, name)[0]
    return found


def validate_receipt_join(receipts: dict[str, dict[str, Any]], observed_sha: str | None = None) -> dict[str, str]:
    if set(receipts) != {"publication", "pr", "merge"}:
        raise TransactionError("publication, PR, and merge receipts are all required")
    publication, pr, merge = receipts["publication"], receipts["pr"], receipts["merge"]
    candidate = publication.get("candidate_head_sha")
    source = publication.get("source_sha")
    tree = publication.get("source_tree_sha")
    base = publication.get("base_sha")
    source = validate_sha(source, "publication source SHA")
    candidate = validate_sha(candidate, "publication candidate SHA")
    base = validate_sha(base, "publication base SHA")
    tree = validate_sha(tree, "publication tree SHA")
    if candidate != source:
        raise TransactionError("publication candidate must preserve the original source head")
    pr_readback = pr.get("readback") if isinstance(pr.get("readback"), dict) else pr
    if pr.get("status") != "complete" or pr.get("independent_readback") is False or pr_readback.get("head_sha") != candidate or pr_readback.get("base_sha") != base or pr_readback.get("tree_sha") != tree or pr_readback.get("independent") is not True:
        raise TransactionError("PR read-back does not join to the publication packet")
    if merge.get("status") != "complete" or merge.get("independent_readback") is not True or merge.get("source_head_sha") != candidate or merge.get("base_sha") != base or merge.get("tree_sha") != tree:
        raise TransactionError("merge receipt does not join to the publication and PR")
    main_sha = validate_sha(merge.get("main_sha"), "merged main SHA")
    parents = merge.get("parents")
    if not isinstance(parents, list) or len(parents) != 2 or parents[0] != base or parents[1] != candidate:
        raise TransactionError("merge receipt must prove the approved normal two-parent merge")
    if observed_sha is not None and observed_sha != main_sha:
        raise TransactionError("observed main SHA differs from the merge receipt")
    return {"source_sha": source, "base_sha": base, "tree_sha": tree, "main_sha": main_sha}


def run_pr_local_gates(source_sha: str) -> list[dict[str, Any]]:
    commands = [
        ["mix", "qa"],
        ["mix", "test", "--warnings-as-errors"],
        ["mix", "ci.security"],
        ["mix", "format", "--check-formatted"],
    ]
    evidence = []
    env = {"ASDF_ELIXIR_VERSION": "1.19.5-otp-28", "ASDF_ERLANG_VERSION": "28.4.1", "MIX_ENV": "test"}
    with tempfile.TemporaryDirectory(prefix="relyra-phase79-local-gates-") as temporary:
        checkout = pathlib.Path(temporary) / "checkout"
        result = subprocess.run(
            ["git", "clone", "--shared", "--no-checkout", str(ROOT), str(checkout)],
            cwd=ROOT, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
            text=True, timeout=180, check=False,
        )
        if result.returncode:
            raise TransactionError(f"could not create isolated local-gate checkout: {result.stdout[-2000:]}")
        run(["git", "checkout", "--detach", source_sha], cwd=checkout)
        deps = ROOT / "deps"
        if deps.exists() and not (checkout / "deps").exists():
            (checkout / "deps").symlink_to(deps, target_is_directory=True)
        for argv in commands:
            try:
                result = subprocess.run(
                    argv, cwd=checkout, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT, text=True, timeout=1800, check=False,
                    env={**os.environ, **env, "GIT_TERMINAL_PROMPT": "0"},
                )
            except (OSError, subprocess.TimeoutExpired) as exc:
                raise TransactionError(f"local gate failed to complete: {' '.join(argv)} ({exc})") from exc
            record = {"command": " ".join(argv), "exit_code": result.returncode, "output_sha256": sha256(result.stdout.encode())}
            evidence.append(record)
            if result.returncode:
                raise TransactionError(f"local gate failed: {' '.join(argv)}\n{result.stdout[-4000:].strip()}")
        if run(["git", "status", "--porcelain=v1", "--untracked-files=all"], cwd=checkout):
            raise TransactionError("local gates changed the frozen source checkout")
    return evidence


def pr_observation(packet: dict[str, Any], fixture_dir: pathlib.Path | None, stage: str) -> dict[str, Any]:
    if fixture_dir:
        value = fixture_json(fixture_dir, stage)
    else:
        branch = packet["branch"]["name"]
        ref_path = f"repos/{REPOSITORY}/git/ref/heads/{quote(branch, safe='')}"
        ref_value = gh_optional(ref_path)
        branch_sha = None
        if ref_value is not None:
            branch_sha = ref_value.get("object", {}).get("sha") if isinstance(ref_value, dict) else None
            validate_sha(branch_sha, "candidate branch SHA")
        prs = gh_json(
            f"repos/{REPOSITORY}/pulls?state=all&base=main&head={REPOSITORY.split('/')[0]}:{branch}&per_page=100"
        )
        if not isinstance(prs, list):
            raise TransactionError("GitHub PR read-back is malformed")
        main_sha = run(["git", "ls-remote", "origin", MAIN_REF]).split()[0]
        value = {
            "repository": REPOSITORY,
            "main_sha": main_sha,
            "branch_sha": branch_sha,
            "pull_requests": [
                {
                    "number": pr.get("number"), "url": pr.get("html_url"),
                    "head_sha": pr.get("head", {}).get("sha"),
                    "head_ref": pr.get("head", {}).get("ref"),
                    "base_sha": pr.get("base", {}).get("sha"),
                    "base_ref": pr.get("base", {}).get("ref"),
                    "state": pr.get("state"), "merged": pr.get("merged"),
                }
                for pr in prs if isinstance(pr, dict)
            ],
        }
    if value.get("repository") != REPOSITORY or value.get("main_sha") != packet.get("base_sha"):
        raise TransactionError("PR preflight repository/main SHA differs from the publication packet")
    branch_sha = value.get("branch_sha")
    if branch_sha is not None and branch_sha != packet.get("source_sha"):
        raise TransactionError("candidate branch exists at a different SHA")
    prs = value.get("pull_requests")
    if not isinstance(prs, list) or len(prs) > 1:
        raise TransactionError("candidate branch has ambiguous matching PR records")
    if prs:
        pr = prs[0]
        if not isinstance(pr, dict) or pr.get("head_sha") != packet.get("source_sha") or pr.get("base_sha") != packet.get("base_sha") or pr.get("head_ref") != packet.get("branch", {}).get("name") or pr.get("base_ref") != MAIN_BRANCH:
            raise TransactionError("existing PR does not exactly match the candidate head and main base")
    return value


def make_pr_operation_packet(publication: dict[str, Any]) -> dict[str, Any]:
    if publication.get("status") != "ready" or publication.get("blockers"):
        raise TransactionError("publication packet has blockers and cannot enter PR preflight")
    pr = publication.get("pull_request")
    branch = publication.get("branch", {}).get("name")
    if not isinstance(pr, dict) or not isinstance(branch, str):
        raise TransactionError("publication packet is missing its exact branch/PR proposal")
    return {
        "repository": REPOSITORY, "base_sha": publication["base_sha"],
        "source_sha": publication["source_sha"], "tree_sha": publication["source_tree_sha"],
        "branch": branch,
        "operations": [
            {"method": "git-push", "ref": f"refs/heads/{branch}", "source_sha": publication["source_sha"], "force": False},
            {"method": "POST", "endpoint": f"repos/{REPOSITORY}/pulls", "title": pr["title"], "head": pr["head"], "base": pr["base"], "body": pr["body"]},
        ],
        "permission": {"contents": "write", "pull-requests": "write"},
        "rollback_limit": "a separate reviewed branch deletion or PR close; no force push",
    }


def stage_pr_preflight(phase_dir: pathlib.Path, fixture_dir: pathlib.Path | None, *, run_gates: bool = True) -> dict[str, Any]:
    verify_publication(phase_dir, fixture_dir)
    publication, publication_bytes = read_json(phase_path(phase_dir, "79-PUBLICATION-PACKET.json"), "publication packet")
    operation_packet = make_pr_operation_packet(publication)
    observation = pr_observation(publication, fixture_dir, "pr-preflight")
    if fixture_dir:
        gates = fixture_json(fixture_dir, "local-gates")
        gate_records = gates.get("gates") if isinstance(gates, dict) else None
        if not isinstance(gate_records, list) or len(gate_records) != 4 or not all(
            isinstance(item, dict) and type(item.get("exit_code")) is int and item["exit_code"] == 0
            for item in gate_records
        ):
            raise TransactionError("fixture local-gate receipt must prove all four required commands passed")
    else:
        gate_records = run_pr_local_gates(publication["source_sha"]) if run_gates else []
        if not run_gates:
            gate_records = []
    transaction = {
        "schema": "phase79-pr-transaction", "version": 1,
        "status": "ready", "partial": False,
        "publication_packet_sha256": sha256(publication_bytes),
        "operation_packet": operation_packet,
        "packet_sha256": approval_digest(operation_packet),
        "approval": None,
        "preflight": {
            "repository": REPOSITORY, "main_sha": observation["main_sha"],
            "branch_sha": observation.get("branch_sha"),
            "pull_requests": observation["pull_requests"],
            "local_gates": gate_records,
            "read_only": True,
        },
        "expected_readback": {
            "head_sha": publication["source_sha"], "head_ref": operation_packet["branch"],
            "base_sha": publication["base_sha"], "base_ref": MAIN_BRANCH,
            "tree_sha": publication["source_tree_sha"],
        },
        "remote_operations": [],
        "readback": None,
    }
    write_json(phase_path(phase_dir, "79-PR-TRANSACTION.json"), transaction)
    return transaction


def stage_pr_result(phase_dir: pathlib.Path, fixture_dir: pathlib.Path | None) -> dict[str, Any]:
    transaction_path = phase_path(phase_dir, "79-PR-TRANSACTION.json")
    transaction, _ = read_json(transaction_path, "PR transaction")
    operation_packet = transaction.get("operation_packet")
    approval = transaction.get("approval")
    if transaction.get("status") != "ready" or not isinstance(operation_packet, dict):
        raise TransactionError("PR transaction is not in a ready preflight state")
    if not isinstance(approval, dict) or approval.get("checkpoint_id") != "79-08-pr-create" or approval.get("response") != "approved" or approval.get("packet_sha256") != approval_digest(operation_packet) or approval.get("scope") != operation_packet.get("operations"):
        raise TransactionError("PR push/create require explicit approval bound to the exact operation packet")

    publication, _ = read_json(phase_path(phase_dir, "79-PUBLICATION-PACKET.json"), "publication packet")
    observation = pr_observation(publication, fixture_dir, "pr-result-preflight")
    previous = transaction.get("preflight", {})
    if observation.get("main_sha") != previous.get("main_sha") or observation.get("branch_sha") != previous.get("branch_sha") or observation.get("pull_requests") != previous.get("pull_requests"):
        raise TransactionError("immediate PR preflight changed after the approval packet was prepared")

    responses: list[dict[str, Any]] = []
    transaction.update({
        "status": "partial", "partial": True, "operation_state": "in_progress",
        "remote_operations": responses, "readback": None,
    })
    write_json(transaction_path, transaction)
    if fixture_dir is None:
        branch = operation_packet["branch"]
        source = operation_packet["source_sha"]
        if observation.get("branch_sha") is None:
            try:
                push = subprocess.run(
                    ["git", "push", "origin", f"{source}:refs/heads/{branch}"], cwd=ROOT,
                    stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                    text=True, timeout=180, check=False,
                    env={**os.environ, "GIT_TERMINAL_PROMPT": "0"},
                )
            except (OSError, subprocess.TimeoutExpired) as exc:
                raise TransactionError(f"approved non-force push did not complete: {exc}") from exc
            responses.append({"operation": "non-force-push", "exit_code": push.returncode, "output_sha256": sha256(push.stdout.encode())})
            transaction["remote_operations"] = responses
            write_json(transaction_path, transaction)
            if push.returncode:
                raise TransactionError("approved branch push failed; record is partial and must not be retried automatically")
        else:
            responses.append({"operation": "non-force-push", "result": "already-at-approved-source-sha"})
            transaction["remote_operations"] = responses
            write_json(transaction_path, transaction)
        if not observation["pull_requests"]:
            operation = operation_packet["operations"][1]
            created = gh_json(operation["endpoint"], method="POST", fields={
                "title": operation["title"], "head": operation["head"],
                "base": operation["base"], "body": operation["body"],
            })
            responses.append({"operation": "create-pull-request", "number": created.get("number"), "url": created.get("html_url")})
            transaction["remote_operations"] = responses
            write_json(transaction_path, transaction)
    else:
        fixture_result = fixture_json(fixture_dir, "pr-result-readback")
        responses.append({"operation": "fixture-replay", "fixture_sha256": sha256(encoded(fixture_result))})

    # Independent read-back after the authorized operations.
    if fixture_dir:
        readback = fixture_json(fixture_dir, "pr-result-readback")
    else:
        publication, _ = read_json(phase_path(phase_dir, "79-PUBLICATION-PACKET.json"), "publication packet")
        readback = pr_observation(publication, None, "pr-result")
    expected = transaction["expected_readback"]
    prs = readback.get("pull_requests")
    if readback.get("branch_sha") != expected["head_sha"] or not isinstance(prs, list) or len(prs) != 1:
        transaction.update({"status": "partial", "partial": True, "remote_operations": responses, "readback": readback})
        write_json(transaction_path, transaction)
        raise TransactionError("PR branch/creation read-back is incomplete or ambiguous; transaction is partial")
    pr = prs[0]
    if pr.get("head_sha") != expected["head_sha"] or pr.get("base_sha") != expected["base_sha"] or pr.get("head_ref") != expected["head_ref"] or pr.get("base_ref") != expected["base_ref"]:
        transaction.update({"status": "partial", "partial": True, "remote_operations": responses, "readback": readback})
        write_json(transaction_path, transaction)
        raise TransactionError("PR independent read-back differs from the approved packet")
    transaction.update({
        "status": "complete", "partial": False, "remote_operations": responses,
        "operation_state": "complete", "independent_readback": True,
        "readback": {
            "repository": REPOSITORY, "number": pr.get("number"), "url": pr.get("url"),
            "head_sha": pr["head_sha"], "head_ref": pr["head_ref"],
            "base_sha": pr["base_sha"], "base_ref": pr["base_ref"],
            "tree_sha": expected["tree_sha"], "independent": True,
        },
    })
    write_json(transaction_path, transaction)
    return transaction


def live_ci_observation() -> dict[str, Any]:
    remote = run(["git", "remote", "get-url", "origin"])
    if not re.search(r"(?:github\.com[:/]szTheory/relyra(?:\.git)?$)", remote):
        raise TransactionError("origin must identify github.com/szTheory/relyra")
    main_rows = run(["git", "ls-remote", "origin", MAIN_REF]).splitlines()
    if len(main_rows) != 1 or len(main_rows[0].split()) != 2:
        raise TransactionError("remote main did not resolve to one exact ref identity")
    main_sha, main_ref = main_rows[0].split()
    validate_sha(main_sha, "observed main SHA")
    if main_ref != MAIN_REF:
        raise TransactionError("remote main ref identity changed during observation")

    workflow_rows = gh_paginated(f"repos/{REPOSITORY}/actions/workflows", "workflows")
    workflows = [
        {"id": item.get("id"), "path": item.get("path"), "state": item.get("state")}
        for item in workflow_rows
        if item.get("path") in EXPECTED_CI_WORKFLOWS
    ]
    if len(workflows) != len(EXPECTED_CI_WORKFLOWS) or any(
        item.get("state") != "active" or not positive_int(item.get("id"))
        for item in workflows
    ):
        raise TransactionError("both canonical owner workflows must be uniquely enabled with live IDs")
    workflow_ids = {item["id"]: item["path"] for item in workflows}

    run_rows = gh_paginated(
        f"repos/{REPOSITORY}/actions/runs?head_sha={main_sha}", "workflow_runs"
    )
    workflow_runs = []
    for item in run_rows:
        if item.get("head_sha") != main_sha:
            continue
        path = workflow_ids.get(item.get("workflow_id"))
        if path is None:
            continue
        workflow_runs.append({
            "id": item.get("id"), "attempt": item.get("run_attempt"),
            "head_sha": item.get("head_sha"), "head_branch": item.get("head_branch"),
            "path": path, "workflow_id": item.get("workflow_id"),
            "check_suite_id": item.get("check_suite_id"),
            "status": item.get("status"), "conclusion": item.get("conclusion"),
            "run_number": item.get("run_number"), "created_at": item.get("created_at"),
            "html_url": item.get("html_url"),
        })

    workflow_jobs = []
    for workflow_run in workflow_runs:
        run_id = workflow_run["id"]
        attempt = workflow_run["attempt"]
        if not positive_int(run_id) or not positive_int(attempt):
            raise TransactionError("GitHub returned a malformed workflow run identity")
        endpoint = f"repos/{REPOSITORY}/actions/runs/{run_id}"
        if attempt > 1:
            endpoint += f"/attempts/{attempt}"
        jobs = gh_paginated(f"{endpoint}/jobs", "jobs")
        workflow_jobs.extend({
            "id": job.get("id"), "workflow_run_id": run_id, "name": job.get("name"),
            "status": job.get("status"), "conclusion": job.get("conclusion"),
            "html_url": job.get("html_url"),
        } for job in jobs)

    check_rows = gh_paginated(f"repos/{REPOSITORY}/commits/{main_sha}/check-runs", "check_runs")
    run_by_suite: dict[int, list[dict[str, Any]]] = {}
    for workflow_run in workflow_runs:
        suite_id = workflow_run.get("check_suite_id")
        if type(suite_id) is int:
            run_by_suite.setdefault(suite_id, []).append(workflow_run)
    run_by_id = {item["id"]: item for item in workflow_runs}
    job_ids_by_run_name: dict[tuple[int, str], list[int]] = {}
    for job in workflow_jobs:
        if type(job.get("id")) is int and type(job.get("workflow_run_id")) is int:
            job_ids_by_run_name.setdefault((job["workflow_run_id"], job.get("name", "")), []).append(job["id"])

    expected_check_names = {
        name for lane in expected_lanes().values() for name in lane["check_names"]
    } | {FLEET_CONTEXT}
    checks = []
    for check in check_rows:
        if check.get("name") not in expected_check_names:
            continue
        details = check.get("details_url") if isinstance(check.get("details_url"), str) else ""
        identity = re.search(r"/actions/runs/(\d+)(?:/job/(\d+))?", details)
        workflow_run_id = int(identity.group(1)) if identity else None
        workflow_job_id = int(identity.group(2)) if identity and identity.group(2) else None
        if workflow_run_id is None:
            suite = check.get("check_suite") if isinstance(check.get("check_suite"), dict) else {}
            suite_matches = run_by_suite.get(suite.get("id"), [])
            if len(suite_matches) == 1:
                workflow_run_id = suite_matches[0]["id"]
        if workflow_run_id is not None and workflow_job_id is None:
            candidates = job_ids_by_run_name.get((workflow_run_id, check.get("name", "")), [])
            if len(candidates) == 1:
                workflow_job_id = candidates[0]
        owner_run = run_by_id.get(workflow_run_id)
        app = check.get("app") if isinstance(check.get("app"), dict) else {}
        checks.append({
            "id": check.get("id"), "name": check.get("name"),
            "head_sha": check.get("head_sha"), "status": check.get("status"),
            "conclusion": check.get("conclusion"),
            "workflow_path": owner_run.get("path") if owner_run else None,
            "workflow_run_id": workflow_run_id, "workflow_job_id": workflow_job_id,
            "details_url": details, "app_slug": app.get("slug"),
        })

    fleet_checks = [item for item in checks if item.get("name") == FLEET_CONTEXT]
    fleet_state = "absent"
    fleet_context: dict[str, Any] = {"name": FLEET_CONTEXT, "sha": main_sha, "state": fleet_state}
    if len(fleet_checks) == 1:
        check = fleet_checks[0]
        fleet_state = (
            "passed"
            if check.get("status") == "completed" and check.get("conclusion") == "success"
            else check.get("conclusion") or check.get("status") or "pending"
        )
        fleet_context = {
            "name": FLEET_CONTEXT, "sha": main_sha, "state": fleet_state,
            "workflow_run_id": check.get("workflow_run_id"),
            "workflow_job_id": check.get("workflow_job_id"), "check_run_id": check.get("id"),
        }

    return {
        "repository": REPOSITORY, "ref": MAIN_REF, "main_sha": main_sha,
        "enabled_workflows": workflows, "workflow_runs": workflow_runs,
        "workflow_jobs": workflow_jobs, "check_runs": checks,
        "fleet_context": fleet_context,
    }


def wait_for_live_ci(target_sha: str, preflight: dict[str, Any]) -> dict[str, Any]:
    for attempt in range(20):
        current = live_ci_observation()
        if current.get("main_sha") != target_sha:
            raise TransactionError("main moved while waiting for approved CI results")
        _repository, _ref, _paths, lanes = validate_ci_observation(current)
        missing, states = ci_missing(current, lanes)
        if not missing and all(state == "passed" for state in states.values()):
            return current
        owner_runs = [item for item in current["workflow_runs"] if item.get("head_sha") == target_sha]
        if owner_runs and all(item.get("status") == "completed" for item in owner_runs):
            return current
        if attempt < 19:
            time.sleep(15)
    raise TransactionError("approved owner workflow results did not reach a bounded terminal state")


def stage_ci_preflight(phase_dir: pathlib.Path, fixture_dir: pathlib.Path | None) -> dict[str, Any]:
    observation = fixture_json(fixture_dir, "ci-preflight") if fixture_dir else live_ci_observation()
    repository, ref, enabled_paths, lanes = validate_ci_observation(observation)
    receipts = observation.get("receipts")
    if receipts is None and not fixture_dir:
        receipts = previous_receipts(phase_dir)
    joined: dict[str, str] | None = None
    if receipts is not None:
        if not isinstance(receipts, dict):
            raise TransactionError("cross-receipt observations must be an object")
        joined = validate_receipt_join(receipts, observation["main_sha"])

    missing_workflows, lane_states = ci_missing(observation, lanes)
    missing_workflows = sorted(set(missing_workflows))
    if receipts is None:
        raise TransactionError("publication, PR, and merge receipts are required before CI preflight")
    status = "no_action" if not missing_workflows and all(value == "passed" for value in lane_states.values()) else "pending"
    packet = {
        "schema": "phase79-ci-dispatch-packet",
        "version": 1,
        "status": status,
        "target": {"repository": repository, "ref": ref, "sha": observation["main_sha"]},
        "source_join": joined,
        "lane_states": lane_states,
        "missing_owner_runs": missing_workflows,
        "enabled_workflows": sorted(enabled_paths),
        "dispatch": {
            "action": "workflow_dispatch",
            "ref": MAIN_BRANCH,
            "workflows": missing_workflows,
            "requests": [
                {
                    "workflow_id": item["id"],
                    "path": item["path"],
                    "endpoint": f"repos/{REPOSITORY}/actions/workflows/{item['id']}/dispatches",
                    "method": "POST",
                    "body": {"ref": MAIN_BRANCH},
                }
                for item in sorted(observation["enabled_workflows"], key=lambda row: row["path"])
                if item["path"] in missing_workflows
            ],
            "performed": False,
        },
        "approval": None,
        "observed_evidence": {
            "enabled_workflows": observation["enabled_workflows"],
            "workflow_runs": observation["workflow_runs"],
            "workflow_jobs": observation["workflow_jobs"],
            "check_runs": observation["check_runs"],
            "fleet_context": observation["fleet_context"],
        },
        "mutation_authorized": False,
    }
    packet["packet_sha256"] = ci_packet_digest(packet)
    validate_ci_dispatch_packet(packet)
    write_json(phase_path(phase_dir, "79-CI-DISPATCH-PACKET.json"), packet)
    return packet


def verify_ci_result(phase_dir: pathlib.Path, fixture_dir: pathlib.Path | None) -> dict[str, Any]:
    packet_path = phase_path(phase_dir, "79-CI-DISPATCH-PACKET.json")
    packet, packet_bytes = read_json(packet_path, "CI dispatch packet")
    validate_ci_dispatch_packet(packet)
    approval = packet.get("approval")
    if packet["status"] == "no_action" and (
        approval is not None
        or packet.get("missing_owner_runs") != []
        or packet.get("dispatch", {}).get("workflows") != []
        or packet.get("dispatch", {}).get("requests") != []
        or packet.get("dispatch", {}).get("performed") is not False
        or not isinstance(packet.get("lane_states"), dict)
        or len(packet["lane_states"]) != 9
        or any(value != "passed" for value in packet["lane_states"].values())
    ):
        raise TransactionError("no-action packet must prove all nine lanes and contain no dispatch authorization")
    if packet["status"] == "pending":
        requests = packet.get("dispatch", {}).get("requests")
        if (
            not isinstance(approval, dict)
            or approval.get("checkpoint_id") != "79-10-ci-dispatch"
            or approval.get("packet_sha256") != packet["packet_sha256"]
            or approval.get("response") != "approved"
            or approval.get("scope") != requests
            or not isinstance(requests, list)
            or not requests
        ):
            raise TransactionError("pending CI dispatch requires explicit approval bound to this packet digest")

    if fixture_dir:
        preflight_receipts = fixture_json(fixture_dir, "ci-result-preflight").get("receipts")
        if preflight_receipts is None:
            preflight_receipts = fixture_json(fixture_dir, "ci-result").get("receipts")
    else:
        preflight_receipts = previous_receipts(phase_dir)
    joined = validate_receipt_join(preflight_receipts, packet["target"]["sha"])
    if packet.get("source_join") != joined:
        raise TransactionError("CI dispatch packet does not join to the exact publication, PR, and merge receipts")

    operation_responses: list[dict[str, Any]] = []
    dispatch_preflight: dict[str, Any] | None = None
    if packet["status"] == "pending":
        dispatch_preflight = fixture_json(fixture_dir, "ci-result-preflight") if fixture_dir else live_ci_observation()
        preflight_repo, preflight_ref, _paths, _lanes = validate_ci_observation(dispatch_preflight)
        if (
            preflight_repo != packet["target"].get("repository")
            or preflight_ref != packet["target"].get("ref")
            or dispatch_preflight.get("main_sha") != packet["target"].get("sha")
            or dispatch_preflight.get("enabled_workflows") != packet.get("observed_evidence", {}).get("enabled_workflows")
        ):
            raise TransactionError("immediate CI dispatch preflight differs from the approved SHA or workflow IDs")
        still_missing, _states = ci_missing(dispatch_preflight, expected_lanes())
        if still_missing != packet.get("dispatch", {}).get("workflows"):
            raise TransactionError("immediate CI dispatch preflight changed the exact missing workflow set")
        requests = packet["dispatch"]["requests"]
        pending_receipt = {
            "schema": "phase79-main-ci-receipt", "version": 1,
            "status": "partial", "operation_state": "dispatch_in_progress",
            "target": packet["target"],
            "approved_packet_sha256": packet["packet_sha256"],
            "approval": approval, "dispatch_requests": requests,
            "dispatch_responses": operation_responses,
            "independent_readback": False,
        }
        write_json(phase_path(phase_dir, "79-MAIN-CI-RECEIPT.json"), pending_receipt)
        if fixture_dir:
            dispatch_fixture = fixture_json(fixture_dir, "ci-dispatch")
            if dispatch_fixture.get("requests") != requests:
                raise TransactionError("fixture dispatch requests differ from the approved packet")
            responses = dispatch_fixture.get("responses")
            if not isinstance(responses, list) or len(responses) != len(requests):
                raise TransactionError("fixture dispatch response set is incomplete")
            for request, response in zip(requests, responses, strict=True):
                if (
                    not isinstance(response, dict)
                    or response.get("workflow_id") != request.get("workflow_id")
                    or response.get("status_code") != 204
                ):
                    raise TransactionError("fixture dispatch response is not an exact successful owner dispatch")
            operation_responses = responses
            pending_receipt["dispatch_responses"] = operation_responses
            write_json(phase_path(phase_dir, "79-MAIN-CI-RECEIPT.json"), pending_receipt)
        else:
            for request in requests:
                try:
                    output = run(
                        [
                            "gh", "api", "--method", request["method"], request["endpoint"],
                            "-f", f"ref={request['body']['ref']}",
                        ],
                        timeout=45,
                    )
                except TransactionError as exc:
                    partial = {
                        "schema": "phase79-main-ci-receipt", "version": 1,
                        "status": "partial", "target": packet["target"],
                        "dispatch_packet_sha256": packet["packet_sha256"],
                        "dispatch_responses": operation_responses,
                        "failed_request": request,
                        "failure": str(exc), "independent_readback": False,
                    }
                    write_json(phase_path(phase_dir, "79-MAIN-CI-RECEIPT.json"), partial)
                    raise TransactionError("CI dispatch was partial; receipt is blocked and no retry is automatic") from exc
                operation_responses.append({
                    "workflow_id": request["workflow_id"], "endpoint": request["endpoint"],
                    "method": request["method"], "body": request["body"],
                    "accepted": True, "response_sha256": sha256(output.encode()),
                })
                pending_receipt["dispatch_responses"] = operation_responses
                write_json(phase_path(phase_dir, "79-MAIN-CI-RECEIPT.json"), pending_receipt)
        write_json(
            phase_path(phase_dir, "79-MAIN-CI-RECEIPT.json"),
            {
                "schema": "phase79-main-ci-receipt", "version": 1,
                "status": "pending-readback", "target": packet["target"],
                "approved_packet_sha256": packet["packet_sha256"],
                "approval": approval, "dispatch_requests": requests,
                "dispatch_responses": operation_responses,
                "independent_readback": False,
            },
        )

    observation = fixture_json(fixture_dir, "ci-result") if fixture_dir else (
        wait_for_live_ci(packet["target"]["sha"], dispatch_preflight)
        if packet["status"] == "pending" and dispatch_preflight is not None
        else live_ci_observation()
    )
    repository, ref, _enabled, lanes = validate_ci_observation(observation)
    if repository != packet["target"].get("repository") or ref != packet["target"].get("ref") or observation["main_sha"] != packet["target"].get("sha"):
        raise TransactionError("final CI observation does not match the prepared packet target")
    if packet.get("source_join") is not None:
        final_receipts = observation.get("receipts") if fixture_dir else None
        if final_receipts is None:
            final_receipts = previous_receipts(phase_dir)
        validate_receipt_join(final_receipts, observation["main_sha"])
    results: dict[str, dict[str, Any]] = {}
    for lane, lane_info in sorted(lanes.items()):
        owner_path = lane_info["owner"]
        matching = [
            item for item in observation["check_runs"]
            if item.get("name") in lane_info["check_names"] and item.get("head_sha") == observation["main_sha"]
            and item.get("workflow_path") == owner_path and item.get("status") == "completed"
            and item.get("conclusion") == "success"
        ]
        by_name = {name: [item for item in matching if item.get("name") == name] for name in lane_info["check_names"]}
        if any(len(rows) != 1 for rows in by_name.values()):
            raise TransactionError(f"lane {lane} lacks one passing read-back for every owner check name")
        evidence = []
        for name in lane_info["check_names"]:
            check = by_name[name][0]
            workflow_id, job_id, check_id = check.get("workflow_run_id"), check.get("workflow_job_id"), check.get("id")
            if not all(positive_int(identity) for identity in (workflow_id, job_id, check_id)):
                raise TransactionError(f"lane {lane} is missing workflow, job, or check identity")
            run = next((item for item in observation["workflow_runs"] if item.get("id") == workflow_id), None)
            if run is None or run.get("path") != owner_path or run.get("status") != "completed" or run.get("conclusion") != "success":
                raise TransactionError(f"lane {lane} does not join to a passing owner workflow run")
            job = next((item for item in observation["workflow_jobs"] if item.get("id") == job_id), None)
            if job is None or job.get("workflow_run_id") != workflow_id or job.get("status") != "completed" or job.get("conclusion") != "success":
                raise TransactionError(f"lane {lane} does not join to a passing owner workflow job")
            evidence.append({"check_name": name, "workflow_run_id": workflow_id, "job_id": job_id, "check_run_id": check_id, "sha": observation["main_sha"], "conclusion": "success"})
        results[lane] = {"owner": owner_path, "evidence": evidence}
    fleet = observation["fleet_context"]
    if fleet.get("state") != "passed" or not all(positive_int(fleet.get(key)) for key in ("workflow_run_id", "workflow_job_id", "check_run_id")):
        raise TransactionError("fleet-proxy-e2e lacks same-SHA passing workflow, job, and check identities")
    fleet_run = next((item for item in observation["workflow_runs"] if item.get("id") == fleet["workflow_run_id"]), None)
    fleet_check = next((item for item in observation["check_runs"] if item.get("id") == fleet["check_run_id"]), None)
    fleet_job = next((item for item in observation["workflow_jobs"] if item.get("id") == fleet["workflow_job_id"]), None)
    if fleet_run is None or fleet_run.get("path") != ".github/workflows/fleet-proxy-e2e.yml" or fleet_run.get("status") != "completed" or fleet_run.get("conclusion") != "success":
        raise TransactionError("fleet context does not join to a passing owner workflow run")
    if fleet_check is None or fleet_check.get("workflow_run_id") != fleet["workflow_run_id"] or fleet_check.get("workflow_job_id") != fleet["workflow_job_id"]:
        raise TransactionError("fleet context check/job identity does not join to its owner run")
    if fleet_job is None or fleet_job.get("workflow_run_id") != fleet["workflow_run_id"] or fleet_job.get("status") != "completed" or fleet_job.get("conclusion") != "success":
        raise TransactionError("fleet context does not join to a passing owner workflow job")
    dispatch_run_identities = []
    if packet["status"] == "pending":
        assert dispatch_preflight is not None
        before = {
            (item.get("path"), item.get("id"), item.get("attempt"))
            for item in dispatch_preflight.get("workflow_runs", [])
        }
        for workflow_path in packet["dispatch"]["workflows"]:
            fresh = [
                item for item in observation["workflow_runs"]
                if item.get("path") == workflow_path
                and (item.get("path"), item.get("id"), item.get("attempt")) not in before
                and item.get("status") == "completed"
                and item.get("conclusion") == "success"
            ]
            if len(fresh) != 1:
                raise TransactionError(f"approved dispatch lacks one new passing owner run for {workflow_path}")
            dispatch_run_identities.append({
                "path": workflow_path, "id": fresh[0]["id"], "attempt": fresh[0]["attempt"],
                "head_sha": fresh[0]["head_sha"],
            })
    receipt = {
        "schema": "phase79-main-ci-receipt", "version": 1, "status": "complete",
        "target": {"repository": repository, "ref": ref, "sha": observation["main_sha"]},
        "source_join": packet.get("source_join"),
        "dispatch_packet_bytes_sha256": sha256(packet_bytes),
        "approved_packet_sha256": packet["packet_sha256"],
        "approval": approval if packet["status"] == "pending" else None,
        "dispatch_requests": packet.get("dispatch", {}).get("requests", []),
        "dispatch_responses": operation_responses,
        "dispatch_run_identities": dispatch_run_identities,
        "lanes": results,
        "fleet_context": {
            "name": FLEET_CONTEXT, "sha": observation["main_sha"], "state": "passed",
            "workflow_run_id": fleet["workflow_run_id"], "job_id": fleet["workflow_job_id"], "check_run_id": fleet["check_run_id"],
        },
        "independent_readback": True,
    }
    write_json(phase_path(phase_dir, "79-MAIN-CI-RECEIPT.json"), receipt)
    return receipt


def verify_publication(phase_dir: pathlib.Path, fixture_dir: pathlib.Path | None = None) -> dict[str, Any]:
    packet = phase_path(phase_dir, "79-PUBLICATION-PACKET.json")
    if not packet.is_file():
        raise TransactionError("publication packet is missing")
    command = ["python3", str(ROOT / "scripts/prepare_phase79_publication.py"), "--verify", str(packet), "--phase-dir", str(phase_dir)]
    if fixture_dir:
        command.extend(["--fixture-dir", str(fixture_dir)])
    result = run(command)
    return {"stage": "publication", "status": "verified", "output": result[-2000:]}


def merge_packet_digest(packet: dict[str, Any]) -> str:
    payload = {key: value for key, value in packet.items() if key not in {"approval", "packet_sha256"}}
    return approval_digest(payload)


def valid_gate_records(records: Any) -> bool:
    expected = [
        "mix qa", "mix test --warnings-as-errors", "mix ci.security",
        "mix format --check-formatted",
    ]
    return (
        isinstance(records, list)
        and len(records) == len(expected)
        and [item.get("command") for item in records if isinstance(item, dict)] == expected
        and all(isinstance(item, dict) and type(item.get("exit_code")) is int and item["exit_code"] == 0 for item in records)
    )


def validate_merge_preflight_observation(
    observation: dict[str, Any], publication: dict[str, Any], pr_transaction: dict[str, Any]
) -> dict[str, Any]:
    pr_readback = pr_transaction.get("readback")
    number = pr_readback.get("number") if isinstance(pr_readback, dict) else None
    if observation.get("repository") != REPOSITORY or observation.get("main_sha") != publication.get("base_sha"):
        raise TransactionError("merge preflight repository or protected main SHA differs from publication")
    if not positive_int(number):
        raise TransactionError("completed PR transaction is missing the exact PR number")
    pr = observation.get("pull_request")
    if not isinstance(pr, dict) or (
        pr.get("number") != number
        or pr.get("state") != "open"
        or pr.get("merged") is not False
        or pr.get("head_sha") != publication.get("source_sha")
        or pr.get("base_sha") != publication.get("base_sha")
        or pr.get("head_ref") != publication.get("branch", {}).get("name")
        or pr.get("base_ref") != MAIN_BRANCH
        or pr.get("draft") is True
        or pr.get("mergeable") is not True
    ):
        raise TransactionError("live PR head/base/state/mergeability differs from the exact candidate")
    if observation.get("repository_settings", {}).get("allow_merge_commit") is not True:
        raise TransactionError("repository does not permit the required normal merge method")
    test = observation.get("synthetic_test")
    if not isinstance(test, dict) or (
        not re.fullmatch(r"[0-9a-f]{40}", str(test.get("sha", "")))
        or test.get("base_sha") != publication.get("base_sha")
        or test.get("head_sha") != publication.get("source_sha")
        or test.get("tree_sha") != publication.get("source_tree_sha")
        or test.get("parents") != [publication.get("base_sha"), publication.get("source_sha")]
    ):
        raise TransactionError("synthetic PR merge tree/topology differs from the isolated candidate proof")

    review = observation.get("review_evidence")
    if not isinstance(review, dict):
        raise TransactionError("merge preflight is missing the required review policy read-back")
    required_reviews = review.get("required_approvals")
    approved_reviews = review.get("approved_reviews")
    if (
        type(required_reviews) is not int
        or required_reviews < 0
        or type(approved_reviews) is not int
        or approved_reviews < required_reviews
        or review.get("changes_requested") is not False
    ):
        raise TransactionError("required PR review condition is not satisfied")

    contexts = observation.get("required_contexts")
    checks = observation.get("required_checks")
    if not isinstance(contexts, list) or not contexts or not isinstance(checks, list):
        raise TransactionError("merge preflight has no complete required-check inventory")
    if len(contexts) != len(set(contexts)) or any(not isinstance(item, str) or not item for item in contexts):
        raise TransactionError("required-check context list is malformed or ambiguous")
    checks_by_name = {name: [] for name in contexts}
    for check in checks:
        if not isinstance(check, dict) or check.get("name") not in checks_by_name:
            raise TransactionError("merge preflight contains an unexpected required check")
        checks_by_name[check["name"]].append(check)
    for name in contexts:
        rows = checks_by_name[name]
        if len(rows) != 1:
            raise TransactionError(f"required check {name} is absent or ambiguous")
        check = rows[0]
        if (
            check.get("head_sha") != test["sha"]
            or check.get("status") != "completed"
            or check.get("conclusion") != "success"
            or check.get("run_status") != "completed"
            or check.get("run_conclusion") != "success"
            or check.get("job_status") != "completed"
            or check.get("job_conclusion") != "success"
            or check.get("workflow_path") not in EXPECTED_CI_WORKFLOWS
            or not all(positive_int(check.get(key)) for key in ("workflow_run_id", "workflow_job_id", "check_run_id"))
        ):
            raise TransactionError(f"required check {name} lacks passing same-SHA owner run/job/check evidence")
    if not valid_gate_records(observation.get("local_gates")):
        raise TransactionError("merge preflight lacks all four passing isolated source gates")
    return {
        "repository": REPOSITORY,
        "main_sha": publication["base_sha"],
        "pr_number": number,
        "head_sha": publication["source_sha"],
        "base_sha": publication["base_sha"],
        "tree_sha": publication["source_tree_sha"],
        "synthetic_test": test,
        "required_contexts": contexts,
        "required_checks": checks,
        "review_evidence": review,
        "repository_settings": observation["repository_settings"],
        "local_gates": observation["local_gates"],
    }


def live_merge_preflight_observation(
    phase_dir: pathlib.Path,
    publication: dict[str, Any],
    pr_transaction: dict[str, Any],
    *,
    run_gates: bool = True,
) -> dict[str, Any]:
    capture, _ = read_json(phase_path(phase_dir, "79-PROTECTION-CAPTURE.json"), "protection capture")
    if capture.get("capture_status") != "complete" or capture.get("main_sha") != publication.get("base_sha") or not isinstance(capture.get("resource"), dict):
        raise TransactionError("same-ref protection capture is incomplete or stale; merge review requirements are unknown")
    pr_readback = pr_transaction.get("readback")
    number = pr_readback.get("number") if isinstance(pr_readback, dict) else None
    if not positive_int(number):
        raise TransactionError("PR transaction has no verified pull request number")
    pr = gh_json(f"repos/{REPOSITORY}/pulls/{number}")
    reviews = gh_json(f"repos/{REPOSITORY}/pulls/{number}/reviews")
    if not isinstance(reviews, list):
        raise TransactionError("GitHub PR review inventory is incomplete")
    latest_by_user: dict[str, dict[str, Any]] = {}
    for review in reviews:
        user = review.get("user", {}).get("login") if isinstance(review.get("user"), dict) else None
        if isinstance(user, str):
            prior = latest_by_user.get(user)
            if prior is None or str(review.get("submitted_at", "")) > str(prior.get("submitted_at", "")):
                latest_by_user[user] = review
    review_settings = capture.get("resource", {}).get("required_pull_request_reviews")
    if not isinstance(review_settings, dict) or type(review_settings.get("required_approving_review_count")) is not int:
        raise TransactionError("complete protection capture lacks a trustworthy review requirement")
    review_evidence = {
        "required_approvals": review_settings["required_approving_review_count"],
        "approved_reviews": sum(item.get("state") == "APPROVED" for item in latest_by_user.values()),
        "changes_requested": any(item.get("state") == "CHANGES_REQUESTED" for item in latest_by_user.values()),
        "review_ids": sorted(item.get("id") for item in latest_by_user.values() if type(item.get("id")) is int),
    }
    remote = run(["git", "remote", "get-url", "origin"])
    pull_ref = f"refs/pull/{number}/merge"
    with tempfile.TemporaryDirectory(prefix="relyra-phase79-pr-merge-test-") as temporary:
        checkout = pathlib.Path(temporary) / "checkout"
        result = subprocess.run(
            ["git", "clone", "--shared", "--no-checkout", str(ROOT), str(checkout)],
            cwd=ROOT, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
            text=True, timeout=180, check=False,
        )
        if result.returncode:
            raise TransactionError(f"cannot create isolated PR test checkout: {result.stdout[-2000:]}")
        run(["git", "remote", "add", "publication", remote], cwd=checkout)
        run(["git", "fetch", "--no-tags", "publication", pull_ref], cwd=checkout, timeout=180)
        test_sha = run(["git", "rev-parse", "FETCH_HEAD"], cwd=checkout)
        test_tree = run(["git", "rev-parse", f"{test_sha}^{{tree}}"], cwd=checkout)
        parents = run(["git", "show", "-s", "--format=%P", test_sha], cwd=checkout).split()
        test_identity = {
            "sha": test_sha, "tree_sha": test_tree,
            "base_sha": publication["base_sha"], "head_sha": publication["source_sha"],
            "parents": parents,
        }
    policy = capture["resource"].get("required_status_checks")
    contexts = policy.get("contexts") if isinstance(policy, dict) else None
    if not isinstance(contexts, list):
        raise TransactionError("complete protection capture lacks required status-check contexts")
    checks = gh_paginated(f"repos/{REPOSITORY}/commits/{test_sha}/check-runs", "check_runs")
    workflows = gh_paginated(f"repos/{REPOSITORY}/actions/workflows", "workflows")
    workflow_path_by_id = {item.get("id"): item.get("path") for item in workflows if item.get("state") == "active"}
    required_checks = []
    for check in checks:
        if check.get("name") not in contexts:
            continue
        details = check.get("details_url") if isinstance(check.get("details_url"), str) else ""
        match = re.search(r"/actions/runs/(\d+)(?:/job/(\d+))?", details)
        if not match or not match.group(2):
            raise TransactionError(f"required check {check.get('name')} lacks direct run/job identity")
        run_id, job_id = int(match.group(1)), int(match.group(2))
        run_record = gh_json(f"repos/{REPOSITORY}/actions/runs/{run_id}")
        workflow_path = workflow_path_by_id.get(run_record.get("workflow_id"))
        jobs = gh_paginated(f"repos/{REPOSITORY}/actions/runs/{run_id}/jobs", "jobs")
        job = next((item for item in jobs if item.get("id") == job_id), None)
        required_checks.append({
            "name": check.get("name"), "head_sha": check.get("head_sha"),
            "status": check.get("status"), "conclusion": check.get("conclusion"),
            "workflow_path": workflow_path, "workflow_run_id": run_id,
            "workflow_job_id": job_id, "check_run_id": check.get("id"),
            "run_status": run_record.get("status"), "run_conclusion": run_record.get("conclusion"),
            "job_status": job.get("status") if job else None,
            "job_conclusion": job.get("conclusion") if job else None,
        })
    main_before = run(["git", "ls-remote", "origin", MAIN_REF]).split()
    if len(main_before) != 2 or main_before[0] != publication["base_sha"]:
        raise TransactionError("protected main moved during merge preflight")
    return {
        "repository": REPOSITORY, "main_sha": main_before[0],
        "pull_request": {
            "number": pr.get("number"), "state": pr.get("state"), "merged": pr.get("merged"),
            "head_sha": pr.get("head", {}).get("sha"), "base_sha": pr.get("base", {}).get("sha"),
            "head_ref": pr.get("head", {}).get("ref"), "base_ref": pr.get("base", {}).get("ref"),
            "draft": pr.get("draft"), "mergeable": pr.get("mergeable"),
        },
        "repository_settings": {"allow_merge_commit": merge_allowed()},
        "synthetic_test": test_identity, "required_contexts": contexts,
        "required_checks": required_checks, "review_evidence": review_evidence,
        "local_gates": run_pr_local_gates(publication["source_sha"]) if run_gates else None,
    }


def stage_merge_preflight(phase_dir: pathlib.Path, fixture_dir: pathlib.Path | None) -> dict[str, Any]:
    publication, publication_bytes = read_json(phase_path(phase_dir, "79-PUBLICATION-PACKET.json"), "publication packet")
    pr_transaction, pr_bytes = read_json(phase_path(phase_dir, "79-PR-TRANSACTION.json"), "PR transaction")
    if publication.get("status") != "ready" or publication.get("blockers") or pr_transaction.get("status") != "complete":
        raise TransactionError("publication and independently verified PR receipt must be complete before merge preflight")
    expected_pr_packet = make_pr_operation_packet(publication)
    pr_approval = pr_transaction.get("approval")
    if (
        pr_transaction.get("operation_packet") != expected_pr_packet
        or pr_transaction.get("packet_sha256") != approval_digest(expected_pr_packet)
        or not isinstance(pr_approval, dict)
        or pr_approval.get("checkpoint_id") != "79-08-pr-create"
        or pr_approval.get("response") != "approved"
        or pr_approval.get("packet_sha256") != approval_digest(expected_pr_packet)
        or pr_approval.get("scope") != expected_pr_packet["operations"]
        or not isinstance(pr_transaction.get("readback"), dict)
        or pr_transaction["readback"].get("independent") is not True
    ):
        raise TransactionError("PR transaction lacks a valid exact proposal approval and read-back")
    observation = (
        fixture_json(fixture_dir, "merge-preflight")
        if fixture_dir
        else live_merge_preflight_observation(phase_dir, publication, pr_transaction)
    )
    validated = validate_merge_preflight_observation(observation, publication, pr_transaction)
    operation = {
        "method": "PUT", "endpoint": f"repos/{REPOSITORY}/pulls/{validated['pr_number']}/merge",
        "body": {
            "sha": publication["source_sha"], "merge_method": "merge",
            "commit_title": "v1.11 First-Adopter Twin closeout",
        },
    }
    packet = {
        "schema": "phase79-merge-packet", "version": 1, "status": "ready",
        "repository": REPOSITORY, "pr_number": validated["pr_number"],
        "source_sha": publication["source_sha"], "base_sha": publication["base_sha"],
        "tree_sha": publication["source_tree_sha"],
        "publication_packet_sha256": sha256(publication_bytes),
        "pr_transaction_sha256": sha256(pr_bytes),
        "preflight": validated, "preflight_fingerprint": approval_digest(validated),
        "operation": operation,
        "rollback_limit": "a separate reviewed revert PR; no alternate merge method or admin bypass",
        "approval": None,
    }
    packet["packet_sha256"] = merge_packet_digest(packet)
    write_json(phase_path(phase_dir, "79-MERGE-PACKET.json"), packet)
    return packet


def verify_merged_commit(source_sha: str, base_sha: str, expected_tree: str, main_sha: str) -> dict[str, Any]:
    remote = run(["git", "remote", "get-url", "origin"])
    with tempfile.TemporaryDirectory(prefix="relyra-phase79-merged-main-") as temporary:
        checkout = pathlib.Path(temporary) / "checkout"
        result = subprocess.run(
            ["git", "clone", "--shared", "--no-checkout", str(ROOT), str(checkout)],
            cwd=ROOT, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
            text=True, timeout=180, check=False,
        )
        if result.returncode:
            raise TransactionError(f"cannot create isolated merged-main checkout: {result.stdout[-2000:]}")
        run(["git", "remote", "add", "publication", remote], cwd=checkout)
        run(["git", "fetch", "--no-tags", "publication", main_sha], cwd=checkout, timeout=180)
        run(["git", "checkout", "--detach", main_sha], cwd=checkout)
        tree_sha = run(["git", "rev-parse", "HEAD^{tree}"], cwd=checkout)
        parents = run(["git", "show", "-s", "--format=%P", "HEAD"], cwd=checkout).split()
        if tree_sha != expected_tree or parents != [base_sha, source_sha]:
            raise TransactionError("merged main tree/parent order differs from the approved normal merge")
        if subprocess.run(
            ["git", "merge-base", "--is-ancestor", source_sha, "HEAD"], cwd=checkout, check=False
        ).returncode:
            raise TransactionError("original source head is not ancestral to resulting main")
        deps = ROOT / "deps"
        if deps.exists() and not (checkout / "deps").exists():
            (checkout / "deps").symlink_to(deps, target_is_directory=True)
        env = {"ASDF_ELIXIR_VERSION": "1.19.5-otp-28", "ASDF_ERLANG_VERSION": "28.4.1", "MIX_ENV": "test"}
        try:
            result = subprocess.run(
                ["mix", "ci.evidence"], cwd=checkout, stdin=subprocess.DEVNULL,
                stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True,
                timeout=1800, check=False, env={**os.environ, **env, "GIT_TERMINAL_PROMPT": "0"},
            )
        except (OSError, subprocess.TimeoutExpired) as exc:
            raise TransactionError(f"merged-main provenance owner did not complete: {exc}") from exc
        if result.returncode:
            raise TransactionError(f"merged-main mix ci.evidence failed: {result.stdout[-4000:].strip()}")
        return {
            "main_sha": main_sha, "tree_sha": tree_sha, "parents": parents,
            "source_ancestor": True, "provenance_owner": "mix ci.evidence",
            "provenance_status": "passed", "provenance_output_sha256": sha256(result.stdout.encode()),
        }


def stage_merge_result(phase_dir: pathlib.Path, fixture_dir: pathlib.Path | None) -> dict[str, Any]:
    packet_path = phase_path(phase_dir, "79-MERGE-PACKET.json")
    packet, packet_bytes = read_json(packet_path, "merge packet")
    operation = packet.get("operation")
    approval = packet.get("approval")
    if packet.get("status") != "ready" or packet.get("packet_sha256") != merge_packet_digest(packet):
        raise TransactionError("merge packet is malformed or its digest is stale")
    if (
        not isinstance(operation, dict)
        or not isinstance(approval, dict)
        or approval.get("checkpoint_id") != "79-09-main-merge"
        or approval.get("packet_sha256") != packet.get("packet_sha256")
        or approval.get("response") != "approved"
        or approval.get("scope") != operation
    ):
        raise TransactionError("main merge requires a distinct approval bound to its exact packet and operation")
    publication, publication_bytes = read_json(phase_path(phase_dir, "79-PUBLICATION-PACKET.json"), "publication packet")
    pr_transaction, pr_bytes = read_json(phase_path(phase_dir, "79-PR-TRANSACTION.json"), "PR transaction")
    if (
        packet.get("publication_packet_sha256") != sha256(publication_bytes)
        or packet.get("pr_transaction_sha256") != sha256(pr_bytes)
        or packet.get("source_sha") != publication.get("source_sha")
        or packet.get("base_sha") != publication.get("base_sha")
        or packet.get("tree_sha") != publication.get("source_tree_sha")
    ):
        raise TransactionError("merge packet no longer joins to the frozen publication and PR receipts")
    observation = (
        fixture_json(fixture_dir, "merge-result-preflight")
        if fixture_dir
        else live_merge_preflight_observation(phase_dir, publication, pr_transaction, run_gates=False)
    )
    if not fixture_dir:
        observation["local_gates"] = packet.get("preflight", {}).get("local_gates")
    validated = validate_merge_preflight_observation(observation, publication, pr_transaction)
    if approval_digest(validated) != packet.get("preflight_fingerprint"):
        raise TransactionError("immediate merge preflight changed after exact approval")

    if fixture_dir:
        result = fixture_json(fixture_dir, "merge-result")
        response = result.get("response")
        readback = result.get("readback")
        provenance = result.get("provenance")
    else:
        partial = {
            "schema": "phase79-merge-receipt", "version": 1,
            "status": "partial", "source_head_sha": packet["source_sha"],
            "base_sha": packet["base_sha"], "tree_sha": packet["tree_sha"],
            "packet_sha256": packet["packet_sha256"], "approval": approval,
            "operation_state": "in_progress", "independent_readback": False,
        }
        write_json(phase_path(phase_dir, "79-MERGE-RECEIPT.json"), partial)
        response = gh_json(operation["endpoint"], method="PUT", fields={
            "sha": operation["body"]["sha"],
            "merge_method": operation["body"]["merge_method"],
            "commit_title": operation["body"]["commit_title"],
        })
        partial["response"] = response
        partial["operation_state"] = "response-readback-pending"
        write_json(phase_path(phase_dir, "79-MERGE-RECEIPT.json"), partial)
        if not isinstance(response, dict) or response.get("merged") is not True:
            raise TransactionError("GitHub did not confirm the approved normal merge; receipt is partial")
        current_main = run(["git", "ls-remote", "origin", MAIN_REF]).split()
        if len(current_main) != 2 or current_main[0] != response.get("sha"):
            raise TransactionError("GitHub merge response is not the current main ref")
        merge_detail = gh_json(f"repos/{REPOSITORY}/pulls/{packet['pr_number']}")
        topology = verify_merged_commit(packet["source_sha"], packet["base_sha"], packet["tree_sha"], response["sha"])
        readback = {
            "main_sha": current_main[0], "tree_sha": topology["tree_sha"],
            "parents": topology["parents"], "pr_number": packet["pr_number"],
            "pr_head_sha": merge_detail.get("head", {}).get("sha"),
            "pr_base_sha": merge_detail.get("base", {}).get("sha"),
            "pr_merged": merge_detail.get("merged"),
            "merge_commit_sha": merge_detail.get("merge_commit_sha"),
            "source_ancestor": topology["source_ancestor"],
        }
        provenance = topology

    if not isinstance(response, dict) or response.get("merged") is not True or not isinstance(readback, dict):
        raise TransactionError("merge result fixture lacks a successful API response and independent read-back")
    result_sha = validate_sha(response.get("sha") if isinstance(response, dict) else None, "merge response SHA")
    readback_sha = validate_sha(readback.get("main_sha") if isinstance(readback, dict) else None, "merge read-back SHA")
    if (
        readback_sha != result_sha
        or readback.get("tree_sha") != packet.get("tree_sha")
        or readback.get("parents") != [packet.get("base_sha"), packet.get("source_sha")]
        or readback.get("pr_number") != packet.get("pr_number")
        or readback.get("pr_head_sha") != packet.get("source_sha")
        or readback.get("pr_base_sha") != result_sha
        or readback.get("pr_merged") is not True
        or readback.get("merge_commit_sha") != response.get("sha")
        or readback.get("source_ancestor") is not True
    ):
        partial = {
            "schema": "phase79-merge-receipt", "version": 1,
            "status": "partial", "source_head_sha": packet["source_sha"],
            "base_sha": packet["base_sha"], "tree_sha": packet["tree_sha"],
            "packet_sha256": packet["packet_sha256"], "approval": approval,
            "response": response, "readback": readback, "independent_readback": False,
        }
        write_json(phase_path(phase_dir, "79-MERGE-RECEIPT.json"), partial)
        raise TransactionError("merge read-back differs from the approved packet; receipt is partial")
    if not isinstance(provenance, dict) or provenance.get("provenance_status") != "passed" or provenance.get("provenance_owner") != "mix ci.evidence":
        raise TransactionError("merged main lacks the provenance owner proof")
    receipt = {
        "schema": "phase79-merge-receipt", "version": 1, "status": "complete",
        "repository": REPOSITORY, "pr_number": packet["pr_number"],
        "source_head_sha": packet["source_sha"], "base_sha": packet["base_sha"],
        "tree_sha": packet["tree_sha"], "main_sha": readback["main_sha"],
        "parents": readback["parents"], "merge_method": "merge",
        "packet_sha256": packet["packet_sha256"], "approval": approval,
        "response": {"sha": response["sha"], "merged": True},
        "readback": readback, "provenance": provenance,
        "independent_readback": True,
    }
    write_json(phase_path(phase_dir, "79-MERGE-RECEIPT.json"), receipt)
    return receipt


def verify_batch_artifacts(phase_dir: pathlib.Path) -> str:
    command = [
        "python3", str(ROOT / "scripts/prepare_phase79_batch.py"),
        "--capture", str(phase_path(phase_dir, "79-PROTECTION-CAPTURE.json")),
        "--inventory", str(phase_path(phase_dir, "79-INVENTORY.json")),
        "--output-dir", str(phase_dir), "--verify",
    ]
    return run(command)


def inventory_is_green(inventory: dict[str, Any], sha: str) -> bool:
    observation = inventory.get("observation", {})
    collection = inventory.get("collection", {})
    lanes = inventory.get("github", {}).get("mandatory_lanes")
    if (
        observation.get("repository") != REPOSITORY
        or observation.get("ref") != MAIN_REF
        or observation.get("main_sha") != sha
        or observation.get("revalidated_sha") != sha
        or collection.get("complete") is not True
        or collection.get("readiness") != "green"
        or not isinstance(lanes, dict)
        or len(lanes) != 9
    ):
        return False
    return all(
        isinstance(record, dict)
        and record.get("state") == "passed"
        and record.get("sha") == sha
        for record in lanes.values()
    )


def protection_snapshot_hashes(phase_dir: pathlib.Path) -> dict[str, str]:
    names = {
        "capture_sha256": "79-PROTECTION-CAPTURE.json",
        "inventory_sha256": "79-INVENTORY.json",
        "desired_sha256": "79-PROTECTION-DESIRED.json",
        "rollback_sha256": "79-PROTECTION-ROLLBACK.json",
        "batch_sha256": "79-REMOTE-BATCH.md",
    }
    hashes = {}
    for key, name in names.items():
        path = phase_path(phase_dir, name)
        if path.is_symlink() or not path.is_file():
            raise TransactionError(f"frozen protection input is missing or unsafe: {name}")
        hashes[key] = sha256(path.read_bytes())
    return hashes


def stage_protection_result(phase_dir: pathlib.Path, fixture_dir: pathlib.Path | None) -> dict[str, Any]:
    publication, _ = read_json(phase_path(phase_dir, "79-PUBLICATION-PACKET.json"), "publication packet")
    pr_transaction, _ = read_json(phase_path(phase_dir, "79-PR-TRANSACTION.json"), "PR transaction")
    merge, _ = read_json(phase_path(phase_dir, "79-MERGE-RECEIPT.json"), "merge receipt")
    ci_receipt, _ = read_json(phase_path(phase_dir, "79-MAIN-CI-RECEIPT.json"), "main CI receipt")
    capture, _capture_bytes = read_json(phase_path(phase_dir, "79-PROTECTION-CAPTURE.json"), "frozen protection capture")
    inventory, _inventory_bytes = read_json(phase_path(phase_dir, "79-INVENTORY.json"), "frozen inventory")
    desired, desired_bytes = read_json(phase_path(phase_dir, "79-PROTECTION-DESIRED.json"), "frozen protection desired")
    rollback, rollback_bytes = read_json(phase_path(phase_dir, "79-PROTECTION-ROLLBACK.json"), "frozen protection rollback")
    batch_path = phase_path(phase_dir, "79-REMOTE-BATCH.md")
    batch_bytes = batch_path.read_bytes()
    hashes = protection_snapshot_hashes(phase_dir)
    target_sha = merge.get("main_sha")
    target_sha = validate_sha(target_sha, "merged main SHA")
    join = validate_receipt_join(
        {"publication": publication, "pr": pr_transaction, "merge": merge}, target_sha
    )
    if (
        publication.get("status") != "ready"
        or pr_transaction.get("status") != "complete"
        or merge.get("status") != "complete"
        or ci_receipt.get("status") != "complete"
        or ci_receipt.get("target", {}).get("sha") != target_sha
        or not isinstance(ci_receipt.get("lanes"), dict)
        or len(ci_receipt["lanes"]) != 9
        or not phase79_ci_lanes_passed(ci_receipt, target_sha)
        or capture.get("capture_status") != "complete"
        or capture.get("capture_errors") != []
        or capture.get("main_sha") != target_sha
        or inventory.get("observation", {}).get("main_sha") != target_sha
        or desired.get("status") != "ready"
        or desired.get("source_capture_sha256") != hashes["capture_sha256"]
        or rollback.get("status") != "ready"
        or rollback.get("source_capture_sha256") != hashes["capture_sha256"]
    ):
        raise TransactionError("protection inputs are incomplete or differ from the verified merged-main/CI identity")
    verify_batch_artifacts(phase_dir)

    transaction_path = phase_path(phase_dir, "79-PROTECTION-TRANSACTION.json")
    prior_transaction = read_json(transaction_path, "protection transaction")[0] if transaction_path.exists() else {}
    if prior_transaction.get("status") == "partial":
        raise TransactionError("protection transaction is partial; a new preflight and approval are required")
    proposal = "exact proposal; not executed." in batch_bytes.decode(errors="replace")
    no_action = "**Status:** no mutation proposed; no command was executed." in batch_bytes.decode(errors="replace")
    if proposal == no_action:
        raise TransactionError("frozen protection batch must be exactly one of proposal or no-action")
    approval = prior_transaction.get("approval")
    if proposal:
        expected_scope = {**hashes, "repository": REPOSITORY, "ref": MAIN_REF, "sha": target_sha}
        if (
            not isinstance(approval, dict)
            or approval.get("checkpoint_id") != "79-11-protection-write"
            or approval.get("response") != "approved"
            or approval.get("scope") != expected_scope
        ):
            raise TransactionError("protection write requires approval bound to every frozen snapshot digest")
    elif approval is not None:
        raise TransactionError("no-action protection batch must not carry mutation approval")

    if fixture_dir:
        fixture = fixture_json(fixture_dir, "protection-result")
        if fixture.get("target_sha") != target_sha or fixture.get("snapshot_hashes") != hashes:
            raise TransactionError("protection fixture does not join to the frozen target and snapshot hashes")
        post_capture = fixture.get("post_capture")
        post_inventory = fixture.get("post_inventory")
        response = fixture.get("response")
        independent = fixture.get("independent_readback") is True
        if not isinstance(post_capture, dict) or not isinstance(post_inventory, dict):
            raise TransactionError("protection fixture lacks both independent post-state observations")
        write_json(phase_path(phase_dir, "79-PROTECTION-POST-CAPTURE.json"), post_capture)
        write_json(phase_path(phase_dir, "79-POST-INVENTORY.json"), post_inventory)
    else:
        remote_main = run(["git", "ls-remote", "origin", MAIN_REF]).split()
        if len(remote_main) != 2 or remote_main[0] != target_sha:
            raise TransactionError("main moved before protection preflight")
        if proposal:
            with tempfile.TemporaryDirectory(prefix="relyra-phase79-protection-preflight-") as temporary:
                fresh_capture_path = pathlib.Path(temporary) / "capture.json"
                run(["python3", str(ROOT / "scripts/capture_phase79_protection.py"), "--output", str(fresh_capture_path)])
                fresh_capture, _ = read_json(fresh_capture_path, "immediate protection preflight capture")
            stable_keys = ("capture_status", "capture_errors", "main_sha", "ref", "resource", "writable_payload", "sources")
            if any(fresh_capture.get(key) != capture.get(key) for key in stable_keys):
                raise TransactionError("live protection state drifted after the exact approval")
            in_progress = {
                "schema": "phase79-protection-transaction", "version": 1,
                "status": "partial", "operation_state": "protection_put_in_progress",
                "target": {"repository": REPOSITORY, "ref": MAIN_REF, "main_sha": target_sha},
                "snapshot_hashes": hashes, "approval": approval,
                "independent_readback": False,
            }
            write_json(transaction_path, in_progress)
            with tempfile.TemporaryDirectory(prefix="relyra-phase79-protection-payload-") as temporary:
                payload_file = pathlib.Path(temporary) / "approved-payload.json"
                payload_file.write_bytes(encoded(desired["desired_payload"]))
                try:
                    output = run([
                        "gh", "api", "--method", "PUT",
                        f"repos/{REPOSITORY}/branches/main/protection",
                        "--input", str(payload_file),
                    ], timeout=60)
                except TransactionError as exc:
                    partial = {
                        "schema": "phase79-protection-transaction", "version": 1,
                        "status": "partial", "target": {"repository": REPOSITORY, "ref": MAIN_REF, "main_sha": target_sha},
                        "snapshot_hashes": hashes, "approval": approval, "failure": str(exc),
                        "operation_state": "protection_put_ambiguous", "independent_readback": False,
                    }
                    write_json(transaction_path, partial)
                    raise TransactionError("protection PUT result is ambiguous; transaction is partial and no rollback is automatic") from exc
                response = {"accepted": True, "response_sha256": sha256(output.encode())}
            in_progress["operation_state"] = "post_readback_pending"
            in_progress["response"] = response
            write_json(transaction_path, in_progress)
        post_capture_path = phase_path(phase_dir, "79-PROTECTION-POST-CAPTURE.json")
        post_inventory_path = phase_path(phase_dir, "79-POST-INVENTORY.json")
        run(["python3", str(ROOT / "scripts/capture_phase79_protection.py"), "--output", str(post_capture_path)])
        run(["python3", str(ROOT / "scripts/collect_phase79_inventory.py"), "--output", str(post_inventory_path)])
        post_capture = read_json(post_capture_path, "post protection capture")[0]
        post_inventory = read_json(post_inventory_path, "post inventory")[0]
        independent = True

    if (
        post_capture.get("capture_status") != "complete"
        or post_capture.get("capture_errors") != []
        or post_capture.get("main_sha") != target_sha
        or post_capture.get("writable_payload") != desired.get("desired_payload")
        or post_capture.get("resource") != desired.get("desired_payload")
        or not inventory_is_green(post_inventory, target_sha)
        or not independent
    ):
        partial = {
            "schema": "phase79-protection-transaction", "version": 1,
            "status": "partial", "target": {"repository": REPOSITORY, "ref": MAIN_REF, "main_sha": target_sha},
            "snapshot_hashes": hashes, "approval": approval,
            "post_capture_sha256": sha256(encoded(post_capture)),
            "post_inventory_sha256": sha256(encoded(post_inventory)),
            "independent_readback": False,
        }
        write_json(transaction_path, partial)
        raise TransactionError("protection post-state is incomplete or differs from the exact desired state")
    post_capture_bytes = phase_path(phase_dir, "79-PROTECTION-POST-CAPTURE.json").read_bytes()
    post_inventory_bytes = phase_path(phase_dir, "79-POST-INVENTORY.json").read_bytes()
    receipt = {
        "schema": "phase79-protection-transaction", "version": 1, "status": "complete",
        "target": {"repository": REPOSITORY, "ref": MAIN_REF, "main_sha": target_sha},
        "snapshot_hashes": hashes, "approval": approval,
        "response": response if proposal else {"operation": "no-action", "performed": False},
        "post_capture_sha256": sha256(post_capture_bytes),
        "post_inventory_sha256": sha256(post_inventory_bytes),
        "readback_payload": post_capture["writable_payload"],
        "source_agreement": True, "independent_readback": independent,
        "cross_receipt_join": join,
    }
    final_main = run(["git", "ls-remote", "origin", MAIN_REF]).split()
    if not fixture_dir and (len(final_main) != 2 or final_main[0] != target_sha):
        receipt["status"] = "partial"
        write_json(transaction_path, receipt)
        raise TransactionError("main moved during protection read-back; transaction remains partial")
    write_json(transaction_path, receipt)
    verify_batch_artifacts(phase_dir)
    return receipt


def phase79_ci_lanes_passed(receipt: dict[str, Any], sha: str) -> bool:
    lanes = receipt.get("lanes")
    if not isinstance(lanes, dict) or len(lanes) != 9:
        return False
    try:
        owners = expected_lanes()
    except TransactionError:
        return False
    if set(lanes) != set(owners):
        return False
    for lane_name, lane in lanes.items():
        expected = owners.get(lane_name, {})
        evidence = lane.get("evidence") if isinstance(lane, dict) else None
        if (
            not isinstance(lane, dict)
            or lane.get("owner") != expected.get("owner")
            or not isinstance(evidence, list)
            or len(evidence) != len(expected.get("check_names", []))
            or {item.get("check_name") for item in evidence if isinstance(item, dict)} != set(expected.get("check_names", []))
        ):
            return False
        for item in evidence:
            if (
                not isinstance(item, dict)
                or item.get("sha") != sha
                or item.get("conclusion") != "success"
                or not all(positive_int(item.get(key)) for key in ("workflow_run_id", "job_id", "check_run_id"))
            ):
                return False
    fleet = receipt.get("fleet_context")
    return (
        isinstance(fleet, dict)
        and fleet.get("name") == FLEET_CONTEXT
        and fleet.get("state") == "passed"
        and fleet.get("sha") == sha
        and all(positive_int(fleet.get(key)) for key in ("workflow_run_id", "job_id", "check_run_id"))
    )


def stage_closeout(phase_dir: pathlib.Path, fixture_dir: pathlib.Path | None) -> dict[str, Any]:
    publication, _ = read_json(phase_path(phase_dir, "79-PUBLICATION-PACKET.json"), "publication packet")
    pr, _ = read_json(phase_path(phase_dir, "79-PR-TRANSACTION.json"), "PR transaction")
    merge, _ = read_json(phase_path(phase_dir, "79-MERGE-RECEIPT.json"), "merge receipt")
    ci, ci_bytes = read_json(phase_path(phase_dir, "79-MAIN-CI-RECEIPT.json"), "main CI receipt")
    protection, _ = read_json(phase_path(phase_dir, "79-PROTECTION-TRANSACTION.json"), "protection transaction")
    inventory, inventory_bytes = read_json(phase_path(phase_dir, "79-POST-INVENTORY.json"), "post inventory")
    post_capture, post_capture_bytes = read_json(phase_path(phase_dir, "79-PROTECTION-POST-CAPTURE.json"), "post protection capture")
    join = validate_receipt_join({"publication": publication, "pr": pr, "merge": merge})
    main_sha = join["main_sha"]
    pr_bytes = phase_path(phase_dir, "79-PR-TRANSACTION.json").read_bytes()
    publication_bytes = phase_path(phase_dir, "79-PUBLICATION-PACKET.json").read_bytes()
    ci_packet, ci_packet_bytes = read_json(phase_path(phase_dir, "79-CI-DISPATCH-PACKET.json"), "CI dispatch packet")
    if (
        publication.get("status") != "ready"
        or pr.get("publication_packet_sha256") != sha256(publication_bytes)
        or not phase79_ci_lanes_passed(ci, main_sha)
        or ci.get("target", {}).get("repository") != REPOSITORY
        or ci.get("target", {}).get("ref") != MAIN_REF
        or ci.get("target", {}).get("sha") != main_sha
        or ci.get("source_join") != join
        or ci.get("approved_packet_sha256") != ci_packet.get("packet_sha256")
        or ci_packet.get("packet_sha256") != ci_packet_digest(ci_packet)
        or ci.get("dispatch_packet_bytes_sha256") != sha256(ci_packet_bytes)
        or ci.get("independent_readback") is not True
    ):
        raise TransactionError("closeout requires nine same-SHA lanes and fleet owner identities")
    if ci_packet.get("status") == "no_action":
        if (
            ci_packet.get("approval") is not None
            or ci.get("approval") is not None
            or ci.get("dispatch_requests") != []
            or ci.get("dispatch_responses") != []
            or ci.get("dispatch_run_identities") != []
            or ci_packet.get("missing_owner_runs") != []
            or ci_packet.get("dispatch", {}).get("performed") is not False
        ):
            raise TransactionError("no-action CI receipt contains dispatch authority or a request")
    elif ci_packet.get("status") == "pending":
        ci_approval = ci_packet.get("approval")
        requests = ci_packet.get("dispatch", {}).get("requests")
        expected_run_paths = [request.get("path") for request in requests if isinstance(request, dict)] if isinstance(requests, list) else []
        responses = ci.get("dispatch_responses")
        run_identities = ci.get("dispatch_run_identities")
        if (
            not isinstance(ci_approval, dict)
            or ci_approval.get("checkpoint_id") != "79-10-ci-dispatch"
            or ci_approval.get("response") != "approved"
            or ci_approval.get("packet_sha256") != ci_packet.get("packet_sha256")
            or ci.get("approval") != ci_approval
            or ci_approval.get("scope") != requests
            or ci.get("dispatch_requests") != requests
            or not isinstance(requests, list)
            or not requests
            or not isinstance(responses, list)
            or len(responses) != len(requests)
            or any(
                not isinstance(response, dict)
                or response.get("workflow_id") != request.get("workflow_id")
                or not (response.get("accepted") is True or response.get("status_code") == 204)
                for request, response in zip(requests, responses, strict=False)
            )
            or not isinstance(run_identities, list)
            or len(run_identities) != len(expected_run_paths)
            or [item.get("path") for item in run_identities if isinstance(item, dict)] != expected_run_paths
            or any(
                not isinstance(item, dict)
                or item.get("head_sha") != main_sha
                or not positive_int(item.get("id"))
                or not positive_int(item.get("attempt"))
                for item in run_identities
            )
            or len({item.get("id") for item in run_identities if isinstance(item, dict)}) != len(run_identities)
        ):
            raise TransactionError("CI dispatch approval/response does not join to the exact packet")
    else:
        raise TransactionError("CI dispatch packet state is invalid at closeout")

    expected_pr_operation_packet = make_pr_operation_packet(publication)
    pr_approval = pr.get("approval")
    if (
        pr.get("operation_packet") != expected_pr_operation_packet
        or pr.get("packet_sha256") != approval_digest(expected_pr_operation_packet)
        or not isinstance(pr_approval, dict)
        or pr_approval.get("checkpoint_id") != "79-08-pr-create"
        or pr_approval.get("response") != "approved"
        or pr_approval.get("packet_sha256") != approval_digest(expected_pr_operation_packet)
        or pr_approval.get("scope") != expected_pr_operation_packet["operations"]
    ):
        raise TransactionError("closeout PR approval does not bind the exact push/PR operation")
    batch_text = phase_path(phase_dir, "79-REMOTE-BATCH.md").read_text(encoding="utf-8")
    proposal = "exact proposal; not executed." in batch_text
    no_action = "**Status:** no mutation proposed; no command was executed." in batch_text
    snapshot_hashes = protection_snapshot_hashes(phase_dir)
    protection_approval = protection.get("approval")
    expected_protection_scope = {
        **snapshot_hashes,
        "repository": REPOSITORY,
        "ref": MAIN_REF,
        "sha": main_sha,
    }
    if proposal == no_action:
        raise TransactionError("closeout protection batch is not exactly one of proposal or no-action")
    if proposal:
        if (
            not isinstance(protection_approval, dict)
            or protection_approval.get("checkpoint_id") != "79-11-protection-write"
            or protection_approval.get("response") != "approved"
            or protection_approval.get("scope") != expected_protection_scope
        ):
            raise TransactionError("protection approval does not bind every frozen snapshot hash")
        response = protection.get("response")
        if not isinstance(response, dict) or response.get("accepted") is not True or not re.fullmatch(r"[0-9a-f]{64}", str(response.get("response_sha256", ""))):
            raise TransactionError("approved protection mutation lacks its bounded API response identity")
    elif protection_approval is not None or protection.get("response") != {"operation": "no-action", "performed": False}:
        raise TransactionError("no-action protection receipt contains mutation authority or response")

    desired, _ = read_json(phase_path(phase_dir, "79-PROTECTION-DESIRED.json"), "protection desired")
    rollback, _ = read_json(phase_path(phase_dir, "79-PROTECTION-ROLLBACK.json"), "protection rollback")
    if (
        protection.get("status") != "complete"
        or protection.get("target", {}).get("repository") != REPOSITORY
        or protection.get("target", {}).get("ref") != MAIN_REF
        or protection.get("target", {}).get("main_sha") != main_sha
        or protection.get("snapshot_hashes") != snapshot_hashes
        or protection.get("post_capture_sha256") != sha256(post_capture_bytes)
        or protection.get("post_inventory_sha256") != sha256(inventory_bytes)
        or protection.get("readback_payload") != post_capture.get("writable_payload")
        or protection.get("source_agreement") is not True
        or protection.get("independent_readback") is not True
        or protection.get("cross_receipt_join") != join
        or desired.get("status") != "ready"
        or desired.get("source_capture_sha256") != snapshot_hashes["capture_sha256"]
        or rollback.get("status") != "ready"
        or rollback.get("source_capture_sha256") != snapshot_hashes["capture_sha256"]
        or post_capture.get("capture_status") != "complete"
        or post_capture.get("capture_errors") != []
        or post_capture.get("main_sha") != main_sha
        or post_capture.get("resource") != desired.get("desired_payload")
        or post_capture.get("writable_payload") != desired.get("desired_payload")
        or not inventory_is_green(inventory, main_sha)
    ):
        raise TransactionError("closeout protection snapshots or same-SHA post-state do not join")
    verify_protection_artifacts(phase_dir)
    packet, _ = read_json(phase_path(phase_dir, "79-MERGE-PACKET.json"), "merge packet")
    if (
        packet.get("packet_sha256") != merge_packet_digest(packet)
        or packet.get("publication_packet_sha256") != sha256(publication_bytes)
        or packet.get("pr_transaction_sha256") != sha256(pr_bytes)
        or merge.get("packet_sha256") != packet.get("packet_sha256")
        or merge.get("repository") != REPOSITORY
        or merge.get("merge_method") != "merge"
        or merge.get("pr_number") != packet.get("pr_number")
        or merge.get("provenance", {}).get("provenance_status") != "passed"
        or merge.get("provenance", {}).get("provenance_owner") != "mix ci.evidence"
        or merge.get("approval") != packet.get("approval")
        or not isinstance(packet.get("approval"), dict)
        or packet["approval"].get("checkpoint_id") != "79-09-main-merge"
        or packet["approval"].get("response") != "approved"
        or packet["approval"].get("scope") != packet.get("operation")
    ):
        raise TransactionError("closeout merge approval does not join to its immutable packet")
    risks, _ = read_json(phase_path(phase_dir, "79-RISKS.json"), "risk ledger")
    items = risks.get("items")
    if not isinstance(items, list) or any(
        item.get("severity") in {"High", "Critical"}
        and (item.get("status") != "resolved" or main_sha not in str(item.get("evidence", "")))
        for item in items if isinstance(item, dict)
    ):
        raise TransactionError("closeout risk ledger contains unresolved High/Critical evidence")
    closeout_path = phase_path(phase_dir, "79-CLOSEOUT.md")
    if closeout_path.is_symlink() or not closeout_path.is_file() or "Release readiness: READY" not in closeout_path.read_text(encoding="utf-8"):
        raise TransactionError("closeout dossier does not make an evidence-backed READY claim")
    if not fixture_dir:
        first = run(["git", "ls-remote", "origin", MAIN_REF]).split()
        if len(first) != 2 or first[0] != main_sha:
            raise TransactionError("live main differs from the merged SHA before closeout")
    receipt = {
        "status": "verified", "target": {"repository": REPOSITORY, "ref": MAIN_REF, "sha": main_sha},
        "source_join": join, "ci_receipt_sha256": sha256(ci_bytes),
        "post_inventory_sha256": sha256(inventory_bytes),
        "post_capture_sha256": sha256(post_capture_bytes),
        "protection_transaction_sha256": sha256(encoded(protection)),
        "independent_readback": True,
    }
    if not fixture_dir:
        last = run(["git", "ls-remote", "origin", MAIN_REF]).split()
        if len(last) != 2 or last[0] != main_sha:
            raise TransactionError("live main moved during closeout verification")
    return receipt


def verify_protection_artifacts(phase_dir: pathlib.Path) -> None:
    artifacts = [
        ("capture_phase79_protection.py", "79-PROTECTION-CAPTURE.json"),
        ("collect_phase79_inventory.py", "79-INVENTORY.json"),
        ("capture_phase79_protection.py", "79-PROTECTION-POST-CAPTURE.json"),
        ("collect_phase79_inventory.py", "79-POST-INVENTORY.json"),
    ]
    for script, name in artifacts:
        path = phase_path(phase_dir, name)
        if path.is_symlink() or not path.is_file():
            raise TransactionError(f"closeout artifact is missing or unsafe: {name}")
        run(["python3", str(ROOT / "scripts" / script), "--verify", str(path)])
    verify_batch_artifacts(phase_dir)


def dispatch(stage: str, phase_dir: pathlib.Path, fixture_dir: pathlib.Path | None) -> dict[str, Any]:
    if stage == "publication":
        return verify_publication(phase_dir, fixture_dir)
    if stage == "pr-preflight":
        return stage_pr_preflight(phase_dir, fixture_dir)
    if stage == "pr-result":
        return stage_pr_result(phase_dir, fixture_dir)
    if stage == "merge-preflight":
        return stage_merge_preflight(phase_dir, fixture_dir)
    if stage == "merge-result":
        return stage_merge_result(phase_dir, fixture_dir)
    if stage == "ci-preflight":
        return stage_ci_preflight(phase_dir, fixture_dir)
    if stage == "ci-result":
        return verify_ci_result(phase_dir, fixture_dir)
    if stage == "protection-result":
        return stage_protection_result(phase_dir, fixture_dir)
    if stage == "closeout":
        return stage_closeout(phase_dir, fixture_dir)
    raise TransactionError(f"unsupported transaction stage: {stage}")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--stage", required=True, choices=sorted(EXPECTED_STAGES))
    parser.add_argument("--phase-dir", required=True, type=pathlib.Path)
    parser.add_argument("--fixture-dir", type=pathlib.Path)
    args = parser.parse_args(argv)
    try:
        phase_dir = args.phase_dir.expanduser().resolve()
        fixture_dir = args.fixture_dir.expanduser().resolve() if args.fixture_dir else None
        result = dispatch(args.stage, phase_dir, fixture_dir)
    except TransactionError as exc:
        print(f"phase79 transaction {args.stage}: {exc}", file=sys.stderr)
        return 1
    except (AttributeError, KeyError, TypeError, ValueError) as exc:
        print(f"phase79 transaction {args.stage}: malformed evidence ({exc})", file=sys.stderr)
        return 1
    print(json.dumps(result, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
