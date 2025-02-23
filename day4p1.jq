#!/usr/bin/env -S jq -Rs -f
def num_xmas(f):
    f | map(select(join("") | [. == "XMAS", . == "SAMX"] | any))
    | length;

def count_diag(f):
    f | transpose | map(num_xmas(transpose)) | add;

def iter4(grid):
    [grid[:-3], grid[1:-2], grid[2:-1], grid[3:]] | transpose;

def count_norm(grid):
     grid | map(num_xmas(iter4(.))) | add;

split("\n") | map(select(length > 0)) # split lines
| map(split("")) # convert to list[list[char]]
| [
    count_norm(.), # horizontal
    count_norm(transpose), ## vertical
    # Down-Right
    count_diag([
        (.[:-3] | map(.[:-3])),
        (.[1:-2] | map(.[1:-2])),
        (.[2:-1] | map(.[2:-1])),
        (.[3:] | map(.[3:]))
    ]),
    # Down-Left
    count_diag([
        (.[:-3] | map(.[3:])),
        (.[1:-2] | map(.[2:-1])),
        (.[2:-1] | map(.[1:-2])),
        (.[3:] | map(.[:-3]))
    ])
]
| add
