#!/usr/bin/env python3
"""Collect a bounded, read-only repository and GitHub closeout inventory."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import pathlib
import re
import subprocess
import sys
import tempfile
from urllib.parse import urlparse


SCHEMA = "phase79-inventory"
VERSION = 1
MAX_OUTPUT_BYTES = 8 * 1024 * 1024
MAX_ITEMS = 5000
ALLOWED_WORKFLOW_FIELDS = (
    "id", "name", "path", "state", "html_url", "created_at", "updated_at"
)
LANE_STATES = {"passed", "failed", "pending", "skipped", "absent", "unknown"}
REQUIRED_LANES = (
    "mix qa", "mix ci.security", "mix ci.evidence", "mix ci.phase73.reconciliation",
    "mix ci.verify", "mix ci.package", "mix ci.ledger_loop", "browser defenses",
    "standalone defenses",
)


class CollectionError(Exception):
    pass


def utc_now() -> str:
    return dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def command(args: list[str], *, cwd: pathlib.Path, fixture: dict | None = None) -> str:
    """Run a read-only local command, or replay a fixture response by command key."""
    if fixture is not None:
        key = " ".join(args)
        entry = fixture.get("commands", {}).get(key)
        if entry is None:
            raise CollectionError(f"fixture is missing command response: {key}")
        if isinstance(entry, dict) and entry.get("exit", 0) != 0:
            raise CollectionError(f"fixture command failed: {key}")
        result = entry.get("stdout", "") if isinstance(entry, dict) else entry
        if not isinstance(result, str):
            raise CollectionError(f"fixture command response is not text: {key}")
        return result
    try:
        completed = subprocess.run(
            args, cwd=cwd, check=False, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            text=True, timeout=45,
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        raise CollectionError(f"local read failed: {args[0]}") from exc
    if completed.returncode:
        raise CollectionError(f"local read failed: {args[0]} exited {completed.returncode}")
    return completed.stdout


def gh_read(repo: str, endpoint: str, page: int, fixture: dict | None) -> tuple[int, object, bool]:
    """Perform a bounded GitHub GET and return status, body, and has-next-page."""
    fixture_key = f"{endpoint}?page={page}"
    if fixture is not None:
        item = fixture.get("github", {}).get(fixture_key)
        if item is None:
            raise CollectionError(f"fixture is missing GitHub response: {fixture_key}")
        return int(item.get("status", 200)), item.get("body"), bool(item.get("next", False))
    url = f"repos/{repo}/{endpoint}"
    separator = "&" if "?" in url else "?"
    url += f"{separator}per_page=100&page={page}"
    try:
        completed = subprocess.run(
            ["gh", "api", "--include", "--method", "GET", url], check=False,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, timeout=45,
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        raise CollectionError("GitHub read failed: gh api") from exc
    # gh writes API errors to stderr and exits nonzero. Keep only a bounded status label.
    if completed.returncode:
        text = completed.stderr.lower()
        if "401" in text or "authentication" in text:
            return 401, None, False
        if "403" in text or "forbidden" in text:
            return 403, None, False
        if "404" in text or "not found" in text:
            return 404, None, False
        if "rate limit" in text:
            return 429, None, False
        return 0, None, False
    headers, body = split_http_response(completed.stdout)
    try:
        parsed = json.loads(body)
    except json.JSONDecodeError as exc:
        raise CollectionError("GitHub returned invalid JSON") from exc
    link = headers.get("link", "")
    next_page = bool(re.search(r'rel="next"', link, re.IGNORECASE))
    return int(headers.get(":status", "200")), parsed, next_page


def split_http_response(value: str) -> tuple[dict[str, str], str]:
    headers: dict[str, str] = {}
    body_parts: list[str] = []
    in_body = False
    for line in value.splitlines():
        if not in_body:
            if line.startswith("HTTP/"):
                match = re.search(r"\s(\d{3})(?:\s|$)", line)
                if match:
                    headers[":status"] = match.group(1)
            elif not line.strip():
                in_body = True
            elif ":" in line:
                key, val = line.split(":", 1)
                headers[key.strip().lower()] = val.strip()
        else:
            body_parts.append(line)
    return headers, "\n".join(body_parts)


def page_source(repo: str, endpoint: str, fixture: dict | None) -> dict:
    rows: list[object] = []
    pages: list[dict] = []
    status = 200
    for page in range(1, 51):
        status, body, has_next = gh_read(repo, endpoint, page, fixture)
        if status != 200:
            return {
                "endpoint": endpoint, "page_count": len(pages), "pages": pages,
                "item_count": len(rows), "access_status": access_status(status),
                "completeness": "incomplete", "items": [],
            }
        if isinstance(body, dict):
            list_field = next((field for field in ("workflows", "workflow_runs", "check_runs") if isinstance(body.get(field), list)), None)
            if list_field is None:
                raise CollectionError(f"GitHub list response is not an array: {endpoint}")
            body = body[list_field]
        if not isinstance(body, list):
            raise CollectionError(f"GitHub list response is not an array: {endpoint}")
        if len(rows) + len(body) > MAX_ITEMS:
            raise CollectionError(f"GitHub list exceeds item bound: {endpoint}")
        rows.extend(body)
        pages.append({"number": page, "item_count": len(body), "status": status})
        if not has_next:
            return {
                "endpoint": endpoint, "page_count": len(pages), "pages": pages,
                "item_count": len(rows), "access_status": "allowed",
                "completeness": "complete", "items": rows,
            }
    return {
        "endpoint": endpoint, "page_count": len(pages), "pages": pages,
        "item_count": len(rows), "access_status": "allowed",
        "completeness": "incomplete", "items": [],
    }


def access_status(status: int) -> str:
    return {401: "unauthenticated", 403: "denied", 404: "not_found", 429: "rate_limited"}.get(
        status, "error"
    )


def only(row: object, fields: tuple[str, ...]) -> dict:
    if not isinstance(row, dict):
        return {}
    return {field: row[field] for field in fields if field in row}


def workflow_item(row: object) -> dict:
    item = only(row, ALLOWED_WORKFLOW_FIELDS)
    state = str(item.get("state", "")).lower()
    item["state"] = "active" if state == "active" else "disabled" if state == "disabled_inactivity" else "unknown"
    return item


def local_inventory(root: pathlib.Path, fixture: dict | None) -> dict:
    status = command(["git", "status", "--porcelain=v1", "-z", "--untracked-files=all"], cwd=root, fixture=fixture)
    tracked = command(["git", "ls-files", "-z"], cwd=root, fixture=fixture).split("\0")
    worktree_text = command(["git", "worktree", "list", "--porcelain"], cwd=root, fixture=fixture)
    branches = command(["git", "for-each-ref", "--format=%(refname:short)%09%(objectname)", "refs/heads", "refs/remotes"], cwd=root, fixture=fixture)
    ignored_text = command(["git", "status", "--ignored", "--porcelain=v1", "-z", "--untracked-files=all"], cwd=root, fixture=fixture)
    tracked_paths = sorted(path for path in tracked if path)
    items = []
    for record in status.split("\0"):
        if len(record) < 4:
            continue
        state, path = record[:2], record[3:]
        if path:
            items.append({"path": path, "git_state": state, "owner": "maintainer" if path == ".tool-versions" else "unknown", "disposition": "preserve; no cleanup authority"})
    candidates = []
    for record in ignored_text.split("\0"):
        if not record.startswith("!! "):
            continue
        path = record[3:]
        if path and (path.startswith(("_build/", "deps/", "node_modules/", "tmp")) or "/tmp" in path):
            candidates.append({"path": path, "owner": "unknown", "disposition": "inspect only; no cleanup authority"})
    return {
        "tracked_path_count": len(tracked_paths),
        "tracked_edits": [item for item in items if item["path"] in tracked_paths],
        "untracked_paths": [item for item in items if item["path"] not in tracked_paths],
        "ignored_generated_candidates": candidates[:200],
        "worktrees": parse_worktrees(worktree_text),
        "branches": parse_branches(branches),
    }


def parse_worktrees(value: str) -> list[dict]:
    result: list[dict] = []
    for block in value.strip().split("\n\n"):
        fields = {}
        for line in block.splitlines():
            if " " in line:
                key, val = line.split(" ", 1)
                fields[key] = val
            else:
                fields[line] = True
        if fields:
            result.append({"path": fields.get("worktree"), "head": fields.get("HEAD"), "branch": fields.get("branch"), "detached": bool(fields.get("detached")), "owner": "repository maintainer", "disposition": "preserve and inspect"})
    return result


def parse_branches(value: str) -> list[dict]:
    result = []
    for line in value.splitlines()[:MAX_ITEMS]:
        name, _, sha = line.partition("\t")
        if name:
            result.append({"name": name, "sha": sha})
    return result


def repository_from_remote(value: str) -> str:
    value = value.strip()
    if value.startswith("git@"):
        match = re.match(r"git@[^:]+:(.+?)(?:\.git)?$", value)
        if match:
            return match.group(1)
    parsed = urlparse(value)
    path = parsed.path.lstrip("/")
    return path[:-4] if path.endswith(".git") else path


def raw_single(repo: str, endpoint: str, fixture: dict | None) -> tuple[dict, int]:
    status, body, _ = gh_read(repo, endpoint, 1, fixture)
    return (body if isinstance(body, dict) else {}), status


def lane_owners(root: pathlib.Path) -> dict[str, list[str]]:
    """Map executable mandatory-lane references to tracked workflow owners."""
    workflow_dir = root / ".github/workflows"
    contents = {}
    for path in sorted(workflow_dir.glob("*.yml")) + sorted(workflow_dir.glob("*.yaml")):
        if not path.is_file() or path.is_symlink():
            continue
        contents[path.name] = path.read_text(encoding="utf-8", errors="replace")
    aliases = ("mix qa", "mix ci.security", "mix ci.evidence", "mix ci.phase73.reconciliation", "mix ci.verify")
    result = {}
    for lane in aliases:
        owners = [name for name, text in contents.items() if lane in text]
        result[lane] = owners
    mix_file = (root / "mix.exs").read_text(encoding="utf-8", errors="replace") if (root / "mix.exs").is_file() else ""
    mix_aliases = {
        "mix qa": r'"qa"\s*=>',
        "mix ci.security": r'"ci\.security"\s*=>',
        "mix ci.evidence": r'"ci\.evidence"\s*=>',
        "mix ci.phase73.reconciliation": r'"ci\.phase73\.reconciliation"\s*=>',
        "mix ci.verify": r'"ci\.verify"\s*=>',
    }
    for lane, pattern in mix_aliases.items():
        if re.search(pattern, mix_file):
            result[lane] = sorted(set(result[lane] + ["mix.exs"]))
    result["mix ci.package"] = [name for name, text in contents.items() if "check_clean_room_consumer.sh" in text or "ci.package" in text]
    result["mix ci.ledger_loop"] = [name for name, text in contents.items() if "demo/ledger_loop" in text or "ledger_loop" in text]
    result["browser defenses"] = [name for name, text in contents.items() if "playwright" in text.lower() or "browser" in text.lower()]
    result["standalone defenses"] = [name for name, text in contents.items() if "GATE-02" in text or "check_ci_gate_integrity" in text]
    return result


def classify_lane(name: str, checks: list, statuses: list, sha: str) -> dict:
    records = [r for r in checks if isinstance(r, dict) and r.get("head_sha") == sha and r.get("name") == name]
    records += [r for r in statuses if isinstance(r, dict) and r.get("sha", sha) == sha and r.get("context") == name]
    if not records:
        return {"state": "absent", "sha": sha, "evidence_count": 0}
    states = []
    for row in records:
        conclusion = str(row.get("conclusion") or row.get("state") or row.get("status") or "").lower()
        if conclusion in {"success", "successful", "completed"}:
            states.append("passed")
        elif conclusion in {"failure", "failed", "timed_out", "action_required", "error"}:
            states.append("failed")
        elif conclusion in {"pending", "queued", "in_progress", "requested", "waiting"}:
            states.append("pending")
        elif conclusion == "skipped":
            states.append("skipped")
        else:
            states.append("unknown")
    state = "failed" if "failed" in states else "pending" if "pending" in states else "unknown" if "unknown" in states else "skipped" if all(s == "skipped" for s in states) else "passed"
    return {"state": state, "sha": sha, "evidence_count": len(records)}


def validate_receipt(receipt: dict) -> list[str]:
    errors = []
    if receipt.get("schema") != SCHEMA or receipt.get("version") != VERSION:
        errors.append("unsupported schema or version")
    observed = receipt.get("observed_at", "")
    try:
        dt.datetime.fromisoformat(observed.replace("Z", "+00:00"))
    except (ValueError, AttributeError):
        errors.append("invalid UTC observation timestamp")
    if not observed.endswith("Z"):
        errors.append("observation timestamp is not UTC")
    repo = receipt.get("repository", {})
    if not repo.get("name"):
        errors.append("missing repository identity")
    observation = receipt.get("observation", {})
    sha = observation.get("main_sha", "")
    if not re.fullmatch(r"[0-9a-f]{40}", sha or ""):
        errors.append("missing or invalid observed main SHA")
    sources = receipt.get("sources", {})
    claimed_complete = receipt.get("collection", {}).get("complete") is True
    if not sources:
        errors.append("missing source provenance")
    for name, source in sources.items():
        if not source.get("endpoint") or not source.get("access_status"):
            errors.append(f"source {name} lacks endpoint or access status")
        if claimed_complete and (source.get("completeness") != "complete" or not source.get("page_count")):
            errors.append(f"source {name} is incomplete")
        if source.get("page_count") != len(source.get("pages", [])):
            errors.append(f"source {name} has inconsistent page count")
        page_numbers = [p.get("number") for p in source.get("pages", [])]
        if page_numbers != list(range(1, len(page_numbers) + 1)):
            errors.append(f"source {name} has missing or duplicate pages")
    github = receipt.get("github", {})
    for row in github.get("check_runs", []):
        if claimed_complete and row.get("head_sha") != sha:
            errors.append("check run is not bound to observed main SHA")
    for name in REQUIRED_LANES:
        lane = github.get("mandatory_lanes", {}).get(name)
        if not lane or lane.get("state") not in LANE_STATES:
            errors.append(f"mandatory lane missing or unrecognized: {name}")
        elif claimed_complete and lane.get("sha") != sha:
            errors.append(f"mandatory lane is not bound to observed main SHA: {name}")
    for workflow in github.get("workflows", []):
        if claimed_complete and workflow.get("state") not in {"active", "disabled"}:
            errors.append("workflow state is absent or unrecognized")
    encoded = json.dumps(receipt, separators=(",", ":")).encode()
    if len(encoded) > MAX_OUTPUT_BYTES:
        errors.append("receipt exceeds output bound")
    if "gho_" in encoded.decode("utf-8", "ignore") or "Authorization:" in encoded.decode("utf-8", "ignore"):
        errors.append("receipt contains sensitive data")
    return errors


def build_receipt(root: pathlib.Path, fixture: dict | None = None) -> dict:
    local = local_inventory(root, fixture)
    remote = command(["git", "remote", "get-url", "origin"], cwd=root, fixture=fixture)
    repo = repository_from_remote(remote)
    if not re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", repo):
        raise CollectionError("could not identify GitHub repository from origin")
    main_before, main_status = raw_single(repo, "git/ref/heads/main", fixture)
    main_sha = str(main_before.get("object", {}).get("sha", ""))
    if main_status != 200 or not re.fullmatch(r"[0-9a-f]{40}", main_sha):
        raise CollectionError("could not read current main ref")
    sources = {}
    endpoints = {
        "pull_requests": "pulls?state=all",
        "issues": "issues?state=all",
        "remote_branches": "branches",
        "workflows": "actions/workflows",
        "workflow_runs": "actions/runs?per_page=100",
        "check_runs": f"commits/{main_sha}/check-runs",
        "statuses": f"commits/{main_sha}/status",
    }
    rows = {}
    for name, endpoint in endpoints.items():
        # Single-object endpoints are normalized to a one-page list for common provenance.
        if name == "statuses":
            body, status = raw_single(repo, endpoint, fixture)
            items = body.get("statuses", []) if status == 200 else []
            source = {"endpoint": endpoint, "page_count": 1 if status == 200 else 0, "pages": [{"number": 1, "item_count": len(items), "status": status}] if status == 200 else [], "item_count": len(items), "access_status": "allowed" if status == 200 else access_status(status), "completeness": "complete" if status == 200 else "incomplete", "items": items}
        else:
            source = page_source(repo, endpoint, fixture)
        sources[name] = {key: value for key, value in source.items() if key != "items"}
        rows[name] = source.get("items", [])
    sources["main_ref"] = {"endpoint": "git/ref/heads/main", "page_count": 1 if main_status == 200 else 0, "pages": [{"number": 1, "item_count": 1, "status": main_status}] if main_status == 200 else [], "item_count": 1 if main_status == 200 else 0, "access_status": "allowed" if main_status == 200 else access_status(main_status), "completeness": "complete" if main_status == 200 else "incomplete"}
    protection, protection_status = raw_single(repo, "branches/main/protection", fixture)
    sources["branch_protection"] = {"endpoint": "branches/main/protection", "page_count": 1 if protection_status == 200 else 0, "pages": [{"number": 1, "item_count": 1, "status": protection_status}] if protection_status == 200 else [], "item_count": 1 if protection_status == 200 else 0, "access_status": "allowed" if protection_status == 200 else access_status(protection_status), "completeness": "complete" if protection_status == 200 else "incomplete"}
    expected = json.loads(command(["scripts/setup_branch_protection.sh", "--print-expected-json"], cwd=root, fixture=fixture))
    contexts = protection.get("required_status_checks", {}).get("contexts", []) if protection_status == 200 else []
    check_response, check_status = raw_single(repo, f"commits/{main_sha}/check-runs", fixture)
    checks = check_response.get("check_runs", []) if check_status == 200 else []
    statuses = rows.get("statuses", [])
    lanes = lane_owners(root)
    required_contexts = expected.get("required_status_checks", {}).get("contexts", [])
    lane_results = {name: {**classify_lane(name, checks, statuses, main_sha), "owners": lanes.get(name, [])} for name in REQUIRED_LANES}
    second_main, second_status = raw_single(repo, "git/ref/heads/main", fixture)
    second_sha = str(second_main.get("object", {}).get("sha", "")) if second_status == 200 else ""
    gaps = []
    if second_sha != main_sha:
        gaps.append("main ref changed during collection; mixed-SHA receipt rejected")
    for name, source in sources.items():
        if source["completeness"] != "complete":
            gaps.append(f"{name} collection incomplete ({source['access_status']})")
    if protection_status != 200:
        gaps.append(f"branch protection inaccessible ({access_status(protection_status)})")
    if any(not lane["owners"] for lane in lane_results.values()):
        gaps.append("one or more mandatory lanes lack a workflow owner")
    if any(lane["state"] != "passed" for lane in lane_results.values()):
        gaps.append("one or more mandatory lanes are not green on observed main SHA")
    context_states = {name: classify_lane(name, checks, statuses, main_sha)["state"] for name in required_contexts}
    issue_rows = [row for row in rows["issues"] if isinstance(row, dict) and "pull_request" not in row]
    workflow_runs = rows["workflow_runs"]
    if workflow_runs and isinstance(workflow_runs[0], dict) and "workflow_runs" in workflow_runs[0]:
        workflow_runs = workflow_runs[0]["workflow_runs"]
    github = {
        "pull_requests": [only(row, ("number", "state", "title", "html_url", "base", "head", "draft", "updated_at")) for row in rows["pull_requests"]],
        "issues": [only(row, ("number", "state", "title", "html_url", "labels", "updated_at")) for row in issue_rows],
        "remote_branches": [only(row, ("name", "commit", "protected")) for row in rows["remote_branches"]],
        "workflows": [workflow_item(row) for row in rows["workflows"] if isinstance(row, dict)],
        "workflow_runs": [only(row, ("id", "name", "event", "status", "conclusion", "head_branch", "head_sha", "run_started_at", "updated_at", "html_url")) for row in workflow_runs if isinstance(row, dict)],
        "check_runs": [only(row, ("name", "status", "conclusion", "head_sha", "started_at", "completed_at", "html_url")) for row in checks if isinstance(row, dict)],
        "statuses": [only(row, ("context", "state", "description", "target_url", "created_at", "updated_at", "sha")) for row in statuses if isinstance(row, dict)],
        "branch_protection": {"access_status": "allowed" if protection_status == 200 else access_status(protection_status), "required_contexts": sorted(contexts), "expected_contexts": sorted(required_contexts), "context_match": sorted(contexts) == sorted(required_contexts)},
        "mandatory_lanes": lane_results,
        "canaries": [],
    }
    if not github["branch_protection"]["context_match"]:
        gaps.append("live required contexts differ from repository expected contexts")
    if github["branch_protection"]["access_status"] != "allowed":
        gaps.append("branch protection access denied")
    return {
        "schema": SCHEMA, "version": VERSION, "observed_at": utc_now(),
        "repository": {"name": repo, "source": "git remote origin"},
        "observation": {"ref": "refs/heads/main", "main_sha": main_sha, "source": f"GET repos/{repo}/git/ref/heads/main", "revalidated_sha": second_sha},
        "collection": {"complete": not gaps, "readiness": "green" if not gaps else "unknown", "gaps": gaps, "github_access": "allowed" if all(s["access_status"] == "allowed" for s in sources.values()) else "partial"},
        "sources": sources,
        "local": local,
        "github": github,
    }


def atomic_write(path: pathlib.Path, payload: dict) -> None:
    if path.exists() or path.is_symlink():
        raise CollectionError("refusing to overwrite existing output")
    encoded = json.dumps(payload, indent=2, sort_keys=True).encode("utf-8") + b"\n"
    if len(encoded) > MAX_OUTPUT_BYTES:
        raise CollectionError("receipt exceeds output bound")
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(prefix=f".{path.name}.", suffix=".tmp", dir=path.parent)
    try:
        os.fchmod(fd, 0o600)
        with os.fdopen(fd, "wb") as stream:
            stream.write(encoded)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, path)
    finally:
        try:
            os.unlink(temporary)
        except FileNotFoundError:
            pass


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=pathlib.Path)
    parser.add_argument("--verify", type=pathlib.Path)
    parser.add_argument("--fixture", type=pathlib.Path, help="replay fixture command/API responses")
    args = parser.parse_args()
    if bool(args.verify) == bool(args.output):
        parser.error("provide exactly one of --output or --verify")
    if args.verify:
        try:
            receipt = json.loads(args.verify.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            print("invalid inventory JSON", file=sys.stderr)
            return 2
        errors = validate_receipt(receipt)
        if errors:
            print("invalid inventory: " + "; ".join(errors), file=sys.stderr)
            return 1
        print(f"valid inventory: {receipt['collection']['readiness']} ({receipt['observation']['main_sha']})")
        return 0
    fixture = None
    if args.fixture:
        try:
            fixture = json.loads(args.fixture.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            print("invalid fixture JSON", file=sys.stderr)
            return 2
    try:
        receipt = build_receipt(pathlib.Path.cwd(), fixture)
        errors = validate_receipt(receipt)
        if errors:
            raise CollectionError("receipt validation failed: " + "; ".join(errors))
        atomic_write(args.output, receipt)
        print(f"wrote {args.output}: {receipt['collection']['readiness']}")
        return 0
    except CollectionError as exc:
        print(f"collection incomplete: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
