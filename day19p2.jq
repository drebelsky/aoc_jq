#!/usr/bin/env -S jq -Rs -f

split("\n\n")
| (.[0] | split(", ")) as $patterns
| ($patterns | length) as $num_patterns
| def ways_for($design):
    # cache -> [ways, cache]
    if $design | length == 0 then
        [1, .]
    elif .[$design] != null then
        [.[$design], .]
    else
        # [i, total, cache]
        [0, 0, .] | until(.[0] == $num_patterns;
            . as [$i, $total]
            | if $design | startswith($patterns[$i]) then
                .[2] | ways_for($design | ltrimstr($patterns[$i])) | [$i + 1, $total + .[0], .[1]]
            else
                setpath([0]; $i + 1)
            end
        ) | .[1:]
        | .[0] as $total
        | .[1] | setpath([$design]; $total)
        | [$total, .]
    end;
.[1] | split("\n") | map(select(length > 0))
| . as $designs
| length as $num_designs
# [i, total, cache]
| [0, 0, {}] | until(.[0] == $num_designs;
    . as [$i, $total]
    | .[2] | ways_for($designs[$i])
    | [$i + 1, $total + .[0], .[1]]
) | .[1]
