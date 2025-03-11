#!/usr/bin/env -S jq -Rrs -f
# display the grid after number of seconds as given by --arg n <n>
# TODO: search for the image in jq instead of "by hand"
101 as $width | 103 as $height
# | 11 as $width | 7 as $height
| (($width / 2) | floor) as $xmid
| (($height / 2) | floor) as $ymid

| def ensure_int:
     # float 64 has 53 bits of precision, constant is 2^53 - 1
    if . > 9007199254740991 then
        error("\(.) has potential precision loss")
    end;

def loc_after($iters):
    . as [$px, $py, $vx, $vy]
    | [(($px + $iters * $vx) | ensure_int % $width), (($py + $iters * $vy) | ensure_int % $height)]
    | [(.[0] + $width) % $width, (.[1] + $height) % $height]; # in case we had negatives

def make_grid($height; $width):
    ([] | .[$width - 1] = null | map(0)) as $row
    | [] | .[$height - 1] = null | map($row);

split("\n") | map(select(length > 0) | [scan("-?\\d+") | tonumber])
| map(loc_after($n | tonumber))
| reduce .[] as [$x, $y] (make_grid($height; $width);
    .[$y][$x] += 1)
# | map(map(if . == 0 then "." else tostring end) | join("")) | join("\n")
| map(map(if . == 0 then " " else "#" end) | join("")) | join("\n")
