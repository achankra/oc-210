# OC-210 labs: developer portals and self-service onboarding

Lab code for OC-210, Developer Portals & Self-Service Onboarding on OpenChoreo, from the Platform Engineering Academy by Platformetrics in collaboration with WSO2/OpenChoreo. The steps for every lab are in the workbook, which is part of this repository: start at [WORKBOOK.md](WORKBOOK.md). Each lab folder has it in two editions, with the files, scripts and programs its steps use:

- **WORKBOOK-local.md**: OpenChoreo v1.3.2 on a local k3d cluster (macOS, Linux, or Windows with WSL 2). The main path for the course.
- **WORKBOOK-sandbox.md**: the WSO2 OpenChoreo Sandbox (v1.2.2) in your browser, for anyone who cannot run the cluster locally.

| Folder | Lab | What is in it |
|---|---|---|
| `prework/` | Pre-work, before Day 1 | Installing the tools and the cluster; in the sandbox edition, starting a session |
| `lab1-portal-scorecard/` | Lab 1: tour the portal, find a service | A scorecard file for the six evaluation planes and a program that checks and summarizes it |
| `lab2-catalog-check/` | Lab 2: register a service in the catalog | A catalog entry to register, two sample entries, and a completeness check |
| `lab3-onboard/` | Lab 3: onboard a team through the portal | The script that sets up a team space (and, through the API, a whole team), templates, a bindings helper, and the timing log |
| `lab4-roles-quota/` | Lab 4: publish a project type as a portal wizard | The starter-tier quota and the edit that builds the type, a quota check, and the access role and binding |
| `lab5-scaffold/` | Lab 5: create a service from the portal | An endpoint check for the data plane gateway, and the same service created through the API |
| `capstone/` | Capstone: onboard a team end to end | The scorecard program and a script that repeats the onboarding through the API |
| `sandbox/` | Sandbox edition | `restore.sh`, which recreates earlier labs in a new one-hour session |
| `tests/` | For instructors | `check-repo.sh`, which checks the lab code without a cluster |

Each folder has its own README with what is in it, the files you create there, and what you should see.

The labs put the portal first. The platform team publishes ProjectTypes and ComponentTypes, and the portal generates a Create Project and a Create Component wizard for each, so a team onboards itself without a ticket and without writing a template. Every lab then shows the same objects through `occ` and the API underneath, which is how onboarding runs when no person is in the loop.

## Setup

In the sandbox, the session block at the top of each lab does all of this. On your own machine, the pre-work installs the tools and the cluster. For the lab code:

```
git clone https://github.com/achankra/oc-210.git ~/oc-210-labs
cd ~/oc-210-labs
python3 -m venv .venv
source ~/oc-210-labs/.venv/bin/activate
pip install pyyaml
```

Every command in the workbook and in these READMEs uses `~/oc-210-labs`. If the repository is somewhere else, link it: `ln -s "/path/to/oc-210-labs" ~/oc-210-labs`. On a Mac, run `echo 'setopt interactivecomments' >> ~/.zshrc && source ~/.zshrc` once, so pasted blocks can contain `#` comment lines.

## What you need

- Docker, k3d, kubectl, Helm and the `occ` CLI v1.3.2, with the OpenChoreo cluster from the pre-work running.
- Python 3.9 or newer, with PyYAML in `.venv` for Labs 2 and 4.

## Known issues on v1.3

The course runs on v1.3.2. Every row holds on v1.3.1 and v1.3.2. The labs already work around each of these. If you see one of the symptoms, the last column says what fixes it and which lab covers it.

| Symptom | Cause | Fix, and where |
|---|---|---|
| zsh runs `#` lines as commands | Comments are off in interactive zsh | `setopt interactivecomments`, pre-work |
| A new project gets no cell namespaces and nothing deploys into it | Cells come only from ProjectReleaseBindings; the portal wizard creates them, but a project applied with `kubectl` gets none | `scripts/bind-project.sh TEAM PROJECT`, Lab 3; `onboard.sh` creates them |
| A new team namespace does not appear in `occ namespace list` or in the portal's wizards | It lacks the control-plane label | `openchoreo.dev/control-plane=true`, set by `onboard.sh`, Lab 3 step 2 |
| `resourcequotas ... is forbidden` on a project binding | The cluster agent cannot manage ResourceQuotas on any install, out of the box | ClusterRole and binding for `cluster-agent-dataplane`, Lab 4 step 2 |
| A new ProjectType has no wizard on the Create page | The portal refreshes on a schedule | Wait a minute and reload, Lab 4 step 3 |
| A component is created but not Ready | Most validation errors show in the object's status, not when it is created | `kubectl get component NAME -n NS -o jsonpath='{.status.conditions}'`, Lab 5 |
| A project's type cannot be changed | The type is fixed when the project is created | Create a new project with the type, as Lab 4 does with `alpha-pilot` |
| The portal import rejects the gist URL | The portal reads only hosts on its allow list | Use the raw URL; an administrator adds the host to `backend.reading.allow`, Lab 2 |

## Check the repository

To check the lab code without a cluster, for example before a cohort or after a change:

```
cd ~/oc-210-labs
source .venv/bin/activate
./tests/check-repo.sh
```

It confirms every file the workbooks use is here and the links between them work, that the scripts parse, and that the Python programs, templates and the Lab 4 quota edit give the results the workbooks describe. It ends with `N passed, 0 failed`. The steps that need the cluster are tested by running the workbook itself.

## Good to know

- Some steps write files as you go, such as the timing log and the Lab 4 ProjectType. They are your own lab output, and git ignores them. Lab 4 has a `reference/` copy of the ProjectType: if that step fails or you fall behind, copy it into place and carry on.
- If the portal has no wizard for a step, each lab gives the same step through the API: `onboard.sh TEAM PROJECT` for a project, `lab5-scaffold/create-order-service.sh` for the service.
- The scripts that create objects check first. `onboard.sh` and `apply-access.sh` only render and check the files until you add `--apply`.
- The Python programs read files or standard input and need no cluster, so you can try them on the samples before the lab.
- The names in the templates (`team-alpha`, `team-developer`, `starter-tier`) are the names the workbook uses. If you change them, use the same names in every step.
- Your output will not match the READMEs character for character. Names, timestamps and generated IDs differ on every machine.
