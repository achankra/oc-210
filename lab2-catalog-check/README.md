# Lab 2: register a service and check the catalog

In Lab 2 you create a project and a component, find them in the portal as a System and a Component, and register one extra catalog entry with a named owner. This folder holds the entry file and a program that checks catalog entries for completeness.

| Path | Purpose |
|---|---|
| `catalog/pilot-docs-site.yaml` | The entry you register in step 4. Replace the owner and the system |
| `catalog/billing-api.yaml` | A complete entry, for comparison |
| `catalog/orphan-service.yaml` | An incomplete entry that shows what the check reports |
| `catalog_check.py` | Checks entries for an owner, a lifecycle, a link and a system |


The steps for this lab are in [WORKBOOK-local.md](WORKBOOK-local.md).

## Files you create in this lab

These are not in the repository until you run the step that writes them. Git ignores them.

| File | Created in | What it is |
|---|---|---|
| `~/oc-210-labs/lab2-work/team-alpha-pilot-project.yaml` | step 1 | The `team-alpha-pilot` Project, on the default pipeline and project type |
| `~/oc-210-labs/lab2-work/pilot-component.yaml` | step 2 | The greeter sample, renamed `pilot-service` and owned by `team-alpha-pilot` |
| `~/oc-210-labs/lab2-work/pilot-scaffold.yaml` | step 2 | What `occ component scaffold` generates, for comparison |
| `pilot-docs-site.yaml` | step 4 | Your filled-in copy of `catalog/pilot-docs-site.yaml`, with your group as owner |

`reference/` holds the first two as they come out on a v1.3.1 install. If a step fails or you fall behind: `mkdir -p ~/oc-210-labs/lab2-work && cp reference/*.yaml ~/oc-210-labs/lab2-work/`. The other two depend on your cluster and your group name.

## Requirements

Python 3.9 or newer and PyYAML, installed in the setup: `source ~/oc-210-labs/.venv/bin/activate`.

## Run the check

On the sample entries first:

```
cd ~/oc-210-labs/lab2-catalog-check
source ~/oc-210-labs/.venv/bin/activate
python3 catalog_check.py catalog/billing-api.yaml catalog/orphan-service.yaml
```

`billing-api` passes every check. `orphan-service` has an owner of `unknown`, no lifecycle, no link and no system, so it fails all four. The last line gives the number of complete entries and the percentage of checks passed.

## Register your own entry

1. Open `catalog/pilot-docs-site.yaml`. Replace the two `REPLACE-WITH-...` values: `spec.owner` with a group that exists in your catalog, written `group:default/` followed by the group name, and `spec.system` with the name of the project you created in the lab. The workbook does this with one command.
2. Run the check on it. Both placeholders count as filled in, so the check does not catch a wrong name. The portal does, when it cannot find the group.
3. Put the file in a Git repository you control and note its raw file URL.
4. In the portal, open `/catalog-import`, paste the URL and import it.

```
cd ~/oc-210-labs/lab2-catalog-check
python3 catalog_check.py catalog/
```

Run on the whole folder, the check includes all three files, so you see your entry next to the two samples. Add `--strict` to exit with status 1 when any entry is incomplete, which is useful in a script.

## What you should see

- Your entry appears in the portal with its owner shown.
- If the owner shows as unknown, the group does not exist in the catalog yet. Import groups before assigning owners.
- The program's percentage is a count of the four items on the entries you gave it. For the portal as a whole, count the entries you can see by hand, as the workbook describes.

## How it maps to OpenChoreo

OpenChoreo creates the Domain, System and Component entities for your namespaces, projects and components, so those need no file. The file here is for something OpenChoreo does not run, such as a documentation site. The completeness check is the same one you would use to decide whether a catalog is healthy: an entry without an owner is an entry nobody will fix.
