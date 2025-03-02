#!/usr/bin/env -S jq -Rs -f
# note, this one takes a while (on my machine about 4 minutes), but it does finish
# jq doesn't support circular data structures (so that everything is JSON-serializable), so we use indices into an array for next/prev in our doubly linked list
# list nodes are an array of length 4 [file_id (-1 if free), length, prev, next]; -1 is used as 
def condense:
    def rec:
        . as [$i, $j, $arr]
        | if $j == 0 then
            $arr
        elif $i == $j then
            [0, $arr[$j][-2], $arr] | rec
        elif $arr[$j][0] == -1 then
            [$i, $arr[$j][-2], $arr] | rec
        elif $arr[$i][0] != -1 or $arr[$i][1] < $arr[$j][1] then
            [$arr[$i][-1], $j, $arr] | rec
        else
            $arr[$i] as $ai
            | $arr[$j] as $aj
            | $arr | .[$ai[-2]] |= (.[-1] = $j) # point free->prev->next at fileblock
            | .[$j] |= (.[-1] = $i) # point fileblock->next at free
            | .[$j] |= (.[-2] = $ai[-2]) # point fileblock->prev at free->prev
            # note, we don't need to coalesce at the end because we won't use those free blocks again, but we do need to make the lengths/forward pointers correct for our checksum calculation
            | .[$i] |= (.[1] -= $aj[1]) # free->size -= fileblock->size
            | .[$i] |= (.[-2] = $j) # point free->prev at fileblock
            | .[$aj[-2]] |= (.[-1] = $aj[-1]) # fileblock->prev->next = fileblock(orig)->next
            | .[$aj[-2]] |= (.[1] += $aj[1]) # fileblock->prev->size = fileblock->size
            | [0, $aj[-2], .] | rec
        end;
    [0, (. | length) - 1, .] | rec;

# not used in the solution, but useful for debugging
def construct:
    . as $arr |
    def rec:
        . as [$i, $res]
        | if $i == null then
            $res
        else
            [$arr[$i][-1], $res + (if $arr[$i][0] == -1 then "." else $arr[$i][0] | tostring end | debug) * $arr[$i][1]] | rec
        end;
    [0, ""] | rec;

def csum:
    . as $arr |
    def rec:
        . as [$i, $j, $res] # $i is pointer into $arr, $j is the location in the hypothetical construct array
        | if $i == null then
            $res
        else
            if $arr[$i][0] == -1 then
                0
            else
                $arr[$i] as [$id, $length]
                | $id * $length / 2 * ($j + $j + $length - 1)
            end
            | [$arr[$i][-1], $j + $arr[$i][1], . + $res] | rec
        end;
    [0, 0, 0] | rec;

split("") | map(tonumber) as $lengths
| reduce $lengths[] as $length ([[[-1, 0, null, null]], 0, true];
    . as [$arr, $file, $is_file]
    | ($arr | length) as $cur
    | $arr | .[-1] |= (.[-1] = $cur) # point previous at us
    | .[$cur] = [if $is_file then $file else -1 end, $length, $cur - 1, null] # add current node
    | [., $file + .5, ($is_file | not)]
) | .[0] | condense
| csum
