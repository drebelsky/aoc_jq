#!/usr/bin/env -S jq -Rs -f

split("\n\n")
| (.[0] | split(", ")) as $patterns
| def can_make:
    if length == 0 then
        true
    else
        . as $rest
        | any($patterns[]; . as $pat | $rest | startswith($pat) and (ltrimstr($pat) | can_make))
    end;
.[1] | split("\n") | map(select(length > 0))
| reduce .[] as $design (0; if $design | can_make then . + 1 end)
