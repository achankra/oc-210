#!/usr/bin/env python3
"""Compare the ResourceQuotas in a namespace with the starter tier.

Usage:
  kubectl get resourcequota -n NAMESPACE -o json | check_quota.py
  check_quota.py quota.json
  check_quota.py quota.json --expect tier.json

The input is the JSON from kubectl get resourcequota -o json. Limits from every
quota in the list are merged. --expect names a JSON file that maps quota keys to
values; without it the Handbook's starter tier is used.
Exit status: 0 when every expected key matches, 1 when one is missing or differs.
"""
import json
import sys

STARTER = {
    "requests.cpu": "4",
    "requests.memory": "8Gi",
    "limits.cpu": "8",
    "limits.memory": "16Gi",
    "persistentvolumeclaims": "5",
    "services.loadbalancers": "1",
    "count/deployments.apps": "10",
}

SUFFIX = {
    "m": 1e-3, "k": 1e3, "K": 1e3, "M": 1e6, "G": 1e9, "T": 1e12, "P": 1e15, "E": 1e18,
    "Ki": 2**10, "Mi": 2**20, "Gi": 2**30, "Ti": 2**40, "Pi": 2**50, "Ei": 2**60,
}


def quantity(text):
    text = str(text).strip()
    for suffix in sorted(SUFFIX, key=len, reverse=True):
        if text.endswith(suffix) and text[: -len(suffix)].replace(".", "", 1).isdigit():
            return float(text[: -len(suffix)]) * SUFFIX[suffix]
    return float(text)


def merged_hard(data):
    items = data.get("items") if data.get("kind") == "List" else [data]
    hard = {}
    for item in items or []:
        limits = (item.get("status") or {}).get("hard") or (item.get("spec") or {}).get("hard") or {}
        hard.update(limits)
    return hard


def main(argv):
    args = argv[1:]
    expect = STARTER
    if "--expect" in args:
        i = args.index("--expect")
        with open(args[i + 1]) as f:
            expect = json.load(f)
        del args[i:i + 2]
    source = open(args[0]) if args else sys.stdin
    data = json.load(source)
    hard = merged_hard(data)
    if not hard:
        print("No ResourceQuota limits found in the input.")
        return 1
    bad = 0
    width = max(len(k) for k in expect)
    for key, want in expect.items():
        have = hard.get(key)
        if have is None:
            print(f"MISSING  {key.ljust(width)}  expected {want}")
            bad += 1
        elif abs(quantity(have) - quantity(want)) > 1e-9:
            print(f"DIFFERS  {key.ljust(width)}  expected {want}, found {have}")
            bad += 1
        else:
            print(f"OK       {key.ljust(width)}  {have}")
    print(f"\n{len(expect) - bad} of {len(expect)} limits match.")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
