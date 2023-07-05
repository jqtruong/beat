#!/bin/awk -f
#


BEGIN {
    RS = "\r\n"
  
    pi = atan2(0, -1)
    wav_style = "sine"
    sps = 44100			# samples per second
    frame = 1/sps
    timed = 1
  
    if (!end) end = sps		# for a 1-second wave

    # frequency of 44050 is low and bass-y
    if (!frequency) frequency = 441

    # not sure i need that
    if (!volume) volume = 1
  
    print "; Sample Rate " sps
    print "; Channels 1"
  
    for (i=1; i<=end; i++) {
	print (i*frame), calc_frame()
    }
  
}


function calc_frame() {
    switch (wav_style) {
    case "sine":
	return sine_wave()

    default:
	return i
    }
}


# https://www3.nd.edu/~dthain/courses/cse20211/fall2013/wavfile/
function sine_wave() {
    time = i/sps
    theta = frequency * time * 2*pi
    sine = sin(theta)
    return volume * sine
}


#
# using 441 as the frequency essentially returns `i', which is an
# integer from 1 to 44100, which is divided by the number of samples
# per second, but 441/44100 in this case, so i/100. the values will
# range from 1 to the frequency... oh! that's one way to interpolate,
# maybe.
#
# theta's equation `frequency * time * 2*pi' is to get a sine wave
# which cycles `frequency' times, e.g. 441 by default.
#
# increasing the `frequency' from 1 to `sps' will eventually produce a
# low pitch with deep bass, until the pitch is clearer and the bass
# low, then the reverse again.  it does fade out at and around 22050,
# after a super high pitch.
