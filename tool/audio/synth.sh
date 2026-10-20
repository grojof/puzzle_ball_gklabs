#!/usr/bin/env bash
# Synthesizes the effects that have no master with ffmpeg, and normalizes them
# like the other effects. No third-party asset is involved.
#
# - heartbeat: the adrenaline rush, two thumps, the second softer, like a
#   "lub-dub";
# - bumper: a bright two-tone ding with a short metallic ring;
# - thud: a mace's heavy hit, a low knock with a burst of noise;
# - whoosh: entering a fan's column, filtered noise swelling and fading.
#
# Usage: tool/audio/synth.sh [output-dir=assets/audio]
#
# EFFECTS_LUFS (default -16) and TRUE_PEAK (dBTP, default -1.5) match
# tool/audio/process.sh.
set -euo pipefail

out="${1:-assets/audio}"
effects_lufs="${EFFECTS_LUFS:--16}"
true_peak="${TRUE_PEAK:--1.5}"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# A decaying 80 Hz tone with harmonics, so phone speakers, which cannot play
# deep bass, still render it.
thump() {
  echo "exp(-16*($1))*(sin(2*PI*80*($1))+0.5*sin(2*PI*160*($1))+0.25*sin(2*PI*240*($1)))"
}
# A compressor evens out each effect's peak before normalizing.
compress="acompressor=threshold=-30dB:ratio=10:attack=1:release=60:makeup=8"

synth() {
  local name="$1" source="$2" duration="$3" filters="$4"
  ffmpeg -hide_banner -loglevel error -y -f lavfi -i \
    "aevalsrc='$source':s=44100:d=$duration" -af "$filters" "$tmp/$name.wav"
}
synth heartbeat "$(thump t)+0.7*gte(t,0.28)*$(thump t-0.28)" 0.8 "$compress"
synth bumper \
  "exp(-9*t)*(sin(2*PI*1320*t)+0.6*sin(2*PI*1980*t)+0.3*sin(2*PI*2640*t))+0.5*exp(-40*t)*sin(2*PI*660*t)" \
  0.45 "$compress"
synth thud \
  "$(thump t)*1.2+0.6*exp(-30*t)*(2*random(0)-1)+0.6*exp(-12*t)*sin(2*PI*110*t)" \
  0.5 "lowpass=f=1800,$compress"
synth whoosh \
  "sin(PI*t/0.6)*sin(PI*t/0.6)*(2*random(0)-1)" \
  0.6 "bandpass=f=900:width_type=o:w=2,$compress"

# Two-pass loudnorm, as in process.sh.
mkdir -p "$out"
for name in heartbeat bumper thud whoosh; do
  stats="$(ffmpeg -hide_banner -nostats -i "$tmp/$name.wav" \
    -af "loudnorm=I=$effects_lufs:TP=$true_peak:LRA=11:print_format=json" \
    -f null - 2>&1 | sed -n '/^{/,/^}/p')"
  get() { sed -n "s/.*\"$1\" : \"\([^\"]*\)\".*/\1/p" <<<"$stats"; }
  ffmpeg -hide_banner -loglevel error -y -i "$tmp/$name.wav" -af \
    "loudnorm=I=$effects_lufs:TP=$true_peak:LRA=11:measured_I=$(get input_i):measured_TP=$(get input_tp):measured_LRA=$(get input_lra):measured_thresh=$(get input_thresh):offset=$(get target_offset):linear=true" \
    -ar 44100 -ac 1 -codec:a libmp3lame -b:a 128k "$out/$name.mp3"
  lufs="$(ffmpeg -hide_banner -nostats -i "$out/$name.mp3" -af ebur128 -f null - 2>&1 |
    awk '/Integrated loudness:/ {getline; print $2; exit}')"
  printf '%-22s %8s bytes  %s LUFS\n' "$name.mp3" "$(wc -c <"$out/$name.mp3")" "$lufs"
done
