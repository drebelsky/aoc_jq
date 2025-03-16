#!/usr/bin/env -S jqc -Rs -f

# greedy solution is okay since we always return to the A button
{
    "7": [0, 0], "8": [0, 1], "9": [0, 2],
    "4": [1, 0], "5": [1, 1], "6": [1, 2],
    "1": [2, 0], "2": [2, 1], "3": [2, 2],
    " ": [3, 0], "0": [3, 1], "A": [3, 2]
} as $NUMPAD
| {
    " ": [0, 0], "^": [0, 1], "A": [0, 2],
    "<": [1, 0], "v": [1, 1], ">": [1, 2]
} as $DPAD
| def find_path($y; $x; $ch; $map):
    # given that the robot is currently on $y, $x, find a shortest path to $ch
    $map[$ch] as [$y2, $x2]
    | ("v" * ($y2 - $y)) as $down
    | ("^" * ($y - $y2)) as $up
    | (">" * ($x2 - $x)) as $right
    | ("<" * ($x - $x2)) as $left
    | if $map[" "][0] == $y and $map[" "][1] == $x2 then
        # start with y
        $down + $up + $right + $left
    elif $map[" "][0] == $y2 and $map[" "][1] == $x then
        # start with x
        $right + $left + $down + $up
    else
        # by distance from A
        $left + $down + $up + $right
    end + "A";

def solve_for($goal; $map):
    # goal index, path taken, cur_loc
    [0, {}, $map["A"]] | until(.[0] == ($goal | length);
        .[0] as $i
        | .[2] as [$y, $x]
        | $goal[$i] as $ch
        | .[1] | find_path($y; $x; $ch; $map) as $p | .[$p] as $cur | setpath([$p]; $cur + 1)
        | [$i + 1, ., $map[$ch]]
    ) | .[1];

def multiply($by):
    with_entries(.value *= $by);

def merge($a; $b):
    reduce ($b | to_entries[]) as {$key, $value} ($a;
        .[$key] += $value);

def up_a_layer:
    reduce to_entries[] as {key: $goal, value: $arity} ({};
        merge(.; solve_for($goal | split(""); $DPAD) | multiply($arity)));

def repeat(f; $times):
    [0, .]
    | until(.[0] == $times;
        .[0] as $i | .[1] | f | [$i + 1, .])
    | .[1];

split("\n") | map(select(length > 0))
| reduce .[] as $line (0; 
    . as $total
    | solve_for($line | split(""); $NUMPAD)
    | repeat(up_a_layer; 25)
    | reduce to_entries[] as {$key, $value} (0; . + ($key | length) * $value)
    | . * ($line | scan("\\d+") | tonumber) + $total
)
