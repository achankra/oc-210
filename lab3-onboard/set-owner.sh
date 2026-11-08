#!/usr/bin/env bash
# Set a project's owner in the catalog.
#
# Usage: ./set-owner.sh TEAM PROJECT [--group GROUP] [--apply]
#
# The portal's Create Project wizard has no owner field, so a project it creates
# shows the portal's default owner, openchoreo-users. This sets the project's
# backstage.io/owner annotation to group:default/GROUP (default: the team name,
# the group onboard.sh creates). Components in the project inherit it unless they
# set their own.
#
# Without --apply it shows the command and the project's current annotations.
# With --apply it sets the annotation and logs the step to onboarding-log.csv.
set -eu
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/scripts/lib.sh"

usage() { sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }
[ $# -ge 2 ] && [ "${1#-}" = "$1" ] && [ "${2#-}" = "$2" ] || usage
TEAM="$1"; PROJECT="$2"; shift 2
GROUP="$TEAM"
APPLY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --apply) APPLY=1 ;;
    --group) GROUP="$2"; shift ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
  shift
done

# Generated entities live in a catalog namespace named after the OpenChoreo
# namespace, while ThunderID groups live in default: use the full reference.
OWNER="group:default/$GROUP"
cmd=(kubectl annotate project "$PROJECT" -n "$TEAM" "backstage.io/owner=$OWNER" --overwrite)

if [ "$APPLY" -eq 0 ]; then
  echo "Would run: ${cmd[*]}"
  echo "Current annotations of $PROJECT:"
  kubectl get project "$PROJECT" -n "$TEAM" -o jsonpath='{.metadata.annotations}'; echo
  echo "Run again with --apply."
  exit 0
fi

log_row "owner" "${cmd[*]}"
echo "+ ${cmd[*]}"
"${cmd[@]}"
echo "Owner of $PROJECT: $OWNER. The catalog shows it after its next sync; components in $PROJECT inherit it."
