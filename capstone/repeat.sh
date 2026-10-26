#!/usr/bin/env bash
# Repeat the scripted part of an onboarding for a new team.
#
# Usage: ./repeat.sh TEAM PROJECT [--apply]
#
# Runs onboard.sh and apply-access.sh for the team, using the starter-tier
# ProjectType from Lab 4. Without --apply it checks the files and creates nothing.
# Scaffolding, deploying and promoting a service stay manual: log each of those
# with ../lab3-onboard/scripts/mark.sh so the scorecard counts them.
set -eu
here="$(cd "$(dirname "$0")" && pwd)"
[ $# -ge 2 ] || { sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }
team="$1"; project="$2"; shift 2
"$here/../lab3-onboard/onboard.sh" "$team" "$project" --project-type starter-tier "$@"
"$here/../lab4-roles-quota/apply-access.sh" "$team" "$@"
