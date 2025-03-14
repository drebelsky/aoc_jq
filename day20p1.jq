#!/usr/bin/env -S jq -Rs -f

[[-1, 0], [1, 0], [0, -1], [0, 1]] as $DIRS
| (reduce ($DIRS[] as [$dy1, $dx1] | $DIRS[] as [$dy2, $dx2] | [$dy1 + $dy2, $dx1 + $dx2]) as $d ({};
    setpath([$d | tostring]; 1)
) | del(.["[0,0]"]) | keys | map(fromjson)) as $DIRS2

| def find_char($grid; $char):
    first(foreach range($grid | length) as $y (
        null;
        $grid[$y] | index($char);
        if . == null then empty else [$y, .] end));

split("\n") | map(select(length > 0) | split(""))
| . as $board
| length as $height
| .[0] | length as $width
| find_char($board; "S") as [$sy, $sx]
| def is_next_step($y; $x):
    # previous location -> bool
    $y >= 0 and $y < $height and $x >= 0 and $x < $width and $board[$y][$x] != "#" and [$y, $x] != .;
def find_path:
    # find path through the maze
    # [[y, x]+], last index is last explored -> [[y, x]+]
    .[-1] as [$y, $x]
    | if $board[$y][$x] == "E" then
        .
    else
        [0, .] | until($DIRS[.[0]] as [$dy, $dx] | .[1][-2] | is_next_step($y + $dy; $x + $dx);
            .[0] += 1
        )
        | $DIRS[.[0]] as [$dy, $dx]
        | .[1] + [[$y + $dy, $x + $dx]] | find_path
    end;
        
[[$sy, $sx]]
| find_path as $path
| reduce range($path | length) as $i ({}; setpath([$path[$i] | tostring]; $i))
| . as $cost
| $path | length as $length
| reduce $path[] as $coord (0;
    $coord as [$y, $x]
    | $cost[$coord | tostring] as $to_coord
    | reduce $DIRS2[] as [$dy, $dx] (.;
        if null | is_next_step($y + $dy; $x + $dx) then
            if $length - 100 >= $length - $cost[[$y + $dy, $x + $dx] | tostring] + $to_coord + 2 then
                . + 1
            end
        end))
