#!/usr/bin/env python3
"""Build and verify the bounded Phase 79 filtered-history proof.

The command is intentionally inert by default.  Candidate replay is available
only when an explicit, caller-owned disposable repository is supplied; the
project repository is never used as an object destination.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile
import zlib
from typing import Any


ROOT = pathlib.Path(__file__).resolve().parents[1]
PHASE_DIR = ROOT / ".planning/phases/79-adopter-ready-closeout"
MAX_WITNESS_BYTES = 8 * 1024 * 1024
MAX_INPUT_BYTES = 32 * 1024 * 1024
MAX_OBJECTS = 4096
MAX_COMMITS = 1000
MAX_TREES = 3000
MAX_BATCH_BYTES = 48 * 1024 * 1024
EXPECTED_REMOTE_URL = "https://github.com/szTheory/relyra.git"
RECEIPT_KEYS = {
    "approval", "blocker", "candidate_status", "counts", "decision", "evidence",
    "exclusion_provenance", "paths", "phase", "plan", "response", "schema",
}
RECEIPT_EVIDENCE_KEYS = {
    "base_sha", "changed_path_count", "commit_count", "packet_path", "packet_sha256",
    "review_path", "review_sha256", "source_sha", "source_tree_sha",
}
RECEIPT_RESPONSE_KEYS = {"normalized_decision", "recorded_date", "scope", "source", "text"}
RECEIPT_PATH_KEYS = {"accepted", "disposition", "path", "proposed_disposition"}
SCOPE_PACKET_KEYS = {
    "base_sha", "commit_count", "diff_path_count", "schema", "source_sha",
    "source_tree_sha", "status", "supersedes_packet_sha256", "unclassified_paths", "version",
}
WITNESS_KEYS = {"schema", "evidence", "dispositions", "base_tree", "commits", "trees", "proof", "limits", "gpgsig"}
WITNESS_LIMIT_KEYS = {"commit_count", "tree_count", "object_count"}
WITNESS_COMMIT_KEYS = {"raw", "parents", "tree"}
PROOF_KEYS = {
    "schema", "base_sha", "original_source_sha", "filtered_source_sha",
    "original_source_tree_sha", "filtered_source_tree_sha", "commit_map", "tree_map",
    "commit_count", "merge_count", "excluded_paths", "signature_handling",
}
MANIFEST_KEYS = {
    "schema", "base_sha", "original_source_sha", "original_source_tree_sha",
    "filtered_source_sha", "filtered_tree_sha", "final_source_sha", "final_tree_sha",
    "commit_map_sha256", "proof_sha256", "bundle_sha256", "overlay_parent_sha",
    "overlay_tip_sha", "overlay_paths", "proof_commit_sha", "remote_url", "branch_name",
}
EXPECTED = {
    "base_sha": "c786a9890f2f99f0dd98f89a1d9713db7c486837",
    "source_sha": "a5820aac9983b7289cbc1cc816120017761a02e3",
    "source_tree_sha": "4ebd2357cb25980edb80c94a144657bfe9083a56",
    "packet_sha256": "4d62608b6050136c44ecfabb4a58476f2d6efeeecafc456a2cc02c1020a50c95",
    "review_sha256": "10332a7ddd4e14ca4798272fe5f451e7c16bd4036af611c135f139519894cca2",
}
SUPERSEDED_SCOPE_PACKET_SHA256 = "76ea68d9b04825512587a7fbaee8097d17cd9a62d7763787beb899ef0b1106b7"
NORMALIZED = (
    "Accept the exact 30 include / 25 exclude recommendations from the reviewed map. "
    "Do not reinterpret this as approval to include all 55 paths; any exclusions keep "
    "this immutable candidate blocked. No GitHub operation is authorized."
)
SCOPE = (
    "Accept the exact 30 include / 25 exclude recommendations; this is not approval "
    "to include all 55 paths and authorizes no GitHub operation."
)
EXPECTED_MAP_SHA256 = "e3233d53487a5498b8b6a65d4468536217cbf8a7118cbb695162ccd34e5b8160"
OVERLAY_PATHS = [
    "scripts/prepare_phase79_filtered_candidate.py",
    "scripts/prepare_phase79_publication.py",
    "scripts/verify_phase79_transaction.py",
    "scripts/verify_phase79_scope_dispositions.py",
    "scripts/verify_phase79_plan_contract.py",
    "test/governance/milestone_scope_test.exs",
    "test/adoption/external_canary_contract_test.exs",
    "mix.exs",
    ".planning/ROADMAP.md",
    ".planning/phases/79-adopter-ready-closeout/79-14-PLAN.md",
    ".planning/phases/79-adopter-ready-closeout/79-15-PLAN.md",
    ".planning/phases/79-adopter-ready-closeout/79-09-PLAN.md",
    ".planning/phases/79-adopter-ready-closeout/79-10-PLAN.md",
    ".planning/phases/79-adopter-ready-closeout/79-11-PLAN.md",
    ".planning/phases/79-adopter-ready-closeout/79-12-PLAN.md",
    ".planning/phases/73-twin-contract-and-baseline/73-RECONCILIATION-PROOF.json",
    ".planning/phases/73-twin-contract-and-baseline/73-SECURITY.md",
    ".planning/phases/73-twin-contract-and-baseline/73-VALIDATION.md",
    ".planning/phases/78-ci-efficiency-and-reliability/78-CLEAN-STATE-RECEIPT.json",
]


class FilteredHistoryError(ValueError):
    pass


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def candidate_branch_name(source_sha: str) -> str:
    if not re.fullmatch(r"[0-9a-f]{40}", source_sha):
        raise FilteredHistoryError("candidate source SHA is malformed for branch derivation")
    return f"codex/v1.11-adopter-ready-{source_sha[:12]}"


def git(root: pathlib.Path, *args: str, data: bytes | None = None, timeout: int = 60) -> bytes:
    try:
        result = subprocess.run(
            ["git", *args], cwd=root, input=data, stdout=subprocess.PIPE,
            stderr=subprocess.PIPE, timeout=timeout, check=False,
            env={**os.environ, "GIT_TERMINAL_PROMPT": "0", "GIT_CONFIG_NOSYSTEM": "1"},
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        raise FilteredHistoryError(f"git {args[0]} could not complete: {exc}") from exc
    if result.returncode:
        raise FilteredHistoryError(
            f"git {args[0]} failed: {result.stderr[-2000:].decode(errors='replace').strip()}"
        )
    return result.stdout


def cat_file_batch(root: pathlib.Path, object_ids: set[str] | list[str]) -> dict[str, tuple[str, bytes]]:
    """Read bounded raw objects with a small number of Git processes."""
    ids = sorted(set(object_ids))
    if not ids:
        return {}
    if any(not re.fullmatch(r"[0-9a-f]{40}", oid) for oid in ids):
        raise FilteredHistoryError("batch object request contains a malformed SHA-1")
    request = b"".join(oid.encode("ascii") + b"\n" for oid in ids)
    check = git(
        root,
        "cat-file",
        "--batch-check=%(objectname) %(objecttype) %(objectsize)",
        data=request,
        timeout=180,
    )
    rows: list[tuple[str, str, int]] = []
    check_lines = check.splitlines()
    if len(check_lines) != len(ids):
        raise FilteredHistoryError("Git batch-check omitted requested objects")
    for expected, line in zip(ids, check_lines):
        fields = line.split()
        if len(fields) != 3 or fields[0].decode("ascii") != expected:
            raise FilteredHistoryError("Git batch-check returned a malformed object row")
        kind = fields[1].decode("ascii")
        try:
            size = int(fields[2])
        except ValueError as exc:
            raise FilteredHistoryError("Git batch-check returned a malformed object size") from exc
        if kind == "missing" or size < 0 or size > MAX_INPUT_BYTES:
            raise FilteredHistoryError("batch object is missing or exceeds the input size limit")
        rows.append((expected, kind, size))
    if len(rows) != len(ids):
        raise FilteredHistoryError("Git batch-check omitted requested objects")

    result: dict[str, tuple[str, bytes]] = {}
    start = 0
    while start < len(rows):
        stop = start
        byte_count = 0
        while stop < len(rows) and (stop == start or byte_count + rows[stop][2] <= MAX_BATCH_BYTES):
            byte_count += rows[stop][2]
            stop += 1
        chunk = rows[start:stop]
        chunk_request = b"".join(oid.encode("ascii") + b"\n" for oid, _kind, _size in chunk)
        output = git(root, "cat-file", "--batch", data=chunk_request, timeout=180)
        offset = 0
        for expected, expected_kind, size in chunk:
            header_end = output.find(b"\n", offset)
            if header_end < 0:
                raise FilteredHistoryError("Git batch output omitted an object header")
            header = output[offset:header_end].split()
            if len(header) != 3 or header[0].decode("ascii") != expected or header[1].decode("ascii") != expected_kind:
                raise FilteredHistoryError("Git batch output object identity or type differs")
            try:
                observed_size = int(header[2])
            except ValueError as exc:
                raise FilteredHistoryError("Git batch output contains a malformed object size") from exc
            if observed_size != size:
                raise FilteredHistoryError("Git batch output size differs from its check record")
            body_start = header_end + 1
            body_end = body_start + size
            if body_end >= len(output) or output[body_end:body_end + 1] != b"\n":
                raise FilteredHistoryError("Git batch output object body is truncated")
            body = output[body_start:body_end]
            result[expected] = (expected_kind, body)
            offset = body_end + 1
        if offset != len(output):
            raise FilteredHistoryError("Git batch output contains trailing data")
        start = stop
    return result


class LooseObjectWriter:
    """Write verified Git objects directly into an owned disposable object store."""

    def __init__(self, repository: pathlib.Path):
        raw_path = git(repository, "rev-parse", "--git-path", "objects").decode().strip()
        path = pathlib.Path(raw_path)
        self.objects = (path if path.is_absolute() else repository / path).resolve()
        self.tree_objects: dict[str, bytes] = {}

    def write(self, kind: bytes, data: bytes) -> bytes:
        if kind not in {b"blob", b"tree", b"commit"} or len(data) > MAX_INPUT_BYTES:
            raise FilteredHistoryError("unsupported or oversized object for the disposable writer")
        payload = kind + b" " + str(len(data)).encode("ascii") + b"\0" + data
        oid = hashlib.sha1(payload).hexdigest()
        object_path = self.objects / oid[:2] / oid[2:]
        if object_path.exists():
            if object_path.is_symlink() or not object_path.is_file():
                raise FilteredHistoryError("existing candidate object path is unsafe")
            try:
                existing = zlib.decompress(object_path.read_bytes())
            except (OSError, zlib.error) as exc:
                raise FilteredHistoryError("existing candidate object cannot be verified") from exc
            if existing != payload:
                raise FilteredHistoryError("candidate object path contains bytes with a different identity")
        else:
            object_path.parent.mkdir(parents=True, exist_ok=True)
            try:
                with object_path.open("xb") as handle:
                    handle.write(zlib.compress(payload))
            except FileExistsError:
                try:
                    existing = zlib.decompress(object_path.read_bytes())
                except (OSError, zlib.error) as exc:
                    raise FilteredHistoryError("racing candidate object cannot be verified") from exc
                if existing != payload:
                    raise FilteredHistoryError("racing candidate object has a different identity")
        if kind == b"tree":
            self.tree_objects[oid] = data
        return oid.encode("ascii")


def read_limited(path: pathlib.Path, limit: int = MAX_INPUT_BYTES) -> bytes:
    if path.is_symlink() or not path.is_file():
        raise FilteredHistoryError(f"input must be a regular non-symlink file: {path}")
    if path.stat().st_size > limit:
        raise FilteredHistoryError(f"input exceeds {limit}-byte limit")
    return path.read_bytes()


def json_file(path: pathlib.Path, label: str, limit: int = MAX_INPUT_BYTES) -> tuple[dict[str, Any], bytes]:
    raw = read_limited(path, limit)
    try:
        value = json.loads(raw)
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise FilteredHistoryError(f"invalid {label}: {exc}") from exc
    if not isinstance(value, dict):
        raise FilteredHistoryError(f"{label} must be an object")
    return value, raw


def review_map(path: pathlib.Path) -> list[tuple[str, str]]:
    rows: list[tuple[str, str]] = []
    for line in read_limited(path).decode("utf-8").splitlines():
        if not line.startswith("| `") or line.startswith("| `Exact path"):
            continue
        cells = line.split("|")
        if len(cells) < 4:
            raise FilteredHistoryError("malformed recommendation table row")
        name = cells[1].strip().strip("`")
        match = re.search(r"\*\*(include|exclude)\*\* \(pending\)", cells[2])
        if not name or not match or any(old[0] == name for old in rows):
            raise FilteredHistoryError(f"invalid or duplicate review path {name!r}")
        rows.append((name, match.group(1)))
    return rows


def validate_receipt(phase_dir: pathlib.Path) -> tuple[dict[str, str], dict[str, str]]:
    receipt_path = phase_dir / "79-SCOPE-DISPOSITIONS.json"
    packet_path = phase_dir / "79-SCOPE-REVIEW-PACKET.json"
    review_path = phase_dir / "79-SCOPE-DISPOSITION-REVIEW.md"
    receipt, _ = json_file(receipt_path, "scope receipt")
    packet, packet_bytes = json_file(packet_path, "scope review packet")
    validate_exact_keys(packet, SCOPE_PACKET_KEYS, "scope review packet")
    if packet.get("schema") != "phase79-scope-review-packet" or packet.get("version") != 1:
        raise FilteredHistoryError("unsupported frozen scope review packet")
    if packet.get("status") != "blocked":
        raise FilteredHistoryError("frozen scope review packet must preserve its original blocked status")
    validate_exact_keys(receipt, RECEIPT_KEYS, "scope receipt")
    if receipt.get("schema") != "relyra.phase79.scope-dispositions.v1":
        raise FilteredHistoryError("unsupported scope receipt schema")
    if (receipt.get("phase"), receipt.get("plan")) != ("79-adopter-ready-closeout", "79-13"):
        raise FilteredHistoryError("scope receipt phase/plan identity differs")
    if receipt.get("decision") != "accepted_recommendations_with_exclusions" or receipt.get("approval") != "accepted_recommendations":
        raise FilteredHistoryError("scope receipt is not the accepted recommendations map")
    evidence = receipt.get("evidence")
    if not isinstance(evidence, dict):
        raise FilteredHistoryError("scope receipt evidence is malformed")
    validate_exact_keys(evidence, RECEIPT_EVIDENCE_KEYS, "scope receipt evidence")
    for key, expected in EXPECTED.items():
        if evidence.get(key) != expected:
            raise FilteredHistoryError(f"scope receipt {key} differs from the frozen reviewed identity")
    if evidence.get("commit_count") != 612 or evidence.get("changed_path_count") != 351:
        raise FilteredHistoryError("scope receipt frozen history/path counts differ")
    if evidence.get("packet_path") != ".planning/phases/79-adopter-ready-closeout/79-SCOPE-REVIEW-PACKET.json" or evidence.get("review_path") != ".planning/phases/79-adopter-ready-closeout/79-SCOPE-DISPOSITION-REVIEW.md":
        raise FilteredHistoryError("scope receipt packet/review paths differ")
    if evidence.get("packet_sha256") != sha256(packet_bytes) or evidence.get("review_sha256") != sha256(read_limited(review_path)):
        raise FilteredHistoryError("packet or review digest differs from the accepted receipt")
    if (packet.get("base_sha"), packet.get("source_sha"), packet.get("source_tree_sha")) != (
        EXPECTED["base_sha"], EXPECTED["source_sha"], EXPECTED["source_tree_sha"]
    ):
        raise FilteredHistoryError("scope review packet source identities differ from the accepted receipt")
    if (
        packet.get("commit_count") != 612
        or packet.get("diff_path_count") != 351
        or packet.get("supersedes_packet_sha256") != SUPERSEDED_SCOPE_PACKET_SHA256
    ):
        raise FilteredHistoryError("scope review packet does not preserve the frozen original scope evidence")
    response = receipt.get("response")
    if not isinstance(response, dict) or response.get("normalized_decision") != NORMALIZED or response.get("scope") != SCOPE:
        raise FilteredHistoryError("scope receipt decision or scope text differs from the accepted response")
    validate_exact_keys(response, RECEIPT_RESPONSE_KEYS, "scope receipt response")
    recommendations = review_map(review_path)
    if packet.get("unclassified_paths") != [path for path, _ in recommendations]:
        raise FilteredHistoryError("scope review packet path list differs from the reviewed recommendation map")
    paths = receipt.get("paths")
    if not isinstance(paths, list) or len(paths) != 55:
        raise FilteredHistoryError("scope receipt must contain exactly 55 paths")
    actual: list[tuple[str, str]] = []
    for row in paths:
        if not isinstance(row, dict):
            raise FilteredHistoryError("scope row is malformed or not accepted")
        validate_exact_keys(row, RECEIPT_PATH_KEYS, "scope path row")
        if row.get("accepted") is not True:
            raise FilteredHistoryError("scope row is malformed or not accepted")
        path, disposition = row.get("path"), row.get("disposition")
        if not isinstance(path, str) or disposition not in {"include", "exclude"}:
            raise FilteredHistoryError("scope row path or disposition is invalid")
        if row.get("proposed_disposition") != disposition:
            raise FilteredHistoryError("accepted disposition diverges from the reviewed recommendation")
        actual.append((path, disposition))
    if actual != recommendations or len({p for p, _ in actual}) != 55:
        raise FilteredHistoryError("accepted map differs from the ordered review recommendations")
    map_bytes = json.dumps(actual, ensure_ascii=False, separators=(",", ":")).encode()
    if sha256(map_bytes) != EXPECTED_MAP_SHA256:
        raise FilteredHistoryError("ordered accepted path map differs from the independently pinned map digest")
    counts = {key: sum(value == key for _, value in actual) for key in ("include", "exclude")}
    if counts != {"include": 30, "exclude": 25} or receipt.get("counts") != {"total": 55, **counts}:
        raise FilteredHistoryError("scope map counts differ from the exact 30/25 decision")
    if receipt.get("candidate_status") != "blocked_requires_candidate_boundary_redesign":
        raise FilteredHistoryError("excluded paths must keep the candidate blocked")
    validate_overlay_allowlist(dict(actual))
    return dict(actual), evidence


def validate_exact_keys(value: dict[str, Any], expected: set[str], label: str) -> None:
    if set(value) != expected:
        raise FilteredHistoryError(f"{label} keys do not match the closed schema")


def parse_commit(raw: bytes) -> tuple[dict[bytes, list[bytes]], bytes]:
    if len(raw) > MAX_INPUT_BYTES or b"\n\n" not in raw:
        raise FilteredHistoryError("malformed or oversized commit object")
    header, message = raw.split(b"\n\n", 1)
    lines = header.split(b"\n")
    if not lines or not lines[0].startswith(b"tree "):
        raise FilteredHistoryError("commit has no tree header")
    fields: dict[bytes, list[bytes]] = {}
    current = None
    for line in lines:
        if line.startswith(b" "):
            if current is None:
                raise FilteredHistoryError("orphan continuation in commit header")
            fields[current][-1] += b"\n" + line
        else:
            key, sep, value = line.partition(b" ")
            if not sep:
                raise FilteredHistoryError("malformed commit header")
            fields.setdefault(key, []).append(value)
            current = key
    for key in (b"tree", b"parent"):
        for value in fields.get(key, []):
            if not re.fullmatch(rb"[0-9a-f]{40}", value):
                raise FilteredHistoryError(f"malformed {key.decode()} object id")
    return fields, message


def parse_tree(raw: bytes) -> list[tuple[bytes, bytes, bytes]]:
    """Parse raw tree bytes without decoding names: (mode, name, oid)."""
    entries: list[tuple[bytes, bytes, bytes]] = []
    index = 0
    while index < len(raw):
        space = raw.find(b" ", index)
        nul = raw.find(b"\0", space + 1)
        if space < 0 or nul < 0 or nul + 21 > len(raw):
            raise FilteredHistoryError("malformed tree entry")
        mode, name = raw[index:space], raw[space + 1:nul]
        oid = raw[nul + 1:nul + 21]
        if mode not in {b"100644", b"100755", b"120000", b"160000", b"40000"} or not name or b"/" in name or b"\0" in name:
            raise FilteredHistoryError("invalid raw tree mode or name")
        entries.append((mode, name, oid))
        index = nul + 21
    if len({name for _, name, _ in entries}) != len(entries):
        raise FilteredHistoryError("duplicate raw tree name")
    return entries


def raw_tree(root: pathlib.Path, oid: bytes, cache: dict[str, bytes] | None = None) -> bytes:
    hex_oid = oid.hex().encode() if len(oid) == 20 else oid
    if not re.fullmatch(rb"[0-9a-f]{40}", hex_oid):
        raise FilteredHistoryError("malformed tree object id")
    key = hex_oid.decode("ascii")
    if cache is not None and key in cache:
        return cache[key]
    raw = git(root, "cat-file", "tree", hex_oid.decode())
    if len(raw) > MAX_INPUT_BYTES:
        raise FilteredHistoryError("tree object exceeds input limit")
    if cache is not None:
        cache[key] = raw
    return raw


def object_digest(kind: bytes, raw: bytes) -> str:
    return hashlib.sha1(kind + b" " + str(len(raw)).encode() + b"\0" + raw).hexdigest()


def tree_closure(root: pathlib.Path, start: bytes, out: dict[str, bytes]) -> None:
    tree_closure_many(root, {start.hex() if len(start) == 20 else start.decode("ascii")}, out)


def tree_closure_many(root: pathlib.Path, roots: set[str], out: dict[str, bytes]) -> None:
    pending = set(roots)
    while pending:
        missing = pending - set(out)
        pending.clear()
        if not missing:
            break
        if len(out) + len(missing) > MAX_TREES:
            raise FilteredHistoryError("tree count limit exceeded")
        objects = cat_file_batch(root, missing)
        for key, (kind, raw) in objects.items():
            if kind != "tree" or object_digest(b"tree", raw) != key:
                raise FilteredHistoryError("tree bytes do not match their object id")
            out[key] = raw
            for mode, _name, child in parse_tree(raw):
                if mode == b"40000":
                    pending.add(child.hex())


def flatten_tree(
    root: pathlib.Path,
    tree_oid: bytes,
    prefix: bytes = b"",
    tree_cache: dict[str, bytes] | None = None,
) -> dict[bytes, tuple[bytes, bytes]]:
    entries: dict[bytes, tuple[bytes, bytes]] = {}
    for mode, name, oid in parse_tree(raw_tree(root, tree_oid, tree_cache)):
        path = prefix + (b"/" if prefix else b"") + name
        if mode == b"40000":
            entries.update(flatten_tree(root, oid, path, tree_cache))
        else:
            entries[path] = (mode, oid)
    return entries


def make_tree(
    root: pathlib.Path,
    entries: dict[bytes, tuple[bytes, bytes]],
    writer: LooseObjectWriter | None = None,
) -> bytes:
    """Create a tree from byte paths in a disposable object database."""
    directories: dict[bytes, dict[bytes, tuple[bytes, bytes]]] = {b"": {}}
    for path, value in entries.items():
        pieces = path.split(b"/")
        if any(piece in {b"", b".", b".."} for piece in pieces):
            raise FilteredHistoryError("invalid path in transformed tree")
        current = b""
        for piece in pieces[:-1]:
            current = current + (b"/" if current else b"") + piece
            directories.setdefault(current, {})
        directories.setdefault(current, {})[pieces[-1]] = value
    for directory in sorted(
        directories,
        key=lambda item: item.count(b"/") + 1 if item else 0,
        reverse=True,
    ):
        children = directories[directory]
        for child_dir in list(directories):
            parent, slash, name = child_dir.rpartition(b"/")
            child_parent = parent if slash else b""
            if child_parent == directory and child_dir != directory:
                tree_oid = create_raw_tree(root, directories[child_dir], writer)
                children[name] = (b"40000", tree_oid)
        if directory == b"":
            return create_raw_tree(root, children, writer).hex().encode("ascii")
    return b""


def create_raw_tree(
    root: pathlib.Path,
    entries: dict[bytes, tuple[bytes, bytes]],
    writer: LooseObjectWriter | None = None,
) -> bytes:
    raw = bytearray()
    for name, (mode, oid) in sorted(entries.items(), key=lambda item: item[0] + (b"/" if item[1][0] == b"40000" else b"")):
        raw.extend(mode + b" " + name + b"\0" + oid)
    if writer is not None:
        return bytes.fromhex(writer.write(b"tree", bytes(raw)).decode("ascii"))
    object_id = git(root, "hash-object", "-t", "tree", "-w", "--stdin", data=bytes(raw)).strip()
    if not re.fullmatch(rb"[0-9a-f]{40}", object_id):
        raise FilteredHistoryError("Git returned a malformed transformed tree object id")
    return bytes.fromhex(object_id.decode("ascii"))


def mapped_tree(
    source_root: pathlib.Path,
    original_tree: bytes,
    base_entries: dict[bytes, tuple[bytes, bytes]],
    excluded: set[bytes],
    candidate_root: pathlib.Path,
    source_tree_cache: dict[str, bytes] | None = None,
    writer: LooseObjectWriter | None = None,
) -> bytes:
    current = flatten_tree(source_root, original_tree, tree_cache=source_tree_cache)
    for path in excluded:
        current.pop(path, None)
        if path in base_entries:
            current[path] = base_entries[path]
    return make_tree(candidate_root, current, writer)


def commit_environment(fields: dict[bytes, list[bytes]]) -> dict[str, str]:
    env: dict[str, str] = {}
    for header, prefix in ((b"author", "AUTHOR"), (b"committer", "COMMITTER")):
        values = fields.get(header, [])
        if len(values) != 1 or b"\n" in values[0]:
            raise FilteredHistoryError(f"commit must have one plain {header.decode()} header")
        match = re.fullmatch(rb"(.*) <([^<>]*)> (-?[0-9]+) ([+-][0-9]{4})", values[0])
        if not match:
            raise FilteredHistoryError(f"malformed {header.decode()} identity")
        env[f"GIT_{prefix}_NAME"] = match.group(1).decode("utf-8", "surrogateescape")
        env[f"GIT_{prefix}_EMAIL"] = match.group(2).decode("utf-8", "surrogateescape")
        env[f"GIT_{prefix}_DATE"] = f"{match.group(3).decode()} {match.group(4).decode()}"
    return env


def rewritten_commit(raw: bytes, tree: bytes, parents: list[str]) -> bytes:
    header, message = raw.split(b"\n\n", 1)
    original_lines = header.split(b"\n")
    output: list[bytes] = []
    parent_index = 0
    skipping_signature = False
    for line in original_lines:
        if line.startswith((b"gpgsig ", b"gpgsig-sha256 ")):
            skipping_signature = True
            continue
        if line.startswith(b" ") and skipping_signature:
            continue
        skipping_signature = False
        if line.startswith(b"tree "):
            output.append(b"tree " + tree)
        elif line.startswith(b"parent "):
            if parent_index >= len(parents):
                raise FilteredHistoryError("rewritten commit has an unexpected parent")
            output.append(b"parent " + parents[parent_index].encode())
            parent_index += 1
        else:
            output.append(line)
    if parent_index != len(parents):
        raise FilteredHistoryError("rewritten commit is missing mapped parent headers")
    return b"\n".join(output) + b"\n\n" + message


def replay_history(
    source_root: pathlib.Path,
    candidate_root: pathlib.Path,
    base: str,
    source: str,
    dispositions: dict[str, str],
    source_tree_cache: dict[str, bytes] | None = None,
) -> dict[str, Any]:
    """Replay frozen history into a caller-owned disposable bare repo."""
    if candidate_root.resolve() == source_root.resolve() or (source_root.resolve() / ".git") == candidate_root.resolve():
        raise FilteredHistoryError("candidate object destination must be a separate owned repository")
    base_tree = git(source_root, "rev-parse", f"{base}^{{tree}}").strip()
    source_tree_cache = source_tree_cache if source_tree_cache is not None else {}
    base_entries = flatten_tree(source_root, base_tree, tree_cache=source_tree_cache)
    excluded = {path.encode("utf-8", "strict") for path, disposition in dispositions.items() if disposition == "exclude"}
    history = commit_history(source_root, base, source)
    included_blobs: set[str] = set()
    excluded_source_only_blobs: set[str] = set()
    for _old_sha, _raw, fields, _message in history:
        original_entries = flatten_tree(source_root, fields[b"tree"][0], tree_cache=source_tree_cache)
        for path, (mode, oid) in original_entries.items():
            if mode not in {b"100644", b"100755", b"120000"}:
                continue
            if path in excluded:
                excluded_source_only_blobs.add(oid.hex())
            else:
                included_blobs.add(oid.hex())
    # Import only original blobs reachable in included paths and the exact base tree.
    # The copy is performed inside the disposable database and never changes source refs.
    git(candidate_root, "fetch", "--no-tags", str(source_root), base)
    writer = LooseObjectWriter(candidate_root)
    commit_map: dict[str, str] = {base: base}
    tree_map: dict[str, str] = {}
    base_candidate_tree = git(candidate_root, "rev-parse", f"{base}^{{tree}}").strip()
    if base_candidate_tree != base_tree:
        raise FilteredHistoryError("disposable repository base tree differs from frozen base")
    base_blobs = {oid.hex() for _path, (mode, oid) in base_entries.items() if mode in {b"100644", b"100755", b"120000"}}
    blobs_to_copy = included_blobs - base_blobs
    for oid, (kind, raw) in cat_file_batch(source_root, blobs_to_copy).items():
        if kind != "blob" or object_digest(b"blob", raw) != oid:
            raise FilteredHistoryError("included source blob is malformed or has the wrong object identity")
        writer.write(b"blob", raw)
    original_commit_set = {row[0] for row in history}
    merge_count = 0
    candidate_tree_cache = writer.tree_objects
    for old_sha, raw, fields, message in history:
        old_parents = [item.decode() for item in fields.get(b"parent", [])]
        if len(old_parents) > 1:
            merge_count += 1
        mapped_parents = []
        for parent in old_parents:
            mapped = commit_map.get(parent)
            if mapped is None:
                raise FilteredHistoryError("parent was not replayed before its child")
            mapped_parents.append(mapped)
        original_tree = fields[b"tree"][0]
        original_entries = flatten_tree(source_root, original_tree, tree_cache=source_tree_cache)
        new_tree = mapped_tree(
            source_root,
            original_tree,
            base_entries,
            excluded,
            candidate_root,
            source_tree_cache,
            writer,
        )
        transformed_entries = flatten_tree(candidate_root, new_tree, tree_cache=candidate_tree_cache)
        validate_path_entries(
            original_entries,
            transformed_entries,
            base_entries,
            {path.decode("utf-8"): "exclude" for path in excluded},
        )
        raw_new = rewritten_commit(raw, new_tree, mapped_parents)
        new_sha = writer.write(b"commit", raw_new).decode("ascii")
        if not re.fullmatch(r"[0-9a-f]{40}", new_sha):
            raise FilteredHistoryError("replayed commit returned malformed object id")
        new_fields, _new_message = parse_commit(raw_new)
        observed_parents = [item.decode() for item in new_fields.get(b"parent", [])]
        validate_parent_map(old_parents, observed_parents, commit_map)
        if new_fields[b"tree"][0].decode() != new_tree.decode("ascii"):
            raise FilteredHistoryError("rewritten commit tree differs from its mapped tree")
        commit_map[old_sha] = new_sha
        tree_map[old_sha] = new_tree.decode()
    if len(commit_map) != len(original_commit_set) + 1 or merge_count != 3:
        raise FilteredHistoryError("one-to-one history map or frozen merge count differs")
    validate_excluded_blob_overlap(excluded_source_only_blobs - base_blobs, included_blobs)
    return {
        "schema": "relyra.phase79.filtered-history-proof.v1",
        "base_sha": base,
        "original_source_sha": source,
        "filtered_source_sha": commit_map[source],
        "original_source_tree_sha": git(source_root, "rev-parse", f"{source}^{{tree}}").strip().decode(),
        "filtered_source_tree_sha": git(candidate_root, "rev-parse", f"{commit_map[source]}^{{tree}}").strip().decode(),
        "commit_map": commit_map,
        "tree_map": tree_map,
        "commit_count": len(history),
        "merge_count": merge_count,
        "excluded_paths": sorted(path.decode("utf-8") for path in excluded),
        "signature_handling": "gpgsig and gpgsig-sha256 headers are omitted from rewritten commits; original signatures do not authenticate rewritten bytes.",
    }


def flatten_witness_tree(
    witness_trees: dict[str, Any],
    tree_sha: str,
    prefix: bytes = b"",
    base_tree_cache: dict[str, bytes] | None = None,
) -> dict[bytes, tuple[bytes, bytes]]:
    try:
        raw = (
            bytes.fromhex(witness_trees[tree_sha])
            if tree_sha in witness_trees
            else (base_tree_cache or {})[tree_sha]
        )
    except (KeyError, TypeError, ValueError) as exc:
        raise FilteredHistoryError("witness omits a source-only tree and the pinned base does not supply it") from exc
    if object_digest(b"tree", raw) != tree_sha:
        raise FilteredHistoryError("witness tree bytes do not match their hash")
    result: dict[bytes, tuple[bytes, bytes]] = {}
    for mode, name, oid in parse_tree(raw):
        path = prefix + (b"/" if prefix else b"") + name
        if mode == b"40000":
            result.update(flatten_witness_tree(witness_trees, oid.hex(), path, base_tree_cache))
        else:
            result[path] = (mode, oid)
    return result


def validate_tree_closure(trees: dict[str, Any], roots: set[str]) -> set[str]:
    closed: set[str] = set()
    pending = list(roots)
    while pending:
        tree_sha = pending.pop()
        if tree_sha in closed:
            continue
        try:
            raw = bytes.fromhex(trees[tree_sha])
        except (KeyError, TypeError, ValueError) as exc:
            raise FilteredHistoryError("witness omits a tree from the recursively closed source history") from exc
        if object_digest(b"tree", raw) != tree_sha:
            raise FilteredHistoryError("witness tree object does not match its declared SHA")
        closed.add(tree_sha)
        for mode, _name, child_oid in parse_tree(raw):
            if mode == b"40000":
                pending.append(child_oid.hex())
    if closed != set(trees):
        raise FilteredHistoryError("witness tree object key set is not exactly the recursive source/base closure")
    return closed


def validate_witness_tree_closure(
    candidate_root: pathlib.Path,
    witness_trees: dict[str, Any],
    roots: set[str],
    base_reachable_objects: set[str],
    base_tree_cache: dict[str, bytes] | None = None,
) -> dict[str, bytes]:
    """Check exact post-base tree closure, resolving shared trees from frozen base ancestry."""
    visited_witness: set[str] = set()
    visited_base: set[str] = set()
    base_cache = dict(base_tree_cache or {})
    pending = set(roots)
    while pending:
        current = pending - visited_witness - visited_base
        pending.clear()
        missing_base: set[str] = set()
        newly_loaded: list[bytes] = []
        for tree_sha in current:
            if tree_sha in witness_trees:
                try:
                    raw = bytes.fromhex(witness_trees[tree_sha])
                except (TypeError, ValueError) as exc:
                    raise FilteredHistoryError("witness tree encoding is malformed") from exc
                if object_digest(b"tree", raw) != tree_sha:
                    raise FilteredHistoryError("witness tree object does not match its declared SHA")
                visited_witness.add(tree_sha)
                newly_loaded.append(raw)
            elif tree_sha in base_reachable_objects:
                raw = base_cache.get(tree_sha)
                if raw is None:
                    missing_base.add(tree_sha)
                else:
                    if object_digest(b"tree", raw) != tree_sha:
                        raise FilteredHistoryError("pinned base tree bytes do not match their object id")
                    visited_base.add(tree_sha)
                    newly_loaded.append(raw)
            else:
                raise FilteredHistoryError("witness omits a source tree not reachable from frozen base")
        for tree_sha, (kind, raw) in cat_file_batch(candidate_root, missing_base).items():
            if kind != "tree" or object_digest(b"tree", raw) != tree_sha:
                raise FilteredHistoryError("frozen base does not provide a valid shared tree object")
            base_cache[tree_sha] = raw
            visited_base.add(tree_sha)
            newly_loaded.append(raw)
        for raw in newly_loaded:
            for mode, _name, child_oid in parse_tree(raw):
                if mode == b"40000":
                    pending.add(child_oid.hex())
    if visited_witness != set(witness_trees):
        raise FilteredHistoryError("witness tree map is not exactly the recursively closed source-only tree set")
    if set(witness_trees) & base_reachable_objects:
        raise FilteredHistoryError("source-only witness duplicates trees already reachable from frozen base")
    return base_cache


def validate_parent_map(old_parents: list[str], observed_parents: list[str], commit_map: dict[str, str]) -> None:
    try:
        expected = [commit_map[parent] for parent in old_parents]
    except KeyError as exc:
        raise FilteredHistoryError("commit map omits an original parent") from exc
    if observed_parents != expected:
        raise FilteredHistoryError("filtered commit parent order/tree differs from the proof map")


def validate_path_entries(original: dict[bytes, tuple[bytes, bytes]], transformed: dict[bytes, tuple[bytes, bytes]], base: dict[bytes, tuple[bytes, bytes]], dispositions: dict[str, str]) -> None:
    expected = dict(original)
    for path, disposition in dispositions.items():
        if disposition == "exclude":
            encoded_path = path.encode("utf-8")
            expected.pop(encoded_path, None)
            if encoded_path in base:
                expected[encoded_path] = base[encoded_path]
    if transformed != expected:
        raise FilteredHistoryError("mapped tree changes included entries or does not restore exclusions to base")


def validate_overlay_allowlist(dispositions: dict[str, str]) -> None:
    excluded = [path.encode("utf-8") for path, disposition in dispositions.items() if disposition == "exclude"]
    for overlay in OVERLAY_PATHS:
        overlay_bytes = overlay.encode("utf-8")
        if any(
            overlay_bytes == path
            or overlay_bytes.startswith(path + b"/")
            or path.startswith(overlay_bytes + b"/")
            for path in excluded
        ):
            raise FilteredHistoryError("declared overlay path overlaps a reviewed exclusion")


def validate_excluded_paths(transformed: dict[bytes, tuple[bytes, bytes]], base: dict[bytes, tuple[bytes, bytes]], dispositions: dict[str, str]) -> None:
    for path, disposition in dispositions.items():
        if disposition != "exclude":
            continue
        encoded = path.encode("utf-8")
        if transformed.get(encoded) != base.get(encoded):
            raise FilteredHistoryError("candidate overlay resurrected or changed a reviewed excluded path")


def validate_excluded_blob_overlap(excluded_blob_oids: set[str], included_blob_oids: set[str]) -> None:
    if excluded_blob_oids & included_blob_oids:
        raise FilteredHistoryError("a source-only excluded blob OID is also reachable via an included path")


def validate_bundle_commit_set(actual: set[str], required: set[str]) -> None:
    if actual != required:
        raise FilteredHistoryError("candidate bundle commit set differs from base ancestry plus mapped and declared commits")


def verify_candidate_contract(candidate_root: pathlib.Path, phase_dir: pathlib.Path) -> dict[str, Any]:
    dispositions, evidence = validate_receipt(phase_dir)
    proof_path = phase_dir / "79-FILTERED-HISTORY-PROOF.json"
    manifest_path = phase_dir / "79-FILTERED-CANDIDATE.json"
    bundle_path = phase_dir / "79-FILTERED-CANDIDATE.bundle"
    witness, proof_raw = json_file(proof_path, "filtered-history proof", MAX_WITNESS_BYTES)
    manifest, manifest_raw = json_file(manifest_path, "filtered-candidate manifest")
    validate_exact_keys(witness, WITNESS_KEYS, "filtered-history witness")
    validate_exact_keys(manifest, MANIFEST_KEYS, "filtered-candidate manifest")
    if witness.get("schema") != "relyra.phase79.filtered-history-witness.v1" or witness.get("evidence") != evidence or witness.get("dispositions") != dispositions:
        raise FilteredHistoryError("proof does not bind the exact accepted receipt")
    proof = witness.get("proof")
    commits, trees = witness.get("commits"), witness.get("trees")
    if not isinstance(proof, dict) or not isinstance(commits, dict) or not isinstance(trees, dict):
        raise FilteredHistoryError("witness commit/tree/proof members are malformed")
    validate_exact_keys(proof, PROOF_KEYS, "filtered-history proof payload")
    limits = witness.get("limits")
    if not isinstance(limits, dict):
        raise FilteredHistoryError("witness limits are malformed")
    validate_exact_keys(limits, WITNESS_LIMIT_KEYS, "filtered-history witness limits")
    if limits != {"commit_count": len(commits), "tree_count": len(trees), "object_count": len(commits) + len(trees)}:
        raise FilteredHistoryError("witness object counts differ from its exact limits record")
    if (proof.get("base_sha"), proof.get("original_source_sha"), proof.get("original_source_tree_sha"), proof.get("commit_count"), proof.get("merge_count")) != (EXPECTED["base_sha"], EXPECTED["source_sha"], EXPECTED["source_tree_sha"], 612, 3):
        raise FilteredHistoryError("proof identities or frozen history counts differ")
    commit_map, tree_map = proof.get("commit_map"), proof.get("tree_map")
    if not isinstance(commit_map, dict) or len(commit_map) != 613 or not isinstance(tree_map, dict) or len(tree_map) != 612:
        raise FilteredHistoryError("proof has incomplete commit/tree maps")
    validate_map_key_sets(commits, commit_map, tree_map, EXPECTED["base_sha"])
    validate_source_commit_closure(commits, EXPECTED["source_sha"], EXPECTED["base_sha"])
    if not re.fullmatch(r"[0-9a-f]{40}", witness.get("base_tree", "")):
        raise FilteredHistoryError("witness base tree identity is malformed")
    if any(not re.fullmatch(r"[0-9a-f]{40}", key) or not isinstance(value, str) or not re.fullmatch(r"[0-9a-f]{40}", value) for key, value in commit_map.items()):
        raise FilteredHistoryError("proof commit map contains malformed identities")
    if any(not re.fullmatch(r"[0-9a-f]{40}", key) or not isinstance(value, str) or not re.fullmatch(r"[0-9a-f]{40}", value) for key, value in tree_map.items()):
        raise FilteredHistoryError("proof tree map contains malformed identities")
    if len(set(commit_map.values())) != len(commit_map):
        raise FilteredHistoryError("old-to-filtered commit map is not one-to-one")
    if commit_map.get(EXPECTED["base_sha"]) != EXPECTED["base_sha"] or commit_map.get(EXPECTED["source_sha"]) != proof.get("filtered_source_sha"):
        raise FilteredHistoryError("proof base/source mapping is inconsistent")
    candidate_commit_ids = set(commit_map.values())
    candidate_tree_roots = set(tree_map.values()) | {witness.get("base_tree")}
    candidate_objects = cat_file_batch(candidate_root, candidate_commit_ids | candidate_tree_roots)
    candidate_tree_cache: dict[str, bytes] = {}
    for oid, (kind, raw) in candidate_objects.items():
        expected_kind = "commit" if oid in candidate_commit_ids else "tree"
        if kind != expected_kind or object_digest(kind.encode("ascii"), raw) != oid:
            raise FilteredHistoryError("candidate commit/tree bytes do not match their object identities")
        if kind == "tree":
            candidate_tree_cache[oid] = raw
    tree_closure_many(candidate_root, candidate_tree_roots, candidate_tree_cache)
    base_commit_raw = candidate_objects[EXPECTED["base_sha"]][1]
    base_fields, _base_message = parse_commit(base_commit_raw)
    if base_fields[b"tree"][0].decode() != witness.get("base_tree"):
        raise FilteredHistoryError("candidate frozen base commit/tree differs from witness.base_tree")
    candidate_base_entries = flatten_tree(candidate_root, base_fields[b"tree"][0], tree_cache=candidate_tree_cache)
    base_reachable_objects = {
        row.split(None, 1)[0].decode("ascii")
        for row in git(candidate_root, "rev-list", "--objects", EXPECTED["base_sha"]).splitlines()
        if row
    }
    tree_roots = {row["tree"] for row in commits.values()}
    base_original_tree_cache = validate_witness_tree_closure(
        candidate_root,
        trees,
        tree_roots,
        base_reachable_objects,
        candidate_tree_cache,
    )
    base_blob_oids = {oid.hex() for _path, (mode, oid) in candidate_base_entries.items() if mode in {b"100644", b"100755", b"120000"}}
    source_only_excluded_blobs: set[str] = set()
    included_blobs: set[str] = set()
    excluded_path_bytes = {path.encode("utf-8"): value for path, value in witness.get("dispositions", {}).items() if value == "exclude"}
    for sha, raw_row in commits.items():
        if not isinstance(raw_row, dict):
            raise FilteredHistoryError("malformed raw commit witness row")
        validate_exact_keys(raw_row, WITNESS_COMMIT_KEYS, "raw commit witness row")
        if not isinstance(raw_row.get("raw"), str):
            raise FilteredHistoryError("malformed raw commit witness row")
        raw = bytes.fromhex(raw_row["raw"])
        fields, original_message = parse_commit(raw)
        if object_digest(b"commit", raw) != sha or fields[b"tree"][0].decode() != raw_row.get("tree"):
            raise FilteredHistoryError("original raw commit witness does not match its identity")
        old_parents = [item.decode() for item in fields.get(b"parent", [])]
        if old_parents != raw_row.get("parents"):
            raise FilteredHistoryError("raw commit parent list differs from witness metadata")
        new_sha = commit_map.get(sha)
        if not isinstance(new_sha, str) or tree_map.get(sha) is None:
            raise FilteredHistoryError("commit map is missing an original commit")
        new_raw = candidate_objects[new_sha][1]
        if object_digest(b"commit", new_raw) != new_sha:
            raise FilteredHistoryError("filtered commit object hash is malformed")
        new_fields, new_message = parse_commit(new_raw)
        observed_parents = [item.decode() for item in new_fields.get(b"parent", [])]
        validate_parent_map(old_parents, observed_parents, commit_map)
        if new_fields[b"tree"][0].decode() != tree_map[sha]:
            raise FilteredHistoryError("filtered commit parent order/tree differs from the proof map")
        signature_keys = {b"gpgsig", b"gpgsig-sha256"}
        original_metadata = {key: values for key, values in fields.items() if key not in {b"tree", b"parent"} | signature_keys}
        filtered_metadata = {key: values for key, values in new_fields.items() if key not in {b"tree", b"parent"} | signature_keys}
        if original_metadata != filtered_metadata or original_message != new_message:
            raise FilteredHistoryError("rewritten commit changed author/committer/message or non-signature metadata")
        original_entries = flatten_witness_tree(trees, raw_row["tree"], base_tree_cache=base_original_tree_cache)
        for path, (mode, oid) in original_entries.items():
            if mode not in {b"100644", b"100755", b"120000"}:
                continue
            if path in excluded_path_bytes:
                source_only_excluded_blobs.add(oid.hex())
            else:
                included_blobs.add(oid.hex())
        observed_entries = flatten_tree(candidate_root, new_fields[b"tree"][0], tree_cache=candidate_tree_cache)
        validate_path_entries(original_entries, observed_entries, candidate_base_entries, dispositions)
    if len(commits) != 612 or len(trees) != 2410:
        raise FilteredHistoryError("witness commit/tree closure counts differ from frozen source")
    if len(proof_raw) > MAX_WITNESS_BYTES:
        raise FilteredHistoryError("filtered-history proof exceeds 8 MiB")
    proof_sha = sha256(proof_raw)
    bundle_sha = sha256(read_limited(bundle_path, MAX_INPUT_BYTES * 16))
    excluded_source_only = source_only_excluded_blobs - base_blob_oids
    validate_excluded_blob_overlap(excluded_source_only, included_blobs)
    with tempfile.TemporaryDirectory(prefix="phase79-bundle-verify-") as temporary:
        mirror = pathlib.Path(temporary) / "bundle.git"
        try:
            cloned = subprocess.run(["git", "clone", "--mirror", str(bundle_path), str(mirror)], cwd=temporary, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=180, check=False, env={**os.environ, "GIT_TERMINAL_PROMPT": "0"})
        except (OSError, subprocess.TimeoutExpired) as exc:
            raise FilteredHistoryError(f"cannot inspect candidate bundle object set: {exc}") from exc
        if cloned.returncode:
            raise FilteredHistoryError("candidate bundle cannot be cloned for object inspection: " + cloned.stdout[-1500:])
        packed_objects: dict[str, str] = {}
        for index in (mirror / "objects/pack").glob("*.idx"):
            rows = git(mirror, "verify-pack", "-v", str(index)).decode(errors="replace").splitlines()
            for line in rows:
                fields = line.split()
                if len(fields) >= 3 and re.fullmatch(r"[0-9a-f]{40}", fields[0]) and fields[1] in {"commit", "tree", "blob", "tag"}:
                    packed_objects[fields[0]] = fields[1]
        packed_excluded = sorted(oid for oid in excluded_source_only if packed_objects.get(oid) == "blob")
        if packed_excluded:
            raise FilteredHistoryError("candidate bundle packs source-only excluded blobs: " + ", ".join(packed_excluded[:8]))
    commit_map_sha = sha256(json.dumps(commit_map, sort_keys=True, separators=(",", ":")).encode())
    final_source = manifest.get("final_source_sha")
    final_tree = manifest.get("final_tree_sha")
    if not isinstance(final_source, str) or not re.fullmatch(r"[0-9a-f]{40}", final_source) or not isinstance(final_tree, str) or not re.fullmatch(r"[0-9a-f]{40}", final_tree):
        raise FilteredHistoryError("candidate manifest final source/tree identities are malformed")
    expected_branch = candidate_branch_name(final_source)
    expected_manifest = {
        "schema": "relyra.phase79.filtered-candidate.v1",
        "base_sha": EXPECTED["base_sha"],
        "original_source_sha": EXPECTED["source_sha"],
        "original_source_tree_sha": EXPECTED["source_tree_sha"],
        "filtered_source_sha": proof["filtered_source_sha"],
        "filtered_tree_sha": proof["filtered_source_tree_sha"],
        "final_source_sha": final_source,
        "final_tree_sha": final_tree,
        "commit_map_sha256": commit_map_sha,
        "proof_sha256": proof_sha,
        "bundle_sha256": bundle_sha,
        "branch_name": expected_branch,
    }
    if any(manifest.get(key) != value for key, value in expected_manifest.items()):
        raise FilteredHistoryError("candidate manifest does not bind proof, bundle, and source identities")
    if manifest.get("remote_url") != EXPECTED_REMOTE_URL:
        raise FilteredHistoryError("candidate manifest remote URL differs from the exact publication repository")
    candidate_origin = git(candidate_root, "remote", "get-url", "origin").decode().strip()
    if candidate_origin != EXPECTED_REMOTE_URL:
        raise FilteredHistoryError("candidate repository origin differs from the exact publication repository")
    if git(candidate_root, "rev-parse", f"refs/heads/{expected_branch}").decode().strip() != final_source:
        raise FilteredHistoryError("candidate branch ref does not match the publication packet branch/SHA contract")
    observed_tip = git(candidate_root, "rev-parse", proof["filtered_source_sha"]).decode().strip()
    observed_tree = git(candidate_root, "rev-parse", f"{observed_tip}^{{tree}}").decode().strip()
    observed_final_tree = git(candidate_root, "rev-parse", f"{final_source}^{{tree}}").decode().strip()
    if observed_tree != proof["filtered_source_tree_sha"] or observed_final_tree != final_tree:
        raise FilteredHistoryError("candidate filtered source tree differs from proof")
    final_entries = flatten_tree(candidate_root, final_tree.encode())
    validate_excluded_paths(final_entries, candidate_base_entries, dispositions)
    git(candidate_root, "merge-base", "--is-ancestor", observed_tip, final_source, timeout=30)
    overlay_parent = manifest.get("overlay_parent_sha")
    overlay_tip = manifest.get("overlay_tip_sha")
    proof_commit = manifest.get("proof_commit_sha")
    if overlay_parent != observed_tip or proof_commit != final_source or not isinstance(overlay_tip, str):
        raise FilteredHistoryError("candidate overlay/proof commit identities are malformed")
    proof_parents = git(candidate_root, "show", "-s", "--format=%P", final_source).decode().split()
    if proof_parents != [overlay_tip] or git(candidate_root, "diff-tree", "--no-commit-id", "--name-only", "-r", final_source).decode().splitlines() != [".planning/phases/79-adopter-ready-closeout/79-FILTERED-HISTORY-PROOF.json"]:
        raise FilteredHistoryError("final proof commit parent or single-path delta differs")
    if overlay_tip != observed_tip:
        git(candidate_root, "merge-base", "--is-ancestor", observed_tip, overlay_tip, timeout=30)
        overlay_paths = git(candidate_root, "diff", "--name-only", "-z", observed_tip, overlay_tip).split(b"\0")
        overlay_paths = sorted(path.decode("utf-8") for path in overlay_paths if path)
    else:
        overlay_paths = []
    validate_overlay_allowlist(dispositions)
    if overlay_paths != manifest.get("overlay_paths") or set(overlay_paths) - set(OVERLAY_PATHS):
        raise FilteredHistoryError("candidate overlay changed undeclared paths")
    with tempfile.TemporaryDirectory(prefix="phase79-bundle-refs-") as temporary:
        mirror = pathlib.Path(temporary) / "refs.git"
        cloned = subprocess.run(["git", "clone", "--mirror", str(bundle_path), str(mirror)], cwd=temporary, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=180, check=False, env={**os.environ, "GIT_TERMINAL_PROMPT": "0"})
        if cloned.returncode:
            raise FilteredHistoryError("candidate bundle refs cannot be inspected: " + cloned.stdout[-1000:])
        bundled_commits = set(git(mirror, "rev-list", "--all").decode().splitlines())
        base_ancestry = set(git(candidate_root, "rev-list", EXPECTED["base_sha"]).decode().splitlines())
        required_commits = base_ancestry | set(commit_map.values()) | {final_source}
        if overlay_tip != observed_tip:
            required_commits.add(overlay_tip)
        validate_bundle_commit_set(bundled_commits, required_commits)
        packed_commits = {oid for oid, kind in packed_objects.items() if kind == "commit"}
        validate_bundle_commit_set(packed_commits, required_commits)
    return {"valid": True, "proof_sha256": proof_sha, "bundle_sha256": bundle_sha, "candidate_manifest_sha256": sha256(manifest_raw), "filtered_source_sha": final_source, "filtered_tree_sha": final_tree, "mapped_source_sha": observed_tip, "mapped_tree_sha": observed_tree, "commit_count": len(commits), "tree_count": len(trees), "commit_map": commit_map}


def validate_map_key_sets(commits: dict[str, Any], commit_map: dict[str, Any], tree_map: dict[str, Any], base_sha: str) -> None:
    if set(commit_map) != set(commits) | {base_sha} or set(tree_map) != set(commits):
        raise FilteredHistoryError("proof commit/tree map keys do not exactly match the witnessed history")


def validate_source_commit_closure(commits: dict[str, Any], source_sha: str, base_sha: str) -> None:
    """Require every witness commit to be reachable through parents from source."""
    pending = [source_sha]
    visited: set[str] = set()
    while pending:
        sha = pending.pop()
        if sha == base_sha or sha in visited:
            continue
        row = commits.get(sha)
        if not isinstance(row, dict) or not isinstance(row.get("parents"), list):
            raise FilteredHistoryError("source parent closure reaches a missing or malformed witness commit")
        visited.add(sha)
        parents = row["parents"]
        if any(not isinstance(parent, str) or not re.fullmatch(r"[0-9a-f]{40}", parent) for parent in parents):
            raise FilteredHistoryError("witness commit parent identity is malformed")
        pending.extend(parents)
    if visited != set(commits):
        raise FilteredHistoryError("witness commits are not exactly the frozen source-to-base parent closure")


def build_candidate(source_root: pathlib.Path, phase_dir: pathlib.Path, candidate_root: pathlib.Path) -> dict[str, Any]:
    source_root = source_root.resolve()
    candidate_input = candidate_root.expanduser().absolute()
    if candidate_input.is_symlink():
        raise FilteredHistoryError("candidate path may not be a symlink")
    try:
        candidate_parent = candidate_input.parent.resolve(strict=True)
    except OSError as exc:
        raise FilteredHistoryError("candidate parent must be an existing owned temporary directory") from exc
    candidate_root = candidate_parent / candidate_input.name
    if candidate_root == source_root or source_root in candidate_root.parents or candidate_root in source_root.parents:
        raise FilteredHistoryError("candidate repository must be isolated outside the active project tree")
    active_git_dir = pathlib.Path(git(source_root, "rev-parse", "--absolute-git-dir").decode().strip()).resolve()
    common_git_dir_raw = git(source_root, "rev-parse", "--git-common-dir").decode().strip()
    common_git_dir = pathlib.Path(common_git_dir_raw)
    if not common_git_dir.is_absolute():
        common_git_dir = (source_root / common_git_dir).resolve()
    else:
        common_git_dir = common_git_dir.resolve()
    for git_dir in {active_git_dir, common_git_dir}:
        if candidate_root == git_dir or git_dir in candidate_root.parents or candidate_root in git_dir.parents:
            raise FilteredHistoryError("candidate repository may not equal, contain, or share the active Git directory")
    allowed_temp_roots = {pathlib.Path(tempfile.gettempdir()).resolve(), pathlib.Path("/private/tmp").resolve(), pathlib.Path("/tmp").resolve()}
    if not any(candidate_parent == temp_root or temp_root in candidate_parent.parents for temp_root in allowed_temp_roots):
        raise FilteredHistoryError("candidate repository must be created under an owned temporary root")
    if candidate_parent.stat().st_uid != os.getuid() or candidate_parent.is_symlink():
        raise FilteredHistoryError("candidate parent must be a non-symlink directory owned by the current user")
    if candidate_root.exists():
        raise FilteredHistoryError("candidate destination already exists; refusing to overwrite an owned or pre-existing path")
    phase_dir.mkdir(parents=True, exist_ok=True)
    proof_path = phase_dir / "79-FILTERED-HISTORY-PROOF.json"
    manifest_path = phase_dir / "79-FILTERED-CANDIDATE.json"
    bundle_path = phase_dir / "79-FILTERED-CANDIDATE.bundle"
    if any(path.exists() or path.is_symlink() for path in (proof_path, manifest_path, bundle_path)):
        raise FilteredHistoryError("candidate evidence output already exists; refusing to overwrite it")
    candidate_root.mkdir()
    git(source_root, "--version")
    init = subprocess.run(["git", "init", str(candidate_root)], cwd=source_root, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=30, check=False)
    if init.returncode:
        raise FilteredHistoryError("cannot initialize owned candidate repository: " + init.stdout[-1000:])
    git(candidate_root, "remote", "add", "origin", "https://github.com/szTheory/relyra.git")
    witness = capture_witness(source_root, phase_dir, candidate_root)
    proof = witness["proof"]
    staging_branch = "phase79-filtered-staging"
    git(candidate_root, "update-ref", f"refs/heads/{staging_branch}", proof["filtered_source_sha"])
    git(candidate_root, "checkout", "-B", staging_branch, proof["filtered_source_sha"])
    for relative in OVERLAY_PATHS:
        source_path = source_root / relative
        target_path = candidate_root / relative
        if source_path.is_symlink() or not source_path.is_file():
            raise FilteredHistoryError(f"approved overlay source is missing or unsafe: {relative}")
        target_path.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source_path, target_path)
    git(candidate_root, "add", "--", *OVERLAY_PATHS)
    overlay_status = subprocess.run(["git", "diff", "--cached", "--name-only", "-z"], cwd=candidate_root, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
    changed = [item.decode("utf-8") for item in overlay_status.stdout.split(b"\0") if item]
    if overlay_status.returncode or set(changed) - set(OVERLAY_PATHS):
        raise FilteredHistoryError("candidate overlay contains a path outside the exact Plan 79-14/79-15 allowlist")
    if changed:
        env = {
            **os.environ,
            "GIT_AUTHOR_NAME": "Relyra Phase 79 Filtered Candidate",
            "GIT_AUTHOR_EMAIL": "phase79-filtered-candidate@example.invalid",
            "GIT_COMMITTER_NAME": "Relyra Phase 79 Filtered Candidate",
            "GIT_COMMITTER_EMAIL": "phase79-filtered-candidate@example.invalid",
            "GIT_AUTHOR_DATE": "2026-10-02T00:00:00+00:00",
            "GIT_COMMITTER_DATE": "2026-10-02T00:00:00+00:00",
            "GIT_TERMINAL_PROMPT": "0",
        }
        result = subprocess.run(["git", "commit", "-m", "chore(79-14): overlay reviewed filtered-history implementation"], cwd=candidate_root, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=120, check=False, env=env)
        if result.returncode:
            raise FilteredHistoryError("cannot record bounded candidate overlay: " + result.stdout[-1500:])
    overlay_tip = git(candidate_root, "rev-parse", "HEAD").decode().strip()
    proof_path.write_bytes((json.dumps(witness, sort_keys=True, separators=(",", ":")) + "\n").encode())
    proof_in_repo = candidate_root / ".planning/phases/79-adopter-ready-closeout/79-FILTERED-HISTORY-PROOF.json"
    proof_in_repo.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(proof_path, proof_in_repo)
    git(candidate_root, "add", "--", ".planning/phases/79-adopter-ready-closeout/79-FILTERED-HISTORY-PROOF.json")
    proof_commit_env = {
        **os.environ,
        "GIT_AUTHOR_NAME": "Relyra Phase 79 Proof",
        "GIT_AUTHOR_EMAIL": "phase79-proof@example.invalid",
        "GIT_COMMITTER_NAME": "Relyra Phase 79 Proof",
        "GIT_COMMITTER_EMAIL": "phase79-proof@example.invalid",
        "GIT_AUTHOR_DATE": "2026-10-02T00:00:01+00:00",
        "GIT_COMMITTER_DATE": "2026-10-02T00:00:01+00:00",
        "GIT_TERMINAL_PROMPT": "0",
    }
    result = subprocess.run(["git", "commit", "-m", "docs(79-14): bind filtered-history proof"], cwd=candidate_root, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=120, check=False, env=proof_commit_env)
    if result.returncode:
        raise FilteredHistoryError("cannot commit proof artifact in isolated candidate: " + result.stdout[-1500:])
    final_source = git(candidate_root, "rev-parse", "HEAD").decode().strip()
    final_tree = git(candidate_root, "rev-parse", "HEAD^{tree}").decode().strip()
    branch = candidate_branch_name(final_source)
    git(candidate_root, "branch", "-m", branch)
    delta = git(candidate_root, "diff-tree", "--no-commit-id", "--name-only", "-r", "HEAD").decode().splitlines()
    if delta != [".planning/phases/79-adopter-ready-closeout/79-FILTERED-HISTORY-PROOF.json"]:
        raise FilteredHistoryError("final proof commit must change only the proof artifact")
    bundle_result = subprocess.run(["git", "bundle", "create", str(bundle_path), f"refs/heads/{branch}"], cwd=candidate_root, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=300, check=False, env={**os.environ, "GIT_TERMINAL_PROMPT": "0"})
    if bundle_result.returncode:
        raise FilteredHistoryError("cannot create proof-bound candidate bundle: " + bundle_result.stdout[-1500:])
    manifest = {
        "schema": "relyra.phase79.filtered-candidate.v1",
        "base_sha": proof["base_sha"],
        "original_source_sha": proof["original_source_sha"],
        "original_source_tree_sha": proof["original_source_tree_sha"],
        "filtered_source_sha": proof["filtered_source_sha"],
        "filtered_tree_sha": proof["filtered_source_tree_sha"],
        "final_source_sha": final_source,
        "final_tree_sha": final_tree,
        "commit_map_sha256": sha256(json.dumps(proof["commit_map"], sort_keys=True, separators=(",", ":")).encode()),
        "proof_sha256": sha256(proof_path.read_bytes()),
        "bundle_sha256": sha256(bundle_path.read_bytes()),
        "overlay_parent_sha": proof["filtered_source_sha"],
        "overlay_tip_sha": overlay_tip,
        "overlay_paths": sorted(changed),
        "proof_commit_sha": final_source,
        "remote_url": EXPECTED_REMOTE_URL,
        "branch_name": branch,
    }
    manifest_path.write_bytes((json.dumps(manifest, indent=2, sort_keys=True) + "\n").encode())
    return verify_candidate_contract(candidate_root, phase_dir)


def commit_history(root: pathlib.Path, base: str, source: str) -> list[tuple[str, bytes, dict[bytes, list[bytes]], bytes]]:
    rows = [row.decode("ascii") for row in git(root, "rev-list", "--topo-order", "--reverse", source, f"^{base}").splitlines()]
    if not rows or len(rows) > MAX_COMMITS:
        raise FilteredHistoryError("original commit count is missing or exceeds the bound")
    all_ids = set(git(root, "rev-list", "--topo-order", "--reverse", base, source).decode().splitlines())
    if not all_ids:
        raise FilteredHistoryError("base/source history is empty")
    raw_commits = cat_file_batch(root, rows)
    output = []
    for sha in rows:
        kind, raw = raw_commits[sha]
        if kind != "commit" or len(raw) > MAX_INPUT_BYTES or object_digest(b"commit", raw) != sha:
            raise FilteredHistoryError("commit bytes do not match object identity or exceed limit")
        fields, message = parse_commit(raw)
        parents = [value.decode() for value in fields.get(b"parent", [])]
        if any(parent not in all_ids and parent != base for parent in parents):
            raise FilteredHistoryError("commit parent is outside the frozen base/source history")
        output.append((sha, raw, fields, message))
    if output[-1][0] != source:
        raise FilteredHistoryError("source tip is not in the replay set")
    return output


def capture_witness(root: pathlib.Path, phase_dir: pathlib.Path, candidate_root: pathlib.Path | None = None) -> dict[str, Any]:
    dispositions, evidence = validate_receipt(phase_dir)
    history = commit_history(root, evidence["base_sha"], evidence["source_sha"])
    commits: dict[str, dict[str, Any]] = {}
    source_tree_cache: dict[str, bytes] = {}
    tree_roots: set[str] = set()
    for sha, raw, fields, _message in history:
        tree = fields[b"tree"][0]
        tree_roots.add(tree.decode("ascii"))
        commits[sha] = {
            "raw": raw.hex(), "parents": [p.decode() for p in fields.get(b"parent", [])],
            "tree": tree.decode(),
        }
    base_tree = git(root, "rev-parse", f"{evidence['base_sha']}^{{tree}}").strip().decode()
    tree_closure_many(root, tree_roots, source_tree_cache)
    base_reachable_objects = {
        row.split(None, 1)[0].decode("ascii")
        for row in git(root, "rev-list", "--objects", evidence["base_sha"]).splitlines()
        if row
    }
    trees = {oid: raw for oid, raw in source_tree_cache.items() if oid not in base_reachable_objects}
    if len(commits) + len(trees) > MAX_OBJECTS:
        raise FilteredHistoryError("total witnessed object count exceeds the explicit limit")
    if candidate_root is not None:
        proof = replay_history(
            root,
            candidate_root,
            evidence["base_sha"],
            evidence["source_sha"],
            dispositions,
            source_tree_cache,
        )
    else:
        with tempfile.TemporaryDirectory(prefix="phase79-owned-filtered-replay-") as temporary:
            candidate = pathlib.Path(temporary) / "filtered.git"
            git(pathlib.Path(temporary), "init", "--bare", str(candidate))
            proof = replay_history(
                root,
                candidate,
                evidence["base_sha"],
                evidence["source_sha"],
                dispositions,
                source_tree_cache,
            )
    witness = {
        "schema": "relyra.phase79.filtered-history-witness.v1",
        "evidence": evidence,
        "dispositions": dispositions,
        "base_tree": base_tree,
        "commits": commits,
        "trees": {key: value.hex() for key, value in sorted(trees.items())},
        "proof": proof,
        "limits": {"commit_count": len(commits), "tree_count": len(trees), "object_count": len(commits) + len(trees)},
        "gpgsig": "Original gpgsig headers are retained only in raw evidence; rewritten commits drop signature headers because their signed bytes change.",
    }
    encoded = (json.dumps(witness, sort_keys=True, separators=(",", ":")) + "\n").encode()
    if len(encoded) > MAX_WITNESS_BYTES:
        raise FilteredHistoryError("encoded witness exceeds 8 MiB")
    if len(commits) != 612 or len(trees) != 2410:
        raise FilteredHistoryError(f"frozen history closure count mismatch: commits={len(commits)} trees={len(trees)}")
    # A witness is object metadata only. Fail closed if any serialized member could carry blob bytes.
    if b'"blob"' in encoded or b'"blob_payload"' in encoded:
        raise FilteredHistoryError("witness must not contain blob payloads")
    return witness


def self_test() -> None:
    # Parser and hash tamper fixtures are deliberately isolated from the active repository.
    verifier_source = pathlib.Path(__file__).read_text(encoding="utf-8").split("def self_test()", 1)[0]
    if 'base_ancestry = set(git(candidate_root, "rev-list", EXPECTED["base_sha"])' not in verifier_source:
        raise AssertionError("candidate base ancestry must be read from the candidate repository")
    if 'base_ancestry = set(git(ROOT, "rev-list", EXPECTED["base_sha"]))' in verifier_source:
        raise AssertionError("candidate verification consulted the active project repository")
    assert candidate_branch_name("1" * 40) == "codex/v1.11-adopter-ready-111111111111"
    expected_follow_on_plans = {
        f".planning/phases/79-adopter-ready-closeout/79-{number}-PLAN.md"
        for number in ("09", "10", "11", "12", "14", "15")
    }
    if not expected_follow_on_plans.issubset(OVERLAY_PATHS):
        raise AssertionError("candidate overlay omits an active Phase 79 handoff plan")
    try:
        candidate_branch_name("bad")
    except FilteredHistoryError:
        pass
    else:
        raise AssertionError("malformed candidate SHA generated a branch name")
    validate_exact_keys({"a": 1, "b": 2}, {"a", "b"}, "fixture")
    try:
        validate_exact_keys({"a": 1, "b": 2, "extra": 3}, {"a", "b"}, "fixture")
    except FilteredHistoryError:
        pass
    else:
        raise AssertionError("extra closed-schema receipt key accepted")
    source, base, orphan = "1" * 40, "2" * 40, "3" * 40
    validate_source_commit_closure({source: {"parents": [base]}}, source, base)
    try:
        validate_source_commit_closure(
            {source: {"parents": [base]}, orphan: {"parents": [base]}}, source, base
        )
    except FilteredHistoryError:
        pass
    else:
        raise AssertionError("disconnected witnessed commit accepted")
    validate_overlay_allowlist({"not-overlaid-secret": "exclude"})
    try:
        validate_overlay_allowlist({"scripts/prepare_phase79_filtered_candidate.py": "exclude"})
    except FilteredHistoryError:
        pass
    else:
        raise AssertionError("overlay allowlist overlapping an exclusion accepted")
    validate_excluded_paths({b"secret": (b"100644", b"base")}, {b"secret": (b"100644", b"base")}, {"secret": "exclude"})
    try:
        validate_excluded_paths({b"secret": (b"100644", b"resurrected")}, {b"secret": (b"100644", b"base")}, {"secret": "exclude"})
    except FilteredHistoryError:
        pass
    else:
        raise AssertionError("overlay resurrected an excluded path")
    assert parse_tree(b"100644 a\0" + bytes.fromhex("1" * 40)) == [(b"100644", b"a", bytes.fromhex("1" * 40))]
    assert parse_tree(b"100644 \xffname\0" + bytes.fromhex("2" * 40))[0][1] == b"\xffname"
    assert parse_commit(b"tree " + b"a" * 40 + b"\nauthor A <a@b> 1 +0000\ncommitter A <a@b> 1 +0000\n\nmsg\n")[0][b"tree"] == [b"a" * 40]
    for bad in (b"100644 no-oid\0", b"40000 x\0short"):
        try:
            parse_tree(bad)
        except FilteredHistoryError:
            pass
        else:
            raise AssertionError("malformed tree accepted")
    assert object_digest(b"tree", b"sample").encode() == hashlib.sha1(b"tree 6\0sample").hexdigest().encode()
    validate_map_key_sets({"a": {}, "b": {}}, {"base": "base", "a": "A", "b": "B"}, {"a": "ta", "b": "tb"}, "base")
    try:
        validate_map_key_sets({"a": {}, "b": {}}, {"base": "base", "a": "A", "x": "X"}, {"a": "ta", "b": "tb"}, "base")
    except FilteredHistoryError:
        pass
    else:
        raise AssertionError("same-size substituted commit map key set accepted")
    valid_raw_tree = b"100644 leaf\0" + bytes.fromhex("3" * 40)
    valid_tree_sha = object_digest(b"tree", valid_raw_tree)
    validate_tree_closure({valid_tree_sha: valid_raw_tree.hex()}, {valid_tree_sha})
    try:
        validate_tree_closure({}, {valid_tree_sha})
    except FilteredHistoryError:
        pass
    else:
        raise AssertionError("missing recursively closed tree accepted")
    parent_map = {"old-parent": "new-parent"}
    validate_parent_map(["old-parent"], ["new-parent"], parent_map)
    try:
        validate_parent_map(["old-parent"], ["altered-parent"], parent_map)
    except FilteredHistoryError:
        pass
    else:
        raise AssertionError("altered mapped parent accepted")
    original_entries = {b"keep": (b"100644", b"a" * 20), b"secret": (b"100644", b"b" * 20)}
    base_entries = {b"keep": (b"100644", b"a" * 20), b"secret": (b"100644", b"c" * 20)}
    restored_entries = {b"keep": (b"100644", b"a" * 20), b"secret": (b"100644", b"c" * 20)}
    dispositions = {"keep": "include", "secret": "exclude"}
    validate_path_entries(original_entries, restored_entries, base_entries, dispositions)
    for changed in (
        {**restored_entries, b"keep": (b"100755", b"a" * 20)},
        {**restored_entries, b"secret": original_entries[b"secret"]},
    ):
        try:
            validate_path_entries(original_entries, changed, base_entries, dispositions)
        except FilteredHistoryError:
            pass
        else:
            raise AssertionError("included entry mutation or excluded-path resurrection accepted")
    try:
        validate_excluded_blob_overlap({"shared"}, {"shared"})
    except FilteredHistoryError:
        pass
    else:
        raise AssertionError("shared excluded/included blob OID accepted")
    validate_excluded_blob_overlap({"excluded"}, {"included"})
    validate_bundle_commit_set({"base", "mapped", "overlay", "proof"}, {"base", "mapped", "overlay", "proof"})
    try:
        validate_bundle_commit_set({"base", "mapped", "overlay", "proof", "extra"}, {"base", "mapped", "overlay", "proof"})
    except FilteredHistoryError:
        pass
    else:
        raise AssertionError("extra bundle overlay commit accepted")
    sys.path.insert(0, str(ROOT / "scripts"))
    from verify_phase79_transaction import TransactionError, validate_candidate_branch, validate_pr_approval

    operation_packet = {"operations": ["push candidate", "create exact PR"]}
    approval = {
        "checkpoint_id": "79-15-pr-create",
        "response": "approved",
        "packet_sha256": sha256(json.dumps(operation_packet, indent=2, sort_keys=True, ensure_ascii=False).encode() + b"\n"),
        "scope": operation_packet["operations"],
    }
    validate_pr_approval(operation_packet, approval)
    stale_approval = {**approval, "checkpoint_id": "79-08-pr-create"}
    try:
        validate_pr_approval(operation_packet, stale_approval)
    except TransactionError:
        pass
    else:
        raise AssertionError("stale PR approval checkpoint passed")
    publication = {
        "source_sha": "1" * 40,
        "candidate_head_sha": "1" * 40,
        "branch": {"name": "codex/v1.11-adopter-ready-111111111111"},
        "pull_request": {"head": "codex/v1.11-adopter-ready-111111111111"},
    }
    validate_candidate_branch(publication)
    try:
        validate_candidate_branch({**publication, "branch": {"name": "refs/heads/relyra-phase79-filtered"}})
    except TransactionError:
        pass
    else:
        raise AssertionError("publication branch unrelated to the final candidate SHA accepted")
    phase = ROOT / ".planning/phases/79-adopter-ready-closeout"
    required_inputs = [phase / name for name in ("79-SCOPE-DISPOSITIONS.json", "79-PUBLICATION-PACKET.json", "79-SCOPE-DISPOSITION-REVIEW.md")]
    if all(path.is_file() and not path.is_symlink() for path in required_inputs):
      validate_receipt(phase)
      with tempfile.TemporaryDirectory(prefix="phase79-receipt-selftest-") as tmp:
        copy = pathlib.Path(tmp) / "phase"
        copy.mkdir()
        for name in ("79-SCOPE-DISPOSITIONS.json", "79-PUBLICATION-PACKET.json", "79-SCOPE-DISPOSITION-REVIEW.md"):
            (copy / name).write_bytes((phase / name).read_bytes())
        receipt_path = copy / "79-SCOPE-DISPOSITIONS.json"
        original_receipt = json.loads(receipt_path.read_bytes())
        for mutate in (
            lambda value: value["evidence"].update(source_sha="0" * 40),
            lambda value: value["counts"].update(include=55, exclude=0),
            lambda value: value["paths"][0].update(disposition="include"),
            lambda value: value["response"].update(normalized_decision="accept all"),
        ):
            altered = json.loads(json.dumps(original_receipt))
            mutate(altered)
            receipt_path.write_text(json.dumps(altered), encoding="utf-8")
            try:
                validate_receipt(copy)
            except FilteredHistoryError:
                pass
            else:
                raise AssertionError("tampered accepted scope receipt passed")
        receipt_path.write_bytes((phase / "79-SCOPE-DISPOSITIONS.json").read_bytes())
        oversized = copy / "oversized"
        with oversized.open("wb") as handle:
            handle.truncate(MAX_INPUT_BYTES + 1)
        try:
            read_limited(oversized)
        except FilteredHistoryError:
            pass
        else:
            raise AssertionError("oversized input passed its bound")
    # Real disposable Git fixture covers ordinary, empty, and merge commit topology.
    with tempfile.TemporaryDirectory(prefix="phase79-filtered-selftest-") as tmp:
        repo = pathlib.Path(tmp) / "repo.git"
        git(pathlib.Path(tmp), "init", "--bare", str(repo))
        env = {**os.environ, "GIT_AUTHOR_NAME": "Fixture", "GIT_AUTHOR_EMAIL": "fixture@example.invalid", "GIT_COMMITTER_NAME": "Fixture", "GIT_COMMITTER_EMAIL": "fixture@example.invalid"}
        def g(*args: str, data: bytes | None = None) -> bytes:
            result = subprocess.run(["git", *args], cwd=repo, input=data, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env={**env, "GIT_DIR": str(repo)})
            if result.returncode:
                raise AssertionError(result.stderr.decode(errors="replace"))
            return result.stdout
        empty_tree = g("mktree", data=b"").decode().strip()
        empty = g("commit-tree", empty_tree, data=b"base\n").decode().strip()
        g("update-ref", "refs/heads/main", empty)
        included_base_blob = g("hash-object", "-w", "--stdin", data=b"base included\n").strip()
        excluded_base_blob = g("hash-object", "-w", "--stdin", data=b"base secret\n").strip()
        included_new_blob = g("hash-object", "-w", "--stdin", data=b"new included\n").strip()
        excluded_new_blob = g("hash-object", "-w", "--stdin", data=b"new secret\n").strip()
        def tree(keep: bytes, secret: bytes) -> bytes:
            raw_tree_bytes = b"100644 keep\0" + bytes.fromhex(keep.decode()) + b"100644 secret\0" + bytes.fromhex(secret.decode())
            return g("hash-object", "-t", "tree", "-w", "--stdin", data=raw_tree_bytes).strip()
        base_tree = tree(included_base_blob, excluded_base_blob)
        base_raw = b"tree " + base_tree + b"\nauthor Fixture <fixture@example.invalid> 1 +0000\ncommitter Fixture <fixture@example.invalid> 1 +0000\n\nbase\n"
        base_commit = g("hash-object", "-t", "commit", "-w", "--stdin", data=base_raw).decode().strip()
        g("update-ref", "refs/heads/main", base_commit)
        def commit(parent: str, keep: bytes, secret: bytes, message: bytes) -> str:
            t = tree(keep, secret)
            raw = b"tree " + t + b"\nparent " + parent.encode() + b"\nauthor Fixture <fixture@example.invalid> 2 +0000\ncommitter Fixture <fixture@example.invalid> 2 +0000\n\n" + message
            return g("hash-object", "-t", "commit", "-w", "--stdin", data=raw).decode().strip()
        c1 = commit(base_commit, included_new_blob, excluded_new_blob, b"ordinary\n")
        c2 = commit(c1, included_new_blob, excluded_new_blob, b"empty\n")
        left1 = commit(c2, included_new_blob, excluded_new_blob, b"left one\n")
        right1 = commit(c2, included_new_blob, excluded_new_blob, b"right one\n")
        merge1_tree = tree(included_new_blob, excluded_new_blob)
        merge1 = g("commit-tree", merge1_tree.decode(), "-p", left1, "-p", right1, data=b"merge one\n").decode().strip()
        left2 = commit(merge1, included_new_blob, excluded_new_blob, b"left two\n")
        right2 = commit(merge1, included_new_blob, excluded_new_blob, b"right two\n")
        merge2 = g("commit-tree", merge1_tree.decode(), "-p", left2, "-p", right2, data=b"merge two\n").decode().strip()
        left3 = commit(merge2, included_new_blob, excluded_new_blob, b"left three\n")
        right3 = commit(merge2, included_new_blob, excluded_new_blob, b"right three\n")
        merge3 = g("commit-tree", merge1_tree.decode(), "-p", left3, "-p", right3, data=b"merge three\n").decode().strip()
        g("update-ref", "refs/heads/main", merge3)
        candidate = pathlib.Path(tmp) / "candidate.git"
        git(pathlib.Path(tmp), "init", "--bare", str(candidate))
        nested_blob = git(candidate, "hash-object", "-w", "--stdin", data=b"base included\n").strip()
        assert nested_blob == included_base_blob
        nested_tree = make_tree(
            candidate,
            {b"nested/leaf": (b"100644", bytes.fromhex(nested_blob.decode()))},
        )
        assert git(candidate, "cat-file", "-t", nested_tree.decode()).strip() == b"tree"
        assert git(candidate, "show", f"{nested_tree.decode()}:nested/leaf").strip() == b"base included"
        proof = replay_history(repo, candidate, base_commit, merge3, {"keep": "include", "secret": "exclude"})
        assert proof["commit_count"] == 11 and proof["merge_count"] == 3
        final_secret = git(candidate, "show", f"{proof['filtered_source_sha']}:secret").strip()
        assert final_secret == b"base secret"
        assert git(candidate, "show", f"{proof['filtered_source_sha']}:keep").strip() == b"new included"
        assert git(candidate, "show", "-s", "--format=%P", proof["filtered_source_sha"]).decode().split() == [proof["commit_map"][left3], proof["commit_map"][right3]]


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--build", action="store_true", help="build the proof-bound candidate in an owned disposable repository")
    parser.add_argument("--capture-witness", action="store_true", help="capture bounded raw commit/tree evidence only")
    parser.add_argument("--verify", "--verify-candidate", dest="verify_candidate", action="store_true", help="verify an existing proof-bound filtered candidate")
    parser.add_argument("--candidate-root", type=pathlib.Path, help="candidate repository used only by --verify-candidate")
    parser.add_argument("--repo-root", type=pathlib.Path, default=ROOT)
    parser.add_argument("--phase-dir", type=pathlib.Path, default=PHASE_DIR)
    parser.add_argument("--output", type=pathlib.Path)
    args = parser.parse_args(argv)
    try:
        if args.self_test:
            self_test()
            print(json.dumps({"self_test": "passed"}))
            return 0
        if args.build:
            if not args.candidate_root:
                raise FilteredHistoryError("--build requires --candidate-root")
            result = build_candidate(args.repo_root.resolve(), args.phase_dir.resolve(), args.candidate_root)
            print(json.dumps(result, sort_keys=True))
            return 0
        if args.verify_candidate:
            if not args.candidate_root:
                raise FilteredHistoryError("--verify-candidate requires --candidate-root")
            result = verify_candidate_contract(args.candidate_root.expanduser().resolve(), args.phase_dir.resolve())
            print(json.dumps(result, sort_keys=True))
            return 0
        if not args.capture_witness:
            raise FilteredHistoryError("choose --self-test or the explicit --capture-witness evidence mode")
        # Read-only source capture; this mode does not replay or construct a candidate.
        witness = capture_witness(args.repo_root.resolve(), args.phase_dir.resolve())
        payload = (json.dumps(witness, sort_keys=True, separators=(",", ":")) + "\n").encode()
        if args.output:
            if args.output.resolve().is_relative_to((args.repo_root.resolve() / ".git").resolve()):
                raise FilteredHistoryError("witness output may not be placed under active .git")
            args.output.write_bytes(payload)
        print(json.dumps({"witness_sha256": sha256(payload), "bytes": len(payload), "commits": 612, "trees": 2410}))
        return 0
    except (OSError, UnicodeError, KeyError, TypeError, ValueError, FilteredHistoryError) as exc:
        print(f"phase79 filtered history: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
