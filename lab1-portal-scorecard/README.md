# Lab 1: score the portal

In Lab 1 you deploy a sample service, find it in the OpenChoreo portal, and score the portal on the six evaluation planes from The Platform Engineer's Handbook. This folder holds the scorecard file and a small program that checks it and summarizes the result.

| Path | Purpose |
|---|---|
| `scorecard-template.csv` | The six planes with empty scores. Copy it and fill it in |
| `sample-scorecard.csv` | A filled example, so you can see the output first |
| `scorecard.py` | Validates a scorecard and prints the total, the weakest planes and the strongest |


The steps for this lab are in [WORKBOOK-local.md](WORKBOOK-local.md).

## Files you create in this lab

| File | What it is |
|---|---|
| `my-scorecard.csv` | Your copy of the template, with a score and a sentence for each plane |

Git ignores it. There is no reference copy: the scores are your own.

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

## How it maps to OpenChoreo

The planes come from Table 6.1 of the Handbook. In the lab you look for each one in the OpenChoreo portal: the catalog and its owners, the component wizard, the logs and deployment views, the access control tab, and the observability tabs. The weakest two planes are where a portal team would put its next effort.
