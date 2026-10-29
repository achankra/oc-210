#!/usr/bin/env python3
"""Turn an export of the default ClusterProjectType into the starter-tier type.

Usage: build_starter_tier.py EXPORT.yaml QUOTA.yaml > starter-tier.yaml

The same edit as Lab 4 step 2: rename the type, give it the display name and
description its portal wizard shows, strip the fields the server sets, and add
the ResourceQuota as a new resource in the cell namespace.
The sandbox restore script uses it to rebuild Lab 4 in a new session.
"""
import sys

import yaml


def main(argv):
    if len(argv) != 3:
        print(__doc__.strip(), file=sys.stderr)
        return 1
    d = yaml.safe_load(open(argv[1]))
    m = d["metadata"]
    for k in ("uid", "resourceVersion", "creationTimestamp", "generation",
              "managedFields", "ownerReferences", "annotations"):
        m.pop(k, None)
    d.pop("status", None)
    m["name"] = "starter-tier"
    m["labels"] = {"openchoreo.dev/name": "starter-tier"}
    # the portal shows these on the Create Project wizard it generates for the type
    m["annotations"] = {"openchoreo.dev/display-name": "Starter tier",
                        "openchoreo.dev/description": "A cell with the starter-tier quota: 4 CPU and 8Gi requested, up to 10 deployments."}
    res = d["spec"]["resources"]
    ns = next(r for r in res if r["id"] == "cell-namespace")
    q = yaml.safe_load(open(argv[2]))
    q["metadata"]["namespace"] = ns["template"]["metadata"]["name"]
    res[:] = [r for r in res if r["id"] != "starter-tier-quota"]
    res.append({"id": "starter-tier-quota", "targetPlane": ns.get("targetPlane", "dataplane"), "template": q})
    yaml.safe_dump(d, sys.stdout, sort_keys=False)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
