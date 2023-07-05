#!/bin/awk -f


@include "init.awk"


BEGIN {}


/^[^;]/ {
    ch1 = ch1 "," $2
    ch2 = ch2 "," $3
}


END {
    # start from the second character, to effectively remove the first
    # comma, when channels values are initially empty
    print "[[" substr(ch1, 2) "], [" substr(ch2, 2) "]]"
}
