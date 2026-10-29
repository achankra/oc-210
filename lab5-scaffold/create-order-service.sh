#!/usr/bin/env bash
# Create order-service through the API: the same component the portal's
# Create Component wizard makes, for when the wizard is not available.
#
# Usage: ./create-order-service.sh NAMESPACE PROJECT [SAMPLES_BRANCH]
# Example: ./create-order-service.sh team-alpha alpha-pilot
#
# It takes the OpenChoreo greeter sample (a pre-built image with one HTTP
# endpoint on port 9090), renames it order-service, places it in the project,
# checks it with a server-side dry run and applies it with occ.
# SAMPLES_BRANCH defaults to release-v1.3; the WSO2 sandbox uses release-v1.2.
set -eu
[ $# -ge 2 ] || { sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }
NS="$1"; PROJECT="$2"; BRANCH="${3:-release-v1.3}"
BASE="https://raw.githubusercontent.com/openchoreo/openchoreo/$BRANCH/samples"
out="$(mktemp -d)"
trap 'rm -rf "$out"' EXIT
curl -fsSL "$BASE/from-image/go-greeter-service/greeter-service.yaml" \
  | sed -e 's/ame: greeter-service/ame: order-service/' \
        -e "s/namespace: default/namespace: $NS/" \
        -e "s/projectName: default/projectName: $PROJECT/" \
  > "$out/order-service.yaml"
grep -n -E "name:|namespace:|projectName|image" "$out/order-service.yaml"
kubectl apply --dry-run=server -f "$out/order-service.yaml"
occ apply -f "$out/order-service.yaml"
kubectl wait --for=condition=Ready "component/order-service" -n "$NS" --timeout=180s
