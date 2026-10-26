# Lab 3: Onboard a team

*OC-210 workbook, local install edition (OpenChoreo v1.3.1 on k3d). Using the WSO2 sandbox instead? See [WORKBOOK-sandbox.md](WORKBOOK-sandbox.md).*

**Goal:** Replace a ticket queue with a short sequence of commands: a labeled team namespace, environments, a promotion pipeline and a project. Do it by hand, then with a script.

## A. Onboard by hand

### 1. Sign in and start the clock

Every command in this part runs in `~/oc-210-labs/lab3-onboard`, so the timing log stays in one place.

```bash
occ login
occ namespace list
cd ~/oc-210-labs/lab3-onboard
rm -f onboarding-log.csv
./scripts/mark.sh "start" "occ login"
```

Sign in with `admin@openchoreo.dev` / `Admin@123`. The first `mark.sh` call creates the log and starts the clock; each step below ends with one.

### 2. Create the team namespace

> **Dry run first:** the block checks with a server-side dry run before it changes anything.

An OpenChoreo namespace carries the label `openchoreo.dev/control-plane=true`. Add owner and tier labels, following the Handbook's `team-{teamname}` convention.

```bash
cd ~/oc-210-labs/lab3-onboard
kubectl create namespace team-alpha --dry-run=server -o name
kubectl create namespace team-alpha
kubectl label namespace team-alpha openchoreo.dev/control-plane=true \
  platform.io/team=team-alpha platform.io/tier=starter
kubectl get namespace team-alpha --show-labels
./scripts/mark.sh "namespace" "kubectl create namespace team-alpha"
```

### 3. Create environments and a pipeline

> **Dry run first:** the block checks with a server-side dry run before it changes anything.

Environments and pipelines are namespaced, so the new namespace needs its own. The block reads the data plane the default environment uses and writes both environments with it.

```bash
cd ~/oc-210-labs/lab3-onboard
DP_KIND=$(kubectl get environment development -n default \
  -o jsonpath='{.spec.dataPlaneRef.kind}')
DP_NAME=$(kubectl get environment development -n default \
  -o jsonpath='{.spec.dataPlaneRef.name}')
echo "data plane: $DP_KIND/$DP_NAME"
cat > team-alpha-envs.yaml <<EOF
{"apiVersion": "openchoreo.dev/v1alpha1", "kind": "Environment",
 "metadata": {"name": "development", "namespace": "team-alpha"},
 "spec": {"dataPlaneRef": {"kind": "$DP_KIND", "name": "$DP_NAME"}, "isProduction": false}}
---
{"apiVersion": "openchoreo.dev/v1alpha1", "kind": "Environment",
 "metadata": {"name": "staging", "namespace": "team-alpha"},
 "spec": {"dataPlaneRef": {"kind": "$DP_KIND", "name": "$DP_NAME"}, "isProduction": false}}
EOF
kubectl apply --dry-run=server -f team-alpha-envs.yaml
occ apply -f team-alpha-envs.yaml
./scripts/mark.sh "environments" "occ apply -f team-alpha-envs.yaml"
```

Then the pipeline, which promotes development to staging:

```bash
cd ~/oc-210-labs/lab3-onboard
cat > team-alpha-pipeline.yaml <<'EOF'
{"apiVersion": "openchoreo.dev/v1alpha1", "kind": "DeploymentPipeline",
 "metadata": {"name": "team-alpha-deployment-pipeline", "namespace": "team-alpha"},
 "spec": {"promotionPaths": [{"sourceEnvironmentRef": {"name": "development"},
                              "targetEnvironmentRefs": [{"name": "staging"}]}]}}
EOF
kubectl apply --dry-run=server -f team-alpha-pipeline.yaml
occ apply -f team-alpha-pipeline.yaml
./scripts/mark.sh "pipeline" "occ apply -f team-alpha-pipeline.yaml"
```

### 4. Create the team's project

> **Dry run first:** the block checks with a server-side dry run before it changes anything.

The project points at the pipeline you just created, and at the default ClusterProjectType for now. Lab 4 adds a typed project.

