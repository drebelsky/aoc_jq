#!/usr/bin/env -S jq -Rs -f

def is_correct(after; update):
    all(foreach update[] as $cur ([]; . + [$cur]; 
        foreach (.[:-1][]) as $before (null; .; [$cur, $before])
    ); after[.[0]][.[1]] | not);

def extract(after; set):
    # extract the rules corresponding to the current set
    reduce (after | to_entries[]) as $entry ({};
        if set[$entry.key] then
            . + {($entry.key): ($entry.value | with_entries(select(set[.key])))}
        end
    );

def find_available($rules; $items):
    first((label $out |
        foreach ($items | keys | .[]) as $item (null; .;
            $item |
            if (($rules[$item] | length) == 0) then
                $item, break $out
            else
                empty
            end
        )
    ),
    error("Couldn't find available"));

def reorder(after; update):
    # reorder update so it is in the correct (technically, reversed) order
    # according to the rules given in the after map

    # first, create a set of values
    reduce update[] as $item ({}; . + {($item): true})
    | . as $set
    | if ($set | length) != (update | length) then
        error
    end
    | reduce range($set | length) as $_ ({result: [], rules: (extract(after; $set)), $set};
        find_available(.rules; .set) as $last
        | .result += [$last]
        | .set |= (. | del(.[$last]))
        | .rules = (.rules as $rules | .set as $set | extract($rules; $set))
    )
    | .result;

def middle(update):
    update | .[length / 2 | floor];

split("\n\n") | (.[1] | split("\n") | map(split(",") | select(length > 0))) as $updates
| (.[0] | split("\n") | map(select(. != ""))
    | map(split("|"))) as $rules
| reduce $rules[] as $item ({};
    if has($item[0]) then
        .[$item[0]].[$item[1]] = true
    else
        .[$item[0]] = {($item[1]): true}
    end
) | . as $after
| reduce $updates[] as $update (0;
    if (is_correct($after; $update) | not) then
        . + (middle(reorder($after; $update)) | tonumber)
    end
)
