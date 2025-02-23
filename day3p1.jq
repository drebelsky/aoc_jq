#!/usr/bin/env -S jq -R -s -f

[scan("mul\\(\\d{1,3},\\d{1,3}\\)")] # find all muls
| map(
    [scan("\\d+")| tonumber] | reduce .[] as $prod (1; . * $prod) # multiply individual muls
) | add
