#!/usr/bin/env -S jq -Rs -f

def is_correct(after; update):
    all(foreach update[] as $cur ([]; . + [$cur]; 
        foreach (.[:-1][]) as $before (null; .; [$cur, $before])
    ); after[.[0]][.[1]] | not);

def middle(update):
    update | .[length / 2 | floor];

split("\n\n") | (.[1] | split("\n") | map(split(",") | select(length > 0))) as $updates
| (.[0] | split("\n") | map(select(. != ""))
    | map(split("|"))) as $rules
| reduce $rules[] as $item ({};
    if has($item[0]) then
        .[$item[0]].[$item[1]] = true
    else
        .[$item[0]] = {($item[1]): true}
    end
) | . as $after
| reduce $updates[] as $update (0;
    if is_correct($after; $update) then
        . + (middle($update) | tonumber)
    end
)
