# Lab 5: Create a service from the portal

*OC-210 workbook, WSO2 sandbox edition (OpenChoreo v1.2.2). Using a local install instead? See [WORKBOOK-local.md](WORKBOOK-local.md).*

**Goal:** Use the portal's Create Component wizard, which the service ComponentType generates, to create a service in the team's project. Call it, find it in the catalog, promote it, then read the files the API underneath works with.

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

## A. Starter kits are component types

### 1. See the types and their wizards

```bash
kubectl get clustercomponenttypes
```

In your browser, open https://console.demo.openchoreo.wso2.com/create. Sign in with `admin@openchoreo.dev` / `Admin@123`. On the Create page, open the **Component** card under Application Resources: each ComponentType has its own template there, service, web application, scheduled task and worker. A platform team adds a starter kit by publishing a type, not by writing a template.

## B. Create the service

### 2. Create order-service from the Service wizard

Open https://console.demo.openchoreo.wso2.com/create, or choose **Create** in the left menu. Sign in with `admin@openchoreo.dev` / `Admin@123`. Under Application Resources, open the **Component** card (Browse component templates) and pick the template for the **Service** type: the portal generates one for each ComponentType the platform team publishes. Fill in these values, then choose **Create**. Field labels differ a little between portal versions; the values are what matter.

| Field | Value |
|---|---|
| Namespace and project | `team-alpha` · `alpha-pilot` |
| Component name | `order-service` |
| Source | Deploy from a pre-built image: `ghcr.io/openchoreo/samples/greeter-service:latest` |
| Endpoint | name `http`, type HTTP, port `9090`, visibility external |

If the console has no Service template under the Component card, create the same component through the API instead: `~/oc-210-labs/lab5-scaffold/create-order-service.sh team-alpha alpha-pilot release-v1.2`.

### 3. Check it and call it

```bash
kubectl get component order-service -n team-alpha
kubectl wait --for=condition=Ready component/order-service -n team-alpha --timeout=180s
kubectl get releasebindings -n team-alpha
kubectl get releasebinding order-service-development -n team-alpha \
  -o jsonpath='{.status.endpoints}{"\n"}'
cd ~/oc-210-labs/lab5-scaffold
./check-endpoint.sh development team-alpha order-service-http greeter/greet 40
```

The script builds the host name `development-team-alpha.demo.openchoreo.wso2.com`, calls the gateway inside the cluster with it, retries while the deployment becomes ready, and prints `Hello, Stranger!`. If there is no `order-service-development` binding, deploy it: `occ component deploy order-service --to development -n team-alpha -p alpha-pilot`.

## C. Catalog and promote

### 4. Find it in the catalog and promote it to staging

In your browser, open https://console.demo.openchoreo.wso2.com/catalog. Open `order-service` under the alpha-pilot System and check its owner and its deployments. Promote it to staging from the component's Deploy page, or from a terminal:

```bash
occ component deploy order-service --to staging -n team-alpha -p alpha-pilot
kubectl get releasebindings -n team-alpha
cd ~/oc-210-labs/lab5-scaffold
./check-endpoint.sh staging team-alpha order-service-http greeter/greet 40
```

## D. The API underneath

### 5. Read what the wizard wrote

> **Verify:** flags can differ between versions. If this fails, run the command with `--help`.

The wizard created a Component and a Workload through the API. The same contract can live in Git as a file: `occ component scaffold` writes one for the same type.

```bash
mkdir -p ~/oc-210-labs/lab5-work && cd ~/oc-210-labs/lab5-work
kubectl get component order-service -n team-alpha -o yaml | head -25
kubectl get workloads -n team-alpha -o yaml | grep -A12 "endpoints:"
occ component scaffold order-service -n team-alpha -p alpha-pilot \
  --clustercomponenttype deployment/service -o order-service-scaffold.yaml
cat order-service-scaffold.yaml
```

The same ComponentType reference, image and endpoint the wizard asked for. The portal is the starting point for people; the file is what a team keeps in Git and applies again.

## Checkpoint

- [ ] `order-service`, created in the portal, answers through the gateway in development and in staging
- [ ] It appears in the catalog under the alpha-pilot System
- [ ] You can point to the ComponentType reference, image and endpoint in what the wizard created

## Troubleshooting

- No Service template under the Component card: run `kubectl get clustercomponenttypes`; the template's name comes from the type's display name.
- Component not Ready: errors show in its status, not when it is created. Run `kubectl get component order-service -n team-alpha -o jsonpath='{.status.conditions}'`.
- 404 from `check-endpoint.sh`: the endpoint name is part of the path. Run `kubectl get httproute -A -l openchoreo.dev/component=order-service -o yaml | grep -A3 path:` and use that path.
- Quota error on the pod: run `kubectl describe resourcequota -n $(kubectl get deployment -A -l openchoreo.dev/component=order-service -o jsonpath='{.items[0].metadata.namespace}')`.
- Staging not available: run `kubectl get deploymentpipeline -n team-alpha -o yaml`; it must promote development to staging (Lab 3).
- Deploy command rejected: run `occ component deploy --help`.
- `check-endpoint.sh` prints a full localhost URL: `GATEWAY_ADDR` is not set. Run the setup block again.
- 404 with the right path: compare the host with `kubectl get httproute -A -l openchoreo.dev/component=order-service -o jsonpath='{..hostnames}'`. If the suffix differs, set it for the session: `export GATEWAY_HOST=<the part after the namespace>`.
- `unknown command "deploy"`: occ 1.2.0 may name it differently. Run `occ component --help`, or promote in the console from the component's Deploy page.

---

Previous: [Lab 4](../lab4-roles-quota/WORKBOOK-sandbox.md) · [All modules](../WORKBOOK.md) · Next: [Capstone](../capstone/WORKBOOK-sandbox.md)
