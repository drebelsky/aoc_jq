#!/usr/bin/env -S jq -Rs -f
def find_antinodes(height; width; points):
    def in_bounds($p):
        $p[0] >= 0 and $p[0] < height and $p[1] >= 0 and $p[1] < width;
    def antinodes(p1; p2):
        # antinodes generated from p2 onward in the direction of p1->p2
        (p2[0] - p1[0]) as $dy | (p2[1] - p1[1]) as $dx |
        def rec:
            if in_bounds(.) then
                ., ([.[0] + $dy, .[1] + $dx] | rec)
            else
                empty
            end;
        p2 | rec;
    reduce (points | combinations(2)) as [$p1, $p2] ({};
        if $p1 != $p2 then
            reduce (antinodes($p1; $p2), antinodes($p2; $p1)) as $antinode (.;
                .[$antinode | tostring] = true
            )
        end
    );

split("\n") | map(select(length > 0) | split(""))
| . as $grid
| length as $height
| (.[0] | length) as $width
| reduce range($height) as $y ({};
    reduce range($width) as $x (.;
        if $grid[$y][$x] != "." then
            .[$grid[$y][$x]] += [[$y, $x]]
        end
    )
)
| reduce .[] as $points ({};
    . + find_antinodes($height; $width; $points)
) | length