```bash
cd ~/oc-210-labs/lab3-onboard
cat > alpha-shop-project.yaml <<'EOF'
{"apiVersion": "openchoreo.dev/v1alpha1", "kind": "Project",
 "metadata": {"name": "alpha-shop", "namespace": "team-alpha"},
 "spec": {"deploymentPipelineRef": {"name": "team-alpha-deployment-pipeline"},
          "type": {"kind": "ClusterProjectType", "name": "default"}}}
EOF
kubectl apply --dry-run=server -f alpha-shop-project.yaml
occ apply -f alpha-shop-project.yaml
./scripts/mark.sh "project" "occ apply -f alpha-shop-project.yaml"
```

Then bind the project to both environments. A project gets a cell namespace per environment only through a ProjectReleaseBinding:

```bash
cd ~/oc-210-labs/lab3-onboard
cat > alpha-shop-bindings.yaml <<'EOF'
{"apiVersion": "openchoreo.dev/v1alpha1", "kind": "ProjectReleaseBinding",
 "metadata": {"name": "alpha-shop-development", "namespace": "team-alpha"},
 "spec": {"owner": {"projectName": "alpha-shop"}, "environment": "development"}}
---
{"apiVersion": "openchoreo.dev/v1alpha1", "kind": "ProjectReleaseBinding",
 "metadata": {"name": "alpha-shop-staging", "namespace": "team-alpha"},
 "spec": {"owner": {"projectName": "alpha-shop"}, "environment": "staging"}}
EOF
kubectl apply --dry-run=server -f alpha-shop-bindings.yaml
occ apply -f alpha-shop-bindings.yaml
./scripts/mark.sh "bindings" "occ apply -f alpha-shop-bindings.yaml"
```

### 5. Verify and stop the clock

```bash
cd ~/oc-210-labs/lab3-onboard
occ namespace list
occ project list -n team-alpha
kubectl get namespaces -l openchoreo.dev/project=alpha-shop -L openchoreo.dev/environment
./scripts/mark.sh "verify" "occ project list -n team-alpha"
python3 ../capstone/onboarding_scorecard.py onboarding-log.csv
```

Find `alpha-shop` in the portal under the team-alpha Domain. The last line prints your time per step and the total; write the total down.

## B. Onboard with a script

### 6. Check, then create a second team

The script renders the same objects from templates, including the two project bindings. Without `--apply` it creates nothing.

```bash
cd ~/oc-210-labs/lab3-onboard
./onboard.sh team-demo demo-shop
cat rendered/team-demo/project.yaml
cat alpha-shop-project.yaml
./onboard.sh team-demo demo-shop --apply
occ project list -n team-demo
```

The script reads the data plane from the default environment, applies the namespace first, then runs a server-side dry run and `occ apply` for each OpenChoreo object. Compare `rendered/team-demo/` with the files you wrote.

## Checkpoint

- [ ] `occ namespace list` shows `team-alpha` and `team-demo`
- [ ] `alpha-shop` appears in the portal
- [ ] You have a recorded onboarding time from `onboarding_scorecard.py`

## Troubleshooting

- Project not listed: run `kubectl get namespace team-alpha --show-labels`; it needs `openchoreo.dev/control-plane=true`.
- No cell namespaces for the project: run `kubectl get projectreleasebindings -n team-alpha`; each environment needs one (step 4).
- Environment rejected: run `echo $DP_KIND/$DP_NAME`; if it is empty, run the two `DP_` lines again.
- Pipeline rejected: run `kubectl get environments -n team-alpha`; both environments must exist first.
- `onboard.sh` cannot read the data plane: run `kubectl get environment development -n default -o yaml | grep -A3 dataPlaneRef`.
- `AlreadyExists` on the namespace: it was created earlier. Run the label line and carry on.

---

Previous: [Lab 2](../lab2-catalog-check/WORKBOOK-local.md) · [All modules](../WORKBOOK.md) · Next: [Lab 4](../lab4-roles-quota/WORKBOOK-local.md)
