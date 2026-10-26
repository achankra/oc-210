# Lab 2: Register a service in the catalog

*OC-210 workbook, WSO2 sandbox edition (OpenChoreo v1.2.2). Using a local install instead? See [WORKBOOK-local.md](WORKBOOK-local.md).*

**Goal:** Create a project and component, see them appear as Backstage System and Component entities, and register an extra catalog entry with an explicit owner.

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

## A. Create a project and component

### 1. Write a project for the pilot team

> **Dry run first:** the block checks with a server-side dry run before it changes anything.

The block reads the pipeline name from the default project and writes the Project as JSON. The type reference points at the default ClusterProjectType.

```bash
mkdir -p ~/oc-210-labs/lab2-work && cd ~/oc-210-labs/lab2-work
PIPE=$(kubectl get project default -n default \
  -o jsonpath='{.spec.deploymentPipelineRef.name}')
echo "pipeline: $PIPE"
cat > team-alpha-pilot-project.yaml <<EOF
{"apiVersion": "openchoreo.dev/v1alpha1", "kind": "Project",
 "metadata": {"name": "team-alpha-pilot", "namespace": "default"},
 "spec": {"deploymentPipelineRef": {"name": "$PIPE"},
          "type": {"kind": "ClusterProjectType", "name": "default"}}}
EOF
cat team-alpha-pilot-project.yaml
kubectl apply --dry-run=server -f team-alpha-pilot-project.yaml
occ apply -f team-alpha-pilot-project.yaml
occ project list -n default
```

A project gets a cell namespace per environment only through a ProjectReleaseBinding. Create one for each environment of the default pipeline:

```bash
for env in development staging production; do
kubectl apply -f - <<EOF
{"apiVersion": "openchoreo.dev/v1alpha1", "kind": "ProjectReleaseBinding",
 "metadata": {"name": "team-alpha-pilot-$env", "namespace": "default",
  "labels": {"openchoreo.dev/project": "team-alpha-pilot", "openchoreo.dev/environment": "$env"}},
 "spec": {"owner": {"projectName": "team-alpha-pilot"}, "environment": "$env"}}
EOF
done
sleep 20
kubectl get namespaces -l openchoreo.dev/project=team-alpha-pilot -L openchoreo.dev/environment
```

### 2. Add a component from the sample image

> **Dry run first:** the block checks with a server-side dry run before it changes anything.

The greeter-service sample from Lab 1, renamed `pilot-service` and owned by `team-alpha-pilot`. The scaffold shows what a generated Component looks like, for comparison.

```bash
cd ~/oc-210-labs/lab2-work
BASE=https://raw.githubusercontent.com/openchoreo/openchoreo/release-v1.2/samples
curl -fsSL $BASE/from-image/go-greeter-service/greeter-service.yaml \
  | sed -e 's/ame: greeter-service/ame: pilot-service/' \
        -e 's/projectName: default/projectName: team-alpha-pilot/' \
  > pilot-component.yaml
grep -n -E "name:|projectName" pilot-component.yaml
kubectl apply --dry-run=server -f pilot-component.yaml
occ apply -f pilot-component.yaml
kubectl get components -n default
occ component scaffold pilot-service -n default -p team-alpha-pilot \
  --clustercomponenttype deployment/service -o pilot-scaffold.yaml
cat pilot-scaffold.yaml
```

## B. Find the entities

### 3. Match runtime objects to catalog entities

In your browser, open https://console.demo.openchoreo.wso2.com/catalog.

| Openchoreo Object | Backstage Entity | Name You Found |
|---|---|---|
| Namespace | Domain |  |
| Project | System |  |
| Component | Component |  |

Find the entity for the namespace (Domain), for your project (System) and for the component (Component). Record each name.

## C. Register an extra entry

### 4. Fill in the catalog-info file

`catalog/pilot-docs-site.yaml` follows the Handbook example: a Component with tags, a link, and a spec that names type, lifecycle and owner. Two placeholders need values. The system is the project from step 1. The owner must be a group that exists in the catalog: in the portal catalog, set the Kind filter to Group and pick one. Put its name on the first line, then paste the rest.

```bash
GROUP=name-of-a-group-from-the-portal
cd ~/oc-210-labs/lab2-catalog-check
sed -e "s/REPLACE-WITH-AN-EXISTING-GROUP/$GROUP/" \
    -e "s/REPLACE-WITH-YOUR-PROJECT-NAME/team-alpha-pilot/" \
    catalog/pilot-docs-site.yaml > pilot-docs-site.yaml
cat pilot-docs-site.yaml
```

The template in `catalog/` stays as it is; your copy is `pilot-docs-site.yaml` in the lab folder.

### 5. Import it through the portal

The portal imports from a URL, so the file has to be on the web. A public GitHub gist is the quickest place, and you already signed in to GitHub for the sandbox. Print the file, then copy it into a new gist in your browser:

```bash
cd ~/oc-210-labs/lab2-catalog-check
cat pilot-docs-site.yaml
```

In your browser, open https://gist.github.com. Name the file `pilot-docs-site.yaml`, paste the content, and choose **Create public gist**. Click **Raw** and copy the URL. Then open https://console.demo.openchoreo.wso2.com/catalog-import, paste the URL, and choose Analyze, then Import.

## D. Completeness check

### 6. Check each entry

The program checks each entry for an owner, a lifecycle, at least one link and a system. Run it on your entry beside the two samples.

```bash
cd ~/oc-210-labs/lab2-catalog-check
source ~/oc-210-labs/.venv/bin/activate
python3 catalog_check.py pilot-docs-site.yaml catalog/billing-api.yaml \
  catalog/orphan-service.yaml
```

It prints yes or NO for each item and the percentage of checks passed. `orphan-service` fails all four. Then open the entries you can see in the portal and tick the same four items by hand.

## Checkpoint

- [ ] The project appears as a System in the portal
- [ ] The component appears under that System
- [ ] The extra entry shows a named owner
- [ ] `catalog_check.py` shows `pilot-docs-site` as complete

## Troubleshooting

- Import fails: the URL must be the raw file URL and reachable from the portal. If the portal says it is not allowed to read that host, the portal's `backend.reading.allow` list needs it; in the sandbox, tell your instructor and complete step 6 on the file instead.
- Owner shows as unknown: the group does not exist in the catalog. Pick a name from the Group filter (Handbook section 6.2) and repeat step 4.
- Entities missing after create: wait a minute; the catalog refreshes on a schedule.
- `pilot-service` not Ready: run `kubectl describe component pilot-service -n default`.

---

Previous: [Lab 1](../lab1-portal-scorecard/WORKBOOK-sandbox.md) · [All modules](../WORKBOOK.md) · Next: [Lab 3](../lab3-onboard/WORKBOOK-sandbox.md)
