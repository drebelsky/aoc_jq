#!/usr/bin/env -S jq -Rs -f

split("\n") | map(select(length > 0)) # split lines
| map(split("\\s+"; null) | map(tonumber)) # split within line + parse`
| map(select(
    [., .[1:]] | transpose | map(select(all(. != null))) # pairwise iterate
    | [
        (map(.[0] - .[1] | abs | [. >= 1, . <= 3] | all) | all), # only include those in range
        (map(.[0] > .[1]) | all) or (map(.[0] < .[1]) | all) # only include all inc or all dec
      ] | all
)) | length
