#!/usr/bin/env python3
"""Turn the onboarding log into the capstone scorecard.

Usage: onboarding_scorecard.py [LOG.csv] [--tickets N]

LOG.csv defaults to onboarding-log.csv. It is written by onboard.sh,
apply-access.sh and mark.sh. Each row is the epoch time, a step name and a
command. The time between one row and the one before it is counted against the
step named on the later row.

Prints time-to-first-deploy, the commands run, tickets, the time per step, the
slowest step, and whether each Handbook threshold was met.
The metrics and thresholds come from The Platform Engineer's Handbook (Packt, 2025),
Chapter 7. The book is not required for the course; we recommend it:
https://peh-packt.platformetrics.com
"""
import csv
import sys

GOAL = 15 * 60       # the course goal: onboard a team in under 15 minutes
FRICTION = 7 * 60    # the seven-minute rule: friction above this sends developers elsewhere


def clock(seconds):
    return f"{int(seconds // 60)}:{int(seconds % 60):02d}"


def main(argv):
    args = argv[1:]
    tickets = 0
    if "--tickets" in args:
        i = args.index("--tickets")
        tickets = int(args[i + 1])
        del args[i:i + 2]
    path = args[0] if args else "onboarding-log.csv"
    try:
        with open(path, newline="") as f:
            rows = [r for r in csv.DictReader(f) if r.get("epoch")]
    except FileNotFoundError:
        print(f"No log at {path}. Run onboard.sh --apply or scripts/mark.sh first.")
        return 1
    if len(rows) < 2:
        print("The log has no steps yet.")
        return 1

    times = [int(r["epoch"]) for r in rows]
    total = times[-1] - times[0]
    per_step, commands, order = {}, {}, []
    for prev, cur, row in zip(times, times[1:], rows[1:]):
        step = row["step"]
        if step not in per_step:
            order.append(step)
            per_step[step] = 0
            commands[step] = 0
        per_step[step] += cur - prev
        if row.get("command"):
            commands[step] += 1

    width = max(len(s) for s in order)
    print(f"{'STEP'.ljust(width)}  TIME   COMMANDS")
    for step in order:
        flag = "  over seven minutes" if per_step[step] > FRICTION else ""
        print(f"{step.ljust(width)}  {clock(per_step[step]).rjust(5)}  {str(commands[step]).rjust(8)}{flag}")

    slowest = max(order, key=lambda s: per_step[s])
    print()
    print(f"Time-to-first-deploy: {clock(total)}")
    print(f"Commands run:         {sum(commands.values())}")
    print(f"Tickets created:      {tickets}")
    print(f"Slowest step:         {slowest} ({clock(per_step[slowest])})")
    print(f"Under the 15-minute goal: {'yes' if total < GOAL else 'no'}")
    print(f"Any step over seven minutes: {'yes' if any(v > FRICTION for v in per_step.values()) else 'no'}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
