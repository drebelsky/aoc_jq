#!/usr/bin/env -S jq -s -f
def cache(key1; key2; blinks; val):
    .[key1] += {(key2): val};

def calculate($arr):
    def rec:
        # [number, blinks_left, cache] -> [total, cache]
        # note, cache isn't stored as a variable (so we don't have an extra reference) for efficient updating
        # also, note that we do grow the stack in the split case and that the cache passing there is a little subtle/annoying
        . as [$num, $blinks_left] | ($num | tostring) as $s | ($blinks_left | tostring) as $bls
        | if $blinks_left == 0 then
            [1, .[-1]]
        elif $num == 0 then
            [1, $blinks_left - 1, .[-1]] | rec
        elif .[-1][$s][$bls] then
            [.[-1][$s][$bls], .[-1]]
        elif (($s | length) % 2 == 0) then
            (($s | length) / 2) as $l
            | [($s[:$l] | tonumber), $blinks_left - 1, .[-1]] | rec
            | .[0] as $lhs
            | [($s[$l:] | tonumber), $blinks_left - 1, .[-1]] | rec
            | (.[0] + $lhs) as $res
            | [$res, (.[-1] | cache($s; $bls; $blinks_left; $res))]
        else
            [$num * 2024, $blinks_left - 1, .[-1]] | rec
            | .[0] as $res
            | [$res, (.[-1] | cache($s; $bls; $blinks_left; $res))]
        end;

    reduce $arr[] as $stone ([0, {}];
        .[0] as $cur_total | [$stone, 75, .[-1]] | rec | [.[0] + $cur_total, .[1]]
    ) | .[0];
    
calculate(.)
