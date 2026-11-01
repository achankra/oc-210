# Lab 1: Tour the portal, find a service

*OC-210 workbook, WSO2 sandbox edition (OpenChoreo v1.2.2). Using a local install instead? See [WORKBOOK-local.md](WORKBOOK-local.md).*

**Goal:** Verify the install, deploy a sample service, and use the portal to find it and its architecture view. Then score the portal on the Handbook's six evaluation planes.

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

## A. Verify

### 1. Check platform defaults

```bash
kubectl get projects,environments,deploymentpipelines -n default
kubectl get clustercomponenttypes
occ version
occ namespace list
occ project list -n default
```

The sandbox signed occ in for you, so there is no `occ login`. The server line shows v1.2.2. Besides `default`, the sandbox ships a demo project, `gcp-microservice-demo`.

## B. Deploy a service

### 2. Apply the greeter-service sample

```bash
BASE=https://raw.githubusercontent.com/openchoreo/openchoreo/release-v1.2/samples
kubectl apply -f $BASE/from-image/go-greeter-service/greeter-service.yaml
kubectl wait --for=condition=Ready component/greeter-service -n default --timeout=180s
kubectl get component,releasebinding -n default
curl -H "Host: $DEVHOST" http://$GWADDR/greeter-service-http/greeter/greet
```

The sandbox's public URLs sit behind a browser check, so the terminal calls the gateway inside the cluster and names the host in a `Host` header. The answer is `Hello, Stranger!`.

## C. Portal tour

### 3. Find the service

In your browser, open https://console.demo.openchoreo.wso2.com/catalog.

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

Run the sample first, then copy the template and open it in nano. Put a score and a sentence after each plane name, keeping the commas. Save with Ctrl-O, Enter, and leave with Ctrl-X. If nano is missing, use `vi`.

```bash
cd ~/oc-210-labs/lab1-portal-scorecard
python3 scorecard.py sample-scorecard.csv
cp scorecard-template.csv my-scorecard.csv
```

```bash
nano ~/oc-210-labs/lab1-portal-scorecard/my-scorecard.csv
```

When you have saved the file:

```bash
cd ~/oc-210-labs/lab1-portal-scorecard
python3 scorecard.py my-scorecard.csv
```

The program lists problems if a plane is missing, a score is outside 0 to 3, or an evidence sentence is empty. It prints the total out of 18 and your two weakest planes. Then compare with `sample-scorecard.csv`, a reference answer for the default local install (13 out of 18). Different scores are fine when your evidence supports them. The sandbox runs v1.2.2, so a plane or two may score differently there.

## Checkpoint

- [ ] `occ project list -n default` shows `default`
- [ ] `greeter-service` appears in the portal catalog
- [ ] Your worksheet has a score and a sentence for each of the six planes
- [ ] `scorecard.py` accepts your file and names your two weakest planes

## Troubleshooting

- Component missing in the portal: refresh, and run `kubectl get components -n default`.
- `scorecard.py` reports a problem: fix the line it names and run it again.
- No answer from curl: run `echo $GWADDR`. If it is empty, run the setup block again.
- Console sign-in loops: sign out of the sandbox console, clear its cookies, and sign in again.

---

Previous: [Pre-work](../prework/WORKBOOK-sandbox.md) · [All modules](../WORKBOOK.md) · Next: [Lab 2](../lab2-catalog-check/WORKBOOK-sandbox.md)
