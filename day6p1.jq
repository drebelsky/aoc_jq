#!/usr/bin/env -S jq -Rs -f

def out_of_range(r; c; height; width):
    r < 0 or c < 0 or r >= width or r >= height;

def key(r; c):
    [r, c] | map(tostring) | join(",");

def count(grid; r; c; $height; $width):
    def rec:
        . as [$r, $c, $dr, $dc, $positions] |
        if out_of_range($r; $c; $height; $width) then
            $positions | length
        elif grid[$r][$c] == "#" then
            [$r - $dr, $c - $dc, $dc, -$dr, $positions] | rec
        else
            [$r + $dr, $c + $dc, $dr, $dc, $positions + {(key($r; $c)): true}] | rec
        end;
    [r, c, -1, 0, {}] | rec;

split("\n") | map(select(. | length > 0) | split(""))
| length as $height
| (.[0] | length) as $width
| . as $grid
| first(
    foreach range($height) as $r (null; .;
        foreach range($width) as $c(null; .; if $grid[$r][$c] == "^" then [$r, $c] else empty end)
    )
) | . as [$r, $c] | {} as $positions
| count($grid; $r; $c; $height; $width)
