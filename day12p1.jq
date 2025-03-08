#!/usr/bin/env -S jq -Rs -f
# use a union-find data structure on size
# note, $$$$ is technically internal only and shouldn't be used, but without it, the code to avoid extra copies gets uglier

def get_parent($node):
    # [parent_map] -> [parent_map, parent]
    [., $node]
    | until(
        .[1] as $node | (.[0] | getpath($node)) == $node;
        .[1] as $node | [.[0], (.[0] | getpath($node))])
    | .[1] as $root
    | [.[0], $node]
    | until(
        .[1] == $root;
        # note it's important to do the setpath outside of the [] to avoid making a copy of parent_map
        .[1] as $node | (.[0] | getpath($node)) as $next | .[0] | setpath($node; $root)
        | [., $next]);

def union($key1; $key2):
    # [parent, size] -> [parent, size, chosen_root]
    .[1] as $size
    | (.[0] | get_parent($key1)) | .[1] as $parent1
    | (.[0] | get_parent($key2)) | .[1] as $parent2
    | ($size | getpath($parent1)) as $size1
    | ($size | getpath($parent2)) as $size2
    | ($size1 + $size2) as $combined
    | [.[0], $$$$size]
    | if $parent1 != $parent2 then
        if $size1 >= $size2 then
            # make parent1 parent2's parent
            setpath([0] + $parent2; $parent1) | setpath([1] + $parent1; $combined)
            | setpath([2]; $parent1)
        else
            # make parent2 parent1's parent
            setpath([0] + $parent1; $parent2) | setpath([1] + $parent2; $combined)
            | setpath([2]; $parent2)
        end
    end;

def calculate($grid):
    ($grid | length) as $height
    | ($grid[0] | length) as $width

    | def in_bounds($y; $x):
        0 <= $y and $y < $height and 0 <= $x and $x < $width;

    def join_square($y; $x):
        # [parent: arr[y][x] -> [py, px], size: arr[y][x] -> number]
        def handle($y2; $x2):
            if in_bounds($y2; $x2) and $grid[$y2][$x2] == $grid[$y][$x] then
                union([$y, $x]; [$y2, $x2])
            end;
        # reduce causes extra copies, so we unroll
        handle($y - 1; $x) | handle($y + 1; $x) | handle($y; $x - 1) | handle($y; $x + 1);

    def perim($y; $x):
        def handle($y2; $x2):
            if (in_bounds($y2; $x2) | not) or $grid[$y2][$x2] != $grid[$y][$x] then
                . + 1
            end;
        0 | handle($y - 1; $x) | handle($y + 1; $x) | handle($y; $x - 1) | handle($y; $x + 1);

    reduce range($height) as $y ([];
        setpath([$y]; reduce range($width) as $x ([];
            setpath([$x]; [$y, $x]))))
    | . as $parent
    | [] | setpath([$width - 1]; 1) | map(1) as $row
    | [] | setpath([$height - 1]; null) | map($row)
    | . as $size
    # as far as I can tell, reduce ends up creating an extra reference in the expr part,
    # so, to minimize the copies expensive here, we use an until instead
    # TODO: check if we copy the rows (the outer two arrays don't get copied)
    | [0, 0, $$$$parent, $$$$size]
    | until (.[0] == $height;
        .[0] as $y
        | .[1] = 0
        | until (.[1] == $width;
            .[1] as $x
            | .[2:] | join_square($y; $x)
            | [$y, $x + 1] + .)
        | .[0] += 1 | .[1] = 0)
    | .[3] as $size
    | [0, 0, 0, .[2]] # TODO: we end up copying the last array
    | until (.[0] == $height;
        .[0] as $y
        | until (.[1] == $width;
            .[1] as $x | .[2] as $total | .[:2] as $key
            | .[-1] | get_parent($key)
            | .[1] as $root
            | ($total + perim($y; $x) * ($size | getpath($root))) as $total
            | .[0]
            | [$y, $x + 1, $total, .])
        | setpath([0]; $y + 1) | setpath([1]; 0))
    | .[2];
    

split("\n") | map(select(length > 0) | split(""))
| calculate(.)
