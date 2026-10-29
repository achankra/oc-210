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
  lab4-roles-quota/build_starter_tier.py lab4-roles-quota/reference/starter-tier.yaml tests/fixtures/default-clusterprojecttype.yaml \
  lab3-onboard/scripts/bind-project.sh lab5-scaffold/create-order-service.sh \
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
for s in lab3-onboard/onboard.sh lab3-onboard/scripts/mark.sh lab3-onboard/scripts/bind-project.sh \
         lab4-roles-quota/apply-access.sh lab5-scaffold/check-endpoint.sh lab5-scaffold/create-order-service.sh \
         capstone/repeat.sh sandbox/restore.sh; do
  [ -x "$s" ] || bad "$s is not executable: chmod +x $s"
  check "$s parses" bash -n "$s"
done

echo "Lab 1: scorecard"
check "sample scorecard passes" python3 lab1-portal-scorecard/scorecard.py lab1-portal-scorecard/sample-scorecard.csv
fails "empty template is rejected" python3 lab1-portal-scorecard/scorecard.py lab1-portal-scorecard/scorecard-template.csv

echo "Lab 2: catalog check"
sed -e "s/REPLACE-WITH-AN-EXISTING-GROUP/platform-team/" -e "s/REPLACE-WITH-YOUR-PROJECT-NAME/default/" \
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
# onboard.sh with stand-ins for kubectl and occ, so it renders without a cluster
mkdir -p "$tmp/bin" "$tmp/space" "$tmp/team"
printf '#!/bin/sh\nexit 0\n' > "$tmp/bin/kubectl"; cp "$tmp/bin/kubectl" "$tmp/bin/occ"; chmod +x "$tmp/bin/kubectl" "$tmp/bin/occ"
DP="--dataplane-kind ClusterDataPlane --dataplane-name default"
# shellcheck disable=SC2086
( cd "$tmp/space" && PATH="$tmp/bin:$PATH" "$root/lab3-onboard/onboard.sh" team-x $DP >/dev/null 2>&1 )
check "onboard.sh TEAM renders the team space and no project" bash -c \
  "cd '$tmp/space/rendered/team-x' && [ -f namespace.yaml ] && [ -f environments.yaml ] && [ -f pipeline.yaml ] && [ ! -f project.yaml ] && [ ! -f bindings.yaml ]"
# shellcheck disable=SC2086
( cd "$tmp/team" && PATH="$tmp/bin:$PATH" "$root/lab3-onboard/onboard.sh" team-x x-shop $DP >/dev/null 2>&1 )
check "onboard.sh TEAM PROJECT renders all five files" bash -c \
  "cd '$tmp/team/rendered/team-x' && ls namespace.yaml environments.yaml pipeline.yaml project.yaml bindings.yaml"
fails "onboard.sh refuses an option in place of the team" "$root/lab3-onboard/onboard.sh" --apply

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
# The Python edit in the Lab 4 workbook step, taken from the workbook itself and run on a
# v1.3 export of the default ClusterProjectType: it must give the reference file
grep -v '^#' tests/fixtures/default-clusterprojecttype.yaml > "$tmp/starter-tier.yaml"
cp lab4-roles-quota/starter-tier-quota.yaml "$tmp/"
python3 - lab4-roles-quota/WORKBOOK-local.md > "$tmp/edit.py" <<'PY'
import sys
md = open(sys.argv[1]).read()
start = md.index('python3 -c "\nimport yaml\nd = yaml.safe_load(open(\'starter-tier.yaml\'))')
body = md[start + len('python3 -c "\n'):]
print(body[:body.index('\n"\n')])
PY
check "the Lab 4 workbook edit gives reference/starter-tier.yaml" bash -c \
  "cd '$tmp' && python3 edit.py && diff starter-tier.yaml '$root/lab4-roles-quota/reference/starter-tier.yaml'"

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
