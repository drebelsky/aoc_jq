#!/usr/bin/env -S jq -Rs -f

def is_safe(arr):
    [arr[:-1], arr[1:]] | transpose # pairwise iterate
    | [
        (map(.[0] - .[1] | abs | [. >= 1, . <= 3] | all) | all), # only include those in range
        (map(.[0] > .[1]) | all) or (map(.[0] < .[1]) | all) # only include all inc or all dec
      ] | all;

split("\n") | map(select(length > 0)) # split lines
| map(split("\\s+"; null) | map(tonumber)) # split within line + parse`
| map(select(. as $arr
    | any(range(0, length); is_safe($arr[:.] + $arr[. + 1:])) # try removing indices
))
| length
