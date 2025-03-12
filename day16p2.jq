#!/usr/bin/env -S jq -Rs -f

def find_char($grid; $char):
    first(foreach range($grid | length) as $y (
        null;
        $grid[$y] | index($char);
        if . == null then empty else [$y, .] end));

def parent($i):
    ($i - 1) / 2 | floor;

def heappush($val):
    # heap -> heap
    . + [$val] | [length - 1, .]
    | until (.[0] == 0 or getpath([1, parent(.[0])]) <= getpath([1, .[0]]);
        .[0] as $i | parent($i) as $p
        | getpath([1, $i]) as $cur
        | getpath([1, $p]) as $par
        | .[1] | setpath([$i]; $par) | setpath([$p]; $cur) | [$p, .])
    | .[1];

def heappop:
    # heap -> heap (look at heap[0] for top)
    length as $length
    | .[$length - 1] as $last
    | del(.[$length - 1])
    | setpath([0]; $last)
    | [0, .]
    | ($length - 1) as $length
    | until(
        .[0] as $i |
            ($i*2 + 1 >= $length or .[1][$i] <= .[1][$i*2 + 1])
            and ($i*2 + 2 >= $length or .[1][$i] <= .[1][$i*2 + 2]);

        .[0] as $i | .[1]
        | if $i*2 + 2 >= $length or .[$i*2 + 1] <= .[$i*2 + 2] then
            .[$i*2 + 1] as $child
            | .[$i] as $cur
            | setpath([$i]; $child) | setpath([$i*2 + 1]; $cur) | [$i*2 + 1, .]
        else
            .[$i*2 + 2] as $child
            | .[$i] as $cur
            | setpath([$i]; $child) | setpath([$i*2 + 2]; $cur) | [$i*2 + 2, .]
        end)
    | .[1];

def key($node):
    $node[1:] | tostring;



{"N": "E", "E": "S", "S": "W", "W": "N"} as $CW
| {"N": "W", "W": "S", "S": "E", "E": "N"} as $CCW 
| {"N": [-1, 0], "E": [0, 1], "S": [1, 0], "W": [0, -1]} as $DIR


| split("\n") | map(select(length > 0) | split(""))
| . as $grid
| ($grid | length) as $height
| ($grid[0] | length) as $width
| def in_bounds($y; $x):
    $y >= 0 and $y < $height and $x >= 0 and $x < $width;
def new_path($dist; $y; $x; $dir):
    # used when we have a new path to [$y, $x, $dir] with cost $dist
    # [heap, min_cost] -> [heap, min_cost]
    key([$dist, $y, $x, $dir]) as $key
    | if in_bounds($y; $x)
        and $grid[$y][$x] != "#"
        and (.[1][$key] == null or .[1][$key] > $dist)
    then
        setpath([1, $key]; $dist)
        | .[1] as $min_cost
        | .[0] | heappush([$dist, $y, $x, $dir])
        | [., $$$$min_cost]
    end;

def dijkstra($sy; $sx; $end_char; $facing):
    [0, $sy, $sx, $facing] as $first
    | first (foreach repeat(null) as $_ ([[$first], {(key($first)): 0}];
        .[0][0] as [$dist, $y, $x, $dir]
        | key(.[0][0]) as $key
        | .[1] as $min_cost
        | .[0] | heappop
        | if $dist > $min_cost[$key] then
            [., $$$$min_cost]
        elif $grid[$y][$x] == $end_char then
            $$$$min_cost | setpath(["min"]; $dist) # a little hacky, but :shrug:
        else
            $DIR[$dir] as [$dy, $dx]
            | [., $$$$min_cost]
            | new_path($dist + 1; $y + $dy; $x + $dx; $dir)
            | new_path($dist + 1000; $y; $x; $CW[$dir]) 
            | new_path($dist + 1000; $y; $x; $CCW[$dir]) 
        end;

     # we only produce a value in the case where we find E, and first stops our foreach from going forever
        objects
    ));

def merge($obj1; $obj2):
    reduce ($obj2 | keys[]) as $key ($obj1;
        if $obj1[$key] == null or $obj2[$key] < $obj1[$key] then
            setpath([$key]; $obj2[$key])
        end
    );

# run 2 dijkstra's à la https://www.reddit.com/r/adventofcode/comments/1hfboft/comment/m2bae5n/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
find_char($grid; "S") as $s_loc
| find_char($grid; "E") as $e_loc 
| dijkstra($s_loc[0]; $s_loc[1]; "E"; "E") as $from_start
| reduce (["N", "S", "E", "W"][]) as $dir ({};
    . as $cur
    | dijkstra($e_loc[0]; $e_loc[1]; "S"; $dir) as $new
    | merge($cur; $new)
) | . as $from_end
| $from_start["min"] as $min
| {"N": "S", "S": "N", "E": "W", "W": "E"} as $flip
| reduce (range($height) as $y | range($width) | [$y, .]) as $loc (0;
    if $loc == $s_loc or $loc == $e_loc then
        . + 1
    else
        if any(["N","S","E","W"][];
            ($loc + [.] | tostring) as $key1
            | ($loc + [$flip[.]] | tostring) as $key2
            | $from_start[$key1] + $from_end[$key2] == $min
        ) then
            . + 1
        end
    end
)
