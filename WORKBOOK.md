# OC-210 workbook

Developer Portals & Self-Service Onboarding on OpenChoreo. Five labs and a capstone, with a pre-work module before Day 1.

Each module folder has two editions of its workbook:

- **WORKBOOK-local.md**: OpenChoreo v1.3.1 on a k3d cluster on your own machine (macOS, Linux, or Windows with WSL 2). This is the main path for the course.
- **WORKBOOK-sandbox.md**: the WSO2 OpenChoreo Sandbox at demo.openchoreo.wso2.com (v1.2.2, one-hour sessions), in your browser. Use it if you cannot run the cluster locally.

## Modules

| Module | Topic | Local install | Sandbox |
|---|---|---|---|
| Pre-work | Before Day 1: Install the tools and the k3d cluster, get the lab code, confirm the portal opens | [WORKBOOK-local.md](prework/WORKBOOK-local.md) | [Session setup](prework/WORKBOOK-sandbox.md) |
| Lab 1 | M01 Portals: Deploy a service, find it in the portal, score the portal on six planes | [WORKBOOK-local.md](lab1-portal-scorecard/WORKBOOK-local.md) | [WORKBOOK-sandbox.md](lab1-portal-scorecard/WORKBOOK-sandbox.md) |
| Lab 2 | M02 Catalog: Create a project and component; register an extra entry with an owner | [WORKBOOK-local.md](lab2-catalog-check/WORKBOOK-local.md) | [WORKBOOK-sandbox.md](lab2-catalog-check/WORKBOOK-sandbox.md) |
| Lab 3 | M03 Onboarding: Onboard team-alpha with occ and record the time; then onboard a second team with a script | [WORKBOOK-local.md](lab3-onboard/WORKBOOK-local.md) | [WORKBOOK-sandbox.md](lab3-onboard/WORKBOOK-sandbox.md) |
| Lab 4 | M04 RBAC and quota: Grant access with roles and bound the cell with a starter-tier quota | [WORKBOOK-local.md](lab4-roles-quota/WORKBOOK-local.md) | [WORKBOOK-sandbox.md](lab4-roles-quota/WORKBOOK-sandbox.md) |
| Lab 5 | M05 Starter kits: Scaffold, deploy and promote a service for the team | [WORKBOOK-local.md](lab5-scaffold/WORKBOOK-local.md) | [WORKBOOK-sandbox.md](lab5-scaffold/WORKBOOK-sandbox.md) |
| Capstone | M06: Onboard team-beta end to end and fill in the scorecard | [WORKBOOK-local.md](capstone/WORKBOOK-local.md) | [WORKBOOK-sandbox.md](capstone/WORKBOOK-sandbox.md) |

## How to use the workbook

- Code blocks are commands to paste; GitHub shows a copy button on each. Lines starting with `#` are comments; the shell ignores them once the pre-work `setopt interactivecomments` line has run (macOS, zsh).
- Blocks are self-contained. A value such as a cell namespace or a data plane name is looked up in the block that needs it.
- The lab code lives in `~/oc-210-labs`. Every `cd` uses that full path, so it works from any folder.
- No block asks you to paste YAML. Objects you write by hand are written as JSON, which `kubectl` and `occ apply` read the same way and which survives copying.
- Long commands are split with `\` at the end of a line. Paste the whole block.
- One value comes from you: the catalog group that owns your entry in Lab 2.
- macOS blocks are the default. Where a step differs, blocks labeled **Linux** and **Windows** follow; paste only the ones for your machine. On Windows every block runs in the Ubuntu terminal on WSL 2, except the ones marked PowerShell. Untagged blocks are the same on every machine.
- **Verify** marks a command whose flags depend on your installed version. If it fails, run it with `--help`.
- Output is described, not reproduced. If a checkpoint does not match, stop and ask.

In the sandbox edition: A sandbox session lasts one hour and keeps nothing. Each lab starts with a **Start of a sandbox session** box; skip it if you are continuing in the same session. Labs 4, 5 and the capstone add a restore line that recreates what earlier labs built.

## Cheat sheet

| Task | Command |
|---|---|
| Login / list | `occ login` · `occ namespace list` · `occ project list -n team-alpha` |
| Create a namespace | `kubectl create namespace team-x` then `kubectl label namespace team-x openchoreo.dev/control-plane=true` |
| Apply a file | `occ apply -f file.yaml` (YAML or JSON) |
| Scaffold | `occ component scaffold <name> --clustercomponenttype deployment/service -n <ns> -p <project>` |
| Deploy / promote | `occ component deploy <name> --to staging -n <ns> -p <project>` |
| Roles | `occ authzrole list -n <ns>` · `occ clusterauthzrole list` · `occ authzrolebinding list -n <ns>` |
| Cell namespace | `kubectl get namespaces -l openchoreo.dev/project=<project> -L openchoreo.dev/environment` |
| Audit | `occ auditlogs --since 7d --result denied` |
| Dry run | `kubectl apply --dry-run=server -f file.yaml` |
| Onboard / access | `./onboard.sh TEAM PROJECT [--apply]` · `./apply-access.sh TEAM [--apply]` |

### Sandbox differences

| Task | In the sandbox |
|---|---|
| Audit | Console, Audit Logs page (occ 1.2 has no `auditlogs`) |
| Call a workload | `curl -H "Host: development-team-alpha.demo.openchoreo.wso2.com" http://$GWADDR/order-service-http/greeter/greet` |
| Restore earlier labs | `~/oc-210-labs/sandbox/restore.sh lab4\|lab5\|capstone` |
| Sign in | occ is already signed in; there is no `occ login` |
| Portal | https://console.demo.openchoreo.wso2.com |

### How the Handbook maps to OpenChoreo

| Handbook idea | OpenChoreo counterpart |
|---|---|
| Six evaluation planes (Table 6.1) | Portal tabs and catalog (Lab 1) |
| Catalog owner and lifecycle | System and Component entities; catalog-info (Lab 2) |
| Onboarding API | Namespace, Environment, DeploymentPipeline and Project, through occ or a script (Lab 3) |
| Namespace, RBAC, quota templates | AuthzRole and binding, ProjectType quota (Lab 4) |
| Project as atomic unit | Project, with namespace, pipeline and catalog entity (Lab 5) |
| Seven-minute rule; time-to-first-deploy | Capstone scorecard |


Sources: OpenChoreo v1.3 documentation (openchoreo.dev); CNCF project page; The Platform Engineer's Handbook, Chapter 6 (developer portals) and Chapter 7 (self-service onboarding).
