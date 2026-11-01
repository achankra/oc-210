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

## When sign-in or the installer fails

**Portal sign-in fails with `Authentication failed, Failed to obtain access token`, and the catalog stays empty.** The cluster was restarted without k3d, for example by restarting Docker or Colima, and CoreDNS lost the `host.k3d.internal` entry that k3d adds on `k3d cluster start`. The installer's DNS rewrite sends every `*.openchoreo.localhost` name inside the cluster to `host.k3d.internal`, so the portal can no longer reach the identity provider at `thunder.openchoreo.localhost`; its log shows `ENOTFOUND thunder.openchoreo.localhost`. Check the entry:

```
kubectl -n kube-system get configmap coredns -o jsonpath='{.data.NodeHosts}'; echo
```

If no line names `host.k3d.internal`, stop and start the cluster through k3d, which adds it back:

```
k3d cluster stop openchoreo
k3d cluster start openchoreo
kubectl wait -n openchoreo-control-plane --for=condition=available --timeout=300s deployment --all
```

Confirm the name resolves inside the cluster, then sign in again in a private window:

```
kubectl run dns-test --restart=Never --image=busybox:1.36 -- nslookup -type=a thunder.openchoreo.localhost
sleep 10; kubectl logs dns-test; kubectl delete pod dns-test
```

The lookup prints an `Address:` line. After any restart, start the cluster with `k3d cluster start openchoreo` rather than restarting its container.

**Re-running the installer fails at the control plane with `UPGRADE FAILED: conflict occurred while applying object openchoreo-control-plane/cluster-gateway-ca`.** An earlier `kubectl apply` wrote the cluster gateway's CA certificate into this ConfigMap, and Helm 4 applies upgrades server-side, so it will not overwrite a field that another tool owns. Everything before this step is fine. Delete the ConfigMap and run the same install command again:

```
kubectl delete configmap cluster-gateway-ca -n openchoreo-control-plane
```

The control plane does not need this copy after the first install, and the installer does not recreate it. Each plane keeps its own copy, which you can check is still there:

```
kubectl get configmap -A | grep cluster-gateway-ca
```

It lists the data, workflow and observability plane namespaces. The conflict comes from Helm 4, which Homebrew installs (`helm version --short`); with Helm 4, delete the ConfigMap before each re-run.

## Known issues on v1.3

The course runs on v1.3.2. Every row holds on v1.3.1 and v1.3.2. The labs already work around each of these. If you see one of the symptoms, the last column says what fixes it and which lab covers it.

