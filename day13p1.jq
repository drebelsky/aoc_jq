#!/usr/bin/env -S jq -Rs -f

def fewest_tokens:
    . as [[$ax, $ay], [$bx, $by], [$px, $py]]
    | reduce range(101) as $nb (500;
        . as $min_cost
        | ($bx * $nb) as $x
        | ($by * $nb) as $y
        | (($px - $x) / $ax) as $na
        | ($na * 3 + $nb) as $cost
        | if $na == ($na | floor)
            and $x + $na * $ax == $px
            and $y + $na * $ay == $py
            and $cost < $min_cost
        then
            $cost
        end
    ) | if . == 500 then 0 end;

split("\n\n") | map(split("\n") | map(select(length > 0) | [scan("\\d+") | tonumber]))
| map(fewest_tokens) | add
