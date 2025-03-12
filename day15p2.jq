#!/usr/bin/env -S jq -Rs -f
def display:
    # grid -> null
    map(join("")) | join("\n") | stderr | null;

def find_robot($grid):
    first(foreach range($grid | length) as $y (
        null;
        $grid[$y] | index("@");
        if . == null then empty else [$y, .] end));

def can_move($y; $x; $dy):
    # takes in grid; returns false | {locations moved to}: dict[str[list[2]]: true]
    if .[$y][$x] == "]" then
        # we can end up with some redundant work on box edges, but this was fast enough
        . as $grid | can_move($y + $dy; $x; $dy) | if . then
            try
                (. + ($grid | can_move($y + $dy; $x - 1; $dy)))
            catch
                false
        end
    elif .[$y][$x] == "[" then
        . as $grid | can_move($y + $dy; $x; $dy) | if . then
            try
                (. + ($grid | can_move($y + $dy; $x + 1; $dy)))
            catch
                false
        end
    elif .[$y][$x] == "." then
        {}
    elif .[$y][$x] == "#" then
        false
    elif .[$y][$x] == "@" then
        can_move($y + $dy; $x; $dy)
    end
    | if . then
        setpath([[$y, $x] | tostring]; true)
    else
        false
    end;

def try_vertical($dy):
    # takes in [[robot_y, robot_x], grid]
    # returns updated [[robot_y, robot_x], grid]
    . as [[$ry, $rx], $grid]
    | ($grid | can_move($ry; $rx; $dy)) as $locs
    | if $locs then
        $locs | del(.[[$ry, $rx] | tostring])
        | reduce (keys[] | fromjson) as [$y, $x] ($grid | setpath([$ry, $rx]; ".");
            setpath([$y, $x]; $grid[$y - $dy][$x])
            | if $locs[[$y - $dy, $x] | tostring] | not then
                setpath([$y - $dy, $x]; ".")
            end
        ) | [[$ry + $dy, $rx], .]
    end;

def try_horizontal($dx):
    # takes in [[robot_y, robot_x], grid]
    # returns updated [[robot_y, robot_x, grid]]
    (.[1] | length) as $height
    | (.[1][0] | length) as $width 
    # try to find first available space
    | . + [.[0]]
    | until(.[-1] as $pos | .[1] | getpath($pos) | . == "." or . == "#";
        .[-1] as [$py, $px]
        | .[:-1] + [[$py, $px + $dx]])
    | .[-1] as $pos
    | if .[1] | getpath($pos) == "#" then
        .[:-1]
    else
        .[0] as $robot
        | [$pos, .[1]] | until(.[0] == $robot;
            .[0] as $cur
            | [.[0][0], .[0][1] - $dx] as $next
            | (.[1] | getpath($next)) as $val
            | .[1] | setpath($cur; $val)
            | [$next, .])
        | .[1] | setpath($robot; ".")
        | [[$robot[0], $robot[1] + $dx], .]
    end;
        
split("\n\n")
| (.[0] | split("\n") | map(
    split("") | map(if . == "#" then "#", "#" elif . == "O" then "[", "]" else ., "." end)
)) as $grid
| (.[1] | split("\n") | join("") | split("")) as $moves
| ($moves | length) as $end
| find_robot($grid) as $robot
# note, we end up making a copy of the grid, but only the first time
| [0, $robot, $grid] | until (.[0] == $end;
    # uncomment the two below comments to generate progression similar to that on spec
    .[0] as $i | .[1:] #  | (.[1] | display | "\n\nMove \($moves[$i]):\n" | stderr) as $_
    | if $moves[$i] == "^" then
        try_vertical(-1)
    elif $moves[$i] == "<" then
        try_horizontal(-1)
    elif $moves[$i] == ">" then
        try_horizontal(1)
    elif $moves[$i] == "v" then
        try_vertical(1)
    end
    | [$i + 1] + .
) | .[-1] as $grid
# | $grid | display
| $grid | length as $height | .[0] | length as $width
| reduce range($height) as $y (0;
    reduce range($width) as $x (.;
        if $grid[$y][$x] == "[" then
            . + 100 * $y + $x
        end))