| Symptom | Cause | Fix, and where |
|---|---|---|
| Portal sign-in fails with `Failed to obtain access token` after a Docker or Colima restart | CoreDNS lost the `host.k3d.internal` entry, so the portal cannot reach the identity provider | `k3d cluster stop openchoreo`, then `k3d cluster start openchoreo`; see [When sign-in or the installer fails](#when-sign-in-or-the-installer-fails) |
| Re-running the installer fails with `UPGRADE FAILED: conflict ... cluster-gateway-ca` | An earlier `kubectl apply` owns the ConfigMap's `ca.crt`, and Helm 4 will not overwrite it | Delete the ConfigMap and re-run the installer; the planes keep their own copies; see [When sign-in or the installer fails](#when-sign-in-or-the-installer-fails) |
| zsh runs `#` lines as commands | Comments are off in interactive zsh | `setopt interactivecomments`, pre-work |
| A new project gets no cell namespaces and nothing deploys into it | Cells come only from ProjectReleaseBindings; the portal wizard creates them, but a project applied with `kubectl` gets none | `scripts/bind-project.sh TEAM PROJECT`, Lab 3; `onboard.sh` creates them |
| A new team namespace does not appear in `occ namespace list` or in the portal's wizards | It lacks the control-plane label | `openchoreo.dev/control-plane=true`, set by `onboard.sh`, Lab 3 step 2 |
| `resourcequotas ... is forbidden` on a project binding | The cluster agent cannot manage ResourceQuotas on any install, out of the box | ClusterRole and binding for `cluster-agent-dataplane`, Lab 4 step 2 |
| A new ProjectType has no template under the Create page's Project card | The portal refreshes on a schedule | Wait a minute and reload, Lab 4 step 3 |
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

## After the course: the rest of the portal

The labs follow one path through the portal: the catalog, the Create page's Project and Component cards, a component's own pages, promotion, and Audit Logs (Lab 4 and the capstone). The course leaves the rest of the portal out on purpose, to keep the onboarding path in focus. On the cluster you already have, each of these takes a few minutes and needs nothing new installed unless the row says so.

| In the portal | What to try | Why it matters |
|---|---|---|
| **APIs**, left menu | See whether the endpoints of `order-service` and `greeter-service` are listed | Teams find a service by the API it offers, not by asking around |
| **Platform**, left menu | See what the platform team's view shows: planes, environments and pipelines | The parts teams build on, which the labs created from the terminal |
| **Create**, Resource card | See which managed resources the platform offers through ResourceTypes | Databases, queues and caches as self-service, the next thing a team asks for after a service |
| **Create**, Platform Resources | Open the Environment, Deployment Pipeline and Notification Channel forms and read them; there is no need to submit | The same objects `onboard.sh` creates, as forms a platform admin can use |
| **Create**, Component card | Create a component that builds from source instead of a pre-built image | The build runs as a Workflow on the workflow plane; Lab 5 used an image to save time |
| **Cost Insights**, left menu | Open it | It needs a FinOps module such as OpenCost before it shows data; that gap is itself a lesson about enabling only what the platform backs |
| An AI agent | Connect one to the control plane and observability MCP servers, as OC-201 Lab 4 does, and ask it to onboard `team-gamma` | An agent is one more client of the same API, under the same roles, and its changes appear in Audit Logs, as yours did in the capstone |

Then score the portal again with the Lab 1 worksheet and compare it with your first score. The planes that moved are the ones you now know how to use; the ones that did not are where a portal team would invest next.

Where to go deeper:

- OpenChoreo documentation: [openchoreo.dev](https://openchoreo.dev)
- OC-201, Cloud Native Platform Engineering with OpenChoreo, if you have not taken it: it builds the platform this course puts a portal on, including governed cells, ComponentTypes and Traits, and agents through MCP
- The Platform Engineer's Handbook (see [About the book](#about-the-book))

When you are done, `k3d cluster stop openchoreo` frees the memory and keeps everything; `k3d cluster delete openchoreo` removes the cluster.

## About the book

Several labs use ideas and numbers from The Platform Engineer's Handbook by Ajay Chankramath (Packt, 2025): the six evaluation planes for a portal (Lab 1, from Chapter 6, Table 6.1), the catalog-info example (Lab 2), the `team-{teamname}` naming convention (Lab 3), the starter-tier quota and team roles (Lab 4), and the onboarding metrics and seven-minute friction threshold (capstone, from Chapter 7). Each place in the workbooks and READMEs names the source. Everything a lab needs is in this repository, so the book is not mandatory, but we recommend getting it to go deeper: [peh-packt.platformetrics.com](https://peh-packt.platformetrics.com) or [Amazon](https://www.amazon.com/dp/B0FR59Z7Q2).

## Good to know

- Some steps write files as you go, such as the timing log and the Lab 4 ProjectType. They are your own lab output, and git ignores them. Lab 4 has a `reference/` copy of the ProjectType: if that step fails or you fall behind, copy it into place and carry on.
- If the portal has no wizard for a step, each lab gives the same step through the API: `onboard.sh TEAM PROJECT` for a project, `lab5-scaffold/create-order-service.sh` for the service.
- The scripts that create objects check first. `onboard.sh` and `apply-access.sh` only render and check the files until you add `--apply`.
- The Python programs read files or standard input and need no cluster, so you can try them on the samples before the lab.
- The names in the templates (`team-alpha`, `team-developer`, `starter-tier`) are the names the workbook uses. If you change them, use the same names in every step.
- Your output will not match the READMEs character for character. Names, timestamps and generated IDs differ on every machine.
