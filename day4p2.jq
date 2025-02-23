#!/usr/bin/env -S jq -Rs -f

def matches(grid; y; x):
    grid[y + 1][x + 1] == "A" 
    and ("MSM" | contains([grid[y][x], grid[y + 2][x + 2]] | join("")))
    and ("MSM" | contains([grid[y][x + 2], grid[y + 2][x]] | join("")));

split("\n") | map(select(length > 0)) # split lines
| map(split("")) # convert to list[list[char]] (can't index a string)
| . as $grid
| length as $height
| .[0] | length as $width
| reduce
    (range($height - 2) as $i | range($width - 2) | [$i, .]) # cartesian product
    as $coord
    (0; if matches($grid; $coord[0]; $coord[1]) then . + 1 end)
