# Lab 4: access roles and a quota

In Lab 4 you give the team-alpha developers scoped access with a role and a binding, and bound the team's cell with a starter-tier quota. You write the role and binding by hand in the workbook. This folder holds the same two files as templates, the quota to add to your ProjectType, and a program that checks the quota that landed in the cell.

| Path | Purpose |
|---|---|
| `templates/role.yaml` | The `team-developer` AuthzRole |
| `templates/binding.yaml` | The AuthzRoleBinding that maps the team's group to that role |
| `apply-access.sh` | Renders both for a team, checks them, and with `--apply` creates them |
| `starter-tier-quota.yaml` | The ResourceQuota for your starter-tier ProjectType |
| `check_quota.py` | Compares the quota in a cell namespace with the starter tier |
| `samples/` | A matching and a non-matching quota, in the format `kubectl` prints |
| `build_starter_tier.py` | The step 5 edit as a program, used by `sandbox/restore.sh` to rebuild the type in a new sandbox session |


The steps for this lab are in [WORKBOOK-local.md](WORKBOOK-local.md).

## Files you create in this lab

These are not in the repository until you run the step that writes them. Git ignores them.

| File | Created in | What it is |
|---|---|---|
| `team-developer-role.yaml` | step 3 | `templates/role.yaml` filled in for team-alpha |
| `team-developer-binding.yaml` | step 4 | `templates/binding.yaml` filled in for team-alpha |
| `starter-tier.yaml` | step 5 | The default ClusterProjectType, renamed `starter-tier`, with the starter-tier ResourceQuota added |

`reference/` holds a copy of each, made from a v1.3.1 install. If a step fails or you fall behind, copy the file into place, for example `cp reference/starter-tier.yaml .`, and carry on from the apply line.

## Requirements

- `kubectl` and `occ`, signed in to your cluster.
- Python 3.9 or newer for `check_quota.py`. No other packages.
- The team-alpha namespace from Lab 3. This lab uses `../lab3-onboard/scripts/`.

## 1. Roles and bindings

Write the role and binding in the workbook first. To see the same result from templates:

```
cd ~/oc-210-labs/lab4-roles-quota
./apply-access.sh team-alpha
./apply-access.sh team-alpha --apply
```

The first form renders `rendered/team-alpha/role.yaml` and `binding.yaml` and checks them with a client-side dry run. The second applies them and lists the team's roles and bindings.

Compare the template with the roles that ship with the platform, so you know which actions exist on your install:

```
occ clusterauthzrole list
occ authzrole list -n team-alpha
```

The binding matches the claim `groups` with the value `team-alpha-developers`. That value has to match the claim in your sign-in token exactly, or the binding does nothing. It has no scope, so it applies to the whole namespace. To narrow it, add `scope` with a `project` under the role mapping.

## 2. The starter-tier ProjectType

Clone the default ClusterProjectType as the workbook describes, then add the quota in `starter-tier-quota.yaml` as a new entry in the same shape as the existing Namespace entry. Create a project that uses the new type. Lab 3's script does this when you pass the type:

```
cd ~/oc-210-labs/lab4-roles-quota
../lab3-onboard/onboard.sh team-alpha alpha-pilot --project-type starter-tier --project-type-kind ClusterProjectType --apply
```

## 3. Check the quota

Find the cell namespace of `alpha-pilot` in development, then check its quota:

```
cd ~/oc-210-labs/lab4-roles-quota
CELL=$(kubectl get namespaces \
  -l openchoreo.dev/project=alpha-pilot,openchoreo.dev/environment=development \
  -o jsonpath='{.items[0].metadata.name}')
echo "cell namespace: $CELL"
kubectl get resourcequota -n $CELL -o json | python3 check_quota.py
```

The program lists each starter-tier limit as OK, DIFFERS or MISSING, and exits with status 1 if any is not OK. Quantities are compared by value, so `8192Mi` matches `8Gi`. To see both outcomes first, run it on the samples:

```
cd ~/oc-210-labs/lab4-roles-quota
python3 check_quota.py samples/quota-starter.json
python3 check_quota.py samples/quota-wrong.json
```

## What you should see

- `occ authzrole list -n team-alpha` shows `team-developer`, and the binding lists the group entitlement.
- The check prints seven OK lines for the cell of a project that uses your type.
- A cell with no quota, such as a project that still uses the default type, prints `No ResourceQuota limits found` and exits with status 1.

## If something fails

- Role rejected: compare field names and action names with an existing role: `kubectl get clusterauthzrole developer -o yaml`.
- The binding has no effect: the claim name or value does not match your token.
- Quota missing: confirm the project uses your type and that its ProjectReleaseBinding has reconciled.

## How it maps to OpenChoreo

The role is a template for what a team's developers may do, and the binding ties it to an identity. The quota is part of the ProjectType, so every project of that type gets the same cell. That is the Handbook's tiered quota, expressed as a type instead of a script that runs after the namespace exists.
