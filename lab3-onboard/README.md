# Lab 3: onboard a team through the portal

This lab replaces a ticket queue with self-service. The platform team sets up a team's space with one command. The team then creates its own project in the portal's Create Project wizard, which the portal generates for each ProjectType, and gets its cells. You time the whole thing, then look at the API underneath and onboard a second team through it.

| Path | Purpose |
|---|---|
| `onboard.sh` | With a team name, creates the team space: namespace, environments, pipeline, and the team's group in the identity provider. With a project name too, also creates the project, owned by the team's group, and its bindings. Checks first; `--apply` creates |
| `set-owner.sh` | Gives a project the team's group as owner in the catalog, for projects created in the portal wizard. Checks first; `--apply` sets it |
| `templates/` | The namespace, environments, pipeline, project and project bindings, with `${...}` values |
| `scripts/create-group.sh` | Creates a group in ThunderID, the local identity provider, through its management API. `onboard.sh` runs it |
| `scripts/bind-project.sh` | Gives a project its cells, one ProjectReleaseBinding per environment, if it has none |
| `scripts/render.py` | Fills a template. Stops if a value is missing |
| `scripts/mark.sh` | Logs a step you did in the portal or by hand, so the timing counts it |
| `scripts/lib.sh` | The log helper the scripts share |

The steps for this lab are in [WORKBOOK-local.md](WORKBOOK-local.md), or [WORKBOOK-sandbox.md](WORKBOOK-sandbox.md) in the WSO2 sandbox.

## Files you create in this lab

| File | Created in | What it is |
|---|---|---|
| `onboarding-log.csv` | every step | The timing log `mark.sh` and the scripts write |
| `rendered/TEAM/` | steps 2 and 6 | What `onboard.sh` renders from `templates/` |

Git ignores both. The capstone writes to the same log.

## Requirements

- The OpenChoreo cluster from the pre-work, and `kubectl` and `occ` signed in to it.
- The portal, signed in with `admin@openchoreo.dev` / `Admin@123`.
- Python 3.9 or newer for `render.py`. No other packages.

## The platform team: a team space

Check, then create:

```
cd ~/oc-210-labs/lab3-onboard
./onboard.sh team-alpha
./onboard.sh team-alpha --apply
```

This reads the data plane from the `development` environment in the `default` namespace, renders the namespace, environments and pipeline into `rendered/team-alpha/`, and checks them. With `--apply` it applies the namespace, then runs a server-side dry run and `occ apply` for each OpenChoreo object. The namespace carries `openchoreo.dev/control-plane=true`, so it appears in OpenChoreo and in the portal's wizards. The script also creates the group `team-alpha` in ThunderID with the installer's system application, as the installer's `occ-login.sh` does; the portal syncs it into the catalog as `group:default/team-alpha`. Running it again is safe. If ThunderID cannot be reached, the script says so and carries on.

## The team: a project from the portal

In the portal, choose **Create**, open the **Project** card, and pick the template for the ProjectType you want. Fill in the namespace, the project name and the pipeline. The wizard creates the project and one ProjectReleaseBinding per environment, so the project gets its cells. Log the step so the timing counts it:

```
cd ~/oc-210-labs/lab3-onboard
./scripts/mark.sh "project" "portal: Create Project, alpha-shop"
```

The wizard has no owner field, so the project starts with the portal's default owner, `openchoreo-users`. Give it the team's group:

```
cd ~/oc-210-labs/lab3-onboard
./set-owner.sh team-alpha alpha-shop
./set-owner.sh team-alpha alpha-shop --apply
```

This sets the project's `backstage.io/owner` annotation to `group:default/team-alpha`; the project's components inherit it. Use `--group NAME` for a different group. The value has to be the full reference: generated entities live in a catalog namespace named after the OpenChoreo namespace, while the identity provider's groups live in `default`.

If the project has no cells, give it bindings:

```
cd ~/oc-210-labs/lab3-onboard
./scripts/bind-project.sh team-alpha alpha-shop
```

## The API underneath

The wizard and the script call the same OpenChoreo API. To onboard a team with no person in the loop, pass a project name and the script creates everything, bindings and owner included:

```
cd ~/oc-210-labs/lab3-onboard
./onboard.sh team-demo demo-shop --apply
```

Options:

| Option | Default | Effect |
|---|---|---|
| `--tier NAME` | `starter` | Value of the `platform.io/tier` label on the namespace |
| `--project-type NAME` | `default` | ProjectType for the project. Lab 4 uses `starter-tier` |
| `--project-type-kind KIND` | `ClusterProjectType` | `ClusterProjectType` or `ProjectType` |
| `--dataplane-kind`, `--dataplane-name` | read from `default` | Data plane the environments map to |

Every command from an `--apply` run is written to `onboarding-log.csv`, with the time it ran. The first `mark.sh` call creates the log and starts the clock. Delete the file to start over.

## What you should see

- `occ namespace list` shows `team-alpha`; `occ project list -n team-alpha` shows `alpha-shop`, created in the portal, with a cell namespace in development and staging.
- `team-demo` and `demo-shop`, created by the script, look the same.
- In the catalog, alpha-shop is owned by `team-alpha` and demo-shop by `team-demo`, not by `openchoreo-users`. The owner appears after the catalog's next sync.

## If something fails

- `team-alpha` is not offered in the wizard: the namespace needs `openchoreo.dev/control-plane=true`, which `onboard.sh` sets. Wait a minute for the portal to refresh.
- `Could not read the data plane`: pass `--dataplane-kind` and `--dataplane-name`, or check that `kubectl get environment development -n default` works.
- A project has no cells: run `./scripts/bind-project.sh TEAM PROJECT`. A project applied with `kubectl` gets no bindings.
- A pipeline is rejected: its promotion paths must name environments that exist in the same namespace.
- `Skipped the group`: the script could not reach ThunderID's management API. The owner annotation still works, but the owner shows without a link. Check `kubectl get httproute -n thunder`, then run `./scripts/create-group.sh TEAM`.
- The owner is still `openchoreo-users`: run `./set-owner.sh TEAM PROJECT` to see the project's annotations, then `--apply` if `backstage.io/owner` is missing. Otherwise wait for the catalog's next sync.

## How it maps to OpenChoreo

The Handbook builds an onboarding API and puts the portal on top of it. In OpenChoreo both already exist: the platform team publishes ProjectTypes, the portal generates a Create Project wizard for each, and the wizard, `occ` and this script are all clients of the same API. The Handbook is The Platform Engineer's Handbook by Ajay Chankramath (Packt, 2026). The book is not required for this course, but we recommend it to go deeper: [peh-packt.platformetrics.com](https://peh-packt.platformetrics.com) or [Amazon](https://www.amazon.com/dp/B0FR59Z7Q2).
