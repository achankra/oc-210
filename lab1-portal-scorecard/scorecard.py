#!/usr/bin/env python3
"""Score a developer portal on the six evaluation planes.

Reads a CSV with the columns plane, score, evidence. Scores run from 0 (absent)
to 3 (strong). Prints a table, the total, and the weakest and strongest planes.

Usage: scorecard.py FILE.csv
Exit status: 0 when the file is valid, 1 when it is not.
"""
import csv
import sys

PLANES = [
    "Service catalog and ownership",
    "Golden paths and scaffolding",
    "Operations and reliability",
    "Security and governance",
    "Observability and telemetry",
    "Insights and AI augmentation",
]


def load(path):
    rows, problems = {}, []
    with open(path, newline="") as f:
        reader = csv.DictReader(f)
        missing = {"plane", "score", "evidence"} - set(reader.fieldnames or [])
        if missing:
            return rows, ["missing column(s): " + ", ".join(sorted(missing))]
        for n, row in enumerate(reader, start=2):
            plane = (row["plane"] or "").strip()
            if plane not in PLANES:
                problems.append(f"line {n}: unknown plane '{plane}'")
                continue
            if plane in rows:
                problems.append(f"line {n}: '{plane}' appears twice")
                continue
            try:
                score = int(row["score"])
            except (TypeError, ValueError):
                problems.append(f"line {n}: score for '{plane}' is not a whole number")
                continue
            if not 0 <= score <= 3:
                problems.append(f"line {n}: score for '{plane}' must be 0 to 3, got {score}")
                continue
            evidence = (row["evidence"] or "").strip()
            if not evidence:
                problems.append(f"line {n}: '{plane}' has no evidence sentence")
            rows[plane] = (score, evidence)
    for plane in PLANES:
        if plane not in rows:
            problems.append(f"no score for '{plane}'")
    return rows, problems


def main(argv):
    if len(argv) != 2:
        print(__doc__.strip().splitlines()[-2], file=sys.stderr)
        return 1
    rows, problems = load(argv[1])
    if problems:
        print("The scorecard is not complete:")
        for p in problems:
            print("  - " + p)
        return 1
    width = max(len(p) for p in PLANES)
    print(f"{'PLANE'.ljust(width)}  SCORE  EVIDENCE")
    for plane in PLANES:
        score, evidence = rows[plane]
        print(f"{plane.ljust(width)}  {score}/3    {evidence}")
    total = sum(s for s, _ in rows.values())
    print(f"\nTotal: {total}/{3 * len(PLANES)}")
    ranked = sorted(PLANES, key=lambda p: (rows[p][0], PLANES.index(p)))
    print("Weakest:   " + ", ".join(f"{p} ({rows[p][0]})" for p in ranked[:2]))
    print("Strongest: " + ", ".join(f"{p} ({rows[p][0]})" for p in reversed(ranked[-2:])))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
