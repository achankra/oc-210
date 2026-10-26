# Lab 5: scaffold, deploy and promote

In Lab 5 you scaffold a component into the team's project, deploy it, call it through the gateway, find it in the catalog and promote it to staging. The scaffolding and deploying happen with `occ` and `kubectl`, and the workbook has the steps. This folder holds one helper for the step that most often goes wrong, calling the endpoint.

| Path | Purpose |
|---|---|
| `check-endpoint.sh` | Builds the gateway URL, calls it until it answers, and prints the response |


The steps for this lab are in [WORKBOOK-local.md](WORKBOOK-local.md).

## Files you create in this lab

These are not in the repository until you run the step that writes them. Git ignores them.

| File | Created in | What it is |
|---|---|---|
| `~/oc-210-labs/lab5-work/order-service-scaffold.yaml` | step 1 | What `occ component scaffold` generates for team-alpha |
| `~/oc-210-labs/lab5-work/order-service.yaml` | step 2 | The greeter sample, renamed `order-service`, in team-alpha's `alpha-pilot` project |

`reference/order-service.yaml` is the second file as it comes out on a v1.3.1 install. If you fall behind: `mkdir -p ~/oc-210-labs/lab5-work && cp reference/order-service.yaml ~/oc-210-labs/lab5-work/`.

## Requirements

`curl`, and the `order-service` component deployed in team-alpha's `alpha-pilot` project, as in the workbook.

## Scaffold and deploy

The workbook has the full steps. In short:

```
cd ~/oc-210-labs/lab5-scaffold
occ component scaffold order-service -n team-alpha -p alpha-pilot \
  --clustercomponenttype deployment/service -o order-service-scaffold.yaml
occ component deploy order-service --to development -n team-alpha -p alpha-pilot
```

`--clustercomponenttype` is written `workloadType/componentTypeName`. Review the scaffolded file before you apply it. If a flag is rejected, run `occ component scaffold --help`.

## Call the endpoint

```
kubectl get httproutes -A -l openchoreo.dev/component=order-service
cd ~/oc-210-labs/lab5-scaffold
./check-endpoint.sh development team-alpha order-service-http greeter/greet
```

The arguments are the environment, the namespace, the endpoint name from the HTTPRoute, and the path.

The script retries every three seconds, up to ten times, because a new deployment takes a moment to become ready. After you promote, call staging the same way:

```
occ component deploy order-service --to staging -n team-alpha -p alpha-pilot
cd ~/oc-210-labs/lab5-scaffold
./check-endpoint.sh staging team-alpha order-service-http greeter/greet
```

## What you should see

- A line with `HTTP 200` and the response from your service, in development and then in staging.
- A `404` means the endpoint name or path is wrong. Take the endpoint name from the HTTPRoute.
- `000` means nothing answered. Check that the gateway pod is running and that k3d publishes port 19080.

## How it maps to OpenChoreo

The scaffolded YAML is a file you can review, keep in Git and apply again, which is what an onboarding flow needs. A ComponentType keeps every scaffolded component in step with the platform: change the type once, and each component gets a new release that it adopts when you bind and promote it.

In the WSO2 sandbox, the session block sets `GATEWAY_ADDR` and `GATEWAY_HOST`. The script then calls the gateway inside the cluster and sends `{environment}-{namespace}.demo.openchoreo.wso2.com` as the `Host` header, because the public URL is behind a browser check that blocks curl.
