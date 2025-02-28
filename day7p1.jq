#!/usr/bin/env -S jq -Rs -f

def can_make($total; $nums):
    def rec($a; $i):
        if $i == ($nums | length) then
            $a == $total
        else
            rec($a + $nums[$i]; $i + 1) or rec($a * $nums[$i]; $i + 1)
        end;
    rec($nums[0]; 1);

split("\n") | map(select(. | length > 0) | [scan("\\d+") | tonumber])
| map(select(can_make(.[0]; .[1:])) | .[0])
| add
