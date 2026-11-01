# OC-210 workbook

Developer Portals & Self-Service Onboarding on OpenChoreo. Five labs and a capstone, with a pre-work module before Day 1.

Each module folder has two editions of its workbook:

- **WORKBOOK-local.md**: OpenChoreo v1.3.2 on a k3d cluster on your own machine (macOS, Linux, or Windows with WSL 2). This is the main path for the course.
- **WORKBOOK-sandbox.md**: the WSO2 OpenChoreo Sandbox at demo.openchoreo.wso2.com (v1.2.2, one-hour sessions), in your browser. Use it if you cannot run the cluster locally.

## Modules

| Module | Topic | Local install | Sandbox |
|---|---|---|---|
| Pre-work | Before Day 1: Install the tools and the k3d cluster, get the lab code, confirm the portal opens | [WORKBOOK-local.md](prework/WORKBOOK-local.md) | [Session setup](prework/WORKBOOK-sandbox.md) |
| Lab 1 | M01 Portals: Deploy a service, find it in the portal, score the portal on six planes | [WORKBOOK-local.md](lab1-portal-scorecard/WORKBOOK-local.md) | [WORKBOOK-sandbox.md](lab1-portal-scorecard/WORKBOOK-sandbox.md) |
| Lab 2 | M02 Catalog: Read the catalog the platform generates; register an extra entry with an owner | [WORKBOOK-local.md](lab2-catalog-check/WORKBOOK-local.md) | [WORKBOOK-sandbox.md](lab2-catalog-check/WORKBOOK-sandbox.md) |
| Lab 3 | M03 Self-service onboarding: Set up team-alpha's space; the team creates its project in the portal wizard, timed; then the API underneath | [WORKBOOK-local.md](lab3-onboard/WORKBOOK-local.md) | [WORKBOOK-sandbox.md](lab3-onboard/WORKBOOK-sandbox.md) |
| Lab 4 | M04 Project types as wizards: Publish a starter-tier ProjectType, use the wizard the portal generates for it, check the quota, grant access | [WORKBOOK-local.md](lab4-roles-quota/WORKBOOK-local.md) | [WORKBOOK-sandbox.md](lab4-roles-quota/WORKBOOK-sandbox.md) |
| Lab 5 | M05 Starter kits: Create, call and promote a service from the portal's Create Component wizard | [WORKBOOK-local.md](lab5-scaffold/WORKBOOK-local.md) | [WORKBOOK-sandbox.md](lab5-scaffold/WORKBOOK-sandbox.md) |
| Capstone | M06: Onboard team-beta end to end through the portal and fill in the scorecard | [WORKBOOK-local.md](capstone/WORKBOOK-local.md) | [WORKBOOK-sandbox.md](capstone/WORKBOOK-sandbox.md) |

## How to use the workbook

- Code blocks are commands to paste; GitHub shows a copy button on each. Lines starting with `#` are comments; the shell ignores them once the pre-work `setopt interactivecomments` line has run (macOS, zsh).
- Blocks are self-contained. A value such as a cell namespace or a data plane name is looked up in the block that needs it.
- The lab code lives in `~/oc-210-labs`. Every `cd` uses that full path, so it works from any folder.
- No block asks you to paste YAML: copying drops indentation, which breaks YAML. Files come from the lab repository or from a script.
- Portal steps say which page to open, what to pick and what to fill in. You sign in to the portal with `admin@openchoreo.dev` / `Admin@123`. Field labels differ a little between portal versions; the values are what matter.
- Long commands are split with `\` at the end of a line. Paste the whole block.
- One value comes from you: the catalog group that owns your entry in Lab 2.
- macOS blocks are the default. Where a step differs, blocks labeled **Linux** and **Windows** follow; paste only the ones for your machine. On Windows every block runs in the Ubuntu terminal on WSL 2, except the ones marked PowerShell. Untagged blocks are the same on every machine.
- **Verify** marks a command whose flags depend on your installed version. If it fails, run it with `--help`.
- Output is described, not reproduced. If a checkpoint does not match, stop and ask.

In the sandbox edition: A sandbox session lasts one hour and keeps nothing. Each lab starts with a **Start of a sandbox session** box; skip it if you are continuing in the same session. Labs 4, 5 and the capstone add a restore line that recreates what earlier labs built.

## Cheat sheet

| Task | Command |
|---|---|
| Create a project | Portal: Create, the Project card, then the template for the ProjectType · API: `./onboard.sh TEAM PROJECT --apply` |
| Create a service | Portal: Create, the Component card, then the template for the ComponentType · API: `occ component scaffold` and `occ apply -f` |
| Team space | `./onboard.sh TEAM [--apply]`: namespace, environments and pipeline, no project |
| Missing cells | `./scripts/bind-project.sh TEAM PROJECT`: one ProjectReleaseBinding per environment |
| List | `occ namespace list` · `occ project list -n team-alpha` · `occ component list -n team-alpha` |
| Deploy / promote | Portal: the component's Deploy page · `occ component deploy <name> --to staging -n <ns> -p <project>` |
| Types behind the wizards | `kubectl get clusterprojecttypes` · `kubectl get clustercomponenttypes` |
| Access | `./apply-access.sh TEAM [--apply]` · `occ authzrole list -n <ns>` · `occ authzrolebinding list -n <ns>` |
| Cell namespace | `kubectl get namespaces -l openchoreo.dev/project=<project> -L openchoreo.dev/environment` |
| Audit (changes only) | `occ auditlogs --since 7d` |
| Published URL | `kubectl get releasebinding <component>-development -n <ns> -o jsonpath='{.status.endpoints}'` |

### Sandbox differences

| Task | In the sandbox |
|---|---|
| Call a workload | `curl -H "Host: development-team-alpha.demo.openchoreo.wso2.com" http://$GWADDR/order-service-http/greeter/greet` |
| Restore earlier labs | `~/oc-210-labs/sandbox/restore.sh lab4\|lab5\|capstone` |
| Sign in | occ is already signed in; there is no `occ login` |
| Portal | https://console.demo.openchoreo.wso2.com |

### How the Handbook maps to OpenChoreo

| Handbook idea | OpenChoreo counterpart |
|---|---|
| Six evaluation planes for a portal | Portal tabs and catalog (Lab 1) |
| Catalog owner and lifecycle | Generated Domain, System and Component entities; catalog-info for the rest (Lab 2) |
| Self-service onboarding on an API | Create Project wizard in the portal; the same Project and bindings through occ or a script (Lab 3) |
| Namespace, RBAC, quota templates | A ProjectType with a quota, published as a portal wizard; AuthzRole and binding (Lab 4) |
| Starter kits and golden paths | A Create Component wizard per ComponentType (Lab 5) |
| Seven-minute rule; time-to-first-deploy | Capstone scorecard |


Sources: OpenChoreo v1.3 documentation (openchoreo.dev); CNCF project page; The Platform Engineer's Handbook by Ajay Chankramath (Packt, 2025), Chapter 6 (developer portals) and Chapter 7 (self-service onboarding). The book is not required for this course, but we recommend it to go deeper: [peh-packt.platformetrics.com](https://peh-packt.platformetrics.com) or [Amazon](https://www.amazon.com/dp/B0FR59Z7Q2).
