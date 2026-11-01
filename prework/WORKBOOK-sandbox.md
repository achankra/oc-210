# Session: Start a sandbox session

*OC-210 workbook, WSO2 sandbox edition (OpenChoreo v1.2.2). Using a local install instead? See [WORKBOOK-local.md](WORKBOOK-local.md).*

**Goal:** A fresh OpenChoreo cluster in the WSO2 sandbox, the lab code, Python and the gateway address ready in its terminal, and the console open in your browser. A session lasts one hour and nothing is kept.

| What | Value |
|---|---|
| Sandbox | https://demo.openchoreo.wso2.com, sign in with GitHub |
| Console | https://console.demo.openchoreo.wso2.com, `admin@openchoreo.dev` / `Admin@123` |
| OpenChoreo | v1.2.2 server, occ 1.2.0. The labs use the release-v1.2 samples |
| Shell | zsh, with kubectl, occ, helm, git and jq installed; occ already signed in |
| Workloads | Reached at the data plane gateway inside the cluster (`$GWADDR`) with the host name `{environment}-{namespace}.demo.openchoreo.wso2.com`. The public URL is behind a browser check that blocks curl |
| Earlier labs | Not kept between sessions. Labs 4, 5 and the capstone start with a restore step that recreates what they need |

### 1. Open the sandbox

In your browser, open https://demo.openchoreo.wso2.com and sign in with GitHub. A terminal opens with a fresh cluster. The timer in the top bar shows the time left. Run every block in that terminal.

### 2. Set up the session

Paste this into the sandbox terminal in your browser, once per session. **Never paste it into a terminal on your own machine:** it changes `~/.zshrc`. Each lab repeats it at the top, so a lab can start in a new session.

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

The last lines print the gateway address and `pyyaml ok`. Opening a new tab in the same session needs nothing more: the settings are in `~/.zshrc`.

### 3. Check the session

```bash
occ namespace list
occ project list -n default
kubectl get clusterprojecttypes
curl -s -o /dev/null -w "%{http_code}\n" -H "Host: $DEVHOST" http://$GWADDR/
```

`default` is listed, with the `default` project and the sandbox's `gcp-microservice-demo`; the `default` project type exists; the gateway answers with a status code such as 404.

### 4. Open the console

In your browser, open https://console.demo.openchoreo.wso2.com and sign in with `admin@openchoreo.dev` / `Admin@123`.

### 5. Optional reading

- Several labs use ideas and numbers from The Platform Engineer's Handbook by Ajay Chankramath (Packt, 2025). Each place says so, and the workbook gives you everything the lab needs.
- While the book is not mandatory, we recommend getting it: [peh-packt.platformetrics.com](https://peh-packt.platformetrics.com) or [Amazon](https://www.amazon.com/dp/B0FR59Z7Q2). Start with Chapter 6, section 6.1 (how to evaluate a portal) and the Chapter 7 sidebar “The onboarding opportunity”.

## Checkpoint

- [ ] The setup block printed the gateway address and `pyyaml ok`
- [ ] `occ namespace list` returns `default`
- [ ] The console opens and you can sign in

## Troubleshooting

- `no matches found` from zsh: a pasted line has an unquoted `[` or `*`. Every block in this workbook is quoted; check the paste.
- `gateway ` with no address: the setup block did not finish. Run it again.
- `git clone` asks for a user name: the lab repository is not public. Tell your instructor.
- `Failed to connect to 10.43...` and the prompt shows your own computer's name: you are in a terminal on your machine, not the sandbox. If the setup block ran on your machine, remove the `GWADDR`, `DEVHOST` and `GATEWAY_` lines from `~/.zshrc`.
- The session ended mid-lab: start a new one, run the lab's start-of-session blocks, then continue from the step you were on.
- A curl to the public URL returns `Just a moment...`: that is the browser check in front of the sandbox. Use `$GWADDR` with the `Host` header, as every block here does.

---

[All modules](../WORKBOOK.md) · Next: [Lab 1](../lab1-portal-scorecard/WORKBOOK-sandbox.md)
