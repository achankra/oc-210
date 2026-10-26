#!/usr/bin/env bash
# Check the lab code without a cluster, before a cohort or after a change.
#
# Usage: ./tests/check-repo.sh
#
# It checks that every file the workbooks use is in the repository, that the
# scripts parse, and that the Python programs, templates and the Lab 4 quota
# edit give the results the workbooks describe. It writes only to a temporary
# folder. Needs python3 with PyYAML (source .venv/bin/activate first).
set -u
cd "$(dirname "$0")/.."
root="$(pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
pass=0; fail=0
ok()  { pass=$((pass + 1)); echo "  ok    $1"; }
bad() { fail=$((fail + 1)); echo "  FAIL  $1"; }
check() { local name="$1"; shift; if "$@" >"$tmp/out" 2>&1; then ok "$name"; else bad "$name"; sed 's/^/        /' "$tmp/out" | head -8; fi; }
fails() { local name="$1"; shift; if "$@" >"$tmp/out" 2>&1; then bad "$name (expected a failure)"; else ok "$name"; fi; }

echo "Files the workbooks use"
for f in \
  WORKBOOK.md prework/WORKBOOK-local.md prework/WORKBOOK-sandbox.md sandbox/restore.sh sandbox/README.md \
  {lab1-portal-scorecard,lab2-catalog-check,lab3-onboard,lab4-roles-quota,lab5-scaffold,capstone}/WORKBOOK-sandbox.md \
  lab4-roles-quota/build_starter_tier.py tests/fixtures/default-clusterprojecttype.yaml \
  lab1-portal-scorecard/{WORKBOOK-local.md,scorecard.py,sample-scorecard.csv,scorecard-template.csv} \
  lab2-catalog-check/{WORKBOOK-local.md,catalog_check.py,catalog/pilot-docs-site.yaml,catalog/billing-api.yaml,catalog/orphan-service.yaml} \
  lab3-onboard/{WORKBOOK-local.md,onboard.sh,scripts/mark.sh,scripts/lib.sh,scripts/render.py} \
  lab3-onboard/templates/{namespace,environments,pipeline,project,bindings}.yaml \
  lab4-roles-quota/{WORKBOOK-local.md,apply-access.sh,check_quota.py,starter-tier-quota.yaml,templates/role.yaml,templates/binding.yaml,samples/quota-starter.json,samples/quota-wrong.json} \
  lab5-scaffold/{WORKBOOK-local.md,check-endpoint.sh} \
  capstone/{WORKBOOK-local.md,onboarding_scorecard.py,repeat.sh}; do
  [ -f "$f" ] && ok "$f" || bad "$f is missing"
done

echo "Workbook links"
for wb in WORKBOOK.md */WORKBOOK-local.md */WORKBOOK-sandbox.md; do
  dir="$(dirname "$wb")"
  for link in $(grep -oE '\]\([^)#: ]+\)' "$wb" | sed -E 's/^\]\(//; s/\)$//'); do
    [ -e "$dir/$link" ] || bad "$wb links to $link, which does not exist"
  done
done
ok "relative links checked"

echo "Scripts"
for s in lab3-onboard/onboard.sh lab3-onboard/scripts/mark.sh lab4-roles-quota/apply-access.sh \
         lab5-scaffold/check-endpoint.sh capstone/repeat.sh sandbox/restore.sh; do
  [ -x "$s" ] || bad "$s is not executable: chmod +x $s"
  check "$s parses" bash -n "$s"
done

echo "Lab 1: scorecard"
check "sample scorecard passes" python3 lab1-portal-scorecard/scorecard.py lab1-portal-scorecard/sample-scorecard.csv
fails "empty template is rejected" python3 lab1-portal-scorecard/scorecard.py lab1-portal-scorecard/scorecard-template.csv

echo "Lab 2: catalog check"
sed -e "s/REPLACE-WITH-AN-EXISTING-GROUP/platform-team/" -e "s/REPLACE-WITH-YOUR-PROJECT-NAME/team-alpha-pilot/" \
  lab2-catalog-check/catalog/pilot-docs-site.yaml > "$tmp/pilot-docs-site.yaml"
check "filled-in entry is complete" python3 lab2-catalog-check/catalog_check.py --strict "$tmp/pilot-docs-site.yaml"
check "billing-api is complete" python3 lab2-catalog-check/catalog_check.py --strict lab2-catalog-check/catalog/billing-api.yaml
fails "orphan-service is incomplete" python3 lab2-catalog-check/catalog_check.py --strict lab2-catalog-check/catalog/orphan-service.yaml

echo "Lab 3: templates and timing log"
VARS="TEAM=team-demo PROJECT=demo-shop TIER=starter PROJECT_TYPE=default PROJECT_TYPE_KIND=ClusterProjectType DATAPLANE_KIND=ClusterDataPlane DATAPLANE_NAME=default"
for t in namespace environments pipeline project bindings; do
  # shellcheck disable=SC2086
  if python3 lab3-onboard/scripts/render.py lab3-onboard/templates/$t.yaml $VARS > "$tmp/$t.yaml" \
     && ! grep -q '\${' "$tmp/$t.yaml" \
     && python3 -c "import sys,yaml; list(yaml.safe_load_all(open(sys.argv[1])))" "$tmp/$t.yaml"; then
    ok "$t.yaml renders to valid YAML"
  else
    bad "$t.yaml does not render"
  fi
