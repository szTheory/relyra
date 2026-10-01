#!/usr/bin/env python3
"""Prepare or verify an inert, history-preserving Phase 79 publication packet."""

from __future__ import annotations

import argparse
import fnmatch
import hashlib
import json
import os
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from typing import Any


ROOT = pathlib.Path(__file__).resolve().parents[1]
PHASE_DIR = ROOT / ".planning/phases/79-adopter-ready-closeout"
REPOSITORY = "szTheory/relyra"
MAIN_REF = "refs/heads/main"
WORKFLOWS = [".github/workflows/security-gates.yml", ".github/workflows/fleet-proxy-e2e.yml"]
EVIDENCE_NAMES = {
    "79-PUBLICATION-PACKET.json", "79-PUBLICATION-COMMITS.txt", "79-PUBLICATION-REVIEW.md",
    "79-PR-TRANSACTION.json", "79-MERGE-PACKET.json", "79-MERGE-RECEIPT.json",
    "79-CI-DISPATCH-PACKET.json", "79-MAIN-CI-RECEIPT.json", "79-PROTECTION-POST-CAPTURE.json",
    "79-POST-INVENTORY.json", "79-POST-INVENTORY.md", "79-PROTECTION-TRANSACTION.json",
    "79-12-SUMMARY.md", "79-11-SUMMARY.md", "79-10-SUMMARY.md", "79-09-SUMMARY.md",
    "79-08-SUMMARY.md", "79-07-SUMMARY.md", "79-REVIEW.md", "79-VERIFICATION.md",
}
GLOBAL_EVIDENCE_PATHS = {".planning/STATE.md", ".planning/state.json", ".planning/ROADMAP.md"}


class PublicationError(Exception):
    pass


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def json_bytes(value: Any) -> bytes:
    return (json.dumps(value, indent=2, sort_keys=True, ensure_ascii=False) + "\n").encode()


