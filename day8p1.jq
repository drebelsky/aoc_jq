#!/usr/bin/env -S jq -Rs -f
def find_antinodes(height; width; points):
    def antinode(p1; p2):
        [2*p2[0] - p1[0], 2*p2[1] - p1[1]] as $p3
        | if $p3[0] < 0 or $p3[0] >= height or $p3[1] < 0 or $p3[1] >= width then
            {}
        else
            {($p3 | map(tostring) | join(",")): true}
        end;
    reduce (points | combinations(2)) as [$p1, $p2] ({};
        if $p1 != $p2 then
            . + antinode($p1; $p2)
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
