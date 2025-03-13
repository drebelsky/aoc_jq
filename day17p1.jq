#!/usr/bin/env -S jq -Rrs -f
# jq doesns't have any bitwise operators, so we implement them using lists of bits
# note, no public 17p2 solution since my solution was input specific

def combo($regs; $op):
    if $op < 4 then
        $op
    elif $op < 7 then
        $regs[$op - 4]
    else
        error("combo op called with value \($op)")
    end;

def bin($num):
    def rec:
        # [so_far, remaining] -> binary representation (in reverse, e.g., 4 = [0, 0, 1])
        if .[1] == 0 then
            .[0]
        else
            (.[1] % 2) as $bit
            | ((.[1] - $bit) / 2) as $next
            | .[0] | . + [$bit]
            | [., $next] | rec
        end;
    if $num == 0 then
        [0]
    else
        [[], $num] | rec
    end;

def dec($bin):
    $bin | length as $len
    | [$len - 1, 0]
    | until(.[0] == -1;
        . as [$i, $cur]
        | [$i - 1, $cur * 2 + $bin[$i]])
    | .[1];

def shift($num; $by):
    dec(bin($num)[$by:]);

def xor($a; $b):
    bin($a) as $a
    | bin($b) as $b
    | [$a, $b] | map(length) | max as $len
    # foreach and reduce both end up making extra copies
    | [0, []] | until(.[0] == $len;
        .[0] as $i
        | .[1] | setpath([$i]; 
            if ($a[$i] // 0) == ($b[$i] // 0) then
                0
            else
                1
            end
        ) | [$i + 1, .])
    | dec(.[1]);
        

split("\n\n") | (.[0] | [scan("\\d+") | tonumber]) as $regs
| .[1] | [scan("\\d+") | tonumber] | . as $program
| length as $len
| [$regs, 0, []]
| until(.[1] >= $len - 1;
    . as [$regs, $ip, $output]
    | $program[$ip] as $opcode
    | $program[$ip + 1] as $operand
    | if $opcode == 0 then
        setpath([0, 0]; shift($regs[0]; combo($regs; $operand)))
        | .[1] += 2
    elif $opcode == 1 then
        setpath([0, 1]; xor($regs[1]; $operand))
        | .[1] += 2
    elif $opcode == 2 then
        setpath([0, 1]; combo($regs; $operand) % 8)
        | .[1] += 2
    elif $opcode == 3 then
        if $regs[0] == 0 then
            .[1] += 2
        else
            .[1] = $operand
        end
    elif $opcode == 4 then
        setpath([0, 1]; xor($regs[1]; $regs[2]))
        | .[1] += 2
    elif $opcode == 5 then
        $$$$output | . + [(combo($regs; $operand) % 8)]
        | [$regs, $ip + 2, .]
    elif $opcode == 6 then
        setpath([0, 1]; shift($regs[0]; combo($regs; $operand)))
        | .[1] += 2
    elif $opcode == 7 then
        setpath([0, 2]; shift($regs[0]; combo($regs; $operand)))
        | .[1] += 2
    else
        error("Invalid opcode \($opcode)")
    end
) | .[-1] | map(tostring) | join(",")
