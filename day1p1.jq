#!/usr/bin/env -S jq -Rs -f

split("\n") | map(select(length > 0)) # split lines
| map(split("\\s+"; null) | map(tonumber)) # split within line + parse
| transpose | map(sort) | transpose # sort
| map(.[0] - .[1] | abs) | add
