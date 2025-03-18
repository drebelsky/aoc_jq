#!/usr/bin/env -S jq -Rs -f

def parse:
    # return [is_key: bool, heights]
    split("\n") | map(select(length > 0) | split(""))
    | . as $split
    | if $split[0][0] == "#" then
        # have lock
        [false, (transpose | map(index(".") - 1))]
    else
        # have key
        [true, (transpose | map(length - index("#") - 1))]
    end;

split("\n\n") | (.[0] | split("\n") | length - 1) as $height | map(parse)
| . as $objects
# [index, locks, keys]
| [0, [], []] | until($objects[.[0]] | not;
    .[0] as $i
    | $objects[$i] as $obj
    | if $obj[0] then
        .[1] as $locks
        | .[2] | . + [$obj[1]]
        | [$i + 1, $locks, .]
    else
        .[2] as $keys
        | .[1] | . + [$obj[1]]
        | [$i + 1, ., $keys]
    end
) | .[1:] | . as [$locks, $keys]
| reduce (range($locks | length) as $l | range($keys | length) | [$l, .]) as [$lock, $key] (0;
    if all([$locks[$lock], $keys[$key]] | transpose[]; add < $height) then
        . + 1
    end
)
