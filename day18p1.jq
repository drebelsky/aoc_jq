#!/usr/bin/env -S jq -Rs -f

70 as $MAX
# | 6 as $MAX
| def in_bounds($x; $y):
    0 <= $x and $x <= $MAX and 0 <= $y and $y <= $MAX;
def handle($dist; $x; $y):
    # [blocked, queue]
    if in_bounds($x; $y) and (.[0][$x][$y] | not) then
        setpath([0, $x, $y]; true)
        | .[0] as $blocked
        | .[1] | . + [[$dist, $x, $y]]
        | [$blocked, .]
    end;

split("\n") | map(select(length > 0) | split(",") | map(tonumber))
| .[:1024]
# | .[:12]
| . as $bytes
# note, we have an inverted grid relative to how it would be displayed since we don't flip the coordinate
| reduce $bytes[] as $coord ([]; setpath($coord; true))
| . as $blocked
# for in-place usage while doing BFS, we keep a pointer to the current start to simulate a queue
# index, blocked, [[dist, y, x]+]
| [0, ($blocked | setpath([0, 0]; true)), [[0, 0, 0]]] | until(type == "number";
    .[0] as $i
    | .[2][$i] as [$dist, $x, $y]
    | if $x == $MAX and $y == $MAX then
        $dist
    else
        .[1:]
        | handle($dist + 1; $x - 1; $y) 
        | handle($dist + 1; $x + 1; $y)
        | handle($dist + 1; $x; $y - 1)
        | handle($dist + 1; $x; $y + 1)
        | [$i + 1] + .
    end
)
