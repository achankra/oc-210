# Lab 3: onboard a team with occ

This lab replaces a ticket queue with a short sequence of commands: a labeled team namespace, environments, a promotion pipeline and a project. You write the steps by hand in the workbook and then run the same steps from a script, so you can see what is worth automating.

| Path | Purpose |
|---|---|
| `onboard.sh` | Renders the five files for a team (including the project bindings), checks them, and with `--apply` creates the objects |
| `templates/` | The namespace, environments, pipeline, project and project bindings, with `${...}` values |
| `scripts/render.py` | Fills a template. Stops if a value is missing |
| `scripts/mark.sh` | Logs a step you ran by hand, so the timing counts it |
| `scripts/lib.sh` | The log helper the scripts share |


The steps for this lab are in [WORKBOOK-local.md](WORKBOOK-local.md).

## Files you create in this lab

These are not in the repository until you run the step that writes them. Git ignores them.

| File | Created in | What it is |
|---|---|---|
| `team-alpha-envs.yaml` | step 3 | The development and staging Environments, on your cluster's data plane |
| `team-alpha-pipeline.yaml` | step 3 | The pipeline that promotes development to staging |
| `alpha-shop-project.yaml` | step 4 | The `alpha-shop` Project |
| `alpha-shop-bindings.yaml` | step 4 | One ProjectReleaseBinding per environment, which create the cells |
| `onboarding-log.csv` | every step | The timing log `mark.sh` and the scripts write |
| `rendered/TEAM/` | part B | What `onboard.sh` renders from `templates/` |
| `order-service.yaml` | capstone | The capstone's service, written here so the log stays in one place |

`reference/` holds the pipeline, project and bindings. If a step fails or you fall behind, copy the file into place, for example `cp reference/alpha-shop-project.yaml .`, apply it, and carry on. The environments file has no reference copy, because it names your cluster's data plane.

## Requirements

- The OpenChoreo cluster from the pre-work, and `kubectl` and `occ` signed in to it (`occ login`).
- Python 3.9 or newer for `render.py`. No other packages.

## Onboard with commands

Do the steps in the workbook by hand first and write down the time, as the lab asks. Then use the script on a second team to see the same result without typing the YAML.

Check without creating anything:

```
cd ~/oc-210-labs/lab3-onboard
./onboard.sh team-demo demo-shop
```

This reads the data plane from the `development` environment in the `default` namespace, renders five files into `rendered/team-demo/`, and checks each one with a client-side dry run. Open the files. They are the objects you wrote by hand in the lab.

Create the objects:

```
cd ~/oc-210-labs/lab3-onboard
./onboard.sh team-demo demo-shop --apply
```

The script applies the namespace first. For each OpenChoreo object it runs a server-side dry run, then `occ apply`. It ends by listing namespaces and the team's projects.

Options:

| Option | Default | Effect |
|---|---|---|
| `--tier NAME` | `starter` | Value of the `platform.io/tier` label on the namespace |
| `--project-type NAME` | `default` | ProjectType for the project. Lab 4 uses `starter-tier` |
| `--project-type-kind KIND` | `ClusterProjectType` | `ClusterProjectType` or `ProjectType` |
| `--dataplane-kind`, `--dataplane-name` | read from `default` | Data plane the environments map to |

Every command from an `--apply` run is written to `onboarding-log.csv`, with the time it ran. The capstone uses that file to compute your time-to-first-deploy. If you run a step by hand, log it so it counts:

```
cd ~/oc-210-labs/lab3-onboard
./scripts/mark.sh "role and binding" "occ apply -f team-developer-role.yaml"
```

The first call creates the log and starts the clock. Delete the file to start over.

## What you should see

- `occ namespace list` shows `team-demo`, and `occ project list -n team-demo` shows `demo-shop`. The project appears in the portal.

## If something fails

- `Could not read the data plane`: pass `--dataplane-kind` and `--dataplane-name`, or check that `kubectl get environment development -n default` works.
- Project not listed: the namespace needs the label `openchoreo.dev/control-plane=true`. `onboard.sh` sets it. A namespace created another way may not have it.
- An Environment is rejected: it must reference an existing data plane. Copy the reference from the `default` environment.
- A pipeline is rejected: its promotion paths must name environments that exist in the same namespace.

## How it maps to OpenChoreo

A team namespace, its environments, its pipeline, its project and the project's bindings are ordinary OpenChoreo resources, so onboarding is applying five files in the right order. The Handbook builds an onboarding service to do this. In OpenChoreo the API already exists, and the portal, the CLI and a script are clients of it.
