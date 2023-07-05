#!/bin/awk -f

BEGIN {
    pi = atan2(0, -1)		# x, the second parameter, can be any
				# negative number...?
    # print "pi " pi > "/dev/stderr"

    for (i=0; i<=44100; i++)
	print sprintf("%5s", i),
	    sprintf("%15s", sin(i/44100*2*pi)),
	    sprintf("%15s", sin(441*i/44100*2*pi)),
	    sprintf("%15s", sin(i/25*2*pi))
}
