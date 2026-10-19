#!/usr/bin/env python3
"""Capture exact, read-only Phase 79 branch-protection evidence."""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import os
import pathlib
import re
import subprocess
import sys
import tempfile


SCHEMA = "phase79-protection-capture"
VERSION = 1
REPOSITORY = "szTheory/relyra"
REF = "refs/heads/main"
API_VERSION = "2026-03-10"
MAX_BYTES = 1024 * 1024
MAX_ACTORS = 100
SHA_RE = re.compile(r"^[0-9a-f]{40}$")
PARENT_SETTINGS = {
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
PARENT_METADATA = {
    "url", "html_url", "protection_url", "node_id", "created_at", "updated_at",
}
BOOL_SETTINGS = {
    "enforce_admins": "enforce_admins",
    "required_signatures": "required_signatures",
    "required_linear_history": "required_linear_history",
    "allow_force_pushes": "allow_force_pushes",
    "allow_deletions": "allow_deletions",
    "block_creations": "block_creations",
    "required_conversation_resolution": "required_conversation_resolution",
    "lock_branch": "lock_branch",
    "allow_fork_syncing": "allow_fork_syncing",
}
REST_ACTOR_TYPES = {"users": "login", "teams": "slug", "apps": "slug"}
GRAPHQL_QUERY = """
query Phase79ProtectionCapture {
  repository(owner: "szTheory", name: "relyra") {
    ref(qualifiedName: "refs/heads/main") {
      name
      target { oid }
      branchProtectionRule {
        id
        pattern
        requiredApprovingReviewCount
        requiresApprovingReviews
        dismissesStaleReviews
        requiresCodeOwnerReviews
        requireLastPushApproval
        restrictsReviewDismissals
        reviewDismissalAllowances(first: 100) {
          totalCount pageInfo { hasNextPage endCursor }
          nodes { actor { __typename ... on User { login } ... on Team { slug } ... on App { slug } } }
        }
        restrictsPushes
        pushAllowances(first: 100) {
          totalCount pageInfo { hasNextPage endCursor }
          nodes { actor { __typename ... on User { login } ... on Team { slug } ... on App { slug } } }
        }
        bypassPullRequestAllowances(first: 100) {
          totalCount pageInfo { hasNextPage endCursor }
          nodes { actor { __typename ... on User { login } ... on Team { slug } ... on App { slug } } }
        }
        bypassForcePushAllowances(first: 100) {
          totalCount pageInfo { hasNextPage endCursor }
          nodes { actor { __typename ... on User { login } ... on Team { slug } ... on App { slug } } }
        }
      }
    }
  }
}
""".strip()


class CaptureError(Exception):
    pass


def utc_now() -> str:
    return dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def canonical_bytes(value: object) -> bytes:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode("utf-8")


def digest(value: object) -> str:
    return hashlib.sha256(canonical_bytes(value)).hexdigest()


def split_http(value: str) -> tuple[dict[str, str], str]:
    headers: dict[str, str] = {}
    body: list[str] = []
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
                key, item = line.split(":", 1)
                headers[key.strip().lower()] = item.strip()
        else:
            body.append(line)
    return headers, "\n".join(body)


def run_gh(args: list[str]) -> tuple[int, object, bool]:
    try:
        result = subprocess.run(
            args, check=False, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            text=True, timeout=45,
        )
    except (OSError, subprocess.TimeoutExpired):
        return 0, None, False
    if len(result.stdout.encode("utf-8", errors="replace")) > MAX_BYTES:
        return 598, None, False
    if "--include" in args:
        headers, raw_body = split_http(result.stdout)
        try:
            status = int(headers.get(":status", "0"))
        except ValueError:
            status = 0
        if not raw_body.strip():
            return status, None, False
        try:
            body = json.loads(raw_body)
        except json.JSONDecodeError:
            return 598, None, False
        return status or (200 if result.returncode == 0 else 0), body, 'rel="next"' in headers.get("link", "").lower()
    if result.returncode != 0:
        return 0, None, False
    try:
        body = json.loads(result.stdout)
    except json.JSONDecodeError:
        return 598, None, False
    return 200, body, False


def fixture_response(fixture: dict, family: str, key: str) -> tuple[int, object, bool]:
    table = fixture.get(family)
    if not isinstance(table, dict) or key not in table:
        return 0, None, False
    entry = table[key]
    sequence = entry.get("responses") if isinstance(entry, dict) else None
    if isinstance(sequence, list):
        counters = fixture.setdefault("_call_counts", {})
        counter_key = f"{family}:{key}"
        index = counters.get(counter_key, 0)
        counters[counter_key] = index + 1
        entry = sequence[index] if index < len(sequence) else None
    if not isinstance(entry, dict):
        return 0, None, False
    return int(entry.get("status", 200)), entry.get("body"), bool(entry.get("next", False))


def rest_get(endpoint: str, fixture: dict | None, *, key: str | None = None) -> tuple[int, object, bool]:
    if fixture is not None:
        return fixture_response(fixture, "rest", key or endpoint)
    url = f"repos/{REPOSITORY}/{endpoint}"
    args = ["gh", "api", "--include", "--method", "GET", "-H", f"X-GitHub-Api-Version: {API_VERSION}", url]
    return run_gh(args)


def read_graphql(fixture: dict | None) -> tuple[int, object, bool]:
    if fixture is not None:
        return fixture_response(fixture, "graphql", "protection")
    return run_gh([
        "gh", "api", "graphql", "-H", f"X-GitHub-Api-Version: {API_VERSION}",
        "-f", f"query={GRAPHQL_QUERY}",
    ])


def read_check_runs(sha: str | None, fixture: dict | None) -> tuple[int, list[dict], list[dict]]:
    if not isinstance(sha, str) or not SHA_RE.fullmatch(sha):
        return 0, [], []
    rows: list[dict] = []
    pages: list[dict] = []
    for page in range(1, 51):
        key = f"commits/{sha}/check-runs?page={page}"
        if fixture is not None:
            status, body, has_next = fixture_response(fixture, "rest", key)
        else:
            status, body, has_next = rest_get(
                f"commits/{sha}/check-runs?per_page=100&page={page}", fixture,
            )
        if status != 200 or not isinstance(body, dict) or not isinstance(body.get("check_runs"), list):
            pages.append({"number": page, "status": status, "item_count": 0, "continuation": False})
            return status, [], pages
        batch = body["check_runs"]
        if len(rows) + len(batch) > 5000:
            return 598, [], pages
        rows.extend(batch)
        pages.append({"number": page, "status": status, "item_count": len(batch), "continuation": has_next})
        if not has_next:
            return 200, rows, pages
    return 598, [], pages


def field(body: object, key: str, expected: type | tuple[type, ...]) -> object:
    if not isinstance(body, dict) or key not in body or not isinstance(body[key], expected):
        raise CaptureError(f"missing or invalid {key}")
    return body[key]


def enabled(body: object, key: str) -> bool:
    value = field(body, key, dict)
    return field(value, "enabled", bool)


def checked_actor_connection(value: object, name: str) -> dict[str, list[str]]:
    if not isinstance(value, dict):
        raise CaptureError(f"missing GraphQL {name} connection")
    nodes = field(value, "nodes", list)
    total = field(value, "totalCount", int)
    page_info = field(value, "pageInfo", dict)
    if page_info.get("hasNextPage") is not False or total != len(nodes) or total > MAX_ACTORS:
        raise CaptureError(f"GraphQL {name} connection is incomplete or oversized")
    actors: dict[str, list[str]] = {key: [] for key in REST_ACTOR_TYPES}
    for node in nodes:
        actor = node.get("actor") if isinstance(node, dict) else None
        if not isinstance(actor, dict):
            raise CaptureError(f"GraphQL {name} actor is missing")
        actor_type = actor.get("__typename")
        if actor_type == "User":
            collection, key = "users", "login"
        elif actor_type == "Team":
            collection, key = "teams", "slug"
        elif actor_type == "App":
            collection, key = "apps", "slug"
        else:
            raise CaptureError(f"GraphQL {name} has an unknown actor type")
        identity = actor.get(key)
        if not isinstance(identity, str) or not identity.strip():
            raise CaptureError(f"GraphQL {name} actor identity is missing")
        actors[collection].append(identity)
    for values in actors.values():
        if len(values) != len(set(values)):
            raise CaptureError(f"GraphQL {name} contains duplicate actors")
        values.sort()
    return actors


def checked_rest_actors(value: object, name: str) -> dict[str, list[str]]:
    if not isinstance(value, dict):
        raise CaptureError(f"missing REST {name} actors")
    result: dict[str, list[str]] = {}
    if set(value) - set(REST_ACTOR_TYPES) - {"url", "users_url", "teams_url", "apps_url"}:
        raise CaptureError(f"REST {name} contains unknown fields")
    for collection, identity_key in REST_ACTOR_TYPES.items():
        rows = field(value, collection, list)
        if len(rows) > MAX_ACTORS:
            raise CaptureError(f"REST {name} is oversized")
        names: list[str] = []
        for row in rows:
            if not isinstance(row, dict):
                raise CaptureError(f"REST {name} contains an invalid actor")
            identity = row.get(identity_key)
            if not isinstance(identity, str) or not identity.strip():
                raise CaptureError(f"REST {name} actor identity is missing")
            names.append(identity)
        if len(names) != len(set(names)):
            raise CaptureError(f"REST {name} contains duplicate actors")
        result[collection] = sorted(names)
    return result


def normalized_checks(parent: dict) -> dict:
    value = field(parent, "required_status_checks", dict)
    allowed = {"strict", "contexts", "checks", "url", "contexts_url"}
    if set(value) - allowed:
        raise CaptureError("required_status_checks contains unknown fields")
    strict = field(value, "strict", bool)
    contexts = field(value, "contexts", list)
    checks = field(value, "checks", list)
    if len(contexts) > 100 or len(checks) > 100:
        raise CaptureError("required status checks are oversized")
    if any(not isinstance(item, str) or not item for item in contexts) or len(contexts) != len(set(contexts)):
        raise CaptureError("required status check contexts are invalid")
    normalized: list[dict] = []
    for item in checks:
        if not isinstance(item, dict) or set(item) != {"context", "app_id"}:
            raise CaptureError("required status check association is incomplete or unknown")
        context, app_id = item["context"], item["app_id"]
        if not isinstance(context, str) or not context or (app_id is not None and (not isinstance(app_id, int) or isinstance(app_id, bool) or app_id < -1)):
            raise CaptureError("required status check association is invalid")
        normalized.append({"context": context, "app_id": app_id})
    if len({item["context"] for item in normalized}) != len(normalized):
        raise CaptureError("required status check associations contain duplicate contexts")
    if sorted(contexts) != sorted(item["context"] for item in normalized):
        raise CaptureError("required status contexts and app associations differ")
    return {"strict": strict, "contexts": sorted(contexts), "checks": sorted(normalized, key=lambda row: row["context"])}


def check_review_agreement(review: dict, rule: dict, graphql_actors: dict[str, dict]) -> tuple[dict, list[str]]:
    errors: list[str] = []
    allowed = {
        "url", "dismiss_stale_reviews", "require_code_owner_reviews", "require_last_push_approval",
        "required_approving_review_count", "dismissal_restrictions", "bypass_pull_request_allowances",
    }
    if set(review) - allowed:
        return {}, ["review subresource contains unknown fields"]
    rest_values: dict[str, object] = {}
    for key in ("dismiss_stale_reviews", "require_code_owner_reviews", "require_last_push_approval"):
        value = review.get(key)
        if not isinstance(value, bool):
            errors.append(f"review subresource is missing {key}")
        else:
            rest_values[key] = value
    rest_count = review.get("required_approving_review_count")
    if not isinstance(rest_count, int) or isinstance(rest_count, bool) or not 0 <= rest_count <= 6:
        errors.append("review subresource has an invalid required approval count")
    rule_count = rule.get("requiredApprovingReviewCount")
    rule_requires = rule.get("requiresApprovingReviews")
    if rule_requires not in (True, False) or (rule_count is not None and (not isinstance(rule_count, int) or isinstance(rule_count, bool) or not 0 <= rule_count <= 6)):
        errors.append("GraphQL approval requirement is invalid")
    elif rule_requires is True and (not isinstance(rule_count, int) or rule_count < 1):
        errors.append("GraphQL approval requirement is internally inconsistent")
    elif rule_requires is False and rule_count not in (None, 0):
        errors.append("GraphQL approval requirement is internally inconsistent")
    elif isinstance(rest_count, int) and rest_count != (rule_count or 0):
        errors.append("GraphQL approval settings conflict with the REST review subresource")
    mapping = {
        "dismiss_stale_reviews": "dismissesStaleReviews",
        "require_code_owner_reviews": "requiresCodeOwnerReviews",
        "require_last_push_approval": "requireLastPushApproval",
    }
    for rest_key, graph_key in mapping.items():
        if not isinstance(rest_values.get(rest_key), bool) or rule.get(graph_key) is not rest_values.get(rest_key):
            errors.append(f"GraphQL {graph_key} conflicts with the REST review subresource")

    dismissal = graphql_actors["reviewDismissalAllowances"]
    bypass = graphql_actors["bypassPullRequestAllowances"]
    if rule.get("restrictsReviewDismissals") not in (True, False):
        errors.append("GraphQL review-dismissal setting is missing")
    if "dismissal_restrictions" in review:
        try:
            if checked_rest_actors(review["dismissal_restrictions"], "review-dismissal") != dismissal:
                errors.append("GraphQL review-dismissal allowances conflict with the REST review subresource")
        except CaptureError as exc:
            errors.append(str(exc))
    if "bypass_pull_request_allowances" in review:
        try:
            if checked_rest_actors(review["bypass_pull_request_allowances"], "PR-bypass") != bypass:
                errors.append("GraphQL PR-bypass allowances conflict with the REST review subresource")
        except CaptureError as exc:
            errors.append(str(exc))
    if "dismissal_restrictions" not in review and rule.get("restrictsReviewDismissals") and not any(dismissal.values()):
        # Enabled with zero listed actors is a valid policy; the GraphQL flag is explicit.
        pass

    if errors:
        return {}, errors
    review_payload = {
        "dismissal_restrictions": dismissal,
        "bypass_pull_request_allowances": bypass,
        "dismiss_stale_reviews": rest_values["dismiss_stale_reviews"],
        "require_code_owner_reviews": rest_values["require_code_owner_reviews"],
        "required_approving_review_count": rest_count,
        "require_last_push_approval": rest_values["require_last_push_approval"],
    }
    return review_payload, []


def read_graphql_sources(body: object) -> tuple[dict, dict, list[str]]:
    errors: list[str] = []
    if not isinstance(body, dict) or body.get("errors") or not isinstance(body.get("data"), dict):
        return {}, {}, ["GraphQL branch protection read failed"]
    repository = body["data"].get("repository")
    ref = repository.get("ref") if isinstance(repository, dict) else None
    if not isinstance(ref, dict) or ref.get("name") != "main":
        return {}, {}, ["GraphQL ref does not identify main"]
    target = ref.get("target")
    sha = target.get("oid") if isinstance(target, dict) else None
    rule = ref.get("branchProtectionRule")
    if not isinstance(rule, dict) or rule.get("pattern") != "main":
        return {"sha": sha, "name": ref.get("name")}, {}, ["GraphQL branch protection rule is missing or does not match main"]
    try:
        actors = {
            "reviewDismissalAllowances": checked_actor_connection(rule.get("reviewDismissalAllowances"), "review-dismissal"),
            "pushAllowances": checked_actor_connection(rule.get("pushAllowances"), "push"),
            "bypassPullRequestAllowances": checked_actor_connection(rule.get("bypassPullRequestAllowances"), "PR-bypass"),
            "bypassForcePushAllowances": checked_actor_connection(rule.get("bypassForcePushAllowances"), "force-push-bypass"),
        }
    except CaptureError as exc:
        return {"sha": sha, "name": ref.get("name"), "pattern": rule.get("pattern")}, {}, [str(exc)]
    safe_rule = {
        "id": rule.get("id"),
        "pattern": rule.get("pattern"),
        "requiredApprovingReviewCount": rule.get("requiredApprovingReviewCount"),
        "requiresApprovingReviews": rule.get("requiresApprovingReviews"),
        "dismissesStaleReviews": rule.get("dismissesStaleReviews"),
        "requiresCodeOwnerReviews": rule.get("requiresCodeOwnerReviews"),
        "requireLastPushApproval": rule.get("requireLastPushApproval"),
        "restrictsReviewDismissals": rule.get("restrictsReviewDismissals"),
        "restrictsPushes": rule.get("restrictsPushes"),
        "actor_counts": {name: sum(len(values) for values in groups.values()) for name, groups in actors.items()},
    }
    return {"sha": sha, "name": ref.get("name")}, {"rule": safe_rule, "actors": actors}, errors


def protect_summary(parent: object) -> tuple[dict, list[str]]:
    errors: list[str] = []
    if not isinstance(parent, dict):
        return {}, ["parent protection response is not an object"]
    unknown = set(parent) - PARENT_SETTINGS - PARENT_METADATA
    if unknown:
        errors.append("parent protection response contains unknown settings: " + ", ".join(sorted(unknown)))
    required = PARENT_SETTINGS - {"required_pull_request_reviews", "restrictions"}
    missing = required - set(parent)
    if missing:
        errors.append("parent protection response is missing settings: " + ", ".join(sorted(missing)))
    normalized: dict = {}
    try:
        normalized["required_status_checks"] = normalized_checks(parent)
    except CaptureError as exc:
        errors.append(str(exc))
    for field_name in BOOL_SETTINGS:
        if field_name not in parent:
            continue
        try:
            normalized[field_name] = enabled(parent, field_name)
        except CaptureError:
            errors.append(f"parent protection setting {field_name} is invalid")
    return normalized, errors


def source_record(status: int, body: object, next_page: bool = False) -> dict:
    return {"status": status, "body": body, "continuation": next_page}


def rest_ref(sha: str | None, body: object, status: int) -> dict:
    return {"status": status, "sha": sha}


def capture_sources(fixture: dict | None) -> tuple[dict, list[str]]:
    errors: list[str] = []
    ref_first_status, ref_first_body, _ = rest_get("git/ref/heads/main", fixture, key="main-ref")
    first_sha = None
    if ref_first_status == 200 and isinstance(ref_first_body, dict):
        obj = ref_first_body.get("object")
        candidate = obj.get("sha") if isinstance(obj, dict) else None
        if isinstance(candidate, str) and SHA_RE.fullmatch(candidate):
            first_sha = candidate
        else:
            errors.append("initial main ref SHA is missing or invalid")
    else:
        errors.append("initial main ref read failed")

    parent_status, parent_body, _ = rest_get("branches/main/protection", fixture)
    review_status, review_body, _ = rest_get("branches/main/protection/required_pull_request_reviews", fixture)
    restriction_status, restriction_body, _ = rest_get("branches/main/protection/restrictions", fixture)
    graphql_status, graphql_body, _ = read_graphql(fixture)
    graph_ref, graph_data, graph_errors = read_graphql_sources(graphql_body if graphql_status == 200 else None)
    errors.extend(graph_errors)
    if graphql_status != 200:
        errors.append("GraphQL branch protection read failed")
    check_status, check_rows, check_pages = read_check_runs(first_sha, fixture)
    fleet_rows = [
        row for row in check_rows
        if isinstance(row, dict) and row.get("name") == "fleet-proxy-e2e" and row.get("head_sha") == first_sha
    ]
    app_ids: set[int] = set()
    for row in fleet_rows:
        app = row.get("app")
        app_id = app.get("id") if isinstance(app, dict) else None
        if isinstance(app_id, int) and not isinstance(app_id, bool) and app_id > 0:
            app_ids.add(app_id)
    if check_status != 200:
        errors.append("current-SHA check-run source is unavailable")
    elif not fleet_rows or len(app_ids) != 1:
        errors.append("fleet-proxy-e2e app association is missing or conflicting on current main")

    ref_second_status, ref_second_body, _ = rest_get("git/ref/heads/main", fixture, key="main-ref")
    second_sha = None
    if ref_second_status == 200 and isinstance(ref_second_body, dict):
        obj = ref_second_body.get("object")
        candidate = obj.get("sha") if isinstance(obj, dict) else None
        if isinstance(candidate, str) and SHA_RE.fullmatch(candidate):
            second_sha = candidate
        else:
            errors.append("final main ref SHA is missing or invalid")
    else:
        errors.append("final main ref read failed")
    if first_sha is not None and second_sha is not None and first_sha != second_sha:
        errors.append("main ref changed during protection capture")
    if first_sha is not None and graph_ref.get("sha") != first_sha:
        errors.append("GraphQL ref SHA differs from the REST main ref")

    parent_fields = sorted(parent_body.keys()) if isinstance(parent_body, dict) else []
    review_fields = sorted(review_body.keys()) if isinstance(review_body, dict) else []
    restriction_message = restriction_body.get("message") if isinstance(restriction_body, dict) else None
    if restriction_status != 200 and not (restriction_status == 404 and restriction_message == "Push restrictions not enabled"):
        errors.append("push restriction subresource did not return a recognized explicit state")
    review_keys = {
        "url", "dismiss_stale_reviews", "require_code_owner_reviews", "require_last_push_approval",
        "required_approving_review_count", "dismissal_restrictions", "bypass_pull_request_allowances",
    }
    safe_review = {key: review_body[key] for key in sorted(review_keys & set(review_body))} if isinstance(review_body, dict) else None
    safe_restrictions = None
    if restriction_status == 200 and isinstance(restriction_body, dict):
        safe_restrictions = {key: restriction_body.get(key) for key in ("users", "teams", "apps")}
    elif restriction_status == 404:
        safe_restrictions = {"message": restriction_message}

    source = {
        "main_ref_before": rest_ref(first_sha, ref_first_body, ref_first_status),
        "parent_protection": {
            "status": parent_status,
            "fields_present": parent_fields,
            "configuration": parent_body if isinstance(parent_body, dict) else None,
        },
        "review_subresource": {"status": review_status, "fields_present": review_fields, "configuration": safe_review},
        "push_restrictions": {"status": restriction_status, "configuration": safe_restrictions},
        "graphql": {
            "status": graphql_status,
            "ref": graph_ref,
            "branch_protection": graph_data,
        },
        "fleet_check_run": {
            "status": check_status,
            "pages": check_pages,
            "matching_count": len(fleet_rows),
            "app_ids": sorted(app_ids),
            "head_sha": first_sha,
        },
        "main_ref_after": rest_ref(second_sha, ref_second_body, ref_second_status),
    }
    return source, errors


def reviews_disabled(parent_body: object, review_source: dict, graph: object) -> bool:
    """True only when the parent omits reviews and GraphQL independently disables them."""
    if not isinstance(parent_body, dict) or "required_pull_request_reviews" in parent_body:
        return False
    rule = graph.get("rule") if isinstance(graph, dict) else None
    actors = graph.get("actors") if isinstance(graph, dict) else None
    if not isinstance(rule, dict) or not isinstance(actors, dict):
        return False
    if rule.get("requiresApprovingReviews") is not False or rule.get("requiredApprovingReviewCount") is not None:
        return False
    if any(rule.get(key) is not False for key in ("requiresCodeOwnerReviews", "requireLastPushApproval", "dismissesStaleReviews")):
        return False
    if any(actors.get("bypassPullRequestAllowances", {}).values()):
        return False
    review = review_source.get("configuration")
    if review_source.get("status") != 200 or not isinstance(review, dict):
        return False
    # The default body never carries enabled review options or actor lists.
    return all(review.get(key) is False for key in ("dismiss_stale_reviews", "require_code_owner_reviews", "require_last_push_approval")) and not (
        {"dismissal_restrictions", "bypass_pull_request_allowances"} & set(review)
    )


def compose_resource(source: dict) -> tuple[dict | None, list[str]]:
    errors: list[str] = []
    parent_source = source.get("parent_protection", {})
    review_source = source.get("review_subresource", {})
    restriction_source = source.get("push_restrictions", {})
    graph = source.get("graphql", {}).get("branch_protection", {})
    graph_ref = source.get("graphql", {}).get("ref", {})
    if parent_source.get("status") != 200:
        errors.append("parent protection GET is not complete")
    parent_body = parent_source.get("configuration")
    parent_config, parent_errors = protect_summary(parent_body)
    errors.extend(parent_errors)
    if reviews_disabled(parent_body, review_source, graph):
        # GitHub keeps answering the review subresource with a default body after
        # reviews are disabled (a DELETE returns 204 and the GET is unchanged), so
        # only the parent omission plus GraphQL agreement establishes the state.
        review_payload = None
    elif review_source.get("status") != 200 or not isinstance(review_source.get("configuration"), dict):
        errors.append("review protection subresource is incomplete")
        review_payload = {}
    else:
        rule = graph.get("rule") if isinstance(graph, dict) else None
        actors = graph.get("actors") if isinstance(graph, dict) else None
        if not isinstance(rule, dict) or not isinstance(actors, dict):
            errors.append("GraphQL branch protection settings are incomplete")
            review_payload = {}
        else:
            review_payload, review_errors = check_review_agreement(
                review_source["configuration"], rule, actors,
            )
            errors.extend(review_errors)

    if not isinstance(graph, dict) or not isinstance(graph.get("rule"), dict):
        errors.append("GraphQL branch protection rule is incomplete")
        rule = {}
        actors = {}
    else:
        rule = graph["rule"]
        actors = graph.get("actors", {})
    if graph_ref.get("name") != "main" or not isinstance(graph_ref.get("sha"), str):
        errors.append("GraphQL target does not identify refs/heads/main")
    if rule.get("pattern") != "main":
        errors.append("GraphQL protection pattern is not exactly main")

    if restriction_source.get("status") == 404:
        if restriction_source.get("configuration") != {"message": "Push restrictions not enabled"}:
            errors.append("push restriction 404 is not the recognized disabled response")
        if rule.get("restrictsPushes") is not False or any(actors.get("pushAllowances", {}).values()):
            errors.append("GraphQL push restriction settings conflict with REST 404")
        restrictions = None
    elif restriction_source.get("status") == 200:
        try:
            restrictions = checked_rest_actors(restriction_source.get("configuration"), "push restriction")
        except CaptureError as exc:
            restrictions = None
            errors.append(str(exc))
        if not isinstance(actors.get("pushAllowances"), dict) or actors.get("pushAllowances") != restrictions:
            errors.append("GraphQL push allowances conflict with the REST restriction subresource")
        if rule.get("restrictsPushes") is not True:
            errors.append("GraphQL does not confirm the REST push restriction resource")
    else:
        restrictions = None
        errors.append("push restriction subresource is incomplete")

    for key in ("reviewDismissalAllowances", "pushAllowances", "bypassPullRequestAllowances", "bypassForcePushAllowances"):
        if key not in actors:
            errors.append(f"GraphQL {key} evidence is missing")
    if rule.get("restrictsReviewDismissals") is False and any(actors.get("reviewDismissalAllowances", {}).values()):
        errors.append("GraphQL review-dismissal flag conflicts with non-empty allowances")

    fleet = source.get("fleet_check_run", {})
    if fleet.get("status") != 200 or fleet.get("head_sha") != source.get("main_ref_before", {}).get("sha"):
        errors.append("fleet check-run evidence is not bound to current main")
    fleet_ids = fleet.get("app_ids")
    if not isinstance(fleet_ids, list) or len(fleet_ids) != 1:
        errors.append("fleet check-run app ID is ambiguous")

    ref_before = source.get("main_ref_before", {}).get("sha")
    ref_after = source.get("main_ref_after", {}).get("sha")
    if not isinstance(ref_before, str) or not SHA_RE.fullmatch(ref_before) or ref_before != ref_after or graph_ref.get("sha") != ref_before:
        errors.append("REST and GraphQL source SHAs do not match")
    if errors:
        return None, list(dict.fromkeys(errors))

    # A non-null REST value in the parent must agree with the supplemental setting reads.
    if isinstance(parent_body, dict):
        if "required_pull_request_reviews" in parent_body:
            top_review = parent_body["required_pull_request_reviews"]
            if top_review is None:
                errors.append("parent protection explicitly disables reviews but the review subresource is enabled")
            elif isinstance(top_review, dict):
                for key in ("dismiss_stale_reviews", "require_code_owner_reviews", "required_approving_review_count", "require_last_push_approval"):
                    if top_review.get(key) != review_payload.get(key):
                        errors.append("parent and supplemental review protection settings conflict")
            else:
                errors.append("parent review protection has an invalid shape")
        if "restrictions" in parent_body:
            top_restrictions = parent_body["restrictions"]
            if (top_restrictions is None) != (restrictions is None):
                errors.append("parent and supplemental push restriction settings conflict")
            elif isinstance(top_restrictions, dict) and isinstance(restrictions, dict):
                try:
                    if checked_rest_actors(top_restrictions, "parent push restriction") != restrictions:
                        errors.append("parent and supplemental push restriction actors conflict")
                except CaptureError as exc:
                    errors.append(str(exc))
    if errors:
        return None, list(dict.fromkeys(errors))

    resource = {
        **parent_config,
        "required_pull_request_reviews": review_payload,
        "restrictions": restrictions,
    }
    # The parent API is the source of status-check associations; preserve those IDs.
    return resource, []


def writable_payload(resource: dict) -> dict:
    writable = {key: value for key, value in resource.items() if key != "required_signatures"}
    return writable


def build_capture(fixture: dict | None = None) -> dict:
    source, errors = capture_sources(fixture)
    resource, composition_errors = compose_resource(source)
    errors.extend(composition_errors)
    errors = list(dict.fromkeys(errors))
    return {
        "schema": SCHEMA,
        "version": VERSION,
        "observed_at": utc_now(),
        "repository": REPOSITORY,
        "ref": REF,
        "main_sha": source.get("main_ref_before", {}).get("sha"),
        "capture_status": "complete" if resource is not None and not errors else "incomplete",
        "capture_errors": errors,
        "source_digest": digest(source),
        "sources": source,
        "resource": resource,
        "writable_payload": writable_payload(resource) if resource is not None else None,
    }


def validate_capture(receipt: object) -> list[str]:
    if not isinstance(receipt, dict):
        return ["capture is not a JSON object"]
    errors: list[str] = []
    if receipt.get("schema") != SCHEMA or receipt.get("version") != VERSION:
        errors.append("capture schema is unsupported")
    if receipt.get("repository") != REPOSITORY or receipt.get("ref") != REF:
        errors.append("capture target is unsupported")
    if not isinstance(receipt.get("observed_at"), str) or not receipt["observed_at"].endswith("Z"):
        errors.append("capture timestamp is invalid")
    source = receipt.get("sources")
    if not isinstance(source, dict) or receipt.get("source_digest") != digest(source):
        errors.append("capture source digest does not match source evidence")
        return errors
    ref_before = source.get("main_ref_before", {}).get("sha")
    if receipt.get("main_sha") != ref_before:
        errors.append("capture main SHA differs from source evidence")
    expected_resource, composition_errors = compose_resource(source)
    expected_status = "complete" if expected_resource is not None and not composition_errors else "incomplete"
    all_errors = list(dict.fromkeys(list(receipt.get("capture_errors", [])) + composition_errors))
    if receipt.get("capture_status") != expected_status:
        errors.append("capture status does not match the available evidence")
    if receipt.get("resource") != expected_resource:
        errors.append("capture resource does not match normalized source evidence")
    expected_payload = writable_payload(expected_resource) if expected_resource is not None else None
    if receipt.get("writable_payload") != expected_payload:
        errors.append("capture writable payload does not match the normalized resource")
    if receipt.get("capture_errors") != all_errors:
        errors.append("capture errors do not match the source evidence")
    return errors


def atomic_write(path: pathlib.Path, payload: dict) -> None:
    if path.exists() or path.is_symlink():
        raise CaptureError("refusing to overwrite existing output")
    encoded = json.dumps(payload, indent=2, sort_keys=True).encode("utf-8") + b"\n"
    if len(encoded) > MAX_BYTES:
        raise CaptureError("capture exceeds output bound")
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
    parser.add_argument("--fixture", type=pathlib.Path, help="replay bounded read-only GitHub responses")
    args = parser.parse_args()
    if bool(args.verify) == bool(args.output):
        parser.error("provide exactly one of --output or --verify")
    if args.verify:
        try:
            if args.verify.stat().st_size > MAX_BYTES:
                raise ValueError("oversized capture")
            receipt = json.loads(args.verify.read_text(encoding="utf-8"))
        except (OSError, ValueError, json.JSONDecodeError):
            print("invalid protection capture JSON", file=sys.stderr)
            return 2
        errors = validate_capture(receipt)
        if errors:
            print("invalid protection capture: " + "; ".join(errors), file=sys.stderr)
            return 1
        print(f"valid protection capture: {receipt['capture_status']} ({receipt['main_sha']})")
        return 0
    fixture = None
    if args.fixture:
        try:
            if args.fixture.stat().st_size > MAX_BYTES:
                raise ValueError("oversized fixture")
            fixture = json.loads(args.fixture.read_text(encoding="utf-8"))
            if not isinstance(fixture, dict):
                raise ValueError("fixture must be an object")
        except (OSError, ValueError, json.JSONDecodeError):
            print("invalid fixture JSON", file=sys.stderr)
            return 2
    try:
        receipt = build_capture(fixture)
        errors = validate_capture(receipt)
        if errors:
            raise CaptureError("capture validation failed: " + "; ".join(errors))
        atomic_write(args.output, receipt)
        print(f"wrote {args.output}: {receipt['capture_status']} ({receipt['main_sha']})")
        return 0
    except CaptureError as exc:
        print(f"capture incomplete: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
