#!/usr/bin/env -S jq -Rrs -f
# jq doesn't have any bitwise operators, so we implement them using lists of bits

70 as $MAX
# | 6 as $MAX
| def in_bounds($x; $y):
    0 <= $x and $x <= $MAX and 0 <= $y and $y <= $MAX;
def handle($x; $y):
    # [blocked, queue]
    if in_bounds($x; $y) and (.[0][$x][$y] | not) then
        setpath([0, $x, $y]; true)
        | .[0] as $blocked
        | .[1] | . + [[$x, $y]]
        | [$blocked, .]
    end;

def can_reach:
    # in-place dfs
    [(. | setpath([0, 0]; true)), [[0, 0]]] | until(type == "boolean" or (.[1] | length == 0);
        .[1][-1] as [$x, $y]
        | del(.[1][-1])
        | if $x == $MAX and $y == $MAX then
            true
        else
            handle($x - 1; $y) 
            | handle($x + 1; $y)
            | handle($x; $y - 1)
            | handle($x; $y + 1)
        end
    ) | if type == "boolean" then true else false end;

split("\n") | map(select(length > 0) | split(",") | map(tonumber))
| . as $bytes
| length as $len
| def reachable_at($i):
    reduce $bytes[:$i + 1][] as $coord ([]; setpath($coord; true)) | can_reach;

def binary_search:
    . as [$lo, $hi]
    | if $lo >= $hi then
        $lo
    else
        (($lo + $hi) / 2) | floor as $mid
        | if reachable_at($mid) then
            [$mid + 1, $hi] | binary_search
        else
            [$lo, $mid] | binary_search
        end
    end;

[0, $len] | binary_search | $bytes[.] | map(tostring) | join(",")
