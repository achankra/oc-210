# Lab 1: score the portal

In Lab 1 you deploy a sample service, find it in the OpenChoreo portal, and score the portal on six evaluation planes, a framework from The Platform Engineer's Handbook. You do not need the book: the planes are defined below. This folder holds the scorecard file and a small program that checks it and summarizes the result. The planes and their key questions come from Chapter 6, Table 6.1. We recommend the book to go deeper: [peh-packt.platformetrics.com](https://peh-packt.platformetrics.com) or [Amazon](https://www.amazon.com/dp/B0FR59Z7Q2).

| Path | Purpose |
|---|---|
| `scorecard-template.csv` | The six planes with empty scores. Copy it and fill it in |
| `sample-scorecard.csv` | A reference answer for the default local install, so you can see the output first and compare afterwards |
| `scorecard.py` | Validates a scorecard and prints the total, the weakest planes and the strongest |


The steps for this lab are in [WORKBOOK-local.md](WORKBOOK-local.md).

## Files you create in this lab

| File | What it is |
|---|---|
| `my-scorecard.csv` | Your copy of the template, with a score and a sentence for each plane |

Git ignores it. Compare it with `sample-scorecard.csv` when you finish; different scores are fine when your evidence supports them.

## Requirements

Python 3.9 or newer. No other packages.

## Run it

Try the sample first:

```
cd ~/oc-210-labs/lab1-portal-scorecard
python3 scorecard.py sample-scorecard.csv
```

Then copy the template, fill in a score from 0 to 3 and one sentence of evidence for each plane, and run it on your copy:

```
cd ~/oc-210-labs/lab1-portal-scorecard
cp scorecard-template.csv my-scorecard.csv
python3 scorecard.py my-scorecard.csv
```

## What you should see

A table with one line per plane, a total out of 18, and the two weakest and two strongest planes. If a plane is missing, a score is outside 0 to 3, or an evidence sentence is empty, the program lists each problem and exits with status 1.

## How to score

| Score | Meaning |
|---|---|
| 0 | Absent. You cannot find it in the portal |
| 1 | Present but thin. A first step exists |
| 2 | Works for the common case |
| 3 | Strong. You would show it to a new team |

Write evidence you could point at: a tab you opened, a page that was empty, a command you ran. The scores are yours. The program does not judge them.

## The six planes

| Plane | What it covers | Key question | Where to look in the OpenChoreo portal |
|---|---|---|---|
| Service catalog and ownership | One source of truth for what exists and which team owns it | Is ownership explicit? | The catalog: Domain, System and Component entities, and their owner field |
| Golden paths and scaffolding | Opinionated templates for starting new services | Can you create a service without tribal knowledge? | The Create page: one wizard per ProjectType and per ComponentType |
| Operations and reliability | Deployment health, runbooks, SLOs and incidents | Are health and runbooks visible? | The component's deployment view, logs and shell |
| Security and governance | Access control, policy enforcement and an audit trail | Can security audit through the portal? | Access control, and Audit Logs in the left menu |
| Observability and telemetry | Logs, metrics and traces for each service | Is each service linked to its signals? | The component's logs, metrics and traces tabs |
| Insights and AI augmentation | Engineering analytics and AI assistants | Is there analytics and automation? | Cost Insights in the left menu; the built-in agents (off by default) |

## Reference answer

`sample-scorecard.csv` is what a default local install of v1.3.2 typically scores: 13 out of 18. The weakest plane is insights and AI augmentation: the Cost Insights page needs a FinOps module to show data, there are no engineering analytics, and the SRE and FinOps agents are off by default. Observability and security are the strongest, because the pre-work installed the observability plane and the portal has its own Audit Logs page. The rest score 2: they work for the common case and leave a clear next step (owners on every entry, a template library, runbooks). The weakest two planes are where a portal team would put its next effort.
