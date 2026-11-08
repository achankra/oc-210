#!/usr/bin/env bash
# Create a team's group in ThunderID, the identity provider of the local install.
#
# Usage: scripts/create-group.sh GROUP
#
# The portal syncs ThunderID groups into the catalog as group:default/GROUP, which
# is what a project's backstage.io/owner annotation points at. The script calls the
# ThunderID management API with the installer's system application, as the
# installer's occ-login.sh does. Override with THUNDER_URL (for example
# http://thunder.openchoreo.localhost:8080), THUNDER_CLIENT_ID and
# THUNDER_CLIENT_SECRET.
#
# Running it again is safe: an existing group is left as it is. If ThunderID cannot
# be reached, the script says so and exits 0, because the owner annotation still
# works; the owner then shows without a link to a group.
set -eu
[ $# -eq 1 ] && [ "${1#-}" = "$1" ] || { sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }
GROUP="$1"
CLIENT_ID="${THUNDER_CLIENT_ID:-openchoreo-system-app}"
CLIENT_SECRET="${THUNDER_CLIENT_SECRET:-openchoreo-system-app-secret}"
URL="${THUNDER_URL:-}"
if [ -z "$URL" ]; then
  host="$(kubectl get httproute -n thunder thunder-httproute -o jsonpath='{.spec.hostnames[0]}' 2>/dev/null || true)"
  [ -n "$host" ] && URL="http://$host:8080"
fi

skip() {
  echo "Skipped the group $GROUP: $1" >&2
  echo "The owner annotation still works; the owner shows without a link to a group." >&2
  exit 0
}
field() {
  # field NAME   reads JSON on stdin and prints one top-level field
  python3 -c "import json,sys
try:
    d = json.load(sys.stdin)
    print(d.get('$1', '') if isinstance(d, dict) else '')
except Exception:
    pass"
}

[ -n "$URL" ] || skip "ThunderID not found (no thunder-httproute in namespace thunder)."

token="$(curl -s --max-time 10 -X POST "$URL/oauth2/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d grant_type=client_credentials -d "client_id=$CLIENT_ID" -d "client_secret=$CLIENT_SECRET" \
  -d scope=system -d "resource=$URL/mcp" | field access_token || true)"
[ -n "$token" ] || skip "no token from $URL for $CLIENT_ID."

ou="$(curl -s --max-time 10 -H "Authorization: Bearer $token" \
  "$URL/organization-units/tree/default" | field id || true)"
[ -n "$ou" ] || skip "could not read the default organization unit from $URL."

body="$(printf '{"name":"%s","description":"Owner group for %s","ouId":"%s"}' "$GROUP" "$GROUP" "$ou")"
code="$(curl -s --max-time 10 -o /dev/null -w '%{http_code}' -X POST "$URL/groups" \
  -H "Authorization: Bearer $token" -H "Content-Type: application/json" -d "$body" || true)"
case "$code" in
  201) echo "Created the group $GROUP in ThunderID. The catalog lists it as group:default/$GROUP after its next sync." ;;
  409) echo "The group $GROUP already exists in ThunderID." ;;
  *)   skip "ThunderID returned HTTP $code when creating it." ;;
esac
