#!/bin/awk -f


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
    num_wavs = NR - num_comments
    print duration, max, min, num_channels, num_wavs, sample_rate
}
