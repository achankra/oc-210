# Lab 2: Register a service in the catalog

*OC-210 workbook, local install edition (OpenChoreo v1.3.2 on k3d). Using the WSO2 sandbox instead? See [WORKBOOK-sandbox.md](WORKBOOK-sandbox.md).*

**Goal:** See how the portal builds the catalog from what the platform runs, read an entity it generated, give the generated entries a real owner, register one extra entry with an explicit owner, and check every entry for completeness.

## A. The catalog the platform generates

### 1. Match platform objects to catalog entities

Nobody wrote a catalog file for the greeter from Lab 1. The portal generates the entries from the platform's own objects.

| Openchoreo Object | Backstage Entity | Name You Found |
|---|---|---|
| Namespace | Domain |  |
| Project | System |  |
| Component | Component |  |

```bash
occ namespace list
occ project list -n default
occ component list -n default
```

**macOS**

```bash
open http://openchoreo.localhost:8080/catalog
```

**Linux**

```bash
xdg-open http://openchoreo.localhost:8080/catalog
```

**Windows, in the WSL 2 Ubuntu terminal**

```bash
explorer.exe http://openchoreo.localhost:8080/catalog
```

Sign in with `admin@openchoreo.dev` / `Admin@123`. Find the entity for the namespace (Domain), the project (System) and the component (Component).

### 2. Read the entity the portal generated

Open `greeter-service` in the catalog. In the menu at the top right of its page, choose **Inspect entity** and read the YAML.

Note which fields the platform filled in (system, type, lifecycle) and which a team would still add (links, docs, tags). Then look at `spec.owner`: it is `openchoreo-users`, the portal's default group, not a team. The platform creates the entities, but it does not know who owns them until someone says so.

### 3. Give the project an owner

A project's `backstage.io/owner` annotation sets the owner of its System and of every component in it; a component can still set its own. Use the full reference, `group:default/NAME`: generated entities live in a catalog namespace named after their OpenChoreo namespace, while the groups from the identity provider live in `default`, so a bare name would point at a group that does not exist. `developers` is one of the groups the local install creates; if your Group filter does not list it, use a group it does list.

```bash
kubectl annotate project default -n default \
  backstage.io/owner=group:default/developers --overwrite
kubectl get project default -n default -o jsonpath='{.metadata.annotations}'; echo
```

After the catalog's next sync, a few minutes, reload `greeter-service`: its owner is `developers`, inherited from the project, and it links to the group. Lab 3 makes this part of onboarding, so every team's projects carry the team's own group.

## B. Register an extra entry

### 4. Fill in the catalog-info file

Some things a team owns are not run by the platform, such as a documentation site. `catalog/pilot-docs-site.yaml` follows the catalog-info example in The Platform Engineer's Handbook by Ajay Chankramath (Packt, 2026): a Component with tags, a link, and a spec that names type, lifecycle and owner. The owner must be a group that exists in the catalog, written in full as `group:default/NAME`; the file already has the `group:default/` part. `developers` from the last step works; to pick another, set the catalog's Kind filter to Group. Put its name on the first line, then paste the rest.

The book is not required for this course, but we recommend it to go deeper: [peh-packt.platformetrics.com](https://peh-packt.platformetrics.com) or [Amazon](https://www.amazon.com/dp/B0FR59Z7Q2).

```bash
GROUP=developers
cd ~/oc-210-labs/lab2-catalog-check
sed -e "s/REPLACE-WITH-AN-EXISTING-GROUP/$GROUP/" \
    -e "s/REPLACE-WITH-YOUR-PROJECT-NAME/default/" \
    catalog/pilot-docs-site.yaml > pilot-docs-site.yaml
cat pilot-docs-site.yaml
```

The entry joins the `default` System, beside the greeter. The template in `catalog/` stays as it is; your copy is `pilot-docs-site.yaml` in the lab folder.

### 5. Import it through the portal

> **Verify:** flags can differ between versions. If this fails, run the command with `--help`.

The portal imports from a URL, so the file has to be on the web. A public GitHub gist is the quickest place. This needs the GitHub CLI and a GitHub account.

**macOS**

```bash
# skip this block if gh --version works
brew install gh
```

**Linux**

```bash
# skip this block if gh --version works
sudo apt-get install -y gh
```

**Windows, in the WSL 2 Ubuntu terminal**

```bash
# skip this block if gh --version works
sudo apt-get install -y gh
```

**Every machine**

```bash
# skip the next line if gh auth status says you are signed in
gh auth login
cd ~/oc-210-labs/lab2-catalog-check
gh gist create --public pilot-docs-site.yaml
GIST=$(gh gist list --limit 1 | cut -f1)
gh api gists/$GIST --jq '.files[].raw_url'
```

**macOS**

```bash
open http://openchoreo.localhost:8080/catalog-import
```

**Linux**

```bash
xdg-open http://openchoreo.localhost:8080/catalog-import
```

**Windows, in the WSL 2 Ubuntu terminal**

```bash
explorer.exe http://openchoreo.localhost:8080/catalog-import
```

Paste the raw URL the `gh api` line printed into the import page, then Analyze and Import. Platform administrators can also register locations with `catalog.locations` in the portal configuration.

## C. Completeness check

### 6. Check each entry

The program checks each entry for an owner, a lifecycle, at least one link and a system. Run it on your entry beside the two samples.

```bash
cd ~/oc-210-labs/lab2-catalog-check
source ~/oc-210-labs/.venv/bin/activate
python3 catalog_check.py pilot-docs-site.yaml catalog/billing-api.yaml \
  catalog/orphan-service.yaml
```

It prints yes or NO for each item and the percentage of checks passed. `orphan-service` fails all four. Then open the greeter's entity again and tick the same four items by hand: what does the generated entry have that a hand-written one often lacks?

## Checkpoint

- [ ] You can name the Domain, System and Component the portal generated for Lab 1's objects
- [ ] `greeter-service` shows `developers` as its owner, not `openchoreo-users`
- [ ] The extra entry shows a named owner and sits in the `default` System
- [ ] `catalog_check.py` shows `pilot-docs-site` as complete

## Troubleshooting

- Import fails: the URL must be the raw file URL and reachable from the portal. If the portal says it is not allowed to read that host, the portal's `backend.reading.allow` list needs it.
- Owner still `openchoreo-users`: the catalog has not synced yet. Wait a few minutes and reload, and check the annotation with `kubectl get project default -n default -o jsonpath='{.metadata.annotations}'`.
- Owner shown but not a link, or shown as unknown: the group does not exist in the catalog, or the value is not a full `group:default/NAME` reference. Pick a name from the Group filter and repeat the step.
- No **Inspect entity** in the menu: open the entity's page, then the three-dot menu at the top right. Some portal versions call it View YAML.
- Entities missing: wait a minute; the catalog refreshes on a schedule.

---

Previous: [Lab 1](../lab1-portal-scorecard/WORKBOOK-local.md) · [All modules](../WORKBOOK.md) · Next: [Lab 3](../lab3-onboard/WORKBOOK-local.md)
