#!/usr/bin/env -S jq -s -f
# note: this does complete, it just takes a pretty long time (156.15 seconds on my machine, though, still faster than using the non-cached p1 solution)

def calculate($arr):
    def rec:
        # [number, blinks_left, cache] -> [total, cache]
        # note, cache isn't stored as a variable (so we don't have an extra reference) for efficient updating
        # also, note that we do grow the stack in the split case and that the cache passing there is a little subtle/annoying
        . as [$num, $blinks_left] | (.[:-1] | tostring) as $key
        | if $blinks_left == 0 then
            [1, .[-1]]
        elif .[-1][$key] then
            [.[-1][$key], .[-1]]
        elif $num == 0 then
            [1, $blinks_left - 1, .[-1]] | rec
            | .[0] as $res
            | [$res, (.[-1] | .[$key] = $res)]
        elif (($num | tostring | length) % 2 == 0) then
            ($num | tostring | .) as $s
            | (($s | length) / 2) as $l
            | [($s[:$l] | tonumber), $blinks_left - 1, .[-1]] | rec
            | .[0] as $lhs
            | [($s[$l:] | tonumber), $blinks_left - 1, .[-1]] | rec
            | (.[0] + $lhs) as $res
            | [$res, (.[-1] | .[$key] = $res)]
        else
            [$num * 2024, $blinks_left - 1, .[-1]] | rec
            | .[0] as $res
            | [$res, (.[-1] | .[$key] = $res)]
        end;

    reduce $arr[] as $stone ([0, {}];
        .[0] as $cur_total | [$stone, 75, .[-1]] | rec | [.[0] + $cur_total, .[1]]
    ) | .[0];
    
calculate(.)
