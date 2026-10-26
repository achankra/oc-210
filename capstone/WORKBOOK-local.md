# Capstone: Onboard a team end to end

*OC-210 workbook, local install edition (OpenChoreo v1.3.1 on k3d). Using the WSO2 sandbox instead? See [WORKBOOK-sandbox.md](WORKBOOK-sandbox.md).*

**Goal:** Onboard team-beta from nothing to a deployed, cataloged and governed service. Measure the time, the commands and the tickets it took.

| Step | What | Done |
|---|---|---|
| 1 | Namespace with control-plane, owner and tier labels (team-beta) | ☐ |
| 2 | Environments and pipeline for team-beta | ☐ |
| 3 | team-developer role and binding for team-beta-developers | ☐ |
| 4 | Project from the starter-tier ProjectType | ☐ |
| 5 | Scaffold, deploy and promote a service | ☐ |
| 6 | Confirm the catalog entry and the quota in the cell | ☐ |

### 1. Start the clock

Work in pairs: one drives, one reads the checklist. Every command runs from `~/oc-210-labs/lab3-onboard`, so the scripts and `mark.sh` write to one log.

```bash
cd ~/oc-210-labs/lab3-onboard
rm -f onboarding-log.csv
./scripts/mark.sh "start" "capstone begins"
```

### 2. Create the namespace, environments, pipeline and project

```bash
cd ~/oc-210-labs/lab3-onboard
./onboard.sh team-beta beta-shop --project-type starter-tier --apply
```

### 3. Apply the role and binding

```bash
cd ~/oc-210-labs/lab3-onboard
../lab4-roles-quota/apply-access.sh team-beta --apply
```

### 4. Scaffold, deploy and promote a service

```bash
cd ~/oc-210-labs/lab3-onboard
BASE=https://raw.githubusercontent.com/openchoreo/openchoreo/release-v1.3/samples
curl -fsSL $BASE/from-image/go-greeter-service/greeter-service.yaml \
  | sed -e 's/ame: greeter-service/ame: order-service/' \
        -e 's/namespace: default/namespace: team-beta/' \
        -e 's/projectName: default/projectName: beta-shop/' \
  > order-service.yaml
occ apply -f order-service.yaml
occ component deploy order-service --to development -n team-beta -p beta-shop
./scripts/mark.sh "deploy" "occ component deploy order-service --to development"
../lab5-scaffold/check-endpoint.sh development team-beta order-service-http greeter/greet 40
occ component deploy order-service --to staging -n team-beta -p beta-shop
./scripts/mark.sh "promote" "occ component deploy order-service --to staging"
```

### 5. Confirm

```bash
cd ~/oc-210-labs/lab3-onboard
occ namespace list
occ project list -n team-beta
kubectl get releasebindings -n team-beta
CELL=$(kubectl get namespaces \
  -l openchoreo.dev/project=beta-shop,openchoreo.dev/environment=development \
  -o jsonpath='{.items[0].metadata.name}')
kubectl get resourcequota -n $CELL -o json | python3 ../lab4-roles-quota/check_quota.py
./scripts/mark.sh "confirm" "check_quota.py"
```

**macOS**

```bash
open http://openchoreo.localhost:8080/catalog
```

**Linux**

```bash
xdg-open http://openchoreo.localhost:8080/catalog
```

**Windows, in the WSL 2 Ubuntu terminal**

```bash
explorer.exe http://openchoreo.localhost:8080/catalog
```

In the portal, check `order-service` under the beta-shop System and its owner.

### 6. Read the scorecard

| Metric (Handbook) | Your Value |
|---|---|
| Time-to-first-deploy (minutes) |  |
| Commands run |  |
| Tickets created | 0 |
| Slowest step and why |  |
| Under the 15-minute goal? Any step over the seven-minute friction threshold? |  |

```bash
cd ~/oc-210-labs/lab3-onboard
python3 ../capstone/onboarding_scorecard.py onboarding-log.csv --tickets 0
```

Copy the numbers into the scorecard table. The time between two logged rows counts against the later step, so waiting before a step counts against that step.

## Checkpoint

- [ ] team-beta has a running, reachable service
- [ ] The catalog shows it with an owner
- [ ] Your time is under 15 minutes, or you can name the slow step

## Troubleshooting

- Stuck on one step: re-read the lab it came from and note the delay in the scorecard.
- The log is empty: run `ls ~/oc-210-labs/lab3-onboard/onboarding-log.csv`; every block must start with that `cd`.
- `starter-tier` not found: run `kubectl get clusterprojecttypes`; repeat Lab 4 step 5 if it is missing.
- `cell namespace` empty in step 6: wait a minute for the ProjectReleaseBinding, then run the block again.

---

Previous: [Lab 5](../lab5-scaffold/WORKBOOK-local.md) · [All modules](../WORKBOOK.md)
