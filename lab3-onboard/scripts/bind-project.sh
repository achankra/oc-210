#!/usr/bin/env bash
# Give a project its cells: one ProjectReleaseBinding per environment.
#
# Usage: scripts/bind-project.sh TEAM PROJECT
#
# The portal's Create Project wizard creates the bindings. A project created
# another way, for example applied with kubectl, gets none, and without them it
# has no cell namespaces. This renders templates/bindings.yaml for the project
# (development and staging), checks it with a server-side dry run, applies it
# with occ, and logs the step.
set -eu
here="$(cd "$(dirname "$0")/.." && pwd)"
. "$here/scripts/lib.sh"
[ $# -eq 2 ] || { sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }
TEAM="$1"; PROJECT="$2"
out="rendered/$TEAM"
mkdir -p "$out"
python3 "$here/scripts/render.py" "$here/templates/bindings.yaml" TEAM="$TEAM" PROJECT="$PROJECT" > "$out/$PROJECT-bindings.yaml"
log_row "bindings" "scripts/bind-project.sh $TEAM $PROJECT"
kubectl apply --dry-run=server -f "$out/$PROJECT-bindings.yaml"
occ apply -f "$out/$PROJECT-bindings.yaml"
echo "Waiting for the cell namespaces of $PROJECT..."
for _ in $(seq 1 24); do
  kubectl get namespaces -l openchoreo.dev/project="$PROJECT" -o name | grep -q . && break
  sleep 5
done
kubectl get namespaces -l openchoreo.dev/project="$PROJECT" -L openchoreo.dev/environment
