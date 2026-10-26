# Capstone: onboard a team end to end

You onboard team-beta from nothing to a deployed, cataloged and governed service, and measure how long it takes. You work in pairs. One person drives and the other reads the checklist. This folder holds the program that turns your log into the scorecard, and a script that repeats the scripted steps.

| Path | Purpose |
|---|---|
| `onboarding_scorecard.py` | Reads the onboarding log and prints time-to-first-deploy, commands, tickets and the slowest step |
| `repeat.sh` | Runs `onboard.sh` and `apply-access.sh` for a team, with the starter-tier ProjectType |


The steps for this lab are in [WORKBOOK-local.md](WORKBOOK-local.md).

The capstone writes its log and `order-service.yaml` in `~/oc-210-labs/lab3-onboard`, so the scripts and `mark.sh` share one log. Git ignores both.

## Requirements

- Everything from Labs 3 to 5, including the `starter-tier` ProjectType from Lab 4.
- Python 3.9 or newer. No other packages.

## The run

Start the clock with the first command you run:

```
cd ~/oc-210-labs/capstone
../lab3-onboard/scripts/mark.sh "start" "capstone begins"
```

Then work through the six steps in the workbook. Use the scripts from the earlier labs where they help, and log every step you run by hand:

```
cd ~/oc-210-labs/capstone
../lab3-onboard/scripts/mark.sh "scaffold and deploy" "occ component deploy order-service --to development -n team-beta"
```

Keep every command in a shell file as you go, so the run can be repeated. When you finish, ask: how long did the scripted steps take compared with the ones you typed?

To repeat the scripted part for another team, without creating anything:

```
cd ~/oc-210-labs/capstone
./repeat.sh team-beta beta-shop
./repeat.sh team-beta beta-shop --apply
```

The first line only renders and checks; the second creates the objects.

## Read the result

```
cd ~/oc-210-labs/capstone
python3 onboarding_scorecard.py --tickets 0
```

The program prints the time spent on each step, then:

| Line | Meaning |
|---|---|
| Time-to-first-deploy | From the first logged row to the last |
| Commands run | Every logged command, including checks |
| Tickets created | The number you pass with `--tickets`. The goal is zero |
| Slowest step | The step that took the most time |
| Under the 15-minute goal | The course target |
| Any step over seven minutes | The Handbook's friction threshold |

The time between two rows counts against the later step, so thinking time before a step is part of that step. That is the point: the log shows where the person waited.

## What you should see

team-beta has a running, reachable service. The catalog shows it with an owner, and the cell has the starter-tier quota. Your time is under 15 minutes, or you can name the step that made it longer.

## How it maps to OpenChoreo

The three leading metrics in the Handbook are time-to-first-deploy, tickets during onboarding and abandonment. This lab measures the first two on a real onboarding. The third is what the first two predict: a developer who waits more than about seven minutes for one step starts looking for a workaround.
