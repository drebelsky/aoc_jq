#!/usr/bin/env -S jq -Rs -f

def invert:
    . as [[$a, $b], [$c, $d]]
    | (($a * $d) - ($b * $c)) as $det
    | if $det == 0 then
        error("noninvertible")
    else
        [$det, [[$d, -$b], [-$c, $a]]]
    end;

def dot($v1; $v2):
    reduce range($v1 | length) as $i (0; . + $v1[$i] * $v2[$i]);

def matmul($M2; $vec2):
    # expects 2x2, and x2
    reduce $M2[] as $row ([]; . + [dot($row; $vec2)]);

def fewest_tokens:
    . as [[$ax, $ay], [$bx, $by], $prize]
    | ($prize | map(. + 10000000000000)) as $prize
    | (.[:2] | transpose | invert) as [$det, $C]
    | matmul($C; $prize) | map(. / $det) as [$A, $B]
    | if $A == ($A | floor) and $B == ($B | floor) then
        $A * 3 + $B
    else
        0
    end;

split("\n\n") | map(split("\n") | map(select(length > 0) | [scan("\\d+") | tonumber]))
| map(fewest_tokens) | add
