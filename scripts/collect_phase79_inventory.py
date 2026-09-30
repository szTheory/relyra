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
VERSION = 2
MAX_OUTPUT_BYTES = 8 * 1024 * 1024
MAX_ITEMS = 5000
BRANCH_PROTECTION_ENDPOINT = "branches/main/protection"
PROTECTION_CONFIGURATION_FIELDS = {
    "required_status_checks",
    "enforce_admins",
    "required_pull_request_reviews",
    "restrictions",
    "required_signatures",
    "required_linear_history",
    "allow_force_pushes",
    "allow_deletions",
    "block_creations",
    "required_conversation_resolution",
    "lock_branch",
    "allow_fork_syncing",
}
PROTECTION_TOPLEVEL_METADATA_FIELDS = {
    "url",
    "html_url",
    "protection_url",
    "node_id",
    "created_at",
    "updated_at",
}
PROTECTION_NESTED_METADATA_FIELDS = {
    "url",
    "html_url",
    "contexts_url",
    "users_url",
    "teams_url",
    "apps_url",
}
PROTECTION_ACTOR_METADATA_FIELDS = {
    "node_id",
    "type",
    "site_admin",
    "gravatar_id",
    "avatar_url",
    "description",
    "privacy",
    "notification_setting",
    "permission",
    "owner",
    "events",
    "permissions",
    "external_url",
    "created_at",
    "updated_at",
}
SENSITIVE_VALUE_RE = re.compile(
    r"(?:gh[pousr]_[A-Za-z0-9_]{16,}|github_pat_[A-Za-z0-9_]+|authorization\s*:|cookie\s*:|password\s*=|BEGIN (?:RSA )?PRIVATE KEY)",
    re.IGNORECASE,
)
ALLOWED_WORKFLOW_FIELDS = (
    "id", "name", "path", "state", "html_url", "created_at", "updated_at"
)
LANE_STATES = {"passed", "failed", "pending", "skipped", "absent", "unknown"}
REQUIRED_LANES = (
    "mix qa", "mix ci.security", "mix ci.evidence", "mix ci.phase73.reconciliation",
    "mix ci.verify", "mix ci.package", "mix ci.ledger_loop", "browser defenses",
    "standalone defenses",
)
PHASE79_OWNED_LOCAL_PATHS = {
    ".planning/phases/79-adopter-ready-closeout/79-CLOSEOUT.md",
    ".planning/phases/79-adopter-ready-closeout/79-INVENTORY.json",
    ".planning/phases/79-adopter-ready-closeout/79-INVENTORY.md",
    ".planning/phases/79-adopter-ready-closeout/79-PROTECTION-DESIRED.json",
    ".planning/phases/79-adopter-ready-closeout/79-PROTECTION-ROLLBACK.json",
    ".planning/phases/79-adopter-ready-closeout/79-REMOTE-BATCH.md",
    ".planning/phases/79-adopter-ready-closeout/79-RISKS.json",
    ".planning/phases/79-adopter-ready-closeout/79-VALIDATION.md",
}


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
        sequence = item.get("responses") if isinstance(item, dict) else None
        if isinstance(sequence, list):
            calls = fixture.setdefault("_call_counts", {})
            call_key = f"{endpoint}?{page}"
            index = calls.get(call_key, 0)
            calls[call_key] = index + 1
            item = sequence[min(index, len(sequence) - 1)]
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
        headers, _discarded = split_http_response(completed.stdout)
        try:
            http_status = int(headers.get(":status", "0"))
        except ValueError:
            http_status = 0
        if http_status:
            return http_status, None, False
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
    if len(body.encode("utf-8")) > MAX_OUTPUT_BYTES:
        return 598, None, False
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
            pages.append({"number": page, "item_count": 0, "status": status, "continuation": False})
            return {
                "endpoint": endpoint, "page_count": page, "pages": pages,
                "item_count": len(rows), "access_status": access_status(status),
                "completeness": "incomplete", "failure_status": status, "items": [],
            }
        reported_total = body.get("total_count") if isinstance(body, dict) else None
        if isinstance(body, dict):
            list_field = next((field for field in ("workflows", "workflow_runs", "check_runs", "statuses", "jobs") if isinstance(body.get(field), list)), None)
            if list_field is None:
                raise CollectionError(f"GitHub list response is not an array: {endpoint}")
            body = body[list_field]
        if not isinstance(body, list):
            raise CollectionError(f"GitHub list response is not an array: {endpoint}")
        if len(rows) + len(body) > MAX_ITEMS:
            raise CollectionError(f"GitHub list exceeds item bound: {endpoint}")
        rows.extend(body)
        pages.append({"number": page, "item_count": len(body), "status": status, "continuation": has_next})
        if not has_next:
            return {
                "endpoint": endpoint, "page_count": len(pages), "pages": pages,
                "item_count": len(rows), "total_count": reported_total if reported_total is not None else len(rows), "access_status": "allowed",
                "completeness": "complete", "items": rows,
            }
    return {
        "endpoint": endpoint, "page_count": len(pages), "pages": pages,
        "item_count": len(rows), "total_count": len(rows), "access_status": "allowed",
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
    item["html_url"] = safe_github_url(item.get("html_url"))
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
            if path in PHASE79_OWNED_LOCAL_PATHS:
                owner = "phase-79"
                disposition = "preserve; no cleanup authority"
            elif path == ".planning/state.json":
                owner = "gsd-workflow"
                disposition = "preserve; no cleanup authority"
            else:
                owner = "maintainer" if path == ".tool-versions" else "unknown"
                disposition = "preserve; no cleanup authority"
            items.append({"path": path, "git_state": state, "owner": owner, "disposition": disposition})
    candidates = []
    seen_candidate_roots = set()
    for record in ignored_text.split("\0"):
        if not record.startswith("!! "):
            continue
        path = record[3:]
        if not path:
            continue
        root = next((prefix.rstrip("/") for prefix in ("_build/", "deps/", "node_modules/") if path.startswith(prefix)), None)
        if root:
            if root in seen_candidate_roots:
                continue
            seen_candidate_roots.add(root)
            path = root + "/"
        elif path.startswith("tmp/"):
            root = "tmp"
            if root in seen_candidate_roots:
                continue
            seen_candidate_roots.add(root)
            path = "tmp/"
        elif not (path.startswith("tmp") or "/tmp" in path):
            continue
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
            result.append({"path": fields.get("worktree"), "head": fields.get("HEAD"), "branch": fields.get("branch"), "detached": bool(fields.get("detached")), "owner": "unknown", "disposition": "preserve; confirm owner before any cleanup"})
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
    host = None
    path = ""
    if value.startswith("git@"):
        match = re.fullmatch(r"git@([^:/?#]+):([^?#]+)", value)
        if match:
            host, path = match.groups()
    else:
        try:
            parsed = urlparse(value)
            port = parsed.port
            if parsed.scheme == "https" and parsed.username is None and parsed.password is None and port in (None, 443):
                host, path = parsed.hostname, parsed.path.lstrip("/")
            elif parsed.scheme == "ssh" and parsed.username == "git" and parsed.password is None and port in (None, 22):
                host, path = parsed.hostname, parsed.path.lstrip("/")
            if parsed.query or parsed.fragment:
                host = None
        except ValueError:
            raise CollectionError("origin host is not an approved GitHub host (github.com)") from None
    if host is None or host.lower() != "github.com":
        raise CollectionError("origin host is not an approved GitHub host (github.com)")
    path = path[:-4] if path.endswith(".git") else path
    if not re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", path):
        raise CollectionError("could not identify GitHub repository from origin")
    return path


def safe_github_url(value: object) -> str | None:
    if not isinstance(value, str):
        return None
    try:
        parsed = urlparse(value)
        hostname = parsed.hostname
        port = parsed.port
    except ValueError:
        return None
    if (
        parsed.scheme == "https"
        and parsed.username is None
        and parsed.password is None
        and not parsed.query
        and not parsed.fragment
        and port in (None, 443)
        and isinstance(hostname, str)
        and (hostname == "github.com" or hostname.endswith(".github.com"))
    ):
        return value[:2048]
    return None


def compact_pull_request(row: object) -> dict:
    if not isinstance(row, dict):
        return {}
    base = row.get("base") if isinstance(row.get("base"), dict) else {}
    head = row.get("head") if isinstance(row.get("head"), dict) else {}
    result = only(row, ("number", "state", "title", "draft", "updated_at"))
    result.update({"html_url": safe_github_url(row.get("html_url")), "base_ref": base.get("ref"), "head_ref": head.get("ref"), "base_sha": base.get("sha"), "head_sha": head.get("sha")})
    return result


def compact_issue(row: object) -> dict:
    if not isinstance(row, dict):
        return {}
    labels = row.get("labels") if isinstance(row.get("labels"), list) else []
    result = only(row, ("number", "state", "title", "updated_at"))
    result.update({"html_url": safe_github_url(row.get("html_url")), "labels": [label.get("name") for label in labels if isinstance(label, dict) and isinstance(label.get("name"), str)]})
    return result


def raw_single(repo: str, endpoint: str, fixture: dict | None) -> tuple[dict, int]:
    status, body, _ = gh_read(repo, endpoint, 1, fixture)
    return (body if isinstance(body, dict) else {}), status


def strip_protection_metadata(value: object, *, root: bool = False, actor: bool = False) -> object:
    """Keep protection settings and actor identifiers; omit API/profile metadata."""
    if isinstance(value, dict):
        cleaned = {}
        for key, child in value.items():
            if not isinstance(key, str):
                continue
            metadata_fields = PROTECTION_NESTED_METADATA_FIELDS
            if root:
                metadata_fields = metadata_fields | PROTECTION_TOPLEVEL_METADATA_FIELDS
            if actor:
                metadata_fields = metadata_fields | PROTECTION_ACTOR_METADATA_FIELDS
            if key in metadata_fields:
                continue
            cleaned[key] = strip_protection_metadata(
                child,
                actor=key in {"users", "teams", "apps"} and isinstance(child, list),
            )
        return cleaned
    if isinstance(value, list):
        return [strip_protection_metadata(child, actor=actor) for child in value]
    return value


def protection_resource_errors(resource: object) -> list[str]:
    """Validate the configuration-bearing portion of GitHub's protection response."""
    errors = []
    if not isinstance(resource, dict):
        return ["branch protection resource is not an object"]
    if set(resource) != PROTECTION_CONFIGURATION_FIELDS:
        missing = sorted(PROTECTION_CONFIGURATION_FIELDS - set(resource))
        extra = sorted(set(resource) - PROTECTION_CONFIGURATION_FIELDS)
        if missing:
            errors.append("branch protection resource is incomplete (missing settings: " + ", ".join(missing) + ")")
        if extra:
            errors.append("branch protection resource has unmodeled settings: " + ", ".join(extra))

    checks = resource.get("required_status_checks")
    if not isinstance(checks, dict) or set(checks) != {"strict", "contexts", "checks"}:
        errors.append("branch protection required_status_checks is incomplete or malformed")
    else:
        contexts = checks.get("contexts")
        check_rows = checks.get("checks")
        if type(checks.get("strict")) is not bool:
            errors.append("branch protection strict setting is malformed")
        if not isinstance(contexts, list) or not all(isinstance(item, str) and item for item in contexts):
            errors.append("branch protection contexts are malformed")
            contexts = []
        if not isinstance(check_rows, list):
            errors.append("branch protection check-app associations are malformed")
            check_rows = []
        associated_contexts = []
        for row in check_rows:
            if not isinstance(row, dict) or set(row) != {"context", "app_id"}:
                errors.append("branch protection check-app association is incomplete")
                continue
            if not isinstance(row.get("context"), str) or not row["context"]:
                errors.append("branch protection check-app context is malformed")
            app_id = row.get("app_id")
            if app_id is not None and (type(app_id) is not int or app_id < -1):
                errors.append("branch protection check-app id is malformed")
            associated_contexts.append(row.get("context"))
        if sorted(contexts) != sorted(associated_contexts):
            errors.append("branch protection contexts do not match check-app associations")

    enabled_fields = PROTECTION_CONFIGURATION_FIELDS - {
        "required_status_checks",
        "required_pull_request_reviews",
        "restrictions",
    }
    for name in sorted(enabled_fields):
        setting = resource.get(name)
        if not isinstance(setting, dict) or set(setting) != {"enabled"} or type(setting.get("enabled")) is not bool:
            errors.append(f"branch protection {name} setting is incomplete or malformed")

    def validate_actor_rows(rows: object, label: str) -> None:
        if not isinstance(rows, list):
            errors.append(f"branch protection {label} restrictions are malformed")
            return
        for row in rows:
            if not isinstance(row, dict) or not row or not set(row) <= {"id", "login", "name", "slug"}:
                errors.append(f"branch protection {label} restriction is incomplete or unmodeled")
                continue
            if "id" in row and (type(row["id"]) is not int or row["id"] < 0):
                errors.append(f"branch protection {label} restriction id is malformed")
            if any(not isinstance(row[key], str) or not row[key] for key in ("login", "name", "slug") if key in row):
                errors.append(f"branch protection {label} restriction identity is malformed")

    def validate_restrictions(value: object, label: str) -> None:
        if value is None:
            return
        if not isinstance(value, dict) or set(value) != {"users", "teams", "apps"}:
            errors.append(f"branch protection {label} settings are incomplete or unmodeled")
            return
        for kind in ("users", "teams", "apps"):
            validate_actor_rows(value.get(kind), f"{label} {kind}")

    reviews = resource.get("required_pull_request_reviews")
    if reviews is not None:
        review_fields = {
            "dismiss_stale_reviews",
            "require_code_owner_reviews",
            "required_approving_review_count",
            "require_last_push_approval",
            "dismissal_restrictions",
        }
        if not isinstance(reviews, dict) or set(reviews) != review_fields:
            errors.append("branch protection review rules are incomplete or unmodeled")
        else:
            for field in ("dismiss_stale_reviews", "require_code_owner_reviews", "require_last_push_approval"):
                if type(reviews.get(field)) is not bool:
                    errors.append(f"branch protection review rule {field} is malformed")
            count = reviews.get("required_approving_review_count")
            if type(count) is not int or count < 0:
                errors.append("branch protection required approval count is malformed")
            validate_restrictions(reviews.get("dismissal_restrictions"), "dismissal")

    validate_restrictions(resource.get("restrictions"), "push")
    if SENSITIVE_VALUE_RE.search(json.dumps(resource, sort_keys=True)):
        errors.append("branch protection resource contains a secret-shaped value")
    return errors


def capture_protection_resource(body: object, status: int) -> dict:
    observed_fields = sorted(key for key in body if isinstance(key, str)) if isinstance(body, dict) else []
    errors = []
    resource = None
    if status != 200:
        if status == 598:
            errors.append("branch protection response exceeded the 8 MiB receipt bound")
        else:
            errors.append(f"branch protection GET unavailable (HTTP {status})")
    elif not isinstance(body, dict):
        errors.append("branch protection response is not an object")
    else:
        try:
            raw_size = len(json.dumps(body, separators=(",", ":")).encode("utf-8"))
        except (TypeError, ValueError):
            raw_size = MAX_OUTPUT_BYTES + 1
        if raw_size > MAX_OUTPUT_BYTES:
            errors.append("branch protection response exceeded the 8 MiB receipt bound")
        elif SENSITIVE_VALUE_RE.search(json.dumps(body, sort_keys=True)):
            errors.append("branch protection response contains a secret-shaped value")
        else:
            known_response_fields = PROTECTION_CONFIGURATION_FIELDS | PROTECTION_TOPLEVEL_METADATA_FIELDS
            unknown = sorted(set(body) - known_response_fields)
            missing = sorted(PROTECTION_CONFIGURATION_FIELDS - set(body))
            if unknown:
                errors.append("branch protection response has unmodeled fields: " + ", ".join(unknown))
            if missing:
                errors.append("branch protection response is missing settings: " + ", ".join(missing))
            if not errors:
                candidate = strip_protection_metadata(body, root=True)
                errors.extend(protection_resource_errors(candidate))
                if not errors:
                    resource = candidate
    return {
        "capture_status": "complete" if resource is not None else "incomplete",
        "observed_fields": observed_fields,
        "resource": resource,
        "capture_errors": errors,
    }


def lane_owners(root: pathlib.Path, fixture: dict | None = None) -> dict[str, list[str]]:
    """Map executable mandatory-lane references to tracked workflow owners."""
    workflow_dir = root / ".github/workflows"
    contents = {}
    try:
        tracked = command(["git", "ls-files", "-z", ".github/workflows"], cwd=root, fixture=fixture).split("\0")
    except (OSError, subprocess.SubprocessError, CollectionError):
        tracked = []
    for relative in sorted(path for path in tracked if path.endswith((".yml", ".yaml"))):
        path = root / relative
        if not path.is_file() or path.is_symlink():
            continue
        contents[path.name] = path.read_text(encoding="utf-8", errors="replace")
    # The security-gates workflow is the canonical mandatory CI owner. Release
    # workflows also run some aliases, but those runs do not establish the
    # protected-main lane contract.
    security_workflow = contents.get("security-gates.yml", "")
    aliases = ("mix qa", "mix ci.security", "mix ci.evidence", "mix ci.phase73.reconciliation", "mix ci.verify")
    result = {}
    for lane in aliases:
        command_pattern = re.compile(r"(?m)^\s*run:\s*" + re.escape(lane) + r"\s*$")
        result[lane] = ["security-gates.yml"] if command_pattern.search(security_workflow) else []
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
    result["mix ci.package"] = ["security-gates.yml"] if re.search(r"(?m)^\s*scripts/check_clean_room_consumer\.sh\s+--profile\s+", security_workflow) else []
    result["mix ci.ledger_loop"] = ["security-gates.yml"] if "mix cmd --cd demo/ledger_loop mix deps.get" in security_workflow and "run: mix ci.demo" in security_workflow else []
    result["browser defenses"] = ["security-gates.yml"] if "run: npx playwright install" in security_workflow and "run: npm run admin-ui:smoke" in security_workflow else []
    result["standalone defenses"] = ["security-gates.yml"] if re.search(r"(?m)^\s*run:\s*mix test --only gate02_c14n --warnings-as-errors\s*$", security_workflow) else []
    return result


def protection_context_owners(name: str) -> list[str]:
    """Bind configured protection contexts to the workflow that emits each job check."""
    owners = {
        "security (27, 1.19.5)": ["security-gates.yml"],
        "security (28, 1.19.5)": ["security-gates.yml"],
        "fleet-proxy-e2e": ["fleet-proxy-e2e.yml"],
    }
    return owners.get(name, [])


def workflow_path_name(value: object) -> str:
    """Normalize GitHub's workflow path, which may include an @ref suffix."""
    if not isinstance(value, str):
        return ""
    path, separator, ref = value.rpartition("@")
    if separator and ref and pathlib.PurePosixPath(path).suffix.lower() in {".yml", ".yaml"}:
        value = path
    return pathlib.PurePosixPath(value).name


def select_latest_owner_runs(sha: str, owners: set[str], runs: list) -> tuple[dict[str, dict], set[str]]:
    """Select one unambiguous latest run per workflow owner for the observed SHA."""
    candidates: dict[str, list[tuple[dt.datetime, int, dict]]] = {owner: [] for owner in owners}
    ambiguous = set()
    for run in runs:
        if not isinstance(run, dict) or run.get("head_sha") != sha:
            continue
        owner = workflow_path_name(run.get("path"))
        if owner not in owners:
            continue
        attempt = run.get("run_attempt")
        stamp = run.get("run_started_at")
        if type(attempt) is not int or attempt < 1 or not isinstance(stamp, str):
            ambiguous.add(owner)
            continue
        try:
            started = dt.datetime.fromisoformat(stamp.replace("Z", "+00:00"))
        except ValueError:
            ambiguous.add(owner)
            continue
        if started.utcoffset() is None or run.get("id") is None:
            ambiguous.add(owner)
            continue
        candidates[owner].append((started, attempt, run))

    selected = {}
    for owner, rows in candidates.items():
        if owner in ambiguous or not rows:
            continue
        latest_key = max((started, attempt) for started, attempt, _run in rows)
        latest = [run for started, attempt, run in rows if (started, attempt) == latest_key]
        if len(latest) != 1:
            ambiguous.add(owner)
            continue
        selected[owner] = latest[0]
    return selected, ambiguous


def job_check_run_id(job: dict) -> int | None:
    """Read the check-run ID from the exact URL exposed by the workflow jobs API."""
    check_run_url = job.get("check_run_url")
    if not isinstance(check_run_url, str):
        return None
    match = re.search(r"/check-runs/(\d+)$", urlparse(check_run_url).path)
    return int(match.group(1)) if match else None


def collect_owner_jobs(repo: str, selected_runs: dict[str, dict], fixture: dict | None) -> tuple[list[dict], dict[str, dict]]:
    jobs = []
    sources = {}
    for owner, run in sorted(selected_runs.items()):
        run_id = run.get("id")
        endpoint = f"actions/runs/{run_id}/jobs?filter=latest"
        source = page_source(repo, endpoint, fixture)
        sources[f"workflow_jobs_run_{run_id}"] = {key: value for key, value in source.items() if key != "items"}
        for job in source.get("items", []):
            if not isinstance(job, dict):
                continue
            jobs.append({
                **only(job, ("id", "name", "status", "conclusion", "head_sha", "started_at", "completed_at")),
                "run_id": run_id,
                "run_attempt": run.get("run_attempt"),
                "workflow_path": run.get("path"),
                "check_run_id": job_check_run_id(job),
            })
    return jobs, sources


def classify_lane(name: str, checks: list, statuses: list, sha: str, owners: list | None = None, runs: list | None = None, required_check_names: list[str] | None = None, jobs: list | None = None, ambiguous_owners: set[str] | None = None) -> dict:
    # A job check is accepted only through its check_run_url in the jobs list
    # for the selected workflow run. Check-suite IDs are shared across Actions
    # workflows and therefore do not establish workflow ownership.
    owner_paths = {
        workflow_path_name(owner)
        for owner in owners or []
        if owner.endswith((".yml", ".yaml"))
    }
    if not owner_paths:
        return {"state": "absent", "sha": sha, "evidence_count": 0, "owners": [], "check_names": [], "evidence": []}

    required_checks = {
        "security-gates.yml": ["security (27, 1.19.5)", "security (28, 1.19.5)"],
        "fleet-proxy-e2e.yml": ["fleet-proxy-e2e"],
    }
    expected_names = sorted(set(required_check_names or [
        check_name
        for path in owner_paths
        for check_name in required_checks.get(path, [])
    ]))
    if not expected_names:
        return {"state": "absent", "sha": sha, "evidence_count": 0, "owners": sorted(owner_paths), "check_names": [], "evidence": []}
    ambiguous_owners = ambiguous_owners or set()
    if owner_paths & ambiguous_owners:
        return {"state": "unknown", "sha": sha, "evidence_count": 0, "owners": sorted(owner_paths), "check_names": expected_names, "evidence": []}
    selected_runs = [run for run in (runs or []) if workflow_path_name(run.get("path")) in owner_paths]
    if not selected_runs:
        return {"state": "absent", "sha": sha, "evidence_count": 0, "owners": sorted(owner_paths), "check_names": expected_names, "evidence": []}

    def check_state(row: dict) -> str:
        status = str(row.get("status", "")).lower()
        conclusion = str(row.get("conclusion") or "").lower()
        if status != "completed":
            return "pending" if status in {"queued", "in_progress", "requested", "waiting"} else "unknown"
        if conclusion in {"success", "successful"}:
            return "passed"
        if conclusion in {"failure", "failed", "timed_out", "action_required", "error", "cancelled"}:
            return "failed"
        if conclusion == "skipped":
            return "skipped"
        return "unknown"

    states = []
    selected_evidence = []
    selected_run_ids = {run.get("id") for run in selected_runs}
    for check_name in expected_names:
        matching_jobs = [
            job for job in jobs or []
            if isinstance(job, dict) and job.get("run_id") in selected_run_ids
            and job.get("head_sha") == sha and job.get("name") == check_name
            and job.get("workflow_path") in {run.get("path") for run in selected_runs if run.get("id") == job.get("run_id")}
            and job.get("run_attempt") == next((run.get("run_attempt") for run in selected_runs if run.get("id") == job.get("run_id")), None)
        ]
        if len(matching_jobs) != 1:
            states.append("unknown" if len(matching_jobs) > 1 else "absent")
            continue
        job = matching_jobs[0]
        check_id = job.get("check_run_id")
        check = next((row for row in checks if isinstance(row, dict) and row.get("id") == check_id and row.get("head_sha") == sha and row.get("name") == check_name), None)
        if check is None:
            states.append("unknown")
            continue
        state = check_state(check)
        states.append(state)
        selected_run = next(run for run in selected_runs if run.get("id") == job.get("run_id"))
        selected_evidence.append({
            "check_run_id": check_id,
            "check_name": check_name,
            "check_suite_id": check.get("check_suite_id"),
            "workflow_run_id": selected_run.get("id"),
            "workflow_job_id": job.get("id"),
            "run_attempt": selected_run.get("run_attempt"),
            "workflow_path": selected_run.get("path"),
        })
    for run in selected_runs:
        conclusion = str(run.get("conclusion") or "").lower()
        status = str(run.get("status") or "").lower()
        if status != "completed":
            states.append("pending" if status in {"queued", "in_progress", "requested", "waiting"} else "unknown")
        elif conclusion not in {"success", "successful"}:
            states.append("failed" if conclusion in {"failure", "failed", "timed_out", "action_required", "error", "cancelled"} else "unknown")
    state = ("failed" if "failed" in states else "pending" if "pending" in states
             else "unknown" if "unknown" in states else "absent" if "absent" in states
             else "passed")
    return {"state": state, "sha": sha, "evidence_count": len(selected_evidence),
            "owners": sorted(owner_paths), "check_names": expected_names, "evidence": selected_evidence}


def unknown_field_errors(value: object, allowed: set[str], label: str) -> list[str]:
    if not isinstance(value, dict):
        return [f"{label} is not an object"]
    unknown = set(value) - allowed
    return [f"{label} has unallowlisted fields: {', '.join(sorted(unknown))}"] if unknown else []


def object_or_empty(value: object, label: str, errors: list[str]) -> dict:
    if not isinstance(value, dict):
        errors.append(f"{label} is not an object")
        return {}
    return value


def object_rows_or_empty(value: object, label: str, errors: list[str]) -> list[dict]:
    if not isinstance(value, list):
        errors.append(f"{label} is not an array")
        return []
    rows = []
    for index, row in enumerate(value):
        if isinstance(row, dict):
            rows.append(row)
        else:
            errors.append(f"{label}[{index}] is not an object")
    return rows


def validate_evidence_binding(result: dict, sha: str, checks: list[dict], runs: list[dict], jobs: list[dict], label: str, expected_owners: list[str], expected_names: list[str], errors: list[str]) -> None:
    if result.get("owners") != expected_owners or result.get("check_names") != expected_names:
        errors.append(f"{label} has unexpected evidence owners or check names")
    workflow_owners = {
        workflow_path_name(owner)
        for owner in expected_owners
        if owner.endswith((".yml", ".yaml"))
    }
    evidence = object_rows_or_empty(result.get("evidence", []), f"{label} evidence", errors)
    result["evidence"] = evidence
    names_seen = set()
    for item in evidence:
        errors.extend(unknown_field_errors(item, {"check_run_id", "check_name", "check_suite_id", "workflow_run_id", "workflow_job_id", "run_attempt", "workflow_path"}, f"{label} evidence item"))
        check = next((row for row in checks if row.get("id") == item.get("check_run_id")), None)
        run = next((row for row in runs if row.get("id") == item.get("workflow_run_id")), None)
        job = next((row for row in jobs if row.get("id") == item.get("workflow_job_id")), None)
        if (check is None or check.get("head_sha") != sha
                or check.get("name") != item.get("check_name")
                or check.get("check_suite_id") != item.get("check_suite_id")):
            errors.append(f"{label} evidence does not match a current-SHA check run")
            continue
        if run is None:
            errors.append(f"{label} evidence references an absent workflow run")
        else:
            if run.get("head_sha") != sha:
                errors.append(f"{label} workflow run is not bound to the observed SHA")
            if run.get("path") != item.get("workflow_path"):
                errors.append(f"{label} workflow path does not match its evidence")
            if run.get("run_attempt") != item.get("run_attempt"):
                errors.append(f"{label} workflow attempt does not match its evidence")
            if workflow_path_name(run.get("path")) not in workflow_owners:
                errors.append(f"{label} workflow run is not owned by the configured workflow")
            if result.get("state") == "passed" and (
                run.get("status") != "completed"
                or not isinstance(run.get("conclusion"), str)
                or run.get("conclusion") not in {"success", "successful"}
            ):
                errors.append(f"{label} passing state references a non-successful workflow run")
        if (job is None or job.get("run_id") != item.get("workflow_run_id")
                or job.get("run_attempt") != item.get("run_attempt")
                or job.get("check_run_id") != item.get("check_run_id")
                or job.get("head_sha") != sha or job.get("name") != item.get("check_name")
                or job.get("workflow_path") != item.get("workflow_path")):
            errors.append(f"{label} evidence is not linked through the selected workflow job")
        if result.get("state") == "passed" and (
            check.get("status") != "completed"
            or not isinstance(check.get("conclusion"), str)
            or check.get("conclusion") not in {"success", "successful"}
        ):
            errors.append(f"{label} passing state references a non-passing check run")
        check_name = item.get("check_name")
        if isinstance(check_name, str):
            names_seen.add(check_name)
        else:
            errors.append(f"{label} evidence has a malformed check name")
    if result.get("evidence_count") != len(evidence):
        errors.append(f"{label} evidence count does not match selected evidence rows")
    if result.get("state") == "passed" and (names_seen != set(expected_names) or len(evidence) != len(expected_names)):
        errors.append(f"{label} passing state lacks exactly one passing check for each required owner job")


def validate_receipt(receipt: object) -> list[str]:
    if not isinstance(receipt, dict):
        return ["receipt is not an object"]
    errors = unknown_field_errors(receipt, {"schema", "version", "observed_at", "repository", "observation", "collection", "sources", "local", "github"}, "receipt")
    for key in ("repository", "observation", "collection", "sources", "local", "github"):
        receipt[key] = object_or_empty(receipt.get(key, {}), key, errors)
    if receipt.get("schema") != SCHEMA or receipt.get("version") != VERSION:
        errors.append("unsupported schema or version")
    observed = receipt.get("observed_at", "")
    try:
        if not isinstance(observed, str):
            raise ValueError
        parsed = dt.datetime.fromisoformat(observed.replace("Z", "+00:00"))
        if parsed.utcoffset() != dt.timedelta(0):
            errors.append("observation timestamp is not UTC")
    except (ValueError, AttributeError):
        errors.append("invalid UTC observation timestamp")
    if not isinstance(observed, str) or not observed.endswith("Z"):
        errors.append("observation timestamp is not UTC")
    repo = receipt.get("repository", {})
    errors.extend(unknown_field_errors(repo, {"name", "source"}, "repository"))
    if not repo.get("name"):
        errors.append("missing repository identity")
    observation = receipt.get("observation", {})
    errors.extend(unknown_field_errors(observation, {"ref", "main_sha", "source", "revalidated_sha", "revalidation_source"}, "observation"))
    sha = observation.get("main_sha", "")
    if observation.get("ref") != "refs/heads/main" or not isinstance(sha, str) or not re.fullmatch(r"[0-9a-f]{40}", sha):
        errors.append("missing or invalid observed main SHA/ref")
    collection = receipt.get("collection", {})
    errors.extend(unknown_field_errors(collection, {"complete", "readiness", "gaps", "github_access"}, "collection"))
    claimed_complete = collection.get("complete") is True
    if claimed_complete and collection.get("readiness") != "green":
        errors.append("complete receipt cannot have a non-green readiness label")
    if not claimed_complete and (collection.get("readiness") == "green" or not collection.get("gaps")):
        errors.append("incomplete receipt must retain explicit gaps and cannot read as green")
    sources = receipt.get("sources", {})
    if not sources:
        errors.append("missing source provenance")
    for name, source in list(sources.items()):
        source = object_or_empty(source, f"source {name}", errors)
        sources[name] = source
        errors.extend(unknown_field_errors(source, {"endpoint", "page_count", "pages", "item_count", "total_count", "access_status", "completeness", "failure_status", "sha"}, f"source {name}"))
        if not source.get("endpoint") or not source.get("access_status"):
            errors.append(f"source {name} lacks endpoint or access status")
        if claimed_complete and (source.get("completeness") != "complete" or not source.get("page_count") or source.get("access_status") != "allowed"):
            errors.append(f"source {name} is incomplete or inaccessible")
        pages = object_rows_or_empty(source.get("pages", []), f"source {name} pages", errors)
        source["pages"] = pages
        if source.get("page_count") != len(pages):
            errors.append(f"source {name} has inconsistent page count")
        for page in pages:
            errors.extend(unknown_field_errors(page, {"number", "item_count", "status", "continuation"}, f"source {name} page"))
        page_numbers = [p.get("number") for p in pages]
        if page_numbers != list(range(1, len(page_numbers) + 1)):
            errors.append(f"source {name} has missing or duplicate pages")
        if claimed_complete and source.get("total_count") is not None and source.get("item_count") != source.get("total_count"):
            errors.append(f"source {name} item count does not match total")
    github = receipt.get("github", {})
    errors.extend(unknown_field_errors(github, {"pull_requests", "issues", "remote_branches", "workflows", "workflow_runs", "check_runs", "workflow_jobs", "statuses", "branch_protection", "mandatory_lanes", "canaries"}, "github"))
    github["mandatory_lanes"] = object_or_empty(github.get("mandatory_lanes", {}), "mandatory lanes", errors)
    github["branch_protection"] = object_or_empty(github.get("branch_protection", {}), "branch protection", errors)
    collection_fields = {
        "pull_requests": {"number", "state", "title", "draft", "updated_at", "html_url", "base_ref", "head_ref", "base_sha", "head_sha"},
        "issues": {"number", "state", "title", "updated_at", "html_url", "labels"},
        "remote_branches": {"name", "sha", "protected"},
        "workflows": {"id", "name", "path", "state", "html_url", "created_at", "updated_at"},
        "workflow_runs": {"id", "name", "workflow_id", "path", "event", "status", "conclusion", "head_branch", "head_sha", "check_suite_id", "run_attempt", "run_started_at", "updated_at", "html_url"},
        "check_runs": {"id", "name", "status", "conclusion", "head_sha", "check_suite_id", "started_at", "completed_at", "html_url"},
        "workflow_jobs": {"id", "name", "status", "conclusion", "head_sha", "started_at", "completed_at", "run_id", "run_attempt", "workflow_path", "check_run_id"},
        "statuses": {"context", "state", "description", "target_url", "created_at", "updated_at", "sha"},
    }
    for name, allowed in collection_fields.items():
        rows = object_rows_or_empty(github.get(name, []), f"github {name}", errors)
        github[name] = rows
        for row in rows:
            errors.extend(unknown_field_errors(row, allowed, f"github {name}"))
    github["canaries"] = object_rows_or_empty(github.get("canaries", []), "github canaries", errors)
    for row in github.get("canaries", []):
        errors.extend(unknown_field_errors(row, {"run_id", "name", "ref", "sha", "observed_at", "status", "source"}, "github canary"))
    local = receipt.get("local", {})
    errors.extend(unknown_field_errors(local, {"tracked_path_count", "tracked_edits", "untracked_paths", "ignored_generated_candidates", "worktrees", "branches"}, "local"))
    for local_collection, allowed in {
        "tracked_edits": {"path", "git_state", "owner", "disposition"},
        "untracked_paths": {"path", "git_state", "owner", "disposition"},
        "ignored_generated_candidates": {"path", "owner", "disposition"},
        "worktrees": {"path", "head", "branch", "detached", "owner", "disposition"},
        "branches": {"name", "sha"},
    }.items():
        rows = object_rows_or_empty(local.get(local_collection, []), f"local {local_collection}", errors)
        local[local_collection] = rows
        for row in rows:
            errors.extend(unknown_field_errors(row, allowed, f"local {local_collection}"))
    for row in github.get("check_runs", []):
        if claimed_complete and row.get("head_sha") != sha:
            errors.append("check run is not bound to observed main SHA")
    for name in REQUIRED_LANES:
        lane = github.get("mandatory_lanes", {}).get(name)
        if not isinstance(lane, dict):
            errors.append(f"mandatory lane missing or unrecognized: {name}")
            continue
        if not isinstance(lane.get("state"), str) or lane.get("state") not in LANE_STATES:
            errors.append(f"mandatory lane missing or unrecognized: {name}")
        else:
            lane = object_or_empty(lane, f"mandatory lane {name}", errors)
            github["mandatory_lanes"][name] = lane
            errors.extend(unknown_field_errors(lane, {"state", "sha", "evidence_count", "owners", "check_names", "evidence"}, f"mandatory lane {name}"))
            lane_owners_value = lane.get("owners", [])
            if not isinstance(lane_owners_value, list) or not all(isinstance(owner, str) for owner in lane_owners_value):
                errors.append(f"mandatory lane owners are malformed: {name}")
                lane_owners_value = []
            workflow_owner_names = sorted({
                workflow_path_name(owner)
                for owner in lane_owners_value
                if owner.endswith((".yml", ".yaml"))
            })
            required_names = sorted({
                check_name
                for owner in workflow_owner_names
                for check_name in {
                    "security-gates.yml": ["security (27, 1.19.5)", "security (28, 1.19.5)"],
                    "fleet-proxy-e2e.yml": ["fleet-proxy-e2e"],
                }.get(owner, [])
            })
            validate_evidence_binding(
                lane, sha, github.get("check_runs", []), github.get("workflow_runs", []), github.get("workflow_jobs", []),
                f"mandatory lane {name}", lane_owners_value, required_names, errors,
            )
            if claimed_complete and (lane.get("sha") != sha or lane.get("state") != "passed" or not lane.get("owners")):
                errors.append(f"mandatory lane is not completely green on observed main SHA: {name}")
    for workflow in github.get("workflows", []):
        if claimed_complete and (not isinstance(workflow.get("state"), str) or workflow.get("state") not in {"active", "disabled"}):
            errors.append("workflow state is absent or unrecognized")
    protection = github.get("branch_protection", {})
    errors.extend(unknown_field_errors(protection, {
        "access_status", "required_contexts", "expected_contexts", "context_match", "context_results",
        "capture_status", "capture_errors", "observed_fields", "resource", "source_endpoint",
    }, "branch protection"))
    protection_source = sources.get("branch_protection", {})
    if protection.get("source_endpoint") != BRANCH_PROTECTION_ENDPOINT or protection_source.get("endpoint") != BRANCH_PROTECTION_ENDPOINT:
        errors.append("branch protection source endpoint is missing or mismatched")
    if protection.get("access_status") != protection_source.get("access_status"):
        errors.append("branch protection access status does not match its source record")
    observed_fields = protection.get("observed_fields", [])
    if not isinstance(observed_fields, list) or not all(isinstance(field, str) for field in observed_fields):
        errors.append("branch protection observed fields are malformed")
        observed_fields = []
    if observed_fields != sorted(set(observed_fields)):
        errors.append("branch protection observed fields are not unique and sorted")
    capture_errors = protection.get("capture_errors", [])
    if not isinstance(capture_errors, list) or not all(isinstance(message, str) and message for message in capture_errors):
        errors.append("branch protection capture errors are malformed")
        capture_errors = []
    capture_status = protection.get("capture_status")
    if capture_status not in {"complete", "incomplete"}:
        errors.append("branch protection capture status is missing or unrecognized")
    if capture_status == "complete":
        resource = protection.get("resource")
        errors.extend(protection_resource_errors(resource))
        allowed_response_fields = PROTECTION_CONFIGURATION_FIELDS | PROTECTION_TOPLEVEL_METADATA_FIELDS
        if not PROTECTION_CONFIGURATION_FIELDS <= set(observed_fields) or not set(observed_fields) <= allowed_response_fields:
            errors.append("branch protection observed fields do not prove a complete modeled response")
        if capture_errors:
            errors.append("complete branch protection capture retains capture errors")
        if protection_source.get("completeness") != "complete":
            errors.append("complete branch protection capture has an incomplete source record")
        if isinstance(resource, dict):
            required_status_checks = resource.get("required_status_checks")
            actual_contexts = (
                required_status_checks.get("contexts")
                if isinstance(required_status_checks, dict)
                else None
            )
            if not isinstance(actual_contexts, list) or sorted(actual_contexts) != sorted(
                protection.get("required_contexts", [])
            ):
                errors.append("branch protection resource contexts do not match the inventory")
    else:
        if protection.get("resource") is not None or not capture_errors:
            errors.append("incomplete branch protection capture must name its failure and omit the resource")
        if protection_source.get("completeness") != "incomplete":
            errors.append("incomplete branch protection capture has a complete source record")
        if claimed_complete:
            errors.append("complete inventory cannot contain an incomplete branch protection capture")
    protection["context_results"] = object_or_empty(protection.get("context_results", {}), "protection context results", errors)
    required_contexts_value = protection.get("required_contexts", [])
    if not isinstance(required_contexts_value, list) or not all(isinstance(context, str) for context in required_contexts_value):
        errors.append("branch protection required contexts is not an array")
        required_contexts_value = []
    protection["required_contexts"] = required_contexts_value
    expected_contexts_value = protection.get("expected_contexts", [])
    if not isinstance(expected_contexts_value, list) or not all(isinstance(context, str) for context in expected_contexts_value):
        errors.append("branch protection expected contexts is not an array")
        expected_contexts_value = []
    if type(protection.get("context_match")) is not bool or protection.get("context_match") != (
        sorted(required_contexts_value) == sorted(expected_contexts_value)
    ):
        errors.append("branch protection context match does not reflect observed and expected contexts")
    context_results = protection.get("context_results", {})
    for context, result in list(context_results.items()):
        result = object_or_empty(result, f"protection context {context}", errors)
        context_results[context] = result
        errors.extend(unknown_field_errors(result, {"state", "sha", "evidence_count", "owners", "check_names", "evidence"}, f"protection context {context}"))
        expected_owners = protection_context_owners(context)
        validate_evidence_binding(
            result, sha, github.get("check_runs", []), github.get("workflow_runs", []), github.get("workflow_jobs", []),
            f"protection context {context}", expected_owners, [context] if expected_owners else [], errors,
        )
        if result.get("state") == "passed" and result.get("sha") != sha:
            errors.append(f"required protection context is not green on observed main SHA: {context}")
    if claimed_complete:
        if collection.get("readiness") != "green" or collection.get("gaps"):
            errors.append("complete receipt must be green and gap-free")
        if observation.get("revalidated_sha") != sha:
            errors.append("main ref changed during collection")
        if protection.get("access_status") != "allowed" or protection.get("context_match") is not True:
            errors.append("branch protection is inaccessible or differs from expected contexts")
        for context, result in context_results.items():
            if result.get("state") != "passed" or result.get("sha") != sha:
                errors.append(f"required protection context is not green on observed main SHA: {context}")
        if set(context_results) != set(protection.get("required_contexts", [])):
            errors.append("required protection context observations are incomplete")
    if SENSITIVE_VALUE_RE.search(json.dumps(receipt, sort_keys=True)):
        errors.append("receipt contains sensitive data")
    if len(json.dumps(receipt, separators=(",", ":")).encode()) > MAX_OUTPUT_BYTES:
        errors.append("receipt exceeds output bound")
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
        "workflow_runs": f"actions/runs?head_sha={main_sha}",
        "check_runs": f"commits/{main_sha}/check-runs",
        "statuses": f"commits/{main_sha}/status",
    }
    rows = {}
    for name, endpoint in endpoints.items():
        source = page_source(repo, endpoint, fixture)
        sources[name] = {key: value for key, value in source.items() if key != "items"}
        rows[name] = source.get("items", [])
    sources["main_ref"] = {"endpoint": "git/ref/heads/main", "page_count": 1 if main_status == 200 else 0, "pages": [{"number": 1, "item_count": 1, "status": main_status, "continuation": False}] if main_status == 200 else [], "item_count": 1 if main_status == 200 else 0, "access_status": "allowed" if main_status == 200 else access_status(main_status), "completeness": "complete" if main_status == 200 else "incomplete", "failure_status": main_status if main_status != 200 else None}
    protection, protection_status = raw_single(repo, BRANCH_PROTECTION_ENDPOINT, fixture)
    protection_capture = capture_protection_resource(protection, protection_status)
    protection_access = "allowed" if protection_status == 200 else access_status(protection_status)
    protection_complete = protection_capture["capture_status"] == "complete"
    sources["branch_protection"] = {
        "endpoint": BRANCH_PROTECTION_ENDPOINT,
        "page_count": 1 if protection_status == 200 else 0,
        "pages": [{"number": 1, "item_count": 1, "status": protection_status, "continuation": False}] if protection_status == 200 else [],
        "item_count": 1 if protection_status == 200 else 0,
        "access_status": protection_access,
        "completeness": "complete" if protection_complete else "incomplete",
        "failure_status": protection_status if protection_status != 200 else None,
    }
    sources["check_runs"]["sha"] = main_sha
    sources["statuses"]["sha"] = main_sha
    expected = json.loads(command(["scripts/setup_branch_protection.sh", "--print-expected-json"], cwd=root, fixture=fixture))
    raw_contexts = protection.get("required_status_checks", {}).get("contexts", []) if protection_status == 200 else []
    contexts = raw_contexts if isinstance(raw_contexts, list) and all(isinstance(item, str) for item in raw_contexts) else []
    checks = rows.get("check_runs", [])
    statuses = rows.get("statuses", [])
    lanes = lane_owners(root, fixture)
    required_contexts = expected.get("required_status_checks", {}).get("contexts", [])
    workflow_runs = rows.get("workflow_runs", [])
    if workflow_runs and isinstance(workflow_runs[0], dict) and "workflow_runs" in workflow_runs[0]:
        workflow_runs = workflow_runs[0]["workflow_runs"]
    owner_paths = {
        workflow_path_name(owner)
        for owner_list in list(lanes.values()) + [protection_context_owners(context) for context in required_contexts]
        for owner in owner_list
        if owner.endswith((".yml", ".yaml"))
    }
    latest_owner_runs, ambiguous_owner_paths = select_latest_owner_runs(main_sha, owner_paths, workflow_runs)
    selected_owner_runs = list(latest_owner_runs.values())
    workflow_jobs, workflow_job_sources = collect_owner_jobs(repo, latest_owner_runs, fixture)
    sources.update(workflow_job_sources)
    lane_results = {
        name: {**classify_lane(name, checks, statuses, main_sha, lanes.get(name, []), selected_owner_runs, jobs=workflow_jobs, ambiguous_owners=ambiguous_owner_paths), "owners": lanes.get(name, [])}
        for name in REQUIRED_LANES
    }
    second_main, second_status = raw_single(repo, "git/ref/heads/main", fixture)
    second_sha = str(second_main.get("object", {}).get("sha", "")) if second_status == 200 else ""
    gaps = []
    if second_sha != main_sha:
        gaps.append("main ref changed during collection; mixed-SHA receipt rejected")
    for name, source in sources.items():
        if source["completeness"] != "complete":
            gaps.append(f"{name} collection incomplete ({source['access_status']})")
    if ambiguous_owner_paths:
        gaps.append("latest owner workflow run or attempt is ambiguous for observed main SHA")
    if protection_status != 200:
        gaps.append(f"branch protection inaccessible ({access_status(protection_status)})")
    if not protection_complete:
        gaps.append("branch protection configuration capture is incomplete")
    if any(not lane["owners"] for lane in lane_results.values()):
        gaps.append("one or more mandatory lanes lack a workflow owner")
    if any(lane["state"] != "passed" for lane in lane_results.values()):
        gaps.append("one or more mandatory lanes are not green on observed main SHA")
    context_results = {
        name: classify_lane(
            name, checks, statuses, main_sha, protection_context_owners(name), selected_owner_runs,
            required_check_names=[name], jobs=workflow_jobs, ambiguous_owners=ambiguous_owner_paths,
        )
        for name in required_contexts
    }
    issue_rows = [row for row in rows["issues"] if isinstance(row, dict) and "pull_request" not in row]
    if any(item.get("state") == "unknown" for item in [workflow_item(row) for row in rows["workflows"] if isinstance(row, dict)]):
        gaps.append("workflow catalog contains an absent or unrecognized state")
    if any(result["state"] != "passed" for result in context_results.values()):
        gaps.append("one or more branch-protection contexts lack passing current-main evidence")
    canary_terms = ("canary", "rulestead", "real-idp")
    canaries = [
        {"run_id": row.get("id"), "name": row.get("name"), "ref": row.get("head_branch"), "sha": row.get("head_sha"), "observed_at": row.get("updated_at"), "status": row.get("conclusion") or row.get("status"), "source": "GitHub Actions workflow run"}
        for row in workflow_runs if isinstance(row, dict) and any(word in str(row.get("name", "") + row.get("path", "")).lower() for word in canary_terms)
    ]
    canaries.extend(
        {"run_id": row.get("id"), "name": row.get("name"), "ref": None, "sha": row.get("head_sha"), "observed_at": row.get("completed_at") or row.get("started_at"), "status": row.get("conclusion") or row.get("status"), "source": "GitHub Actions check run"}
        for row in checks if isinstance(row, dict) and any(word in str(row.get("name", "")).lower() for word in canary_terms)
    )
    github = {
        "pull_requests": [compact_pull_request(row) for row in rows["pull_requests"]],
        "issues": [compact_issue(row) for row in issue_rows],
        "remote_branches": [{"name": row.get("name"), "sha": row.get("commit", {}).get("sha") if isinstance(row.get("commit"), dict) else None, "protected": row.get("protected")} for row in rows["remote_branches"] if isinstance(row, dict)],
        "workflows": [workflow_item(row) for row in rows["workflows"] if isinstance(row, dict)],
        "workflow_runs": [{**only(row, ("id", "name", "workflow_id", "path", "event", "status", "conclusion", "head_branch", "head_sha", "check_suite_id", "run_attempt", "run_started_at", "updated_at")), "html_url": safe_github_url(row.get("html_url"))} for row in workflow_runs if isinstance(row, dict)],
        "check_runs": [{**only(row, ("id", "name", "status", "conclusion", "head_sha", "check_suite_id", "started_at", "completed_at")), "html_url": safe_github_url(row.get("html_url"))} for row in checks if isinstance(row, dict)],
        "workflow_jobs": workflow_jobs,
        "statuses": [{**only(row, ("context", "state", "description", "created_at", "updated_at", "sha")), "target_url": safe_github_url(row.get("target_url"))} for row in statuses if isinstance(row, dict)],
        "branch_protection": {
            "access_status": protection_access,
            "required_contexts": sorted(contexts),
            "expected_contexts": sorted(required_contexts),
            "context_match": sorted(contexts) == sorted(required_contexts),
            "context_results": context_results,
            "capture_status": protection_capture["capture_status"],
            "capture_errors": protection_capture["capture_errors"],
            "observed_fields": protection_capture["observed_fields"],
            "resource": protection_capture["resource"],
            "source_endpoint": BRANCH_PROTECTION_ENDPOINT,
        },
        "mandatory_lanes": lane_results,
        "canaries": canaries,
    }
    if not github["branch_protection"]["context_match"]:
        gaps.append("live required contexts differ from repository expected contexts")
    if github["branch_protection"]["access_status"] != "allowed":
        gaps.append("branch protection access denied")
    receipt = {
        "schema": SCHEMA, "version": VERSION, "observed_at": utc_now(),
        "repository": {"name": repo, "source": "git remote origin"},
        "observation": {"ref": "refs/heads/main", "main_sha": main_sha, "source": f"GET repos/{repo}/git/ref/heads/main", "revalidated_sha": second_sha},
        "collection": {"complete": not gaps, "readiness": "green" if not gaps else "unknown", "gaps": gaps, "github_access": "allowed" if all(s["access_status"] == "allowed" for s in sources.values()) else "partial"},
        "sources": sources,
        "local": local,
        "github": github,
    }
    if len(json.dumps(receipt, separators=(",", ":")).encode("utf-8")) > MAX_OUTPUT_BYTES:
        branch_protection = receipt["github"]["branch_protection"]
        if branch_protection["resource"] is not None:
            branch_protection["resource"] = None
            branch_protection["capture_status"] = "incomplete"
            branch_protection["capture_errors"].append(
                "complete branch protection resource would exceed the 8 MiB receipt bound"
            )
            receipt["sources"]["branch_protection"]["completeness"] = "incomplete"
            receipt["collection"]["complete"] = False
            receipt["collection"]["readiness"] = "unknown"
            receipt["collection"]["gaps"].append(
                "branch protection configuration capture is incomplete"
            )
    return receipt


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
