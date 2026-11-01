# Lab 4: publish a project type as a portal wizard

In Lab 4 the platform team publishes a starter-tier ProjectType with the Handbook's quota. The portal turns it into a Create Project wizard, with no template to write. The team creates `alpha-pilot` from that wizard, and its cells get the quota. Then the team's developers get access through a role and a binding. This folder holds the quota, the edit that builds the type, the access templates, and a program that checks the quota in a cell. The starter-tier values come from The Platform Engineer's Handbook by Ajay Chankramath (Packt, 2026). The book is not required for this course, but we recommend it to go deeper: [peh-packt.platformetrics.com](https://peh-packt.platformetrics.com) or [Amazon](https://www.amazon.com/dp/B0FR59Z7Q2).

| Path | Purpose |
|---|---|
| `starter-tier-quota.yaml` | The ResourceQuota for your starter-tier ProjectType |
| `build_starter_tier.py` | The step 2 edit as a program: renames the default type, sets the display name and description the portal shows on its wizard, and adds the quota. `sandbox/restore.sh` uses it |
| `check_quota.py` | Compares the quota in a cell namespace with the starter tier |
| `samples/` | A matching and a non-matching quota, in the format `kubectl` prints |
| `templates/role.yaml` | The `team-developer` AuthzRole |
| `templates/binding.yaml` | The AuthzRoleBinding that maps the team's group to that role |
| `apply-access.sh` | Renders both for a team, checks them, and with `--apply` creates them |

The steps for this lab are in [WORKBOOK-local.md](WORKBOOK-local.md), or [WORKBOOK-sandbox.md](WORKBOOK-sandbox.md) in the WSO2 sandbox.

## Files you create in this lab

| File | Created in | What it is |
|---|---|---|
| `starter-tier.yaml` | step 2 | The default ClusterProjectType, renamed `starter-tier`, with its display name and the starter-tier ResourceQuota |
| `rendered/team-alpha/` | step 6 | The role and binding `apply-access.sh` renders |

Git ignores them. `reference/starter-tier.yaml` is the first file, made from a v1.3 install. If step 2 fails or you fall behind: `cp reference/starter-tier.yaml . && kubectl apply -f starter-tier.yaml`.

## Requirements

- `kubectl` and `occ`, signed in to your cluster, and the portal.
- Python 3.9 or newer with PyYAML: `source ~/oc-210-labs/.venv/bin/activate`.
- The team-alpha space from Lab 3.

## The starter-tier ProjectType

The workbook exports the default ClusterProjectType and edits it in one Python command. The same edit as a program:

```
cd ~/oc-210-labs/lab4-roles-quota
kubectl get clusterprojecttype default -o yaml > default.yaml
python3 build_starter_tier.py default.yaml starter-tier-quota.yaml > starter-tier.yaml
kubectl apply -f starter-tier.yaml
```

The cluster agent has to be allowed to manage ResourceQuotas first, on any install; the workbook's step 2 grants it. Once the type exists, the portal's Create page lists a template called **Starter tier** under the **Project** card.

## Check the quota

Find the cell namespace of `alpha-pilot` in development, then check its quota:

```
cd ~/oc-210-labs/lab4-roles-quota
CELL=$(kubectl get namespaces \
  -l openchoreo.dev/project=alpha-pilot,openchoreo.dev/environment=development \
  -o jsonpath='{.items[0].metadata.name}')
kubectl get resourcequota -n $CELL -o json | python3 check_quota.py
```

The program lists each starter-tier limit as OK, DIFFERS or MISSING, and exits with status 1 if any is not OK. Quantities are compared by value, so `8192Mi` matches `8Gi`. To see both outcomes, run it on `samples/quota-starter.json` and `samples/quota-wrong.json`.

## Access for the team

```
cd ~/oc-210-labs/lab4-roles-quota
./apply-access.sh team-alpha
./apply-access.sh team-alpha --apply
```

The first form renders `rendered/team-alpha/role.yaml` and `binding.yaml` and checks them. The second applies them and lists the team's roles and bindings. The binding matches the claim `groups` with the value `team-alpha-developers`; that value has to match the sign-in token exactly. A service client, such as a pipeline, is matched on `client_id` instead.

## What you should see

- A Starter tier template under the Project card on the portal's Create page.
- Seven OK lines for the cell of `alpha-pilot`. A project on the default type prints `No ResourceQuota limits found`.
- `occ authzrole list -n team-alpha` shows `team-developer`.
- Audit Logs in the portal's left menu shows the creation of `alpha-pilot` and the role and binding; `occ auditlogs --since 1h` shows the same entries.

## If something fails

- No Starter tier template under the Project card: wait a minute and reload. Check the display name with `kubectl get clusterprojecttype starter-tier -o jsonpath='{.metadata.annotations}'`.
- `resourcequotas ... is forbidden`: the cluster agent grant in step 2 is missing.
- Quota missing: confirm the project uses `starter-tier` (`kubectl get project alpha-pilot -n team-alpha -o jsonpath='{.spec.type}'`). A project's type cannot be changed after it is created.
- Role rejected: compare field and action names with `kubectl get clusterauthzrole developer -o yaml`.

## How it maps to OpenChoreo

The Handbook's tiered quota becomes a ProjectType, and publishing the type is all it takes to give teams a self-service way to use it: the portal generates the wizard. Every project created from it gets the same cell.
