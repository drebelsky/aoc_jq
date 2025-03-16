#!/usr/bin/env -S jq -Rs -f

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

# collect 3 cliques
| keys_unsorted
| . as $nodes
| length as $len
| [0, {}] | until(.[0] == $len;
    .[0] as $i
    | if $nodes[$i] | startswith("t") then
        ($graph[$nodes[$i]] | keys_unsorted) as $connected
        | ($connected | length) as $others
        | [0, 1, .[1]] | until(.[0] == $others;
            . as [$j, $k]
            | if $k == $others then
                [$j + 1, $j + 2, .[-1]]
            else
                $connected[$j] as $a
                | $connected[$k] as $b
                | if $graph[$a][$b] then
                    .[-1] | setpath([[$nodes[$i], $a, $b] | sort | tostring]; true)
                    | [$j, $k + 1, .]
                else
                    [$j, $k + 1, .[-1]]
                end
            end
        ) | [$i + 1, .[-1]]
    else
        .[0] += 1
    end
) | .[1] | length
