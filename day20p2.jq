#!/usr/bin/env -S jq -Rs -f
# Note: this is somewhat slow (takes about two minutes on my machine), but
# could plausibly be sped up with a two-layer cache like day11p2; it was fast
# enough, though, so I didn't optimize further

[[-1, 0], [1, 0], [0, -1], [0, 1]] as $DIRS

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
| def in_bounds($y; $x):
    $y >= 0 and $y < $height and $x >= 0 and $x < $width;

def is_next_step($y; $x):
    # previous location -> bool
     in_bounds($y; $x) and $board[$y][$x] != "#" and [$y, $x] != .;
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
| def count_cheats($y; $x; $initial):
    def handle($y2; $x2; $dist):
        # [., ., visited, queue] -> [., ., visited', queue']
        ([$y2, $x2] | tostring) as $key
        | if in_bounds($y2; $x2) and (.[2][$key] | not) then
            setpath([2, $key]; true)
            | . as [$a, $b, $visited] # manual unpack because [:1] ends up creating an extra ref
            | .[-1] | . + [[$dist, $y2, $x2]]
            | [$a, $b, $visited, .]
        end;
    # for simple in-place usage while doing BFS, we keep a pointer to the current start to simulate a queue
    # [index: number, saved: number, visited: map[string[list[2]], true], queue: [[dist, y, x]]
    [0, 0, {([$y, $x] | tostring): true}, [[0, $y, $x]]] | until(.[0] == (.[-1] | length);
        .[-1][.[0]] as [$dist, $y, $x]
        | if $board[$y][$x] != "#" and ($length - $cost[[$y, $x] | tostring] + $dist + $initial + 100 <= $length) then
            .[1] += 1
        end
        | if $dist < 20 then
            handle($y + 1; $x + 0; $dist + 1)
            | handle($y + -1; $x + 0; $dist + 1)
            | handle($y + 0; $x + 1; $dist + 1)
            | handle($y + 0; $x + -1; $dist + 1)
        end
        | .[0] += 1
    ) | .[1];

reduce $path[] as $coord (0;
    $coord as [$y, $x]
    | $cost[$coord | tostring] as $to_coord
    | . + count_cheats($y; $x; $to_coord)
)
