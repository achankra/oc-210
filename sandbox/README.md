# Sandbox helpers

For the sandbox edition of the workbook (WORKBOOK-sandbox.md in each lab folder), which runs on the WSO2 OpenChoreo Sandbox at demo.openchoreo.wso2.com.

| Path | Purpose |
|---|---|
| `restore.sh` | Recreates what earlier labs built, in a new session |

A sandbox session lasts one hour and keeps nothing, but Labs 4, 5 and the capstone build on earlier labs. Each of those labs starts with a restore line:

| Run | Recreates |
|---|---|
| `~/oc-210-labs/sandbox/restore.sh lab4` | team-alpha with its environments, pipeline and the alpha-shop project (Lab 3), created through the API |
| `~/oc-210-labs/sandbox/restore.sh lab5` | The lab4 state, plus the quota grant, the starter-tier ProjectType and the alpha-pilot project (Lab 4) |
| `~/oc-210-labs/sandbox/restore.sh capstone` | The quota grant and the starter-tier ProjectType (Lab 4) |

Skip it if you ran the earlier lab in the same session. Running it twice does no harm, and it writes nothing to your onboarding log. It works on a local cluster too, for example after you recreate the cluster.

The sandbox's gateway is reached inside the cluster. The session block sets `GATEWAY_ADDR` and `GATEWAY_HOST`, so `lab5-scaffold/check-endpoint.sh` calls the gateway's address with the host name in a `Host` header.
