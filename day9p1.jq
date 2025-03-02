#!/usr/bin/env -S jq -Rs -f
def arr(value; length):
    reduce range(length) as $_ ([]; . + [value]);

def condense:
    def rec:
        . as [$i, $j, $arr]
        | if $i >= $j then
            $arr
        elif $arr[$j] == null then
            [$i, $j - 1, $arr] | rec
        elif $arr[$i] != null then
            [$i + 1, $j, $arr] | rec
        else
            [$i + 1, $j - 1, ($arr | .[$i] = .[$j] | .[$j] = null)] | rec
        end;
    [0, (. | length) - 1, .] | rec;

split("") | map(tonumber) as $nums
| reduce $nums[] as $num ([[], 0, true];
    . as [$arr, $file, $is_file]
    | if $is_file then
        [$arr + arr($file; $num), $file + 1, false]
    else
        [$arr + arr(null; $num), $file, true]
    end
) | .[0] | condense as $arr | reduce range($arr | length) as $i (0;
    if $arr[$i] != null then
        . + $i * $arr[$i]
    end)
