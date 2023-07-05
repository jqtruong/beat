#!/bin/awk -f


BEGIN {
    # value to multiply each channel value with
    if (!group_size) group_size = 1
    if (!scale) scale = 1
    if (!translate) translate = 0
    x = translate
    y = 0
}


/^; Channels / && !num_channels {
    num_channels = $NF
}


/^[^;]/ {
    if (wav_count == group_size) {
	group_average = wav_average(wav_values, wav_count)
	print (y * group_size) " -> " ((y + 1) * group_size) ": " group_average > "/dev/stderr"
	for (i in wav_values) print wav_values[i] > "/dev/stderr"
	printf("-draw 'line  %d,%d  %.0f,%d'  ", x, y, (x + group_average * scale), y)
	wav_count = 0
	delete wav_values
	y++
    }
    wav_values[wav_count++] = $2
}


END {
    if (wav_count > 0) {
	group_average = wav_average(wav_values, wav_count)
	for (i in wav_values) print wav_values[i] > "/dev/stderr"
	printf("-draw 'line  %d,%d  %.0f,%d'", x, y, (x + group_average * scale), y)
    }
}


function wav_average(values, count) {
    sum = 0
    for (i=0; i<count; i++) {
	sum += values[i]
    }

    return sum/count
}


# given image size of 1008x1250
# `translate': 504, i.e. center on x
# `scale': 504 too?
#  1 rad * 504 + 504 = 1008
#  0 rad * 504 + 504 =  504
# -1 rad * 504 + 504 =    0
