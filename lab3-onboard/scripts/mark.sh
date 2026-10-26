#!/usr/bin/env bash
# Log a step you ran by hand, so the scorecard counts it.
#
# Usage: scripts/mark.sh "step name" ["the command you ran"]
# The first call creates the log and starts the clock.
set -eu
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/lib.sh"
[ $# -ge 1 ] || { echo 'Usage: scripts/mark.sh "step name" ["command"]' >&2; exit 1; }
log_row "$1" "${2:-}"
echo "Logged: $1"
