#!/usr/bin/env -S jq -Rrs -f
# unfortunately Tsukiyama et al is pay walled, so we just do the dumb exponential iteration

split("\n") | map(select(length > 0) | split("-"))
| . as $lines
| length as $len
# construct graph
| [0, {}] | until(.[0] == $len;
    .[0] as $i
    | $lines[$i] as $key
    | .[1]
    | setpath($key; true)
    | setpath($key | reverse; true)
    | [$i + 1, .])
| .[1]
| . as $graph

| def find_clique($k):
    $graph | with_entries(select(.value | length + 1 >= $k))
    | . as $smaller
    | keys as $nodes
    | def rec($so_far; $i):
        if $so_far | length == $k then
            $so_far
        elif $nodes | length == $i then
            empty
        else
            $nodes[$i] as $cur
            | if all($so_far[]; $graph[.][$cur]) then
                rec($so_far + [$cur]; $i + 1), rec($so_far; $i + 1)
            else
                rec($so_far; $i + 1)
            end
        end;
    rec([]; 0);

$graph | map(length) | max | . as $neighbors
| first (foreach range($neighbors + 1; 0; -1) as $k (null;
    find_clique($k)))
| join(",")
