# Lab 5: Scaffold and deploy

*OC-210 workbook, local install edition (OpenChoreo v1.3.1 on k3d). Using the WSO2 sandbox instead? See [WORKBOOK-sandbox.md](WORKBOOK-sandbox.md).*

**Goal:** Start a new service from a scaffold, deploy it into the team's project, view it in the portal catalog and promote it.

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

> **Dry run first:** the block checks with a server-side dry run before it changes anything.

Fill the scaffold's placeholders with a known-good image: the greeter sample, named `order-service`, in team-alpha's `alpha-pilot` project.

```bash
cd ~/oc-210-labs/lab5-work
BASE=https://raw.githubusercontent.com/openchoreo/openchoreo/release-v1.3/samples
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

The script builds the gateway URL, retries while the deployment becomes ready, and prints `Hello, Stranger!`.

## D. Catalog and promote

### 4. Promote and call staging

```bash
occ component deploy order-service --to staging -n team-alpha -p alpha-pilot
kubectl get releasebindings -n team-alpha
cd ~/oc-210-labs/lab5-scaffold
./check-endpoint.sh staging team-alpha order-service-http greeter/greet 40
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

In the portal, open `order-service` under the alpha-pilot System and check its deployments.

### 5. Optional: create a component from the portal wizard

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

---

Previous: [Lab 4](../lab4-roles-quota/WORKBOOK-local.md) · [All modules](../WORKBOOK.md) · Next: [Capstone](../capstone/WORKBOOK-local.md)
