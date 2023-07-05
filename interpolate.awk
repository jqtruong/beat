#!/bin/awk -f
#
# e.g. (grab the variables from ./dat-meta.awk)
#
# $ awk -v count=53043 -v min=-0.21438598633 -v max=0.20867919922 -v precision=11 \
#       -f Code/beat/interpolate.awk Desktop/hello/adele.dat |
#           awk 'BEGIN { FS=";" } { print $3 }' |
#           bc -l

BEGIN {
    OFS = ";"

    # helper formula strings
    DIVIDED_BY = " / "
    MINUS = " - "
    PLUS = " + "
    POW = "^"
    TIMES = " * "

    x1 = -1
    x2 = 1
    x_delta = x2 - x1

    y1 = 1
    y2 = -1
    y_delta = y2 - y1

    # from wav meta
    wav_delta = max - min
    ratio = x_delta DIVIDED_BY PAREN(wav_delta TIMES 10 POW precision)
}


# interpolation formulas
/^[^;]/ && (!lim || NR < lim) {
    pos = (NR - comments)
    frame = y1 PLUS pos TIMES y_delta DIVIDED_BY count

    pos = PAREN(bcfier($2) MINUS min) TIMES 10 POW precision
    ch1 = x1 PLUS pos TIMES ratio

    pos = PAREN(bcfier($3) MINUS min) TIMES 10 POW precision
    ch2 = x1 PLUS pos TIMES ratio

    print frame, ch1, ch2
}


END {
}


function PAREN(str) {
    return "(" str ")"
}


function decuple(value) {
    return value TIMES 10 POW precision


#
# convert a string as input for GNU Basic Calculator
#
function bcfier(wav) {
    # scientific notation from 1.23e-04 to 1.23*10^-04
    scienota = gensub(/e(.+)$/, "*10^\\1", "g", wav)
    return scienota
}
