#!/usr/bin/env bash
# Onboard a team: namespace, environments, pipeline, project and project bindings.
#
# Usage: ./onboard.sh TEAM PROJECT [options]
#
# By default this renders the files and checks them without touching the
# cluster. Add --apply to create the objects.
#
# Options:
#   --apply                       create the objects
#   --tier NAME                   value of the platform.io/tier label (default: starter)
#   --project-type NAME           ProjectType for the project (default: default)
#   --project-type-kind KIND      ClusterProjectType or ProjectType (default: ClusterProjectType)
#   --dataplane-kind KIND         data plane kind for the environments
#   --dataplane-name NAME         data plane name for the environments
#
# Without the two data plane options, the values are read from the development
# environment in the default namespace.
#
# With --apply, every command is logged to onboarding-log.csv (override with ONBOARD_LOG).
set -eu

here="$(cd "$(dirname "$0")" && pwd)"
. "$here/scripts/lib.sh"

[ $# -ge 2 ] || { sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }
TEAM="$1"; PROJECT="$2"; shift 2

APPLY=0
TIER="starter"
PROJECT_TYPE="default"
PROJECT_TYPE_KIND="ClusterProjectType"
DATAPLANE_KIND=""
DATAPLANE_NAME=""
while [ $# -gt 0 ]; do
  case "$1" in
    --apply) APPLY=1 ;;
    --tier) TIER="$2"; shift ;;
    --project-type) PROJECT_TYPE="$2"; shift ;;
    --project-type-kind) PROJECT_TYPE_KIND="$2"; shift ;;
    --dataplane-kind) DATAPLANE_KIND="$2"; shift ;;
    --dataplane-name) DATAPLANE_NAME="$2"; shift ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
  shift
done

# A check-only run does not write to the log, so it never counts toward the timing.
[ "$APPLY" -eq 1 ] || ONBOARD_LOG=/dev/null

case "$TEAM" in
  [a-z0-9]*) ;;
  *) echo "TEAM must start with a lowercase letter or digit." >&2; exit 1 ;;
esac

run() {
  # run COMMAND...   logs the command, then runs it
  log_row "$STEP" "$*"
  echo "+ $*"
  "$@"
}

STEP="read data plane"
if [ -z "$DATAPLANE_KIND" ] || [ -z "$DATAPLANE_NAME" ]; then
  DATAPLANE_KIND="$(kubectl get environment development -n default -o jsonpath='{.spec.dataPlaneRef.kind}')"
  DATAPLANE_NAME="$(kubectl get environment development -n default -o jsonpath='{.spec.dataPlaneRef.name}')"
  log_row "$STEP" "kubectl get environment development -n default"
fi
[ -n "$DATAPLANE_KIND" ] && [ -n "$DATAPLANE_NAME" ] || {
  echo "Could not read the data plane. Pass --dataplane-kind and --dataplane-name." >&2; exit 1; }
echo "Data plane: $DATAPLANE_KIND/$DATAPLANE_NAME"

out="rendered/$TEAM"
mkdir -p "$out"
VARS="TEAM=$TEAM PROJECT=$PROJECT TIER=$TIER PROJECT_TYPE=$PROJECT_TYPE PROJECT_TYPE_KIND=$PROJECT_TYPE_KIND DATAPLANE_KIND=$DATAPLANE_KIND DATAPLANE_NAME=$DATAPLANE_NAME"

STEP="render files"
for name in namespace environments pipeline project bindings; do
  # shellcheck disable=SC2086
  python3 "$here/scripts/render.py" "$here/templates/$name.yaml" $VARS > "$out/$name.yaml"
done
log_row "$STEP" "render.py x5"
echo "Rendered five files in $out/"

if [ "$APPLY" -eq 0 ]; then
  STEP="check files"
  for name in namespace environments pipeline project bindings; do
    run kubectl apply --dry-run=client -f "$out/$name.yaml"
  done
  echo
  echo "Nothing was created. Run again with --apply to onboard $TEAM."
  exit 0
fi

STEP="namespace"
run kubectl apply --dry-run=server -f "$out/namespace.yaml"
run kubectl apply -f "$out/namespace.yaml"

for name in environments pipeline project bindings; do
  STEP="$name"
  run kubectl apply --dry-run=server -f "$out/$name.yaml"
  run occ apply -f "$out/$name.yaml"
done

STEP="verify"
run occ namespace list
run occ project list -n "$TEAM"
echo "Waiting for the cell namespaces of $PROJECT..."
for _ in $(seq 1 24); do
  kubectl get namespaces -l openchoreo.dev/project="$PROJECT" -o name | grep -q . && break
  sleep 5
done
run kubectl get namespaces -l openchoreo.dev/project="$PROJECT" -L openchoreo.dev/environment
echo
echo "Onboarded $TEAM with project $PROJECT. Log: $ONBOARD_LOG"
