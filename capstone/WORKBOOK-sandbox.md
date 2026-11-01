# Capstone: Onboard a team end to end

*OC-210 workbook, WSO2 sandbox edition (OpenChoreo v1.2.2). Using a local install instead? See [WORKBOOK-local.md](WORKBOOK-local.md).*

**Goal:** Onboard team-beta from nothing to a deployed, cataloged and governed service, through the portal. Measure the time, the commands and the tickets it took. A sandbox session is one hour, so start the capstone in a fresh session.

## Start of a sandbox session

Paste into the sandbox terminal in your browser, never into a terminal on your own machine. Skip this box if you are still in the session where you ran the previous lab; pasting it twice does no harm. In a new session, paste the setup block. It clones the lab code, sets up Python, and saves the gateway address for every later block.

```bash
setopt interactivecomments
grep -q interactivecomments ~/.zshrc || echo 'setopt interactivecomments' >> ~/.zshrc
[ -d ~/oc-210-labs ] || git clone https://github.com/achankra/oc-210.git ~/oc-210-labs
cd ~/oc-210-labs
python3 -m venv --without-pip --system-site-packages .venv
GWIP=$(kubectl get svc gateway-default -n openchoreo-data-plane -o jsonpath='{.spec.clusterIP}')
sed -i -e '/^export GWADDR=/d' -e '/^export DEVHOST=/d' -e '/^export GATEWAY_/d' ~/.zshrc
echo "export GWADDR=$GWIP:9080" >> ~/.zshrc
echo "export DEVHOST=development-default.demo.openchoreo.wso2.com" >> ~/.zshrc
echo "export GATEWAY_ADDR=$GWIP:9080" >> ~/.zshrc
echo "export GATEWAY_HOST=demo.openchoreo.wso2.com" >> ~/.zshrc
source ~/.zshrc
deactivate 2>/dev/null
source ~/oc-210-labs/.venv/bin/activate
echo "gateway $GWADDR"
python3 -c "import yaml; print('pyyaml ok')"
```

```bash
~/oc-210-labs/sandbox/restore.sh capstone
```

In a new session, the second block recreates the starter-tier type from Lab 4. Skip it if you ran Lab 4 in this session.

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

In your browser, open https://console.demo.openchoreo.wso2.com/create. Choose **Create** in the left menu (or https://console.demo.openchoreo.wso2.com/create). Sign in with `admin@openchoreo.dev` / `Admin@123`. Pick the Create Project template for **Starter tier**: the portal generates one for each ProjectType the platform team publishes. Fill in the namespace `team-beta`, the project name `beta-shop` and the deployment pipeline `team-beta-deployment-pipeline`, then choose **Create**. Field labels differ a little between portal versions; these three values are what matter. If the console's Create page has no Create Project template for this type, the sandbox's version predates the generated wizards. Create the same project through the API instead: `cd ~/oc-210-labs/lab3-onboard && ./onboard.sh team-beta beta-shop --project-type starter-tier --apply`.

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

Open https://console.demo.openchoreo.wso2.com/create, or choose **Create** in the left menu. Sign in with `admin@openchoreo.dev` / `Admin@123`. Pick the Create Component template for the **Service** type: the portal generates one for each ComponentType the platform team publishes. Fill in these values, then choose **Create**. Field labels differ a little between portal versions; the values are what matter.

| Field | Value |
|---|---|
| Namespace and project | `team-beta` · `beta-shop` |
| Component name | `order-service` |
| Source | Deploy from a pre-built image: `ghcr.io/openchoreo/samples/greeter-service:latest` |
| Endpoint | name `http`, type HTTP, port `9090`, visibility external |

If the console has no Create Component template for the Service type, create the same component through the API instead: `~/oc-210-labs/lab5-scaffold/create-order-service.sh team-beta beta-shop release-v1.2`. Then log it, call it and promote it:

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

In your browser, open https://console.demo.openchoreo.wso2.com/catalog. In the portal, check `order-service` under the beta-shop System and its owner.

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

The metrics and the seven-minute friction threshold come from The Platform Engineer's Handbook by Ajay Chankramath (Packt, 2025), Chapter 7. The book is not required for this course, but we recommend it to go deeper: [peh-packt.platformetrics.com](https://peh-packt.platformetrics.com) or [Amazon](https://www.amazon.com/dp/B0FR59Z7Q2).

## Checkpoint

- [ ] team-beta has a running, reachable service, created through the portal
- [ ] The catalog shows it with an owner
- [ ] Your time is under 15 minutes, or you can name the slow step

## Troubleshooting

- Stuck on one step: re-read the lab it came from and note the delay in the scorecard.
- The log is empty: run `ls ~/oc-210-labs/lab3-onboard/onboarding-log.csv`; every terminal block must start with that `cd`.
- No Starter tier wizard: run `kubectl get clusterprojecttypes`; run `~/oc-210-labs/sandbox/restore.sh capstone`.
- No cell namespaces for beta-shop: run `./scripts/bind-project.sh team-beta beta-shop`.
- `cell namespace` empty in the last step: wait a minute for the ProjectReleaseBinding, then run the block again.

---

Previous: [Lab 5](../lab5-scaffold/WORKBOOK-sandbox.md) · [All modules](../WORKBOOK.md)
