# Lab 2: register a service and check the catalog

In Lab 2 you see how the portal builds the catalog from what the platform runs: the namespace, project and component from Lab 1 appear as a Domain, a System and a Component without anyone writing a catalog file. You read one of those generated entities, register one extra entry with a named owner, and check entries for completeness. This folder holds the entry file and the completeness check.

| Path | Purpose |
|---|---|
| `catalog/pilot-docs-site.yaml` | The entry you register in step 3. Replace the owner and the system |
| `catalog/billing-api.yaml` | A complete entry, for comparison |
| `catalog/orphan-service.yaml` | An incomplete entry that shows what the check reports |
| `catalog_check.py` | Checks entries for an owner, a lifecycle, a link and a system |

The steps for this lab are in [WORKBOOK-local.md](WORKBOOK-local.md), or [WORKBOOK-sandbox.md](WORKBOOK-sandbox.md) in the WSO2 sandbox.

## Files you create in this lab

| File | Created in | What it is |
|---|---|---|
| `pilot-docs-site.yaml` | step 3 | Your filled-in copy of `catalog/pilot-docs-site.yaml`, with your group as owner and `default` as its system |

Git ignores it. It depends on your group name, so there is no reference copy.

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

1. Fill in `catalog/pilot-docs-site.yaml`: `spec.owner` with a group that exists in your catalog, written `group:default/` followed by the group name, and `spec.system` with `default`, the project from Lab 1. The workbook does this with one `sed` command.
2. Run the check on it. Both placeholders count as filled in, so the check does not catch a wrong name. The portal does, when it cannot find the group.
3. Put the file somewhere the portal can read it, such as a public GitHub gist, and note its raw URL.
4. In the portal, open `/catalog-import`, paste the URL and import it.

```
cd ~/oc-210-labs/lab2-catalog-check
python3 catalog_check.py catalog/
```

Run on the whole folder, the check includes all three files. Add `--strict` to exit with status 1 when any entry is incomplete, which is useful in a script.

## What you should see

- The greeter from Lab 1 appears as a Component in the `default` System, and its entity was generated, not written.
- Your entry appears in the portal with its owner shown, in the same System.
- If the owner shows as unknown, the group does not exist in the catalog yet. Pick one from the Group filter.

## How it maps to OpenChoreo

OpenChoreo creates the Domain, System and Component entities for your namespaces, projects and components, so ownership comes from the platform's objects and cannot drift from what runs. The file here is for something OpenChoreo does not run, such as a documentation site. The completeness check is the same one you would use to decide whether a catalog is healthy: an entry without an owner is an entry nobody will fix.
