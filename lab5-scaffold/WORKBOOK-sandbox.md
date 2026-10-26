# Lab 5: Scaffold and deploy

*OC-210 workbook, WSO2 sandbox edition (OpenChoreo v1.2.2). Using a local install instead? See [WORKBOOK-local.md](WORKBOOK-local.md).*

**Goal:** Start a new service from a scaffold, deploy it into the team's project, view it in the portal catalog and promote it.

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
~/oc-210-labs/sandbox/restore.sh lab5
```

In a new session, the second block recreates team-alpha from Lab 3 and the starter-tier type and alpha-pilot project from Lab 4. Skip it if you ran Lab 4 in this session.

## A. Scaffold

### 1. Scaffold a component into the team project

> **Verify:** flags can differ between versions. If this fails, run the command with `--help`.

```bash
mkdir -p ~/oc-210-labs/lab5-work && cd ~/oc-210-labs/lab5-work
occ component scaffold order-service -n team-alpha -p alpha-pilot \
  --clustercomponenttype deployment/service -o order-service-scaffold.yaml
cat order-service-scaffold.yaml
```

Identify the ComponentType reference, the workload (container image, endpoints) and any traits. Required fields are placeholders. A `deployment/service` component needs at least one endpoint.

## B. Adjust and apply

### 2. Write the component and deploy to development

> **Verify:** flags can differ between versions. If this fails, run the command with `--help`.

Fill the scaffold's placeholders with a known-good image: the greeter sample, named `order-service`, in team-alpha's `alpha-pilot` project.

```bash
cd ~/oc-210-labs/lab5-work
BASE=https://raw.githubusercontent.com/openchoreo/openchoreo/release-v1.2/samples
curl -fsSL $BASE/from-image/go-greeter-service/greeter-service.yaml \
  | sed -e 's/ame: greeter-service/ame: order-service/' \
        -e 's/namespace: default/namespace: team-alpha/' \
        -e 's/projectName: default/projectName: alpha-pilot/' \
  > order-service.yaml
grep -n -E "name:|namespace:|projectName|image" order-service.yaml
kubectl apply --dry-run=server -f order-service.yaml
occ apply -f order-service.yaml
occ component deploy order-service --to development -n team-alpha -p alpha-pilot
```

Compare `order-service.yaml` with `order-service-scaffold.yaml`: the same ComponentType reference, now with an image and an endpoint.

## C. Deploy and call

### 3. Call the endpoint

```bash
kubectl get releasebindings -n team-alpha
kubectl get httproutes -A -l openchoreo.dev/component=order-service
cd ~/oc-210-labs/lab5-scaffold
./check-endpoint.sh development team-alpha order-service-http greeter/greet 40
```

The script builds the host name `development-team-alpha.demo.openchoreo.wso2.com`, calls the gateway inside the cluster with it, retries while the deployment becomes ready, and prints `Hello, Stranger!`.

## D. Catalog and promote

### 4. Promote and call staging

```bash
occ component deploy order-service --to staging -n team-alpha -p alpha-pilot
kubectl get releasebindings -n team-alpha
cd ~/oc-210-labs/lab5-scaffold
./check-endpoint.sh staging team-alpha order-service-http greeter/greet 40
```

In your browser, open https://console.demo.openchoreo.wso2.com/catalog. In the portal, open `order-service` under the alpha-pilot System and check its deployments.

### 5. Optional: create a component from the portal wizard

In your browser, open https://console.demo.openchoreo.wso2.com/create.

Compare the YAML it produces with your scaffold. The portal's scaffolder actions (`openchoreo:component:create` and related) generate the same resources.

## Checkpoint

- [ ] The component answers through the gateway in development and in staging
- [ ] It appears in the portal under the alpha-pilot System
- [ ] A staging ReleaseBinding exists

## Troubleshooting

- Deploy command rejected: run `occ component deploy --help`.
- 404 from `check-endpoint.sh`: run `kubectl get httproute -A -l openchoreo.dev/component=order-service -o yaml | grep -A3 path:`.
- Quota error on the pod: run `kubectl describe resourcequota -n $(kubectl get deployment -A -l openchoreo.dev/component=order-service -o jsonpath='{.items[0].metadata.namespace}')`.
- Staging not available: run `kubectl get deploymentpipeline -n team-alpha -o yaml`; it must promote development to staging (Lab 3).
- `check-endpoint.sh` prints a full localhost URL: `GATEWAY_ADDR` is not set. Run the setup block again.
- 404 with the right path: compare the host with `kubectl get httproute -A -l openchoreo.dev/component=order-service -o jsonpath='{..hostnames}'`. If the suffix differs, set it for the session: `export GATEWAY_HOST=<the part after the namespace>`.
- `unknown command "deploy"`: occ 1.2.0 may name it differently. Run `occ component --help`, or promote in the console from the component's Deploy page.

---

Previous: [Lab 4](../lab4-roles-quota/WORKBOOK-sandbox.md) · [All modules](../WORKBOOK.md) · Next: [Capstone](../capstone/WORKBOOK-sandbox.md)
