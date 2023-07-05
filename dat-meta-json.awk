#!/bin/awk -f


@include "init.awk"


BEGIN {
    max = 0
    min = 0
}


/^;/ {
    num_comments++
}


/^; Sample Rate [[:digit:]]+/ {
    # not sprintf'ing treats the output differently by deleting some chars
    sample_rate = sprintf("%d", $4)
}


/^; Channels [[:digit:]]+/ {
    # see comment in sample rate
    num_channels = sprintf("%d", $3)
}


/^[^;]/ {
    duration = $1

    for (i=0; i<num_channels; i++) {
	val = $(i + 2)
	min = val < min ? val : min
	max = val > max ? val : max
    }
}


END {
    num_rows = NR - num_comments
    print "{"                                  \
        q("num_channels") ":" num_channels "," \
        q("num_rows")     ":" num_rows     "," \
        q("duration")     ":" duration     "," \
        q("max")          ":" max          "," \
        q("min")          ":" min          "," \
        q("sample_rate")  ":" sample_rate      \
    "}"
}
