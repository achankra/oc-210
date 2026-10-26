# OC-210 labs: developer portals and self-service onboarding

Lab code for OC-210, Developer Portals & Self-Service Onboarding on OpenChoreo, from the Platform Engineering Academy by Platformetrics in collaboration with WSO2/OpenChoreo. The steps for every lab are in the workbook, which is part of this repository: start at [WORKBOOK.md](WORKBOOK.md). Each lab folder has it in two editions, with the files, scripts and programs its steps use:

- **WORKBOOK-local.md**: OpenChoreo v1.3.1 on a local k3d cluster (macOS, Linux, or Windows with WSL 2). The main path for the course.
- **WORKBOOK-sandbox.md**: the WSO2 OpenChoreo Sandbox (v1.2.2) in your browser, for anyone who cannot run the cluster locally.

| Folder | Lab | What is in it |
|---|---|---|
| `prework/` | Pre-work, before Day 1 | Installing the tools and the cluster; in the sandbox edition, starting a session |
| `lab1-portal-scorecard/` | Lab 1: tour the portal, find a service | A scorecard file for the six evaluation planes and a program that checks and summarizes it |
| `lab2-catalog-check/` | Lab 2: register a service in the catalog | A catalog entry to register, two sample entries, and a completeness check |
| `lab3-onboard/` | Lab 3: onboard a team | Templates and a script that onboard a team, and a step log |
| `lab4-roles-quota/` | Lab 4: access roles and a quota | Role and binding templates, the starter-tier quota, and a quota check |
| `lab5-scaffold/` | Lab 5: scaffold and deploy | An endpoint check for the data plane gateway |
| `capstone/` | Capstone: onboard a team end to end | The scorecard program and a script that repeats the onboarding |
| `sandbox/` | Sandbox edition | `restore.sh`, which recreates earlier labs in a new one-hour session |
| `tests/` | For instructors | `check-repo.sh`, which checks the lab code without a cluster |

Each folder has its own README with what is in it, the files you create there, and what you should see.

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

- Docker, k3d, kubectl, Helm and the `occ` CLI v1.3.1, with the OpenChoreo cluster from the pre-work running.
- Python 3.9 or newer, with PyYAML in `.venv` for Labs 2 and 4.

## Known issues on v1.3.1

The labs already work around each of these. If you see one of the symptoms, the last column says what fixes it and which lab covers it.

| Symptom | Cause | Fix, and where |
|---|---|---|
| zsh runs `#` lines as commands | Comments are off in interactive zsh | `setopt interactivecomments`, pre-work |
| A new project gets no cell namespaces and nothing deploys into it | Cells come only from ProjectReleaseBindings | One binding per environment: Lab 2 step 1, Lab 3 step 4, and `onboard.sh` |
| A new team namespace does not appear in `occ namespace list` | It lacks the control-plane label | `openchoreo.dev/control-plane=true`, Lab 3 step 2 |
| `resourcequotas ... is forbidden` on a project binding | The data plane agent cannot manage ResourceQuotas | ClusterRole and binding for `cluster-agent-dataplane`, Lab 4 step 5 |
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

- Some steps write files as you go, such as the Lab 3 project and the Lab 4 ProjectType. They are your own lab output, and git ignores them. Labs 2 to 5 have a `reference/` folder with a copy of each one that does not depend on your cluster: if a step fails or you fall behind, copy the file into place and carry on.

- The scripts that create objects check first. `onboard.sh` and `apply-access.sh` only render and check the files until you add `--apply`.
- The Python programs read files or standard input and need no cluster, so you can try them on the samples before the lab.
- The names in the templates (`team-alpha`, `team-developer`, `starter-tier`) are the names the workbook uses. If you change them, use the same names in every step.
- Your output will not match the READMEs character for character. Names, timestamps and generated IDs differ on every machine.
