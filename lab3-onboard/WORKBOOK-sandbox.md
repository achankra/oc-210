# Lab 3: Onboard a team through the portal

*OC-210 workbook, WSO2 sandbox edition (OpenChoreo v1.2.2). Using a local install instead? See [WORKBOOK-local.md](WORKBOOK-local.md).*

**Goal:** Replace a ticket queue with self-service. As the platform team, set up a team's space in one command; as the team, create your own project in the portal's Create Project wizard and get its cells. Time it, then see the API underneath and onboard a second team with it.

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

## A. The platform team sets up the space

### 1. Start the clock

Every command in this lab runs in `~/oc-210-labs/lab3-onboard`, so the timing log stays in one place.

```bash
cd ~/oc-210-labs/lab3-onboard
rm -f onboarding-log.csv
./scripts/mark.sh "start" "onboarding begins"
```

The first `mark.sh` call creates the log and starts the clock. Each step below ends with a logged line.

### 2. Create the team space

> **Dry run first:** the block checks with a server-side dry run before it changes anything.

A team space is what the platform team owns: a namespace with the control-plane, owner and tier labels (the Handbook's `team-{teamname}` convention), development and staging environments on the cluster's data plane, and a pipeline that promotes development to staging. The script checks first; `--apply` creates them and logs each command.

```bash
cd ~/oc-210-labs/lab3-onboard
./onboard.sh team-alpha
./onboard.sh team-alpha --apply
kubectl get namespace team-alpha --show-labels
occ namespace list
```

With a team name only, the script creates the space and no project: the team creates that itself, next. `team-alpha` now appears in `occ namespace list` and, as a Domain, in the portal.

## B. The team creates its project

### 3. Create the project from the portal wizard

In your browser, open https://console.demo.openchoreo.wso2.com/create. Choose **Create** in the left menu (or https://console.demo.openchoreo.wso2.com/create). Sign in with `admin@openchoreo.dev` / `Admin@123`. Pick the Create Project template for **Default Project Type**: the portal generates one for each ProjectType the platform team publishes. Fill in the namespace `team-alpha`, the project name `alpha-shop` and the deployment pipeline `team-alpha-deployment-pipeline`, then choose **Create**. Field labels differ a little between portal versions; these three values are what matter. If the console's Create page has no Create Project template for this type, the sandbox's version predates the generated wizards. Create the same project through the API instead: `cd ~/oc-210-labs/lab3-onboard && ./onboard.sh team-alpha alpha-shop --apply`.

```bash
cd ~/oc-210-labs/lab3-onboard
./scripts/mark.sh "project" "portal: Create Project, alpha-shop"
```

### 4. Check the cells and stop the clock

```bash
cd ~/oc-210-labs/lab3-onboard
occ project list -n team-alpha
kubectl get projectreleasebindings -n team-alpha
kubectl get namespaces -l openchoreo.dev/project=alpha-shop -L openchoreo.dev/environment
./scripts/mark.sh "verify" "occ project list -n team-alpha"
python3 ../capstone/onboarding_scorecard.py onboarding-log.csv
```

The wizard creates a ProjectReleaseBinding for each environment in the pipeline, so `alpha-shop` gets a cell namespace in development and in staging. If the bindings list is empty, run `./scripts/bind-project.sh team-alpha alpha-shop` and look again. Find `alpha-shop` in the portal under the team-alpha Domain. The last line prints your time per step and the total; write the total down.

## C. The API underneath

### 5. Read what the wizard created

The portal's wizard calls the same OpenChoreo API that occ uses (its scaffolder action is `openchoreo:project:create`). Compare the project it created with the template the script uses.

```bash
cd ~/oc-210-labs/lab3-onboard
kubectl get project alpha-shop -n team-alpha -o yaml | head -25
cat templates/project.yaml
kubectl get projectreleasebinding -n team-alpha -o name
```

The same few fields: a name, a namespace, a pipeline and a ProjectType. The bindings are what give the project its cells; a project applied with `kubectl` gets none, which is why the script also renders `templates/bindings.yaml`.

### 6. Onboard a second team through the API

When onboarding needs to run without a person, for example from an HR system or a chatbot, the same objects come from the API. The script does it in one command, project and bindings included.

```bash
cd ~/oc-210-labs/lab3-onboard
./onboard.sh team-demo demo-shop
./onboard.sh team-demo demo-shop --apply
occ project list -n team-demo
ls rendered/team-demo/
```

Portal and script produce the same objects through the same API. The portal is the self-service path for people; the API is the path for automation.

## Checkpoint

- [ ] `occ namespace list` shows `team-alpha` and `team-demo`
- [ ] `alpha-shop`, created in the portal, has a cell namespace in development and staging
- [ ] You have a recorded onboarding time from `onboarding_scorecard.py`

## Troubleshooting

- `team-alpha` missing from the namespace list in the wizard: run `kubectl get namespace team-alpha --show-labels`; it needs `openchoreo.dev/control-plane=true`. Then wait a minute for the portal to refresh.
- No pipeline to pick in the wizard: run `kubectl get deploymentpipelines -n team-alpha`; run `./onboard.sh team-alpha --apply` again if it is missing.
- No cell namespaces for the project: run `./scripts/bind-project.sh team-alpha alpha-shop`.
- `onboard.sh` cannot read the data plane: run `kubectl get environment development -n default -o yaml | grep -A3 dataPlaneRef`.
- The wizard reports an error after Create: the project may still have been created. Run `occ project list -n team-alpha` before trying again.

---

Previous: [Lab 2](../lab2-catalog-check/WORKBOOK-sandbox.md) · [All modules](../WORKBOOK.md) · Next: [Lab 4](../lab4-roles-quota/WORKBOOK-sandbox.md)
