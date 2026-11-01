# Lab 2: Register a service in the catalog

*OC-210 workbook, WSO2 sandbox edition (OpenChoreo v1.2.2). Using a local install instead? See [WORKBOOK-local.md](WORKBOOK-local.md).*

**Goal:** See how the portal builds the catalog from what the platform runs, read an entity it generated, register one extra entry with an explicit owner, and check every entry for completeness.

## Start of a sandbox session

Paste into the sandbox terminal in your browser, never into a terminal on your own machine. Skip this box if you are still in the session where you ran the previous lab; pasting it twice does no harm. In a new session, paste the setup block. It clones the lab code, sets up Python, and saves the gateway address for every later block.

```bash
setopt interactivecomments
grep -q interactivecomments ~/.zshrc || echo 'setopt interactivecomments' >> ~/.zshrc
[ -d ~/oc-210-labs ] || git clone https://github.com/achankra/oc-210.git ~/oc-210-labs
cd ~/oc-210-labs
python3 -m venv --without-pip --system-site-packages .venv
GWIP=$(kubectl get svc gateway-default -n openchoreo-data-plane -o jsonpath='{.spec.clusterIP}')
sed -i -e '/^export GWADDR=/d' -e '/^export DEVHOST=/d' -e '/^export GATEWAY_/d' ~/.zshrc
echo "export GWADDR=$GWIP:9080" >> ~/.zshrc
echo "export DEVHOST=development-default.demo.openchoreo.wso2.com" >> ~/.zshrc
echo "export GATEWAY_ADDR=$GWIP:9080" >> ~/.zshrc
echo "export GATEWAY_HOST=demo.openchoreo.wso2.com" >> ~/.zshrc
source ~/.zshrc
deactivate 2>/dev/null
source ~/oc-210-labs/.venv/bin/activate
echo "gateway $GWADDR"
python3 -c "import yaml; print('pyyaml ok')"
```

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

In your browser, open https://console.demo.openchoreo.wso2.com/catalog. Sign in with `admin@openchoreo.dev` / `Admin@123`. Find the entity for the namespace (Domain), the project (System) and the component (Component).

### 2. Read the entity the portal generated

Open `greeter-service` in the catalog. In the menu at the top right of its page, choose **Inspect entity** and read the YAML.

Note which fields the platform filled in (system, owner, type, lifecycle) and which a team would still add (links, docs, tags). Ownership comes from the platform's objects, so it cannot drift from what runs.

## B. Register an extra entry

### 3. Fill in the catalog-info file

Some things a team owns are not run by the platform, such as a documentation site. `catalog/pilot-docs-site.yaml` follows the catalog-info example in The Platform Engineer's Handbook by Ajay Chankramath (Packt, 2026): a Component with tags, a link, and a spec that names type, lifecycle and owner. The owner must be a group that exists in the catalog: in the portal catalog, set the Kind filter to Group and pick one. Put its name on the first line, then paste the rest.

The book is not required for this course, but we recommend it to go deeper: [peh-packt.platformetrics.com](https://peh-packt.platformetrics.com) or [Amazon](https://www.amazon.com/dp/B0FR59Z7Q2).

```bash
GROUP=name-of-a-group-from-the-portal
cd ~/oc-210-labs/lab2-catalog-check
sed -e "s/REPLACE-WITH-AN-EXISTING-GROUP/$GROUP/" \
    -e "s/REPLACE-WITH-YOUR-PROJECT-NAME/default/" \
    catalog/pilot-docs-site.yaml > pilot-docs-site.yaml
cat pilot-docs-site.yaml
```

The entry joins the `default` System, beside the greeter. The template in `catalog/` stays as it is; your copy is `pilot-docs-site.yaml` in the lab folder.

### 4. Import it through the portal

The portal imports from a URL, so the file has to be on the web. A public GitHub gist is the quickest place, and you already signed in to GitHub for the sandbox. Print the file, then copy it into a new gist in your browser:

```bash
cd ~/oc-210-labs/lab2-catalog-check
cat pilot-docs-site.yaml
```

In your browser, open https://gist.github.com. Name the file `pilot-docs-site.yaml`, paste the content, and choose **Create public gist**. Click **Raw** and copy the URL. Then open https://console.demo.openchoreo.wso2.com/catalog-import, paste the URL, and choose Analyze, then Import.

## C. Completeness check

### 5. Check each entry

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
- [ ] The extra entry shows a named owner and sits in the `default` System
- [ ] `catalog_check.py` shows `pilot-docs-site` as complete

## Troubleshooting

- Import fails: the URL must be the raw file URL and reachable from the portal. If the portal says it is not allowed to read that host, the portal's `backend.reading.allow` list needs it; in the sandbox, tell your instructor and run step 5 on the file instead.
- Owner shows as unknown: the group does not exist in the catalog. Pick a name from the Group filter and repeat step 3.
- No **Inspect entity** in the menu: open the entity's page, then the three-dot menu at the top right. Some portal versions call it View YAML.
- Entities missing: wait a minute; the catalog refreshes on a schedule.

---

Previous: [Lab 1](../lab1-portal-scorecard/WORKBOOK-sandbox.md) · [All modules](../WORKBOOK.md) · Next: [Lab 3](../lab3-onboard/WORKBOOK-sandbox.md)
