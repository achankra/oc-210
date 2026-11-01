# Lab 1: Tour the portal, find a service

*OC-210 workbook, local install edition (OpenChoreo v1.3.2 on k3d). Using the WSO2 sandbox instead? See [WORKBOOK-sandbox.md](WORKBOOK-sandbox.md).*

**Goal:** Verify the install, deploy a sample service, and use the portal to find it and its architecture view. Then score the portal on the Handbook's six evaluation planes.

## A. Verify

### 1. Check platform defaults

> **Verify:** flags can differ between versions. If this fails, run the command with `--help`.

```bash
kubectl get projects,environments,deploymentpipelines -n default
kubectl get clustercomponenttypes
occ config controlplane update default --url http://api.openchoreo.localhost:8080
occ login
occ namespace list
occ project list -n default
```

`occ login` opens a browser; sign in with `admin@openchoreo.dev` / `Admin@123`.

## B. Deploy a service

### 2. Apply the greeter-service sample

```bash
BASE=https://raw.githubusercontent.com/openchoreo/openchoreo/release-v1.3/samples
kubectl apply -f $BASE/from-image/go-greeter-service/greeter-service.yaml
kubectl wait --for=condition=Ready component/greeter-service -n default --timeout=180s
kubectl get component,releasebinding -n default
curl http://development-default.openchoreoapis.localhost:19080/greeter-service-http/greeter/greet
```

## C. Portal tour

### 3. Find the service

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

Sign in with `admin@openchoreo.dev` / `Admin@123`. Locate `greeter-service`. Open its overview, then the architecture graph and the deployment view. Note which entity types appear (Domain, System, Component).

### 4. Look for the tabs

List which of these you can see for the component: logs, metrics, traces, builds, deployments, access control. Note whether the portal offers a shell into a running instance. Write them in the worksheet.

## D. Score the portal

### 5. Fill in the six-plane worksheet

Score each plane from 0 (absent) to 3 (strong) and write one sentence of evidence: something you opened, saw or could not find. The second column says what each plane covers; the third is the question to answer. 0 means you cannot find it, 1 present but thin, 2 works for the common case, 3 you would show it to a new team.

The six planes and their key questions come from The Platform Engineer's Handbook by Ajay Chankramath (Packt, 2026), Chapter 6, Table 6.1. The book is not required for this course, but we recommend it to go deeper: [peh-packt.platformetrics.com](https://peh-packt.platformetrics.com) or [Amazon](https://www.amazon.com/dp/B0FR59Z7Q2).

| Plane | What It Covers | Key Question | Score 0-3 | Evidence |
|---|---|---|---|---|
| Service catalog and ownership | One source of truth for what exists and which team owns it | Is ownership explicit? |  |  |
| Golden paths and scaffolding | Opinionated templates for starting new services | Can you create a service without tribal knowledge? |  |  |
| Operations and reliability | Deployment health, runbooks, SLOs and incidents | Are health and runbooks visible? |  |  |
| Security and governance | Access control, policy enforcement and an audit trail | Can security audit through the portal? |  |  |
| Observability and telemetry | Logs, metrics and traces for each service | Is each service linked to its signals? |  |  |
| Insights and AI augmentation | Engineering analytics and AI assistants | Is there analytics and automation? |  |  |

### 6. Check the scorecard with the program

Run the sample first, then copy the template and open it in an editor. Put a score and a sentence after each plane name, keeping the commas.

```bash
cd ~/oc-210-labs/lab1-portal-scorecard
python3 scorecard.py sample-scorecard.csv
cp scorecard-template.csv my-scorecard.csv
```

**macOS**

```bash
# opens in TextEdit
open -e ~/oc-210-labs/lab1-portal-scorecard/my-scorecard.csv
```

**Linux**

```bash
nano ~/oc-210-labs/lab1-portal-scorecard/my-scorecard.csv
```

**Windows, in the WSL 2 Ubuntu terminal**

```bash
nano ~/oc-210-labs/lab1-portal-scorecard/my-scorecard.csv
```

When you have saved the file:

```bash
cd ~/oc-210-labs/lab1-portal-scorecard
python3 scorecard.py my-scorecard.csv
```

The program lists problems if a plane is missing, a score is outside 0 to 3, or an evidence sentence is empty. It prints the total out of 18 and your two weakest planes. Then compare with `sample-scorecard.csv`, a reference answer for the default local install (13 out of 18). Different scores are fine when your evidence supports them.

## Checkpoint

- [ ] `occ project list -n default` shows `default`
- [ ] `greeter-service` appears in the portal catalog
- [ ] Your worksheet has a score and a sentence for each of the six planes
- [ ] `scorecard.py` accepts your file and names your two weakest planes

## Troubleshooting

- Component missing in the portal: refresh, and run `kubectl get components -n default`.
- Portal sign-in loops: clear cookies for openchoreo.localhost and retry.
- `scorecard.py` reports a problem: fix the line it names and run it again.

---

Previous: [Pre-work](../prework/WORKBOOK-local.md) · [All modules](../WORKBOOK.md) · Next: [Lab 2](../lab2-catalog-check/WORKBOOK-local.md)
