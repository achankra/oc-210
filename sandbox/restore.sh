#!/usr/bin/env bash
# Rebuild what the earlier labs created, in a new sandbox session.
#
# Usage: ~/oc-210-labs/sandbox/restore.sh lab4|lab5|capstone
#
# A sandbox session lasts one hour and keeps nothing, but Labs 4, 5 and the
# capstone build on earlier labs. This recreates that state:
#   lab4      team-alpha with its environments, pipeline and alpha-shop (Lab 3)
#   lab5      lab4, plus the quota grant, the starter-tier type and alpha-pilot (Lab 4)
#   capstone  the quota grant and the starter-tier type (Lab 4)
# The role and binding of Lab 4 are not restored; Lab 5 does not need them.
# Every step can run twice. Nothing is written to your onboarding log.
set -eu
here="$(cd "$(dirname "$0")/.." && pwd)"
export ONBOARD_LOG=/dev/null
[ $# -eq 1 ] || { sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }

lab3_state() {
  echo "== Lab 3: team-alpha"
  (cd "$here/lab3-onboard" && ./onboard.sh team-alpha alpha-shop --apply)
}

lab4_type() {
  echo "== Lab 4: quota grant for the cluster agent"
  kubectl create clusterrole lab-cluster-agent-quotas \
    --verb=get,list,watch,create,update,patch,delete --resource=resourcequotas,limitranges \
    --dry-run=client -o yaml | kubectl apply -f -
  kubectl create clusterrolebinding lab-cluster-agent-quotas \
    --clusterrole=lab-cluster-agent-quotas \
    --serviceaccount=openchoreo-data-plane:cluster-agent-dataplane \
    --dry-run=client -o yaml | kubectl apply -f -
  echo "== Lab 4: starter-tier ClusterProjectType"
  tmp="$(mktemp -d)"
  kubectl get clusterprojecttype default -o yaml > "$tmp/default.yaml"
  python3 "$here/lab4-roles-quota/build_starter_tier.py" "$tmp/default.yaml" \
    "$here/lab4-roles-quota/starter-tier-quota.yaml" > "$tmp/starter-tier.yaml"
  kubectl apply -f "$tmp/starter-tier.yaml"
  rm -rf "$tmp"
}

lab4_project() {
  echo "== Lab 4: alpha-pilot on starter-tier"
  (cd "$here/lab3-onboard" && ./onboard.sh team-alpha alpha-pilot --project-type starter-tier --apply)
}

case "$1" in
  lab4) lab3_state ;;
  lab5) lab3_state; lab4_type; lab4_project ;;
  capstone) lab4_type ;;
  *) echo "Unknown lab: $1. Use lab4, lab5 or capstone." >&2; exit 1 ;;
esac
echo
echo "Restored the state $1 needs. Carry on from the lab's first step."
