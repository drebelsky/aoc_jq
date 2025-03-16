#!/usr/bin/env -S jq -s -f
import "xor_table" as $XOR;
# this isn't particularly efficient, it takes about 2.5 minutes on my machine

def xor($a; $b):
    [1, 0, $a, $b]
    | until(.[-1] == 0 and .[-2] == 0;
        . as [$mul, $res, $a, $b]
        | ($a % 256) as $a_rem
        | ($b % 256) as $b_rem
        | [$mul * 256, $res + $mul * $XOR[0][$a_rem][$b_rem], ($a - $a_rem) / 256, ($b - $b_rem) / 256])
    | .[1];

def prune:
    . % 16777216;

def div($a; $b):
    ($a % $b) as $rem
    | ($a - $rem) / $b;

def next:
    xor(.; . * 64) | prune
    | xor(.; div(.; 32)) | prune
    | xor(.; . * 2048) | prune;

2000 as $NUM_ITEMS
| map(
    [. % 10, foreach range($NUM_ITEMS) as $_ (.; next; . % 10)]
    | . as $nums
    | [foreach range(1; $NUM_ITEMS) as $i (null; $nums[$i] - $nums[$i - 1]; .)] as $diffs
    | $diffs | (length + 1) as $end
    # here we use an until to avoid the copying of the object
    | [4, {}] | until(.[0] == $end;
        .[0] as $i
        | ($diffs[$i-4 : $i] | tostring) as $key
        | .[1]
        | if .[$key] | not then
            setpath([$key]; $nums[$i])
        end | [$i + 1, .])
    | .[1]
) as $objs
| reduce $objs[] as $obj ({}; . + $obj)
| reduce keys_unsorted[] as $key (0;
    . as $best
    | reduce $objs[] as $obj (0; . + $obj[$key])
    | . as $cur
    | if $cur > $best then
        $cur
    else
        $best
    end
)