done
fails "render.py refuses a missing value" python3 lab3-onboard/scripts/render.py lab3-onboard/templates/project.yaml TEAM=x
( cd "$tmp" && "$root/lab3-onboard/scripts/mark.sh" start "occ login" >/dev/null \
  && sleep 1 && "$root/lab3-onboard/scripts/mark.sh" namespace "kubectl create namespace" >/dev/null )
check "onboarding_scorecard.py reads a mark.sh log" python3 capstone/onboarding_scorecard.py "$tmp/onboarding-log.csv" --tickets 0

echo "Lab 4: role, binding, quota"
for t in role binding; do
  if python3 lab3-onboard/scripts/render.py lab4-roles-quota/templates/$t.yaml TEAM=team-alpha > "$tmp/$t.yaml" \
     && python3 -c "import sys,yaml; yaml.safe_load(open(sys.argv[1]))" "$tmp/$t.yaml"; then
    ok "$t.yaml renders to valid YAML"
  else
    bad "$t.yaml does not render"
  fi
done
check "starter quota sample passes" python3 lab4-roles-quota/check_quota.py lab4-roles-quota/samples/quota-starter.json
fails "wrong quota sample is flagged" python3 lab4-roles-quota/check_quota.py lab4-roles-quota/samples/quota-wrong.json
# The same edit as the Lab 4 step, run on a v1.3.1 export of the default ClusterProjectType
cp tests/fixtures/default-clusterprojecttype.yaml "$tmp/starter-tier.yaml"
cp lab4-roles-quota/starter-tier-quota.yaml "$tmp/"
check "Lab 4 edit builds a starter-tier ProjectType with the quota" bash -c "cd '$tmp' && python3 -c \"
import yaml
d = yaml.safe_load(open('starter-tier.yaml'))
m = d['metadata']
for k in ('uid', 'resourceVersion', 'creationTimestamp', 'generation', 'managedFields', 'ownerReferences', 'annotations'):
    m.pop(k, None)
d.pop('status', None)
m['name'] = 'starter-tier'
m['labels'] = {'openchoreo.dev/name': 'starter-tier'}
res = d['spec']['resources']
ns = next(r for r in res if r['id'] == 'cell-namespace')
q = yaml.safe_load(open('starter-tier-quota.yaml'))
q['metadata']['namespace'] = ns['template']['metadata']['name']
res.append({'id': 'starter-tier-quota', 'targetPlane': ns.get('targetPlane', 'dataplane'), 'template': q})
yaml.safe_dump(d, open('starter-tier.yaml', 'w'), sort_keys=False)
d = yaml.safe_load(open('starter-tier.yaml'))
assert d['metadata']['name'] == 'starter-tier'
qr = [r for r in d['spec']['resources'] if r['id'] == 'starter-tier-quota'][0]
assert qr['template']['kind'] == 'ResourceQuota'
assert len(qr['template']['spec']['hard']) == 7
assert qr['template']['metadata']['namespace'] == '\\\${metadata.namespace}'
\""

grep -v '^#' tests/fixtures/default-clusterprojecttype.yaml > "$tmp/default.yaml"
check "build_starter_tier.py (sandbox restore) matches reference/starter-tier.yaml" bash -c \
  "python3 lab4-roles-quota/build_starter_tier.py '$tmp/default.yaml' lab4-roles-quota/starter-tier-quota.yaml | diff - lab4-roles-quota/reference/starter-tier.yaml"

echo "Lab 5: endpoint helper"
fails "check-endpoint.sh prints usage without arguments" lab5-scaffold/check-endpoint.sh
lab5-scaffold/check-endpoint.sh development team-alpha order-service-http greeter/greet 1 > "$tmp/local.txt" 2>&1
check "local URL is {env}-{namespace}.openchoreoapis.localhost:19080" \
  grep -q "GET http://development-team-alpha.openchoreoapis.localhost:19080/order-service-http/greeter/greet" "$tmp/local.txt"
GATEWAY_ADDR=127.0.0.1:9 GATEWAY_HOST=demo.openchoreo.wso2.com \
  lab5-scaffold/check-endpoint.sh development team-alpha order-service-http greeter/greet 1 > "$tmp/sandbox.txt" 2>&1
check "sandbox call goes to GATEWAY_ADDR with the Host header" \
  grep -q "GET http://127.0.0.1:9/order-service-http/greeter/greet  (Host: development-team-alpha.demo.openchoreo.wso2.com)" "$tmp/sandbox.txt"

echo "Sandbox"
fails "restore.sh refuses an unknown lab" sandbox/restore.sh lab9
check "sandbox workbooks use the v1.2 samples only" bash -c "! grep -l 'release-v1.3' */WORKBOOK-sandbox.md"
awk '/^```/{inblock=!inblock; next} inblock' */WORKBOOK-sandbox.md > "$tmp/sandbox-code.txt"
check "sandbox code blocks have no local-only commands" bash -c "! grep -nE 'openchoreoapis.localhost|occ login|brew install|xdg-open|^open ' '$tmp/sandbox-code.txt'"

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
