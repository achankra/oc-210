# Lab 4: Access roles and a quota

*OC-210 workbook, local install edition (OpenChoreo v1.3.1 on k3d). Using the WSO2 sandbox instead? See [WORKBOOK-sandbox.md](WORKBOOK-sandbox.md).*

**Goal:** Give the team-alpha developers scoped access with a role and a binding, and bound the team's cell with a starter-tier quota.

## A. List roles

### 1. See what exists

The roles OpenChoreo ships with are cluster roles. The team-alpha namespace has none of its own yet.

```bash
occ clusterauthzrole list
occ authzrole list -n team-alpha
kubectl get clusterauthzrole developer -o yaml
```

Find `spec.actions`. Actions are written `resource:verb`, and wildcards are allowed.

### 2. See the claims the existing bindings match

```bash
kubectl api-resources | grep -i authz
kubectl get clusterauthzrolebindings -o custom-columns=\
NAME:.metadata.name,CLAIM:.spec.entitlement.claim,VALUE:.spec.entitlement.value
```

Users are matched on the `groups` claim (for example `admins`, `developers`); service clients on `client_id`. Your binding in part C uses `groups`.

## B. Role

### 3. Create a team-developer role

> **Dry run first:** the block checks with a server-side dry run before it changes anything.

The role template in the lab folder, filled in for team-alpha. The action names appear in the OpenChoreo authorization docs, which do not list every action; compare them with the role you read in step 1.

```bash
cd ~/oc-210-labs/lab4-roles-quota
python3 ../lab3-onboard/scripts/render.py templates/role.yaml TEAM=team-alpha \
  > team-developer-role.yaml
cat team-developer-role.yaml
kubectl apply --dry-run=server -f team-developer-role.yaml
occ apply -f team-developer-role.yaml
occ authzrole list -n team-alpha
```

## C. Binding

### 4. Bind it to the team group

> **Dry run first:** the block checks with a server-side dry run before it changes anything.

The Handbook binds Keycloak groups. Here the subject is an entitlement: a claim and value from your ThunderID token. Without a scope the binding covers the whole namespace.

```bash
cd ~/oc-210-labs/lab4-roles-quota
python3 ../lab3-onboard/scripts/render.py templates/binding.yaml TEAM=team-alpha \
  > team-developer-binding.yaml
cat team-developer-binding.yaml
kubectl apply --dry-run=server -f team-developer-binding.yaml
occ apply -f team-developer-binding.yaml
occ authzrolebinding list -n team-alpha
```

`./apply-access.sh team-alpha --apply` does steps 3 and 4 in one command; the capstone uses it.

## D. ProjectType with a quota

### 5. Create a starter-tier ProjectType

> **Dry run first:** the block checks with a server-side dry run before it changes anything.

Export the default type. One Python command then renames it `starter-tier`, strips the server-added fields, keeps the Namespace entry (`id: cell-namespace`), and adds the ResourceQuota from `starter-tier-quota.yaml` as a new entry with the same plane and namespace expression as the Namespace entry.

| Quota Key (Handbook Starter Tier) | Value |
|---|---|
| `requests.cpu` / `requests.memory` | 4 / 8Gi |
| `limits.cpu` / `limits.memory` | 8 / 16Gi |
| `persistentvolumeclaims` | 5 |
| `services.loadbalancers` | 1 |
| `count/deployments.apps` | 10 |

```bash
# once per cluster: let the data plane agent manage quotas
kubectl create clusterrole lab-cluster-agent-quotas \
  --verb=get,list,watch,create,update,patch,delete --resource=resourcequotas,limitranges
kubectl create clusterrolebinding lab-cluster-agent-quotas \
  --clusterrole=lab-cluster-agent-quotas \
  --serviceaccount=openchoreo-data-plane:cluster-agent-dataplane

cd ~/oc-210-labs/lab4-roles-quota
source ~/oc-210-labs/.venv/bin/activate
kubectl get clusterprojecttypes
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

The list shows `default` and `starter-tier`. If the dry run returns an error, it names the field the API rejected. The data plane agent creates everything a project type renders, and out of the box it may not manage ResourceQuotas. Without this grant the cell apply fails with `resourcequotas ... is forbidden` and none of the type's resources land. A project type can only stamp out what the agent is allowed to manage. If `create` says `AlreadyExists`, the grant is already there.

## E. Use it and verify

### 6. Create a project that uses the type

```bash
cd ~/oc-210-labs/lab3-onboard
./onboard.sh team-alpha alpha-pilot --project-type starter-tier --apply
occ project list -n team-alpha
```

The script finds the namespace already exists and applies the rest. A type is fixed when the project is created, so the type of an existing project cannot be changed; that is why this is a new project.

### 7. Check the quota in the cell

The ProjectReleaseBinding for a project and environment owns the cell namespace. Wait about a minute for it to reconcile, then:

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

The samples show both outcomes first. The last line should print seven OK lines for your cell.

## Checkpoint

- [ ] `occ authzrole list -n team-alpha` shows `team-developer`
- [ ] The binding lists the group entitlement `team-alpha-developers`
- [ ] `check_quota.py` prints seven OK lines for the alpha-pilot cell

## Troubleshooting

- Role rejected: compare field names with `kubectl get clusterauthzrole developer -o yaml`; schemas differ by version.
- `cell namespace:` prints nothing: the binding has not reconciled. Run `kubectl get projectreleasebindings -n team-alpha` and wait.
- `resourcequotas ... is forbidden` on the project binding: run the first lines of step 5 (the agent grant), then `kubectl annotate projectreleasebinding alpha-pilot-development -n team-alpha lab/retry=$(date +%s) --overwrite`.
- `No ResourceQuota limits found`: run `kubectl get project alpha-pilot -n team-alpha -o jsonpath='{.spec.type}'`; it must name `starter-tier`.
- `ModuleNotFoundError: yaml`: run `source ~/oc-210-labs/.venv/bin/activate` and repeat the step.
- Cannot match a group: the value must match the `groups` claim in the token exactly.

---

Previous: [Lab 3](../lab3-onboard/WORKBOOK-local.md) · [All modules](../WORKBOOK.md) · Next: [Lab 5](../lab5-scaffold/WORKBOOK-local.md)
