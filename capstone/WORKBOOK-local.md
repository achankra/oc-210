# Capstone: Onboard a team end to end

*OC-210 workbook, local install edition (OpenChoreo v1.3.2 on k3d). Using the WSO2 sandbox instead? See [WORKBOOK-sandbox.md](WORKBOOK-sandbox.md).*

**Goal:** Onboard team-beta from nothing to a deployed, cataloged and governed service, through the portal. Measure the time, the commands and the tickets it took.

| Step | What | Where | Done |
|---|---|---|---|
| 1 | Team space: namespace, environments, pipeline (platform team) | `onboard.sh` | ☐ |
| 2 | Project `beta-shop` from the Starter tier wizard | Portal | ☐ |
| 3 | team-developer role and binding for team-beta-developers | `apply-access.sh` | ☐ |
| 4 | Service `order-service` from the Service wizard, deployed and promoted | Portal | ☐ |
| 5 | The catalog entry, its owner and the quota in the cell | Portal and terminal | ☐ |

### 1. Start the clock

Work in pairs: one drives, one reads the checklist. Every terminal block runs from `~/oc-210-labs/lab3-onboard`, so the scripts and `mark.sh` write to one log.

```bash
cd ~/oc-210-labs/lab3-onboard
rm -f onboarding-log.csv
./scripts/mark.sh "start" "capstone begins"
```

### 2. Create the team space

```bash
cd ~/oc-210-labs/lab3-onboard
./onboard.sh team-beta --apply
```

### 3. Create beta-shop from the Starter tier wizard

**macOS**

```bash
open http://openchoreo.localhost:8080/create
```

**Linux**

```bash
xdg-open http://openchoreo.localhost:8080/create
```

**Windows, in the WSL 2 Ubuntu terminal**

```bash
explorer.exe http://openchoreo.localhost:8080/create
```

Choose **Create** in the left menu (or http://openchoreo.localhost:8080/create). Sign in with `admin@openchoreo.dev` / `Admin@123`. Under Application Resources, open the **Project** card (Browse project templates) and pick the template for **Starter tier**: the portal generates one for each ProjectType the platform team publishes. Fill in the namespace `team-beta`, the project name `beta-shop` and the deployment pipeline `team-beta-deployment-pipeline`, then choose **Create**. Field labels differ a little between portal versions; these three values are what matter.

```bash
cd ~/oc-210-labs/lab3-onboard
./scripts/mark.sh "project" "portal: Create Project, beta-shop"
kubectl get projectreleasebindings -n team-beta
```

### 4. Apply the role and binding

```bash
cd ~/oc-210-labs/lab3-onboard
../lab4-roles-quota/apply-access.sh team-beta --apply
```

### 5. Create, call and promote order-service

Open http://openchoreo.localhost:8080/create, or choose **Create** in the left menu. Sign in with `admin@openchoreo.dev` / `Admin@123`. Under Application Resources, open the **Component** card (Browse component templates) and pick the template for the **Service** type: the portal generates one for each ComponentType the platform team publishes. Fill in these values, then choose **Create**. Field labels differ a little between portal versions; the values are what matter.

| Field | Value |
|---|---|
| Namespace and project | `team-beta` · `beta-shop` |
| Component name | `order-service` |
| Source | Deploy from a pre-built image: `ghcr.io/openchoreo/samples/greeter-service:latest` |
| Endpoint | name `http`, type HTTP, port `9090`, visibility external |

Then log it, call it and promote it:

```bash
cd ~/oc-210-labs/lab3-onboard
./scripts/mark.sh "service" "portal: Create Component, order-service"
../lab5-scaffold/check-endpoint.sh development team-beta order-service-http greeter/greet 40
occ component deploy order-service --to staging -n team-beta -p beta-shop
./scripts/mark.sh "promote" "occ component deploy order-service --to staging"
../lab5-scaffold/check-endpoint.sh staging team-beta order-service-http greeter/greet 40
```

### 6. Confirm

```bash
cd ~/oc-210-labs/lab3-onboard
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

### 7. Read the scorecard

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

Copy the numbers into the scorecard table. The time between two logged rows counts against the later step, so time spent in the portal counts against the step you log after it.

The metrics and the seven-minute friction threshold come from The Platform Engineer's Handbook by Ajay Chankramath (Packt, 2026), Chapter 7. The book is not required for this course, but we recommend it to go deeper: [peh-packt.platformetrics.com](https://peh-packt.platformetrics.com) or [Amazon](https://www.amazon.com/dp/B0FR59Z7Q2).

### 8. Check the audit trail

The clock has stopped. Choose **Audit Logs** in the portal's left menu and find team-beta's changes: the environments and pipeline that `onboard.sh` applied with `occ`, `beta-shop` from the wizard, the role and binding, `order-service`, and its promotion to staging. Each entry names who made the change and whether it was allowed.

One change is missing: the namespace. `onboard.sh` creates it with `kubectl`, which does not go through the OpenChoreo API, so the audit log never sees it. Anything a team should be able to audit has to go through the API: the portal, `occ`, or an agent through MCP.

## Checkpoint

- [ ] team-beta has a running, reachable service, created through the portal
- [ ] The catalog shows it with an owner
- [ ] Your time is under 15 minutes, or you can name the slow step
- [ ] Audit Logs shows team-beta's changes, and you can say why the namespace is not among them

## Troubleshooting

- Stuck on one step: re-read the lab it came from and note the delay in the scorecard.
- The log is empty: run `ls ~/oc-210-labs/lab3-onboard/onboarding-log.csv`; every terminal block must start with that `cd`.
- No Starter tier wizard: run `kubectl get clusterprojecttypes`; repeat Lab 4 part B if `starter-tier` is missing.
- No cell namespaces for beta-shop: run `./scripts/bind-project.sh team-beta beta-shop`.
- `cell namespace` empty in the last step: wait a minute for the ProjectReleaseBinding, then run the block again.

---

Previous: [Lab 5](../lab5-scaffold/WORKBOOK-local.md) · [All modules](../WORKBOOK.md)
