#!/bin/awk -f
#

BEGIN {
  next_frame = 0
  pi = atan2(0, -1)

  if (!dur) dur = 1
  if (!freq) freq = 44100

  frame_dur = 1 / freq
  end = dur * freq
}

END {
}

function print_frame(content) {
  if (timed) {
    print sprintf("%20s", next_frame), content
    next_frame += frame_dur
  }
  else {
    print content
  }
}

function to_deg(rad) {
   return rad*180/pi
}

