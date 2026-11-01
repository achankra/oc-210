# Capstone: onboard a team end to end

You onboard team-beta from nothing to a deployed, cataloged and governed service, through the portal, and measure how long it takes. You work in pairs. One person drives and the other reads the checklist. This folder holds the program that turns your log into the scorecard, and a script that repeats the onboarding through the API.

| Path | Purpose |
|---|---|
| `onboarding_scorecard.py` | Reads the onboarding log and prints time-to-first-deploy, commands, tickets and the slowest step |
| `repeat.sh` | Runs `onboard.sh` and `apply-access.sh` for a team, with the starter-tier ProjectType: the same onboarding with no portal |

The steps are in [WORKBOOK-local.md](WORKBOOK-local.md), or [WORKBOOK-sandbox.md](WORKBOOK-sandbox.md) in the WSO2 sandbox.

The capstone writes its log in `~/oc-210-labs/lab3-onboard`, so the scripts and `mark.sh` share one log. Git ignores it.

## Requirements

- Everything from Labs 3 to 5, including the `starter-tier` ProjectType from Lab 4.
- Python 3.9 or newer. No other packages.

## The run

| Step | What | Where |
|---|---|---|
| 1 | Team space: namespace, environments, pipeline | `onboard.sh team-beta --apply` |
| 2 | Project `beta-shop` from the Starter tier wizard | Portal |
| 3 | Role and binding for `team-beta-developers` | `apply-access.sh team-beta --apply` |
| 4 | `order-service` from the Service wizard, deployed and promoted | Portal, then `occ` |
| 5 | Catalog entry, owner and quota | Portal and `check_quota.py` |

Log every portal step with `../lab3-onboard/scripts/mark.sh "step name" "what you did"`, so the timing counts it.

To repeat the onboarding for another team through the API, with no portal:

```
cd ~/oc-210-labs/capstone
./repeat.sh team-gamma gamma-shop
./repeat.sh team-gamma gamma-shop --apply
```

The first line only renders and checks; the second creates the objects.

## Read the result

```
cd ~/oc-210-labs/lab3-onboard
python3 ../capstone/onboarding_scorecard.py onboarding-log.csv --tickets 0
```

| Line | Meaning |
|---|---|
| Time-to-first-deploy | From the first logged row to the last |
| Commands run | Every logged command, including checks |
| Tickets created | The number you pass with `--tickets`. The goal is zero |
| Slowest step | The step that took the most time |
| Under the 15-minute goal | The course target |
| Any step over seven minutes | The Handbook's friction threshold |

The time between two rows counts against the later step, so time spent in a portal form counts against the step you log after it. That is the point: the log shows where the person waited.

## What you should see

team-beta has a running, reachable service, created through the portal. The catalog shows it with an owner, and the cell has the starter-tier quota. Your time is under 15 minutes, or you can name the step that made it longer.

After the clock stops, Audit Logs in the portal shows team-beta's changes made through the OpenChoreo API: the environments, pipeline, project, role, binding, component and promotion. The namespace is not there, because `onboard.sh` creates it with `kubectl`, outside the API.

## How it maps to OpenChoreo

The three leading metrics in the Handbook are time-to-first-deploy, tickets during onboarding and abandonment. This lab measures the first two on a real onboarding. The third is what the first two predict: a developer who waits more than about seven minutes for one step starts looking for a workaround. The metrics and the seven-minute threshold come from The Platform Engineer's Handbook by Ajay Chankramath (Packt, 2026), Chapter 7. The book is not required for this course, but we recommend it to go deeper: [peh-packt.platformetrics.com](https://peh-packt.platformetrics.com) or [Amazon](https://www.amazon.com/dp/B0FR59Z7Q2).

## What next

The labs used one path through the portal. [After the course: the rest of the portal](../README.md#after-the-course-the-rest-of-the-portal) in the top-level README lists the parts you have not used yet, with something to try in each.
