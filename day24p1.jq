#!/usr/bin/env -S jq -Rs -f

def eval($gate; $vals):
    if $gate | length != 3 then
        error("gate length was not 3")
    end
    | $gate as [$type, $val1, $val2]
    | if $type == "XOR" then
        ($val1 + $val2) % 2
    elif $type == "OR" then
        if $val1 + $val2 >= 1 then 1 else 0 end
    elif $type == "AND" then
        if $val1 + $val2 == 2 then 1 else 0 end
    else
        error("Invalid type \($type)")
    end;

def to_decimal:
    . as $arr
    | [0, 0] | until($arr[.[0]] | not;
        . as [$i, $cur]
        | [$i + 1, $cur * 2 + $arr[$i]])
    | .[1];

split("\n\n") | .[1] as $gates | .[0]
| split("\n") | map(split(": ") | .[1] |= tonumber)
| . as $inputs
| $gates | split("\n") | map(
    select(length > 0)
    | split(" -> ")
    | .[1] as $out
    | .[0] | split(" ") | [.[1], .[0], .[2], $out])
| . as $gates
| length as $len
# index, outgoing, incoming
| [0, {}, {}] | until(.[0] == $len;
    .[0] as $i
    | $gates[$i] as [$op, $ina, $inb, $out]
    | getpath([1, $ina]) as $cura
    | setpath([1, $ina]; $cura + [$out])
    | getpath([1, $inb]) as $curb
    | setpath([1, $inb]; $curb + [$out])
    | setpath([2, $out]; [$op])
    | setpath([0]; $i + 1))
| .[1] as $outgoing
# no deps, vals assigned, incoming
| [$inputs, {}, .[2]] | until(.[0] | length == 0;
    . as [$no_dep, $vals, $incoming]
    | $$$$no_dep | .[-1] as [$gate, $val] | del(.[-1]) | . as $no_dep
    | $$$$vals | setpath([$gate]; $val) | . as $vals
    | $outgoing[$gate] | . as $out
    | length as $len
    | [0, $$$$incoming, $$$$no_dep] | until(.[0] == $len;
        $out[.[0]] as $child
        | (getpath([1, $child]) + [$val]) as $cur
        | setpath([1, $child]; $cur)
        | if $cur | length == 3 then
            . as [$i, $in] | .[-1] | . + [[$child, eval($cur; $vals)]]
            | . as $tmp | [$i + 1, $$$$in, $$$$tmp]
        else
            .[0] += 1
        end
    ) | [.[2], $vals, .[1]]
) | .[1] | to_entries | map(select(.key | startswith("z"))) | sort_by(.key | ltrimstr("z") | tonumber | -.) | map(.value) | to_decimal
