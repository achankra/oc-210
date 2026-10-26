#!/usr/bin/env bash
# Call a deployed component through the data plane gateway and wait for it to answer.
#
# Usage: ./check-endpoint.sh ENVIRONMENT NAMESPACE ENDPOINT-NAME PATH [TRIES]
# Example: ./check-endpoint.sh development team-alpha order-service-http greeter/greet
#
# The host name follows the gateway pattern from the workbook:
#   {environment}-{namespace}.{GATEWAY_HOST}, path /{endpoint-name}/{path}
# Local install (default): http://{environment}-{namespace}.openchoreoapis.localhost:19080/...
# WSO2 sandbox: the session block sets GATEWAY_ADDR (the gateway's in-cluster address)
# and GATEWAY_HOST, and the script calls GATEWAY_ADDR with the host name as a Host header.
# To find the endpoint name and host: kubectl get httproutes -A
set -u

[ $# -ge 4 ] || { sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }
env_name="$1"; ns="$2"; endpoint="$3"; path="${4#/}"; tries="${5:-10}"
host="${GATEWAY_HOST:-openchoreoapis.localhost}"
port="${GATEWAY_PORT:-19080}"
vhost="${env_name}-${ns}.${host}"
if [ -n "${GATEWAY_ADDR:-}" ]; then
  url="http://${GATEWAY_ADDR}/${endpoint}/${path}"
  hdr=(-H "Host: ${vhost}")
  echo "GET $url  (Host: $vhost)"
else
  url="http://${vhost}:${port}/${endpoint}/${path}"
  hdr=()
  echo "GET $url"
fi

i=1
while [ "$i" -le "$tries" ]; do
  code=$(curl -s -o /dev/null --max-time 5 -w '%{http_code}' ${hdr[@]+"${hdr[@]}"} "$url" || true)
  case "$code" in
    2??) echo "HTTP $code on try $i"; curl -s --max-time 5 ${hdr[@]+"${hdr[@]}"} "$url"; echo; exit 0 ;;
    *)   echo "try $i of $tries: HTTP ${code:-000}" ;;
  esac
  i=$((i + 1)); sleep 3
done
echo "No successful answer. Check the endpoint name and host with: kubectl get httproutes -A" >&2
echo "A 404 usually means the endpoint name, path or host is wrong; 000 means nothing answered." >&2
exit 1
