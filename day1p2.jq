#!/usr/bin/env -S jq -Rs -f

split("\n") | map(select(length > 0)) # split lines
| map(split("\\s+"; null) | map(tonumber)) # split within line + parse
| transpose
| (.[1] | reduce .[] as $item ({}; .[$item | tostring] += 1)) as $counts
| .[0] | reduce .[] as $item (0; . + $item * ($counts[$item | tostring] // 0))
