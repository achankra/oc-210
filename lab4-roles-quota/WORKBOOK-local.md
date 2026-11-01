# Lab 4: Publish a project type as a portal wizard

*OC-210 workbook, local install edition (OpenChoreo v1.3.2 on k3d). Using the WSO2 sandbox instead? See [WORKBOOK-sandbox.md](WORKBOOK-sandbox.md).*

**Goal:** As the platform team, publish a starter-tier ProjectType with the Handbook's quota and watch the portal turn it into a Create Project wizard, with no template to write. As the team, create a project from it and find the quota in its cells. Then give the team's developers access.

## A. One wizard per project type

### 1. See the types and their wizards

```bash
kubectl get clusterprojecttypes
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

Sign in with `admin@openchoreo.dev` / `Admin@123`. On the Create page, open the **Project** card under Application Resources: it lists one template for each ProjectType, so today the default one, plus any types left from OC-201 on the same cluster, such as `governed`. The Platform Resources cards below create the types themselves; this lab does that with YAML.

## B. Publish the starter tier

### 2. Create the starter-tier ProjectType

> **Dry run first:** the block checks with a server-side dry run before it changes anything.

Export the default type. One Python command renames it `starter-tier`, gives it the display name and description the portal shows on its wizard, strips the server-added fields, and adds the ResourceQuota from `starter-tier-quota.yaml` to the cell namespace. The quota values are the starter tier from The Platform Engineer's Handbook by Ajay Chankramath (Packt, 2025). The book is not required for this course, but we recommend it to go deeper: [peh-packt.platformetrics.com](https://peh-packt.platformetrics.com) or [Amazon](https://www.amazon.com/dp/B0FR59Z7Q2).

| Quota Key (Handbook Starter Tier) | Value |
|---|---|
| `requests.cpu` / `requests.memory` | 4 / 8Gi |
| `limits.cpu` / `limits.memory` | 8 / 16Gi |
| `persistentvolumeclaims` | 5 |
| `services.loadbalancers` | 1 |
| `count/deployments.apps` | 10 |

```bash
# once per cluster: let the cluster agent manage quotas
kubectl create clusterrole lab-cluster-agent-quotas \
  --verb=get,list,watch,create,update,patch,delete --resource=resourcequotas,limitranges
kubectl create clusterrolebinding lab-cluster-agent-quotas \
  --clusterrole=lab-cluster-agent-quotas \
  --serviceaccount=openchoreo-data-plane:cluster-agent-dataplane

cd ~/oc-210-labs/lab4-roles-quota
source ~/oc-210-labs/.venv/bin/activate
kubectl get clusterprojecttype default -o yaml > starter-tier.yaml
python3 -c "
import yaml
d = yaml.safe_load(open('starter-tier.yaml'))
m = d['metadata']
drop = ('uid', 'resourceVersion', 'creationTimestamp', 'generation',
'managedFields', 'ownerReferences', 'annotations')
for k in drop: m.pop(k, None)
d.pop('status', None)
m['name'] = 'starter-tier'
m['labels'] = {'openchoreo.dev/name': 'starter-tier'}
m['annotations'] = {'openchoreo.dev/display-name': 'Starter tier',
'openchoreo.dev/description': 'A cell with the starter-tier quota: 4 CPU and 8Gi requested, up to 10 deployments.'}
res = d['spec']['resources']
ns = next(r for r in res if r['id'] == 'cell-namespace')
q = yaml.safe_load(open('starter-tier-quota.yaml'))
q['metadata']['namespace'] = ns['template']['metadata']['name']
plane = ns.get('targetPlane', 'dataplane')
res.append({'id': 'starter-tier-quota', 'targetPlane': plane, 'template': q})
yaml.safe_dump(d, open('starter-tier.yaml', 'w'), sort_keys=False)
"
grep -n -A14 "id: starter-tier-quota" starter-tier.yaml
kubectl apply --dry-run=server -f starter-tier.yaml
kubectl apply -f starter-tier.yaml
kubectl get clusterprojecttypes
```

The list shows `default` and `starter-tier`, plus any types left from OC-201 on the same cluster, such as `governed`. The cluster agent creates everything a project type renders, and on any install it cannot manage ResourceQuotas until you grant it; without the grant the cell fails with `resourcequotas ... is forbidden`. If `create` says `AlreadyExists`, the grant is already there.

### 3. Find its wizard in the portal

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

Open the **Project** card again: a template for **Starter tier** is now listed, with the description you set. Nobody wrote a template: publishing the type is the whole job. If it is not there yet, wait a minute and reload.

## C. The team uses it

### 4. Create alpha-pilot from the Starter tier wizard

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

Choose **Create** in the left menu (or http://openchoreo.localhost:8080/create). Sign in with `admin@openchoreo.dev` / `Admin@123`. Under Application Resources, open the **Project** card (Browse project templates) and pick the template for **Starter tier**: the portal generates one for each ProjectType the platform team publishes. Fill in the namespace `team-alpha`, the project name `alpha-pilot` and the deployment pipeline `team-alpha-deployment-pipeline`, then choose **Create**. Field labels differ a little between portal versions; these three values are what matter. A project's type is fixed when it is created, which is why this is a new project rather than a change to `alpha-shop`.

### 5. Check the quota in the cell

The ProjectReleaseBinding for each environment owns a cell namespace. Wait about a minute for it to reconcile, then:

```bash
kubectl get projectreleasebindings -n team-alpha
kubectl get namespaces -l openchoreo.dev/project=alpha-pilot -L openchoreo.dev/environment
CELL=$(kubectl get namespaces \
  -l openchoreo.dev/project=alpha-pilot,openchoreo.dev/environment=development \
  -o jsonpath='{.items[0].metadata.name}')
