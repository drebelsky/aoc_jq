#!/usr/bin/env -S jq -Rs -f

def out_of_range(r; c; height; width):
    r < 0 or c < 0 or r >= width or r >= height;

def key(r; c):
    [r, c] | map((if . == -0 then 0 end) | tostring) | join(",");

def key(r; c; dr; dc):
    [r, c, dr, dc] | map((if . == -0 then 0 end) | tostring) | join(",");

def make_null(height; width):
    reduce range(height) as $_ ([];
        . + [reduce range(width) as $_ ([]; . + [null])]);

def first_obstacle(grid; height; width; dr; dc):
    reduce (if dr == 1 then range(height - 1; -1; -1) else range(height) end) as $r (make_null(height; width);
        reduce (if dc == 1 then range(width - 1; -1; -1) else range(width) end) as $c (.;
            if grid[$r][$c] == "#" then
                .[$r][$c] = [$r, $c]
            else
                .[$r][$c] = .[$r + dr][$c + dc]
            end
        ));

def get_candidates(grid; r; c; $height; $width):
    def rec:
        . as [$r, $c, $dr, $dc, $positions] |
        if out_of_range($r; $c; $height; $width) then
            $positions
        elif grid[$r][$c] == "#" then
            [$r - $dr, $c - $dc, $dc, -$dr, $positions] | rec
        else
            [$r + $dr, $c + $dc, $dr, $dc, $positions + {(key($r; $c)): true}] | rec
        end;
    [r, c, -1, 0, {}] | rec;

def can_reach(r1; c1; r2; c2; dr; dc):
    if dr == 1 and (c1 != c2 or r1 > r2) then
        false
    elif dr == -1 and (c1 != c2 or r1 < r2) then
        false
    elif dc == 1 and (r1 != r2 or c1 > c2) then
        false
    elif dc == -1 and (r1 != r2 or c1 < c2) then
        false
    else
        true
    end;

def mandist(p1; p2):
    [p1, p2] | transpose | map(.[0] - .[1] | abs) | add;

def does_loop(grid; gr; gc; obsr; obsc; obstacles):
     def next_obstacle(r; c; dr; dc):
        if can_reach(r; c; obsr; obsc; dr; dc) then
            obstacles[key(dr; dc)][r][c] as $opt1
            | if $opt1 == null or mandist([r, c]; [obsr, obsc]) < mandist([r, c]; $opt1) then
                [obsr, obsc]
            else
                $opt1
            end
        else
            obstacles[key(dr; dc)][r][c]
        end;
    def rec:
        . as [$r, $c, $dr, $dc, $seen]
        | if $seen[key($r; $c; $dr; $dc)] then
            true
        else
            ($seen | .[key($r; $c; $dr; $dc)] = true) as $seen
            | next_obstacle($r; $c; $dr; $dc) as $obs
            | if $obs == null then
                false
            else
                [$obs[0] - $dr, $obs[1] - $dc, $dc, -$dr, $seen] | rec
            end
        end;
    [gr, gc, -1, 0, {}] | rec;

split("\n") | map(select(. | length > 0) | split(""))
| length as $height
| (.[0] | length) as $width
| . as $grid
# find guard
| first(
    foreach range($height) as $r (null; .;
        foreach range($width) as $c(null; .; if $grid[$r][$c] == "^" then [$r, $c] else empty end)
    )
) | . as [$gr, $gc] | {} as $positions
# get locations along guards path
| get_candidates($grid; $gr; $gc; $height; $width) | keys
| map(split(",") | map(tonumber)) as $candidates
# save first obstacle along each direction for more efficient loop detection
| reduce [-1, 1][] as $d ([];
    . + reduce [true, false][] as $dr_zero ([];
        . + (if $dr_zero then [[0, $d]] else [[$d, 0]] end)))
| reduce .[] as [$dr, $dc] ({}; . + {(key($dr; $dc)): first_obstacle($grid; $height; $width; $dr; $dc)})
| . as $obstacles
| reduce $candidates[] as [$r, $c] (0;
    if ($r != $gr or $c != $gc) and does_loop($grid; $gr; $gc; $r; $c; $obstacles) then
        . + 1
    end
)
