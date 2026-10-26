#!/usr/bin/env python3
"""Check catalog entries for the four completeness items from Lab 2.

Each Component entry is checked for an owner, a lifecycle, at least one link,
and a system. Other entity kinds are checked for an owner and a link.

Usage: catalog_check.py [--strict] PATH [PATH ...]
PATH is a catalog-info YAML file or a folder that holds them. A file can hold
several entries separated by ---.
With --strict the exit status is 1 when any entry is incomplete.
"""
import os
import sys

try:
    import yaml
except ImportError:
    sys.exit("PyYAML is required: pip install pyyaml")


def files_under(path):
    if os.path.isdir(path):
        for name in sorted(os.listdir(path)):
            if name.endswith((".yaml", ".yml")):
                yield os.path.join(path, name)
    else:
        yield path


def checks_for(entry):
    kind = entry.get("kind", "")
    meta = entry.get("metadata") or {}
    spec = entry.get("spec") or {}
    owner = str(spec.get("owner") or "").strip()
    results = {
        "owner": bool(owner) and owner.lower() not in ("unknown", "tbd"),
        "link": bool(meta.get("links")),
    }
    if kind == "Component":
        results["lifecycle"] = bool(str(spec.get("lifecycle") or "").strip())
        results["system"] = bool(str(spec.get("system") or "").strip())
    return results


def main(argv):
    strict = "--strict" in argv
    paths = [a for a in argv[1:] if a != "--strict"]
    if not paths:
        print(__doc__.strip(), file=sys.stderr)
        return 1
    total = passed = entries = complete = 0
    for path in paths:
        for fname in files_under(path):
            with open(fname) as f:
                docs = [d for d in yaml.safe_load_all(f) if isinstance(d, dict)]
            for entry in docs:
                if "kind" not in entry:
                    continue
                name = (entry.get("metadata") or {}).get("name", "(no name)")
                results = checks_for(entry)
                entries += 1
                total += len(results)
                passed += sum(results.values())
                if all(results.values()):
                    complete += 1
                marks = "  ".join(f"{k}: {'yes' if v else 'NO'}" for k, v in results.items())
                print(f"{entry['kind']}/{name}  ({os.path.basename(fname)})")
                print(f"    {marks}")
    if entries == 0:
        print("No catalog entries found.")
        return 1
    pct = round(100 * passed / total)
    print(f"\n{complete} of {entries} entries complete; {passed} of {total} checks passed ({pct}%)")
    return 1 if strict and complete < entries else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
