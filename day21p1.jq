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
    end | split("") + ["A"];

def solve_for($goal; $map):
    # goal index, path taken, cur_loc
    [0, [], $map["A"]] | until(.[0] == ($goal | length);
        .[0] as $i
        | .[2] as [$y, $x]
        | $goal[$i] as $ch
        | .[1] | [$i + 1, . + find_path($y; $x; $ch; $map), $map[$ch]]
    ) | .[1];

def get_child($path; $map):
    # for debugging, not particularly efficient
    [foreach $path[] as $ch ($map["A"];
        . as [$y, $x]
        | if $ch == "<" then
            [$y, $x - 1]
        elif $ch == ">" then
            [$y, $x + 1]
        elif $ch == "^" then
            [$y - 1, $x]
        elif $ch == "v" then
            [$y + 1, $x]
        end;

        if $ch == "A" then
            . as $val | $map | to_entries | map(select(.value == $val) | .key) | .[0]
        else
            empty
        end
    )];

split("\n") | map(select(length > 0))
| reduce .[] as $line (0;
    . as $total
    | solve_for(($line | split("")); $NUMPAD)
    | solve_for(.; $DPAD)
    | solve_for(.; $DPAD) | length
    | . * ($line | scan("\\d+") | tonumber) + $total
)
