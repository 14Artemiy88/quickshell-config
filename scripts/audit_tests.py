#!/usr/bin/env python3
"""Audit CHECK.sh test registration and flag high-confidence overlap candidates.

This is a review aid, not an automatic test merger: shared targets and repeated
assertions can represent complementary coverage of different failure modes.
Only the Python standard library is used.
"""

from __future__ import annotations

import hashlib
import re
import sys
from collections import defaultdict
from itertools import combinations
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CHECK = ROOT / "CHECK.sh"
TEST_DIR = ROOT / "tests"
REGISTRATION = re.compile(r'^\s*run_test\s+"\$ROOT/tests/([^" ]+)"\s*$', re.MULTILINE)
ASSERTION = re.compile(
    r"\[\[|\bassert(?:\.|\s*\()|\bgrep\s|\bcmp\s|\bdiff\s|\bjq\s+-e\b|"
    r"\bexpect(?:_[A-Za-z0-9_]+)?\s*\(|\bfail\s*\(|\btest\s+-"
)
ROOT_TARGET = re.compile(r"(?:\$ROOT/|\$\{ROOT\}/)([A-Za-z0-9_./-]+)")
LITERAL_TARGET = re.compile(r"(?<![A-Za-z0-9_])((?:components|scripts|js|docs)/[A-Za-z0-9_./-]+)")


def meaningful_lines(path: Path) -> list[str]:
    lines: list[str] = []
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        lines.append(re.sub(r"\s+", " ", stripped))
    return lines


def assertion_lines(path: Path) -> set[str]:
    result: set[str] = set()
    for line in meaningful_lines(path):
        if ASSERTION.search(line):
            result.add(line)
    return result


def target_paths(path: Path) -> set[str]:
    result: set[str] = set()
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        candidates = [match.group(1) for match in ROOT_TARGET.finditer(line)]
        candidates.extend(match.group(1) for match in LITERAL_TARGET.finditer(line))
        for candidate in candidates:
            candidate = candidate.rstrip(".,:;)")
            if candidate.startswith("tests/") or candidate == "CHECK.sh":
                continue
            if (ROOT / candidate).exists():
                result.add(candidate)
    return result


def normalized_digest(path: Path) -> str:
    # Keep literals and heredoc content intact; ignore only comments/whitespace.
    payload = "\n".join(meaningful_lines(path)).encode("utf-8")
    return hashlib.sha256(payload).hexdigest()


def main() -> int:
    if not CHECK.is_file() or not TEST_DIR.is_dir():
        print("test audit: CHECK.sh or tests directory is missing", file=sys.stderr)
        return 2

    registered = REGISTRATION.findall(CHECK.read_text(encoding="utf-8"))
    registered_counts: dict[str, int] = defaultdict(int)
    for name in registered:
        registered_counts[name] += 1

    disk_files = {path.name for path in TEST_DIR.glob("test_*.sh")}
    registered_files = set(registered_counts)
    missing = sorted(name for name in registered_files if not (TEST_DIR / name).is_file())
    unregistered = sorted(disk_files - registered_files)
    repeated_registration = sorted(name for name, count in registered_counts.items() if count > 1)

    print(f"Test inventory: {len(registered)} CHECK registrations, {len(disk_files)} test files")
    print(
        "Registration mismatches: "
        f"missing={len(missing)}, unregistered={len(unregistered)}, "
        f"registered-more-than-once={len(repeated_registration)}"
    )
    for label, items in (
        ("Missing files", missing),
        ("Unregistered files", unregistered),
        ("Repeated registrations", repeated_registration),
    ):
        for name in items:
            print(f"  {label}: {name}")

    groups: dict[str, list[str]] = defaultdict(list)
    for path in sorted(TEST_DIR.glob("test_*.sh")):
        groups[normalized_digest(path)].append(path.name)
    exact_groups = [names for names in groups.values() if len(names) > 1]
    print(f"Exact source duplicate groups: {len(exact_groups)}")
    for names in exact_groups:
        print("  " + " <-> ".join(names))

    records = []
    for path in sorted(TEST_DIR.glob("test_*.sh")):
        checks = assertion_lines(path)
        targets = target_paths(path)
        if len(checks) >= 3 and targets:
            records.append((path.name, checks, targets))

    candidates = []
    for left, right in combinations(records, 2):
        common_checks = left[1] & right[1]
        common_targets = left[2] & right[2]
        if len(common_checks) < 3 or not common_targets:
            continue
        union = left[1] | right[1]
        similarity = len(common_checks) / len(union) if union else 0.0
        if similarity >= 0.15:
            candidates.append((similarity, len(common_checks), len(common_targets), left[0], right[0], sorted(common_targets)))

    candidates.sort(reverse=True)
    print(
        "Semantic overlap candidates: "
        f"{len(candidates)} (shared assertions + shared source targets; manual review only)"
    )
    for similarity, shared_checks, shared_targets, left, right, targets in candidates[:20]:
        print(
            f"  {left} <-> {right}: {similarity:.0%} assertion overlap, "
            f"{shared_checks} shared checks, {shared_targets} shared targets"
        )
        for target in targets[:4]:
            print(f"    target: {target}")

    if not candidates:
        print("  No pairs met the overlap threshold.")

    if missing or unregistered or repeated_registration or exact_groups:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
