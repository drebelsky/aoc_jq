#!/usr/bin/env -S jq -Rs -f
# xn1 ^ yn1 -> xorn1
# xn1 & yn1 -> and1
# xorn1 ^ cn0 -> zn1
# cn0 & xorn1 -> cn1'
# cn1' or andn1 -> cn1

# gate categories (in order of sort)
# * &^ (carry, xor)
# * x
# * y
# * z
# * | (andn1, cn1')

# identify swapped gates by noting whether we connect to the correct output

def tostr:
    . | tostring | . as $s
    | length as $len | (2 - $len) * "0" + $s;

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
    | setpath([2, $out]; [$op, $ina, $inb])
    | setpath([0]; $i + 1))
| .[1:] | . as [$outgoing, $incoming]
| .[0]
# identify types
| reduce (keys_unsorted[], (range(46) | tostr | "z" + .)) as $key ({};
    if $outgoing[$key] | length == 1 then
        setpath([$key]; "|")
    elif $key | startswith("x") then
        setpath([$key]; "x")
    elif $key | startswith("y") then
        setpath([$key]; "y")
    elif $key | startswith("z") then
        setpath([$key]; "z")
    else
        setpath([$key]; "&^")
    end
) | . as $types
# check for output to incorrect type
| [foreach $gates[] as [$op, $ina, $inb, $out] (null;
    if $ina == "x00" or $ina == "y00" or $out == "z45" then
        # this way we don't have to handle the half adder or last bit, which are probably
        # correct (mine was)
        empty
    else
        [$types[$ina], $types[$inb]] | sort as [$ta, $tb]
        | $types[$out] as $to
        | if $op == "XOR" then
            if $ta == "x" and $to != "&^" then
                $out
            elif $ta == "&^" and $to != "z" then
                $out
            else
                empty
            end
        elif $op == "OR" and $to != "&^" then
            $out
        elif $op == "AND" and $to != "|" then
            $out
        else
            empty
        end
    end
)] | sort | join(",")
