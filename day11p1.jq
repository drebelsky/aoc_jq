#!/usr/bin/env -S jq -s -f
# stone format: [number, blinks left]

def blink($stone):
    # shouldn't pass stones that have already been blinked fully
    # returns [updated_stone, new_stone?]
    $stone | ($stone[1] - 1) as $blinks_left
    | if $stone[0] == 0 then
        [[1, $blinks_left]]
    elif ($stone[0] | tostring | length % 2 == 0) then
        $stone[0] | tostring | . as $num
        | (length / 2) as $l
        | [[$num[:$l] | tonumber, $blinks_left], [$num[$l:] | tonumber, $blinks_left]]
    else
        [[$stone[0] * 2024, $blinks_left]]
    end;

def calculate($arr):
    def rec:
        # [total, arr]; note we don't keep arr as a variable so that we have efficient array update
        . as [$total]
        | if 0 == (.[1] | length) then
            $total
        elif .[1][-1][1] == 0 then
            [$total + 1, .[1][:-1]] | rec
        else
            .[1] | blink(.[-1]) as $res
            | [$total, (. | (.[-1] = $res[0]) | . + $res[1:])] | rec
        end;
    [0, $arr] | rec;
    
calculate(map([., 25]))
