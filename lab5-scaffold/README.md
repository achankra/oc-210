# Lab 5: create a service from the portal

In Lab 5 the team creates `order-service` from the portal's Create Component wizard, which the portal generates for each ComponentType. You call it through the gateway, find it in the catalog, promote it to staging, and then read the Component and Workload the wizard created through the API. This folder holds the endpoint helper and a script that creates the same service through the API.

| Path | Purpose |
|---|---|
| `check-endpoint.sh` | Builds the gateway URL, calls it until it answers, and prints the response |
| `create-order-service.sh` | Creates `order-service` through the API, the same component the wizard makes, for when the wizard is not available |

The steps for this lab are in [WORKBOOK-local.md](WORKBOOK-local.md), or [WORKBOOK-sandbox.md](WORKBOOK-sandbox.md) in the WSO2 sandbox.

## Files you create in this lab

| File | Created in | What it is |
|---|---|---|
| `~/oc-210-labs/lab5-work/order-service-scaffold.yaml` | step 5 | What `occ component scaffold` generates for the same type, for comparison with what the wizard made |

Git ignores it.

## Requirements

`curl`, the portal, and team-alpha's `alpha-pilot` project from Lab 4.

## Without the wizard

If the portal has no Service template under the **Component** card on the Create page, create the same component through the API:

```
cd ~/oc-210-labs/lab5-scaffold
./create-order-service.sh team-alpha alpha-pilot
```

## Call the endpoint

```
kubectl get httproutes -A -l openchoreo.dev/component=order-service
cd ~/oc-210-labs/lab5-scaffold
./check-endpoint.sh development team-alpha order-service-http greeter/greet
```

The arguments are the environment, the namespace, the endpoint path name (`{component}-{endpoint}`) and the path. The script retries every three seconds, up to ten times by default, because a new deployment takes a moment to become ready. The URL the platform actually published is in the ReleaseBinding: `kubectl get releasebinding order-service-development -n team-alpha -o jsonpath='{.status.endpoints}'`.

After you promote, call staging the same way:

```
occ component deploy order-service --to staging -n team-alpha -p alpha-pilot
cd ~/oc-210-labs/lab5-scaffold
./check-endpoint.sh staging team-alpha order-service-http greeter/greet
```

In the WSO2 sandbox, the session block sets `GATEWAY_ADDR` and `GATEWAY_HOST`. The script then calls the gateway inside the cluster and sends `{environment}-{namespace}.demo.openchoreo.wso2.com` as the `Host` header, because the public URL is behind a browser check that blocks curl.

## What you should see

- A line with `HTTP 200` and `Hello, Stranger!`, in development and then in staging.
- A `404` means the endpoint name or path is wrong. Take it from the HTTPRoute.
- `000` means nothing answered. Check that the gateway pod is running and that k3d publishes port 19080.

## How it maps to OpenChoreo

Each ComponentType the platform team publishes is a starter kit: the portal turns it into a Create Component wizard, and the component it creates is the same contract you could keep in Git as a file. A later change to the type reaches components that have `autoDeploy: true` as a new release; others adopt it when they are deployed again.