def git(root: pathlib.Path, *args: str, timeout: int = 120) -> str:
    try:
        result = subprocess.run(
            ["git", *args], cwd=root, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT, text=True, timeout=timeout, check=False,
            env={**os.environ, "GIT_TERMINAL_PROMPT": "0"},
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        raise PublicationError(f"git command could not complete: {args[0]} ({exc})") from exc
    if result.returncode:
        raise PublicationError(f"git {args[0]} failed: {result.stdout[-3000:].strip()}")
    return result.stdout.strip()


def git_blob_bytes(root: pathlib.Path, revision: str, path: str) -> bytes:
    try:
        result = subprocess.run(
            ["git", "cat-file", "blob", f"{revision}:{path}"], cwd=root,
            stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            timeout=120, check=False, env={**os.environ, "GIT_TERMINAL_PROMPT": "0"},
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        raise PublicationError(f"cannot read frozen source file {path}: {exc}") from exc
    if result.returncode:
        raise PublicationError(f"source commit is missing {path}: {result.stderr.decode(errors='replace')[-1000:]}")
    return result.stdout


def command(argv: list[str], cwd: pathlib.Path, *, timeout: int = 1800, env: dict[str, str] | None = None) -> tuple[int, str]:
    try:
        result = subprocess.run(
            argv, cwd=cwd, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT, text=True, timeout=timeout, check=False,
            env={**os.environ, **(env or {}), "GIT_TERMINAL_PROMPT": "0"},
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        raise PublicationError(f"command could not complete: {pathlib.Path(argv[0]).name} ({exc})") from exc
    return result.returncode, result.stdout


def read_json(path: pathlib.Path, label: str) -> dict[str, Any]:
    try:
        if path.is_symlink() or not path.is_file() or path.stat().st_size > 8 * 1024 * 1024:
            raise PublicationError(f"{label} must be a regular JSON file of at most 8 MiB")
        value = json.loads(path.read_bytes())
    except PublicationError:
        raise
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise PublicationError(f"cannot read {label}: {exc}") from exc
    if not isinstance(value, dict):
        raise PublicationError(f"{label} must be a JSON object")
    return value


def write_bytes(path: pathlib.Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    try:
        with os.fdopen(descriptor, "wb") as handle:
            handle.write(data)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary, path)
    finally:
        try:
            os.unlink(temporary)
        except FileNotFoundError:
            pass


def remote_url(root: pathlib.Path) -> str:
    value = git(root, "remote", "get-url", "origin")
    if not re.search(r"(?:github\.com[:/]szTheory/relyra(?:\.git)?$)", value):
        raise PublicationError("origin must identify github.com/szTheory/relyra")
    return value


def live_main_sha(root: pathlib.Path, remote: str) -> str:
    value = git(root, "ls-remote", remote, MAIN_REF)
    rows = value.splitlines()
    if len(rows) != 1 or len(rows[0].split()) != 2 or rows[0].split()[1] != MAIN_REF:
        raise PublicationError("remote main did not resolve to exactly one ref identity")
    sha = rows[0].split()[0]
    if not re.fullmatch(r"[0-9a-f]{40}", sha):
        raise PublicationError("remote main returned a malformed SHA")
    return sha


def merge_allowed() -> bool:
    code, output = command(["gh", "api", "repos/szTheory/relyra", "--jq", ".allow_merge_commit"], ROOT, timeout=45)
    if code:
        raise PublicationError(f"cannot verify GitHub normal-merge setting: {output[-2000:].strip()}")
    if output.strip() not in {"true", "false"}:
        raise PublicationError("GitHub returned an ambiguous allow_merge_commit value")
    return output.strip() == "true"


def planned_paths(root: pathlib.Path, source_sha: str) -> tuple[set[str], dict[str, list[str]]]:
    allowed: set[str] = set(GLOBAL_EVIDENCE_PATHS)
    owner: dict[str, list[str]] = {}
    tree_paths = nul_paths(
        root, "ls-tree", "-r", "--name-only", "-z", source_sha, "--", ".planning/phases"
    )
    phase_paths = [path for path in tree_paths if re.match(r"\.planning/phases/7[3-9]-", path)]
    for path in phase_paths:
        if re.match(r"\.planning/phases/7[3-9]-[^/]+/[^/]+-PLAN\.md$", path):
            plan_id = pathlib.PurePosixPath(path).name.removesuffix("-PLAN.md")
            try:
                plan_text = git_blob_bytes(root, source_sha, path).decode("utf-8")
            except UnicodeDecodeError:
                plan_text = ""
            for planned in frontmatter_paths_from_text(plan_text):
                normalized = planned.removeprefix("./")
                allowed.add(normalized)
                owner.setdefault(normalized, []).append(plan_id)
        if re.match(r"\.planning/phases/7[3-9]-[^/]+/(?:7[3-9]-|COVERAGE\.md$|79-)", path):
            allowed.add(path)
            owner.setdefault(path, []).append("phase-artifact")
    for path in (".planning/PROJECT.md", ".planning/ROADMAP.md", ".planning/REQUIREMENTS.md", ".planning/WINDOWS.md"):
        if subprocess.run(["git", "cat-file", "-e", f"{source_sha}:{path}"], cwd=root, check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0:
            allowed.add(path)
            owner.setdefault(path, []).append("project-governance")
    return allowed, owner


def frontmatter_paths_from_text(text: str) -> list[str]:
    if not text.startswith("---\n"):
        return []
    parts = text.split("---", 2)
    if len(parts) < 3:
        return []
    front = parts[1]
    match = re.search(r"(?ms)^files_modified:\s*\n(.*?)(?=^[A-Za-z_][\w-]*\s*:|\Z)", front)
    if not match:
        return []
    return [
        item.strip().strip("\"'")
        for item in re.findall(r"(?m)^\s*-\s*(.+?)\s*$", match.group(1))
        if item.strip()
    ]


def path_is_planned(path: str, allowed: set[str]) -> bool:
    if path in allowed:
        return True
    for pattern in allowed:
        if "*" in pattern and fnmatch.fnmatchcase(path, pattern):
            return True
        if pattern.endswith("/") and path.startswith(pattern):
            return True
    return False


def nul_paths(root: pathlib.Path, *args: str) -> list[str]:
    raw = git(root, *args)
    return [item for item in raw.split("\0") if item]


def parse_name_status(raw: str) -> list[dict[str, str]]:
    parts = [item for item in raw.split("\0") if item]
    output: list[dict[str, str]] = []
    index = 0
    while index < len(parts):
        status = parts[index]
        index += 1
        if status.startswith(("R", "C")):
            if index + 1 >= len(parts):
                raise PublicationError("malformed Git rename/copy manifest")
            old_path, new_path = parts[index], parts[index + 1]
            index += 2
            output.append({"status": status, "path": old_path})
            output.append({"status": status, "path": new_path})
        else:
            if index >= len(parts):
                raise PublicationError("malformed Git path manifest")
            output.append({"status": status, "path": parts[index]})
            index += 1
    return output


def commit_manifest(root: pathlib.Path, base_sha: str, source_sha: str, allowed: set[str], owner: dict[str, list[str]]) -> tuple[list[dict[str, Any]], list[dict[str, str]], list[dict[str, str]]]:
    commits = [item for item in git(root, "rev-list", "--reverse", f"{base_sha}..{source_sha}").splitlines() if item]
    if not commits:
        raise PublicationError("source candidate contains no commits beyond remote main")
    diff_raw = git(root, "diff", "--name-status", "-z", base_sha, source_sha)
    diff_paths = parse_name_status(diff_raw)
    unknown_paths = [item for item in diff_paths if not path_is_planned(item["path"], allowed)]
    output: list[dict[str, Any]] = []
    blockers: list[dict[str, str]] = []
    for sha in commits:
        body = git(root, "show", "-s", "--format=%B", sha)
        subject = body.splitlines()[0] if body.splitlines() else ""
        parents_raw = git(root, "show", "-s", "--format=%P", sha)
        parents = parents_raw.split() if parents_raw else []
        changed = parse_name_status(git(root, "show", "--pretty=format:", "--name-status", "-z", sha))
        commit_unknown = [item for item in changed if not path_is_planned(item["path"], allowed)]
        plan_refs = sorted(set(re.findall(r"(?<!\d)(7[3-9]-\d{1,2})(?!\d)", body)))
        all_phase_paths = [item["path"] for item in changed if re.match(r"\.planning/phases/7[3-9]-", item["path"])]
        if len(parents) > 1 and not changed:
            classification = "merge-topology"
        elif plan_refs:
            classification = "phase-plan-deliverable"
        elif all_phase_paths:
            classification = "phase-artifact"
        elif changed and not commit_unknown:
            classification = "declared-deliverable-path"
        else:
            classification = "unclassified"
        disposition = "included" if classification != "unclassified" and not commit_unknown else "blocked"
        if disposition == "blocked":
            blockers.append({"commit": sha, "subject": subject, "reason": "unclassified commit or changed path"})
        output.append({
            "sha": sha, "subject": subject, "parents": parents,
            "paths": changed, "plan_refs": plan_refs,
            "path_owners": {item["path"]: sorted(set(owner.get(item["path"], []))) for item in changed},
            "classification": classification, "disposition": disposition,
        })
    return output, diff_paths, unknown_paths + [item for record in output for item in record["paths"] if not path_is_planned(item["path"], allowed)]


def worktree_inventory(root: pathlib.Path) -> dict[str, Any]:
    raw = git(root, "status", "--porcelain=v1", "-z", "--untracked-files=all")
    records = [item for item in raw.split("\0") if item]
    tracked: list[dict[str, str]] = []
    untracked: list[str] = []
    for row in records:
        status = row[:2]
        path = row[3:]
        if status == "??":
            untracked.append(path)
        else:
            tracked.append({"status": status, "path": path})
    return {"tracked_dirty": tracked, "untracked": untracked, "included": False}


def post_source_commits(root: pathlib.Path, source_sha: str) -> list[dict[str, Any]]:
    head = git(root, "rev-parse", "HEAD")
    if head == source_sha:
        return []
    if subprocess.run(["git", "merge-base", "--is-ancestor", source_sha, head], cwd=root, check=False).returncode:
        raise PublicationError("current HEAD no longer descends from the frozen publication source")
    commits = [item for item in git(root, "rev-list", "--reverse", f"{source_sha}..{head}").splitlines() if item]
    allowed_after = GLOBAL_EVIDENCE_PATHS | {
        f".planning/phases/79-adopter-ready-closeout/{name}" for name in EVIDENCE_NAMES
    }
    result: list[dict[str, Any]] = []
    for sha in commits:
        paths = parse_name_status(git(root, "show", "--pretty=format:", "--name-status", "-z", sha))
        disallowed = [item["path"] for item in paths if item["path"] not in allowed_after]
        if disallowed:
            raise PublicationError("source changed after freeze: " + ", ".join(sorted(set(disallowed))))
        result.append({"sha": sha, "paths": paths, "disposition": "evidence-only; excluded from candidate"})
    return result


def simulate_merge(root: pathlib.Path, remote: str, base_sha: str, source_sha: str) -> dict[str, Any]:
    with tempfile.TemporaryDirectory(prefix="relyra-phase79-publication-") as temporary:
        checkout = pathlib.Path(temporary) / "checkout"
        code, output = command(["git", "clone", "--shared", "--no-checkout", str(root), str(checkout)], root, timeout=180)
        if code:
            raise PublicationError(f"could not create owned isolated checkout: {output[-2000:].strip()}")
        command(["git", "remote", "add", "publication", remote], checkout, timeout=45)
        command(["git", "fetch", "--no-tags", "publication", f"{MAIN_REF}:refs/remotes/publication/main"], checkout, timeout=180)
        fetched = git(checkout, "rev-parse", "refs/remotes/publication/main")
        if fetched != base_sha:
            raise PublicationError("isolated checkout fetched a different remote main SHA")
        command(["git", "checkout", "--detach", base_sha], checkout, timeout=45)
        code, output = command(["git", "merge", "--no-ff", "--no-edit", source_sha], checkout, timeout=180)
        if code:
            raise PublicationError(f"normal merge topology conflicts: {output[-2500:].strip()}")
        merge_sha = git(checkout, "rev-parse", "HEAD")
        merge_tree = git(checkout, "rev-parse", "HEAD^{tree}")
        source_tree = git(root, "rev-parse", f"{source_sha}^{{tree}}")
        parents = git(checkout, "show", "-s", "--format=%P", merge_sha).split()
        if merge_tree != source_tree or parents != [base_sha, source_sha]:
            raise PublicationError("simulated main does not preserve the source tree and exact two-parent topology")
        if subprocess.run(["git", "merge-base", "--is-ancestor", source_sha, merge_sha], cwd=checkout, check=False).returncode:
            raise PublicationError("original source tip is not ancestral to simulated main")

        deps = ROOT / "deps"
        if deps.exists() and not (checkout / "deps").exists():
            (checkout / "deps").symlink_to(deps, target_is_directory=True)

        nested_demo_checkout = checkout / "demo" / "ledger_loop"
        for cache_name in ("deps", "_build"):
            nested_demo_cache = ROOT / "demo" / "ledger_loop" / cache_name
            if nested_demo_cache.exists() and not (nested_demo_checkout / cache_name).exists():
                (nested_demo_checkout / cache_name).symlink_to(
                    nested_demo_cache, target_is_directory=True
                )
        env = {
            "ASDF_ELIXIR_VERSION": "1.19.5-otp-28",
            "ASDF_ERLANG_VERSION": "28.4.1",
            "MIX_ENV": "test",
        }
        code, test_output = command(["mix", "ci.evidence"], checkout, timeout=1800, env=env)
        if code:
            raise PublicationError(f"isolated mix ci.evidence failed ({code}): {test_output[-5000:].strip()}")
        return {
            "base_sha": base_sha, "source_sha": source_sha, "merge_sha": merge_sha,
            "tree_sha": merge_tree, "source_tree_sha": source_tree,
            "parents": parents, "source_ancestor": True,
            "provenance_owner": "mix ci.evidence",
            "provenance_status": "passed",
            "provenance_output_sha256": digest(test_output.encode()),
            "provenance_output_tail": test_output[-1000:].strip(),
        }


def build(root: pathlib.Path, phase_dir: pathlib.Path, fixture_dir: pathlib.Path | None) -> dict[str, Any]:
    source_sha = git(root, "rev-parse", "HEAD")
    source_tree = git(root, "rev-parse", f"{source_sha}^{{tree}}")
    if fixture_dir:
        fixture = read_json(fixture_dir / "publication.json", "publication fixture")
        remote = fixture.get("remote_url")
        base_sha = fixture.get("base_sha")
        allow_merge = fixture.get("allow_merge_commit")
        if not isinstance(remote, str) or not isinstance(base_sha, str) or not re.fullmatch(r"[0-9a-f]{40}", base_sha) or type(allow_merge) is not bool:
            raise PublicationError("publication fixture needs remote_url, full base_sha, and allow_merge_commit")
    else:
        remote = remote_url(root)
        base_sha = live_main_sha(root, remote)
        allow_merge = merge_allowed()
    if not allow_merge:
        raise PublicationError("repository settings do not permit the required normal two-parent merge")

    allowed, owner = planned_paths(root, source_sha)
    commits, diff_paths, unknown_paths = commit_manifest(root, base_sha, source_sha, allowed, owner)
    workflow_digests = {}
    for path in WORKFLOWS:
        workflow = root / path
        if not workflow.is_file() or workflow.is_symlink():
            raise PublicationError(f"required owner workflow is missing or unsafe: {path}")
        workflow_digests[path] = digest(workflow.read_bytes())

    # The isolated checkout and provenance owner are part of the packet proof.
    if fixture_dir and (read_json(fixture_dir / "publication.json", "publication fixture").get("skip_mix_evidence") is True):
        raise PublicationError("fixture mode cannot skip the provenance owner")
    proof = simulate_merge(root, remote, base_sha, source_sha)
    worktree = worktree_inventory(root)
    blockers = []
    if unknown_paths:
        blockers.append("unclassified commit/path scope remains")
    if worktree["tracked_dirty"]:
        worktree_blockers = [
            item["path"] for item in worktree["tracked_dirty"]
            if item["path"] not in GLOBAL_EVIDENCE_PATHS
            and not (item["path"].startswith(".planning/phases/79-adopter-ready-closeout/") and pathlib.Path(item["path"]).name in EVIDENCE_NAMES)
        ]
        if worktree_blockers:
            blockers.append("tracked source edits exist outside workflow/evidence state")
    short = source_sha[:12]
    branch = f"codex/v1.11-adopter-ready-{short}"
    if fixture_dir:
        existing_branch = None
    else:
        existing = git(root, "ls-remote", remote, f"refs/heads/{branch}").split()
        existing_branch = existing[0] if existing else None
    if existing_branch not in {None, source_sha}:
        blockers.append("candidate branch already exists at a different SHA")

    commit_bytes = json_bytes(commits)
    diff_bytes = json_bytes(diff_paths)
    commits_path = phase_dir / "79-PUBLICATION-COMMITS.txt"
    commit_text = "".join(f"{row['sha']}\t{row['classification']}\t{row['subject']}\n" for row in commits)
    write_bytes(commits_path, commit_text.encode())
    packet = {
        "schema": "phase79-publication-packet", "version": 1,
        "status": "blocked" if blockers else "ready",
        "blockers": blockers,
        "target": {"repository": REPOSITORY, "ref": MAIN_REF},
        "base_sha": base_sha, "source_sha": source_sha,
        "candidate_head_sha": source_sha, "source_tree_sha": source_tree,
        "commit_count": len(commits), "commit_manifest_sha256": digest(commit_bytes),
        "diff_path_count": len(diff_paths), "diff_manifest_sha256": digest(diff_bytes),
        "commit_manifest_path": "79-PUBLICATION-COMMITS.txt",
        "path_dispositions": [
            {"status": item["status"], "path": item["path"],
             "disposition": "blocked; unexplained path" if not path_is_planned(item["path"], allowed) else "included; declared Phase 73-79 deliverable",
             "owners": sorted(set(owner.get(item["path"], [])))}
            for item in diff_paths
        ],
        "unclassified_paths": sorted({item["path"] for item in unknown_paths}),
        "commit_classifications": commits,
        "simulated_main": proof,
        "workflow_digests": workflow_digests,
        "repository_settings": {"allow_merge_commit": allow_merge},
        "branch": {"name": branch, "existing_sha": existing_branch},
        "pull_request": {
            "title": "v1.11 First-Adopter Twin closeout",
            "head": branch, "base": MAIN_BRANCH,
            "body": f"Source-bound Phase 73-79 candidate {source_sha}; proposed normal merge only.",
            "create_endpoint": f"POST repos/{REPOSITORY}/pulls",
        },
        "merge": {"method": "merge", "expected_parent_order": [base_sha, source_sha], "rollback_limit": "a separate reviewed revert PR; no force push"},
        "permissions": {"branch_push": ["contents:write"], "pull_request": ["pull-requests:write"], "protection": [], "workflow_dispatch": []},
        "worktree_exclusions": worktree,
        "post_source_commits": [],
        "remote_operations_performed": [],
        "approval": None,
    }
    phase_dir.mkdir(parents=True, exist_ok=True)
    packet_path = phase_dir / "79-PUBLICATION-PACKET.json"
    write_bytes(packet_path, json_bytes(packet))
    review = [
        "# Phase 79 Publication Review",
        "",
        f"**Status:** {packet['status']}",
        f"**Target:** `{REPOSITORY}@{MAIN_REF}`",
        f"**Base:** `{base_sha}`",
        f"**Original source/candidate:** `{source_sha}`",
        f"**Tree:** `{source_tree}`",
        f"**Commits:** {len(commits)}; manifest SHA-256 `{digest(commit_bytes)}`",
        f"**Changed paths:** {len(diff_paths)}; manifest SHA-256 `{digest(diff_bytes)}`",
        f"**Simulated normal merge:** `{proof['merge_sha']}` with tree `{proof['tree_sha']}`",
        f"**Provenance owner:** `{proof['provenance_owner']}` — {proof['provenance_status']}",
        "",
        "## Scope blockers",
    ]
    review.extend(f"- {item}" for item in blockers) if blockers else review.append("- None")
    review.extend([
        "",
        "## Excluded working-tree paths",
        "These paths were observed locally and are not part of the committed candidate:",
    ])
    review.extend(f"- `{item['path']}` ({item['status']})" for item in worktree["tracked_dirty"])
    review.extend(f"- `{item}` (untracked)" for item in worktree["untracked"])
    review.extend([
        "- No cleanup authority is implied.",
        "",
        "## Proposed operations",
        f"- Non-force push of original source `{source_sha}` to `{branch}`.",
        f"- Create one PR through `{packet['pull_request']['create_endpoint']}` against `main`.",
        "- Later normal merge requires a separate packet and approval.",
        "- No GitHub write, dispatch, protection update, or branch cleanup was performed.",
        "",
    ])
    write_bytes(phase_dir / "79-PUBLICATION-REVIEW.md", "\n".join(review).encode())
    return packet


def verify(root: pathlib.Path, phase_dir: pathlib.Path, packet_path: pathlib.Path, fixture_dir: pathlib.Path | None) -> dict[str, Any]:
    packet = read_json(packet_path, "publication packet")
    if packet.get("schema") != "phase79-publication-packet" or packet.get("version") != 1:
        raise PublicationError("publication packet schema is unsupported")
    if packet.get("target") != {"repository": REPOSITORY, "ref": MAIN_REF}:
        raise PublicationError("publication packet target is not the exact repository main ref")
    source = packet.get("source_sha")
    base = packet.get("base_sha")
    if not isinstance(source, str) or not re.fullmatch(r"[0-9a-f]{40}", source) or not isinstance(base, str) or not re.fullmatch(r"[0-9a-f]{40}", base):
        raise PublicationError("publication packet has malformed source/base identities")
    if packet.get("candidate_head_sha") != source:
        raise PublicationError("candidate head must be the original source commit")
    if subprocess.run(["git", "merge-base", "--is-ancestor", base, source], cwd=root, check=False).returncode:
        raise PublicationError("publication base is not an ancestor of the original source head")
    current_tree = git(root, "rev-parse", f"{source}^{{tree}}")
    if current_tree != packet.get("source_tree_sha"):
        raise PublicationError("candidate head/tree differs from the original source commit")
    worktree_exclusions = packet.get("worktree_exclusions")
    if not isinstance(worktree_exclusions, dict) or worktree_exclusions.get("included") is not False:
        raise PublicationError("uncommitted or untracked working-tree content may not enter the candidate")
    if packet.get("approval") is not None or packet.get("remote_operations_performed") != []:
        raise PublicationError("publication packet must remain inert and unapproved")

    if fixture_dir:
        fixture = read_json(fixture_dir / "publication.json", "publication fixture")
        observed_base = fixture.get("base_sha")
        allow_merge = fixture.get("allow_merge_commit")
        existing_branch = None
    else:
        remote = remote_url(root)
        observed_base = live_main_sha(root, remote)
        allow_merge = merge_allowed()
    if observed_base != base:
        raise PublicationError("remote main changed after the publication packet was prepared")
    if allow_merge is not True:
        raise PublicationError("repository no longer permits the required normal two-parent merge")

    allowed, owner = planned_paths(root, source)
    commits, diff_paths, unknown_paths = commit_manifest(root, base, source, allowed, owner)
    expected_commit_bytes = json_bytes(commits)
    expected_diff_bytes = json_bytes(diff_paths)
    expected_commit_text = "".join(
        f"{row['sha']}\t{row['classification']}\t{row['subject']}\n" for row in commits
    ).encode()
    if packet.get("commit_count") != len(commits) or packet.get("commit_manifest_sha256") != digest(expected_commit_bytes):
        raise PublicationError("commit manifest digest or count differs from immutable Git history")
    if packet.get("commit_classifications") != commits:
        raise PublicationError("commit classifications differ from immutable Git history")
    if packet.get("diff_path_count") != len(diff_paths) or packet.get("diff_manifest_sha256") != digest(expected_diff_bytes):
        raise PublicationError("path manifest digest or count differs from immutable Git history")
    if packet.get("path_dispositions") != [
        {
            "status": item["status"], "path": item["path"],
            "disposition": "blocked; unexplained path" if not path_is_planned(item["path"], allowed) else "included; declared Phase 73-79 deliverable",
            "owners": sorted(set(owner.get(item["path"], []))),
        }
        for item in diff_paths
    ]:
        raise PublicationError("path dispositions differ from the exact base-to-source diff")
    if packet.get("unclassified_paths") != sorted({item["path"] for item in unknown_paths}):
        raise PublicationError("unclassified path list differs from immutable Git history")
    commit_path = phase_dir / "79-PUBLICATION-COMMITS.txt"
    if commit_path.is_symlink() or not commit_path.is_file() or commit_path.read_bytes() != expected_commit_text:
        raise PublicationError("publication commit list is altered or incomplete")

    source_workflows = {}
    for path in WORKFLOWS:
        contents = git_blob_bytes(root, source, path)
        source_workflows[path] = digest(contents)
    if packet.get("workflow_digests") != source_workflows:
        raise PublicationError("workflow digest does not describe the frozen source commit")

    later = post_source_commits(root, source)
    if packet.get("status") not in {"ready", "blocked"}:
        raise PublicationError("publication status is invalid")
    proof = packet.get("simulated_main")
    if not isinstance(proof, dict) or (
        proof.get("base_sha") != base
        or proof.get("source_sha") != source
        or proof.get("tree_sha") != current_tree
        or proof.get("source_tree_sha") != current_tree
        or proof.get("parents") != [base, source]
        or proof.get("source_ancestor") is not True
        or proof.get("provenance_owner") != "mix ci.evidence"
        or proof.get("provenance_status") != "passed"
        or not re.fullmatch(r"[0-9a-f]{64}", str(proof.get("provenance_output_sha256", "")))
    ):
        raise PublicationError("simulated main tree does not equal the candidate source tree")

    branch_name = f"codex/v1.11-adopter-ready-{source[:12]}"
    branch_record = packet.get("branch")
    if not isinstance(branch_record, dict) or branch_record.get("name") != branch_name:
        raise PublicationError("candidate branch is not deterministically bound to the source SHA")
    if packet.get("pull_request") != {
        "title": "v1.11 First-Adopter Twin closeout", "head": branch_name,
        "base": MAIN_BRANCH,
        "body": f"Source-bound Phase 73-79 candidate {source}; proposed normal merge only.",
        "create_endpoint": f"POST repos/{REPOSITORY}/pulls",
    }:
        raise PublicationError("PR proposal differs from the exact candidate and target")
    if packet.get("merge") != {
        "method": "merge", "expected_parent_order": [base, source],
        "rollback_limit": "a separate reviewed revert PR; no force push",
    }:
        raise PublicationError("merge method or rollback boundary changed")

    if fixture_dir:
        existing_branch = None
    else:
        rows = git(root, "ls-remote", remote, f"refs/heads/{branch_name}").splitlines()
        existing_branch = None
        if rows:
            if len(rows) != 1 or len(rows[0].split()) != 2:
                raise PublicationError("candidate branch ref lookup is ambiguous")
            existing_branch = rows[0].split()[0]
            if existing_branch != source:
                raise PublicationError("candidate branch exists at a different SHA")
    if existing_branch not in {None, source}:
        raise PublicationError("candidate branch read-back differs from the frozen source SHA")

    current_worktree = worktree_inventory(root)
    allowed_dirty = GLOBAL_EVIDENCE_PATHS | {
        f".planning/phases/79-adopter-ready-closeout/{name}" for name in EVIDENCE_NAMES
    }
    dirty_source = [item["path"] for item in current_worktree["tracked_dirty"] if item["path"] not in allowed_dirty]
    recomputed_blockers = []
    if unknown_paths:
        recomputed_blockers.append("unclassified commit/path scope remains")
    if dirty_source:
        recomputed_blockers.append("tracked source edits exist outside workflow/evidence state")
    if packet.get("blockers") != recomputed_blockers:
        raise PublicationError("publication blocker list does not match the current source and scope evidence")
    if (packet["status"] == "ready") != (not recomputed_blockers):
        raise PublicationError("publication readiness contradicts the recomputed blockers")
    packet["post_source_commits"] = later
    return {"stage": "publication", "status": packet["status"], "source_sha": source, "base_sha": base, "source_tree_sha": current_tree, "post_source_commits": later, "blockers": packet.get("blockers", [])}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--verify", type=pathlib.Path, help="verify an existing packet")
    parser.add_argument("--phase-dir", type=pathlib.Path, default=PHASE_DIR)
    parser.add_argument("--fixture-dir", type=pathlib.Path, help="owned bounded read fixture directory")
    parser.add_argument("--repo-root", type=pathlib.Path, default=ROOT)
    args = parser.parse_args(argv)
    try:
        root = args.repo_root.resolve()
        phase_dir = args.phase_dir.resolve()
        fixture_dir = args.fixture_dir.resolve() if args.fixture_dir else None
        if args.verify:
            verify_path = pathlib.Path(os.path.abspath(args.verify.expanduser()))
            if verify_path.is_symlink():
                raise PublicationError("publication packet must be a regular, non-symlink file")
            result = verify(root, phase_dir, verify_path, fixture_dir)
        else:
            result = build(root, phase_dir, fixture_dir)
    except PublicationError as exc:
        print(f"phase79 publication: {exc}", file=sys.stderr)
        return 1
    except (AttributeError, KeyError, TypeError, ValueError, OSError) as exc:
        print(f"phase79 publication: malformed evidence ({exc})", file=sys.stderr)
        return 1
    print(json.dumps(result, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
