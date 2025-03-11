#!/usr/bin/env -S jq -Rs -f
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

split("\n") | map(select(length > 0) | [scan("-?\\d+") | tonumber])
| map(loc_after(100))
| reduce .[] as [$x, $y] ([0, 0, 0, 0];
    if $x < $xmid then
        if $y < $ymid then
            .[0] += 1
        elif $y > $ymid then
            .[1] += 1
        end
    elif $x > $xmid then
        if $y < $ymid then
            .[2] += 1
        elif $y > $ymid then
            .[3] += 1
        end
    end
) | reduce .[] as $i (1; . * $i)
