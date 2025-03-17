#!/usr/bin/env -S jq -Rs -f
# TODO: require less manual review of debug messages
# xn1 ^ yn1 -> xor1
# xn1 & yn1 -> and1
# xorn1 ^ cn0 -> zn1
# cn0 & xorn1 -> cn1'
# cn1' or andn1 -> cn1

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
| def find($gate; $type):
    # find the pair for $gate of type $out, i.e., given
    # $gate $type $gate2 (either order) -> $out
    # return [$out, $gate2]
    first (foreach (try $outgoing[$gate][] catch error("here \($gate)")) as $out (null;
        $incoming[$out];
        if .[0] != $type then
            empty
        else
            [$out, (.[1:][] | select(. != $gate))]
        end
    ), (null | debug("could not find a gate of \($type) with \($gate) as an input")));
            
find("x00"; "XOR")[0] as $xor0
| find("x00"; "AND")[0] as $c0
| reduce (range(1; 45) | tostr) as $i ($c0;
    . as $c | find("x" + $i; "XOR")[0] as $xor1
    | find("x" + $i; "AND")[0] as $and1
    | find($xor1; "XOR") as $z
    | if $z[0] != ("z" + $i) then
        debug("\($xor1) is the xor for \($i) but is XORed with carry (\($z[1])) not to z\($i) but to \($z[0])")
    end
    | if $z[1] != $c then
        if $c | type == "array" then
            debug("didn't know carry for \($i), (had wrong candidate \($c[0]), but real carry was \($z[1])")
        else
            debug("expected carry input to \($i) to be \($c), but got \($z[1])")
        end
    end
    | try 
        find($xor1; "AND") as $cn1p1
        | find($and1; "OR") as $cn1p2
        | if $cn1p1[0] != $cn1p2[1] then
            debug("error for \($i): \($xor1) is ANDed with \($cn1p1[1]) to form \($cn1p1[0]); while \($and1) is ORed with \($cn1p2[1]) (to form \($cn1p2[0]))")
        end
    catch
        debug("Couldn't get cn1' candidates: xor1: \($xor1), and1: \($and1)")
    | try
        (find($and1; "OR")[0]
        | if . == null then
            debug("for \($i), found and1 as \($and1), but there was no OR gate for that")
        end)
    catch
        [$and1]
) | empty
