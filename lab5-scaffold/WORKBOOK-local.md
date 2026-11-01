# Lab 5: Create a service from the portal

*OC-210 workbook, local install edition (OpenChoreo v1.3.2 on k3d). Using the WSO2 sandbox instead? See [WORKBOOK-sandbox.md](WORKBOOK-sandbox.md).*

**Goal:** Use the portal's Create Component wizard, which the service ComponentType generates, to create a service in the team's project. Call it, find it in the catalog, promote it, then read the files the API underneath works with.

## A. Starter kits are component types

### 1. See the types and their wizards

```bash
kubectl get clustercomponenttypes
```

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

Sign in with `admin@openchoreo.dev` / `Admin@123`. On the Create page, open the **Component** card under Application Resources: each ComponentType has its own template there, service, web application, scheduled task and worker. A platform team adds a starter kit by publishing a type, not by writing a template.

## B. Create the service

### 2. Create order-service from the Service wizard

Open http://openchoreo.localhost:8080/create, or choose **Create** in the left menu. Sign in with `admin@openchoreo.dev` / `Admin@123`. Under Application Resources, open the **Component** card (Browse component templates) and pick the template for the **Service** type: the portal generates one for each ComponentType the platform team publishes. Fill in these values, then choose **Create**. Field labels differ a little between portal versions; the values are what matter.

| Field | Value |
|---|---|
| Namespace and project | `team-alpha` · `alpha-pilot` |
| Component name | `order-service` |
| Source | Deploy from a pre-built image: `ghcr.io/openchoreo/samples/greeter-service:latest` |
| Endpoint | name `http`, type HTTP, port `9090`, visibility external |

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

The script retries while the deployment becomes ready and prints `Hello, Stranger!`. The `status.endpoints` line shows the URL the platform published. If there is no `order-service-development` binding, the component was created without deploying: run `occ component deploy order-service --to development -n team-alpha -p alpha-pilot`.

## C. Catalog and promote

### 4. Find it in the catalog and promote it to staging

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

Open `order-service` under the alpha-pilot System and check its owner and its deployments. Promote it to staging from the component's Deploy page, or from a terminal:

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

---

Previous: [Lab 4](../lab4-roles-quota/WORKBOOK-local.md) · [All modules](../WORKBOOK.md) · Next: [Capstone](../capstone/WORKBOOK-local.md)
