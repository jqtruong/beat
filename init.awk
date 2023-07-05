#!/bin/awk -f
#

BEGIN {
  next_frame = 0
  pi = atan2(0, -1)

  if (!dur) dur = 1
  if (!freq) freq = 44100
  if (!multi) multi = 1
  if (!scale) scale = 1

  frame_dur = 1 / freq
}


END {
}


function multi_print(frame_content) {
  for (i=0; i<multi; i++) print_frame(frame_content)
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


function spached(ch1, ch2) {
  return ch1 ":" ch1 * scale ", " ch2 ":" ch2 * scale
}


function schaled(ch1, ch2) {
  return sprintf("%20s", ch1 * scale) " " sprintf("%20s", ch2 * scale)
}


# what if a wav value is not in radians?
function to_deg(rad) {
   return rad*180/pi
}


function q(str) {
    return "\"" str "\""
}
