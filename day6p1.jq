#!/usr/bin/env -S jq -Rs -f

def out_of_range(r; c; height; width):
    r < 0 or c < 0 or r >= width or r >= height;

def key(r; c):
    [r, c] | map(tostring) | join(",");

def count(grid; r; c; height; width; dr; dc; positions):
    if out_of_range(r; c; height; width) then
        positions | length
    elif grid[r][c] == "#" then
        (r - dr) as $r
        | (c - dc) as $c
        | dc as $dr
        | (-dr) as $dc
        | count(grid; $r; $c; height; width; $dr; $dc; positions)
    else
        (positions + {(key(r; c)): true}) as $positions
        | (r + dr) as $r
        | (c + dc) as $c
        | count(grid; $r; $c; height; width; dr; dc; $positions)
    end;

split("\n") | map(select(. | length > 0) | split(""))
| length as $height
| (.[0] | length) as $width
| . as $grid
| first(
    foreach range($height) as $r (null; .;
        foreach range($width) as $c(null; .; if $grid[$r][$c] == "^" then [$r, $c] else empty end)
    )
) | . as [$r, $c] | {} as $positions
| count($grid; $r; $c; $height; $width; -1; 0; $positions)
