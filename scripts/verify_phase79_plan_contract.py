#!/usr/bin/env python3
"""Run the Phase 79 Plan 14 evidence gates and downstream plan-index checks."""

from __future__ import annotations

import argparse
import json
import os
import pathlib
import subprocess
import sys


ROOT = pathlib.Path(__file__).resolve().parents[1]
GSD_TOOLS_RELATIVE = pathlib.Path("gsd-core/bin/gsd-tools.cjs")
GSD_TOOLS_UNAVAILABLE_PREFIX = (
    "gsd_tools_unavailable: gsd-tools not found; set GSD_TOOLS to an installed gsd-tools.cjs or install GSD"
)


class GsdToolsUnavailable(RuntimeError):
    """gsd-tools could not be located; carries the stable gsd_tools_unavailable marker."""


def resolve_gsd_tools(env=None, root: pathlib.Path = ROOT) -> pathlib.Path:
    """Locate gsd-tools: GSD_TOOLS, CLAUDE_CONFIG_DIR, HOME/.claude, HOME/.codex, then repository."""
    env = os.environ if env is None else env
    override = env.get("GSD_TOOLS") or None
    if override is not None:
        path = pathlib.Path(override)
        if path.is_file():
            return path
        raise GsdToolsUnavailable(f"{GSD_TOOLS_UNAVAILABLE_PREFIX}; GSD_TOOLS={path} is not a regular file "
                                  "(an explicit override never falls back)")
    home = pathlib.Path(env.get("HOME") or pathlib.Path.home())
    candidates = []
    if env.get("CLAUDE_CONFIG_DIR"):
        candidates.append(pathlib.Path(env["CLAUDE_CONFIG_DIR"]) / GSD_TOOLS_RELATIVE)
    candidates += [home / ".claude" / GSD_TOOLS_RELATIVE, home / ".codex" / GSD_TOOLS_RELATIVE,
                   pathlib.Path(root) / GSD_TOOLS_RELATIVE]
    for path in candidates:
        if path.is_file():
            return path
    raise GsdToolsUnavailable(f"{GSD_TOOLS_UNAVAILABLE_PREFIX}; searched: {', '.join(map(str, candidates))}")


def run(command: list[str], label: str) -> str:
    result = subprocess.run(command, cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, check=False)
    if result.returncode:
        raise RuntimeError(f"{label} failed ({result.returncode}):\n{(result.stdout + result.stderr)[-12000:]}")
    return result.stdout


def verify_handoff() -> None:
    raw = run(["node", str(resolve_gsd_tools()), "phase-plan-index", "79", "--raw"], "GSD phase-plan-index")
    index = json.loads(raw)
    plans = {row["id"]: row for row in index["plans"]}
    assert plans["79-14"]["wave"] == 8 and plans["79-14"]["depends_on"] == ["79-07"]
    assert plans["79-15"]["wave"] == 9 and plans["79-15"]["depends_on"] == ["79-14"]
    assert plans["79-09"]["wave"] == 10 and plans["79-09"]["depends_on"] == ["79-15"]
    assert plans["79-10"]["wave"] == 11 and plans["79-10"]["depends_on"] == ["79-09"]
    assert plans["79-11"]["wave"] == 12 and plans["79-11"]["depends_on"] == ["79-10"]
    assert plans["79-12"]["wave"] == 13 and plans["79-12"]["depends_on"] == ["79-11"]
    # The disposable candidate intentionally omits plan summaries.  In that
    # view, Wave 8 may show the intentionally halted 79-08 and completed 79-14
    # as incomplete even though the active planning checkout records their
    # terminal summaries.  No other Wave 8 work may remain actionable.
    wave_8_incomplete = {key for key in index["incomplete"] if plans[key]["wave"] == 8}
    assert wave_8_incomplete <= {"79-08", "79-14"}, (
        f"unexpected actionable Wave 8 plans in candidate index: {sorted(wave_8_incomplete)}"
    )
    assert index["waves"]["9"] == ["79-15"]
    assert index["waves"]["10"] == ["79-09"]
    assert index["waves"]["11"] == ["79-10"]
    assert index["waves"]["12"] == ["79-11"]
    assert index["waves"]["13"] == ["79-12"]


def verify_evidence() -> None:
    run([sys.executable, str(ROOT / "scripts/prepare_phase79_filtered_candidate.py"), "--self-test"], "filtered-history self-test")
    run(["mix", "ci.evidence"], "mix ci.evidence")
    run(["mix", "ci.phase73.reconciliation"], "mix ci.phase73.reconciliation")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--handoff", action="store_true")
    group.add_argument("--evidence", action="store_true")
    args = parser.parse_args()
    try:
        verify_handoff() if args.handoff else verify_evidence()
        print(json.dumps({"valid": True, "contract": "handoff" if args.handoff else "evidence"}))
        return 0
    except (OSError, ValueError, AssertionError, RuntimeError, json.JSONDecodeError) as exc:
        print(f"Phase 79 plan contract: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
