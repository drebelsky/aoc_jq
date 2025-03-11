#!/usr/bin/env -S jq -Rs -f
def find_robot($grid):
    first(foreach range($grid | length) as $y (
        null;
        $grid[$y] | index("@");
        if . == null then empty else [$y, .] end));

def try_move($dy; $dx):
    # takes in [[robot_y, robot_x], grid]
    # returns updated [[robot_y, robot_x, grid]]
    (.[1] | length) as $height
    | (.[1][0] | length) as $width 
    # try to find first available space
    | . + [.[0]]
    | until(.[-1] as $pos | .[1] | getpath($pos) | . == "." or . == "#";
        .[-1] as [$py, $px]
        | .[:-1] + [[$py + $dy, $px + $dx]])
    | .[-1] as $pos
    | if .[1] | getpath($pos) == "#" then
        .[:-1]
    else
        .[0] as $robot
        | [$pos, .[1]] | until(.[0] == $robot;
            .[0] as $cur
            | [.[0][0] - $dy, .[0][1] - $dx] as $next
            | (.[1] | getpath($next)) as $val
            | .[1] | setpath($cur; $val)
            | [$next, .])
        | .[1] | setpath($robot; ".")
        | [[$robot[0] + $dy, $robot[1] + $dx], .]
    end;
        
split("\n\n") | (.[0] | split("\n") | map(split(""))) as $grid
| (.[1] | split("\n") | join("") | split("")) as $moves
| ($moves | length) as $end
| find_robot($grid) as $robot
# note, we end up making a copy of the grid, but only the first time
| [0, $robot, $grid] | until (.[0] == $end;
    .[0] as $i | .[1:]
    | if $moves[$i] == "^" then
        try_move(-1; 0)
    elif $moves[$i] == "<" then
        try_move(0; -1)
    elif $moves[$i] == ">" then
        try_move(0; 1)
    elif $moves[$i] == "v" then
        try_move(1; 0)
    end
    | [$i + 1] + .
) | .[-1] as $grid | $grid | length as $height | .[0] | length as $width
| reduce range($height) as $y (0;
    reduce range($width) as $x (.;
        if $grid[$y][$x] == "O" then
            . + 100 * $y + $x
        end))
