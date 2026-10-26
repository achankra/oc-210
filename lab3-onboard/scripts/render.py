#!/usr/bin/env python3
"""Fill a template with KEY=VALUE pairs and print the result.

Usage: render.py TEMPLATE KEY=VALUE [KEY=VALUE ...]

Each ${KEY} in the template is replaced. A ${KEY} with no value is an error,
so a missing value never reaches the cluster.
"""
import string
import sys


def main(argv):
    if len(argv) < 2:
        print(__doc__.strip(), file=sys.stderr)
        return 1
    values = {}
    for pair in argv[2:]:
        key, sep, value = pair.partition("=")
        if not sep or not key:
            print(f"Not a KEY=VALUE pair: {pair}", file=sys.stderr)
            return 1
        values[key] = value
    with open(argv[1]) as f:
        template = string.Template(f.read())
    try:
        sys.stdout.write(template.substitute(values))
    except KeyError as e:
        print(f"No value for {e.args[0]} in {argv[1]}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
