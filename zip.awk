#!/bin/awk -f
#
# zip 2 files into columns


BEGIN {
  max = 0
}

# https://stackoverflow.com/a/14984673/578870
FNR == NR {
  file1[NR] = $0
  len = length($0)
  max = len > max ? len : max
  next
}

FNR != NR && NF > 0 {
  print sprintf("%" max "s", file1[FNR]), $0
}
