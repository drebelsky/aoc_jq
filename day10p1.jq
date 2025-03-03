#!/usr/bin/env -S jq -Rs -f
def in_bounds($y; $x; $height; $width):
    $y >= 0 and $y < $height and $x >= 0 and $x < $width;

def pad($num; $len):
    $num | tostring as $s | ($len - ($s | length)) * " " + $s;

def debug_print($grid; $dp):
    $dp | reduce .[] as $row ([];
        . + [reduce $row[] as $val ([]; . + [($val | length)])]
    ) | . as $dp
    | $grid | length as $height
    | $grid[0] | length as $width
    | $grid | flatten | map(tostring | length) | max as $gl
    | $dp | flatten | map(tostring | length) | max as $dl
    | reduce range($height) as $y (null;
        reduce range($width) as $x ([]; . + ["\(pad($grid[$y][$x]; $gl)): \(pad($dp[$y][$x]; $dl))"])
        | join("|") | stderr | "\n" | stderr
    ) | null;

split("\n") | map(select(length > 0) | split("") | map(if . == "." then -1 else tonumber end)) as $grid
| $grid | length as $height
| $grid[0] | length as $width
| [] | .[$width - 1] = null | . as $row
| [] | .[$height - 1] = null | map($row) as $dp
| reduce range(9; -1; -1) as $num ($dp;
    reduce range($height) as $y (.;
        reduce range($width) as $x (.;
            if $grid[$y][$x] == $num then
                if $num == 9 then
                    .[$y][$x] = {([$y, $x] | tostring): true}
                else
                    . as $dp | .[$y][$x] = reduce [[0, -1], [0, 1], [-1, 0], [1, 0]][] as [$dy, $dx] ({};
                        if in_bounds($y + $dy; $x + $dx; $height; $width)
                           and $num + 1 == $grid[$y + $dy][$x + $dx] then
                            . + $dp[$y + $dy][$x + $dx]
                        end
                    )
                end
            end
        )
    )
) | . as $dp
| reduce range($height) as $y (0;
    reduce range($width) as $x (.;
        if $grid[$y][$x] == 0 then
            . + ($dp[$y][$x] | length)
        end
    )
)
