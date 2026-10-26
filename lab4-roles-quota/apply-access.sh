#!/usr/bin/env bash
# Render and apply the team-developer role and its binding for a team.
#
# Usage: ./apply-access.sh TEAM [--apply]
#
# Without --apply the files are rendered and checked with a client-side dry run.
# With --apply each file gets a server-side dry run, then occ apply.
# Commands are logged to the same file as onboard.sh when you pass --apply.
set -eu

here="$(cd "$(dirname "$0")" && pwd)"
lab3="$here/../lab3-onboard"
. "$lab3/scripts/lib.sh"

[ $# -ge 1 ] || { sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }
TEAM="$1"; APPLY=0
[ "${2:-}" = "--apply" ] && APPLY=1
[ "$APPLY" -eq 1 ] || ONBOARD_LOG=/dev/null

out="rendered/$TEAM"
mkdir -p "$out"
for name in role binding; do
  python3 "$lab3/scripts/render.py" "$here/templates/$name.yaml" TEAM="$TEAM" > "$out/$name.yaml"
done
echo "Rendered role.yaml and binding.yaml in $out/"

STEP="role and binding"
run() { log_row "$STEP" "$*"; echo "+ $*"; "$@"; }

if [ "$APPLY" -eq 0 ]; then
  for name in role binding; do run kubectl apply --dry-run=client -f "$out/$name.yaml"; done
  echo; echo "Nothing was created. Run again with --apply."
  exit 0
fi
for name in role binding; do
  run kubectl apply --dry-run=server -f "$out/$name.yaml"
  run occ apply -f "$out/$name.yaml"
done
run occ authzrole list -n "$TEAM"
run occ authzrolebinding list -n "$TEAM"
