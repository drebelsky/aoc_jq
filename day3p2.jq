#!/usr/bin/env -S jq -R -s -f

[scan("mul\\(\\d{1,3},\\d{1,3}\\)|do\\(\\)|don't\\(\\)")]
| reduce .[] as $item (
    {active: true, sum: 0};
    if $item | startswith("mul") then
        if .active then
            .sum += ([$item | scan("\\d+") | tonumber] | .[0] * .[1])
        end
    elif $item | startswith("don't") then
        .active = false
    else
        .active = true
    end
) | .sum
