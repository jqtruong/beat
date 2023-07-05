#!/bin/awk -f


#
# pacmd list-sources | grep -A1 "index:" | awk -f parse-pa.awk
#


BEGIN {
    RS = "\n--\n"
    FS = "\n"

    print "index", "name"
}


{
    name = split_kv($2)
    gsub(/[<>]/, "", name)
    print sprintf("%5s", split_kv($1)), name
}


function split_kv(kv) {
    # split() sets findings by reference
    # https://www.gnu.org/software/gawk/manual/html_node/String-Functions.html#index-split_0028_0029-function-1
    split(kv, k_and_v, ": ")
    return k_and_v[2]
}