echo "cell namespace: $CELL"
cd ~/oc-210-labs/lab4-roles-quota
python3 check_quota.py samples/quota-starter.json
python3 check_quota.py samples/quota-wrong.json
kubectl get resourcequota -n $CELL -o json | python3 check_quota.py
```

The samples show both outcomes first. The last line should print seven OK lines for your cell. Every project created from the Starter tier wizard gets the same quota.

## D. Give the team access

### 6. Apply the team-developer role and binding

> **Dry run first:** the block checks with a server-side dry run before it changes anything.

A team needs access as well as a project. The script renders a `team-developer` role and a binding to the group `team-alpha-developers` from `templates/`, checks them, and with `--apply` creates them.

```bash
cd ~/oc-210-labs/lab4-roles-quota
./apply-access.sh team-alpha
cat rendered/team-alpha/role.yaml rendered/team-alpha/binding.yaml
./apply-access.sh team-alpha --apply
occ authzrole list -n team-alpha
occ authzrolebinding list -n team-alpha
```

Members of `team-alpha-developers` can now deploy and debug in team-alpha, and see its projects in the portal. Users match on the `groups` claim; a pipeline or bot would be bound by its `client_id` instead. OC-201 Lab 2 covers the role model in depth.

## Checkpoint

- [ ] `kubectl get clusterprojecttypes` shows `starter-tier`, and the portal lists a Starter tier wizard
- [ ] `alpha-pilot`, created from that wizard, has a cell with seven OK lines from `check_quota.py`
- [ ] `occ authzrole list -n team-alpha` shows `team-developer`

## Troubleshooting

- No Starter tier template under the Project card: wait a minute and reload the Create page. Run `kubectl get clusterprojecttype starter-tier -o jsonpath='{.metadata.annotations}'` to check the display name.
- `cell namespace:` prints nothing: the binding has not reconciled, or the wizard created none. Run `kubectl get projectreleasebindings -n team-alpha`; if `alpha-pilot` has none, run `../lab3-onboard/scripts/bind-project.sh team-alpha alpha-pilot`.
- `resourcequotas ... is forbidden` on the project binding: run the grant lines of step 2, then `kubectl annotate projectreleasebinding alpha-pilot-development -n team-alpha lab/retry=$(date +%s) --overwrite`.
- `No ResourceQuota limits found`: run `kubectl get project alpha-pilot -n team-alpha -o jsonpath='{.spec.type}'`; it must name `starter-tier`.
- `ModuleNotFoundError: yaml`: run `source ~/oc-210-labs/.venv/bin/activate` and repeat the step.
- Role rejected: compare field names with `kubectl get clusterauthzrole developer -o yaml`.

---

Previous: [Lab 3](../lab3-onboard/WORKBOOK-local.md) · [All modules](../WORKBOOK.md) · Next: [Lab 5](../lab5-scaffold/WORKBOOK-local.md)
