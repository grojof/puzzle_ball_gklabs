#!/usr/bin/env bash
# Synthesizes the adrenaline rush's heartbeat with ffmpeg: two thumps, the
# second softer, like a "lub-dub", normalized like the other effects. No
# third-party asset is involved.
#
# Usage: tool/audio/heartbeat.sh [output-dir=assets/audio]
#
# EFFECTS_LUFS (default -16) and TRUE_PEAK (dBTP, default -1.5) match
# tool/audio/process.sh.
set -euo pipefail

out="${1:-assets/audio}"
effects_lufs="${EFFECTS_LUFS:--16}"
true_peak="${TRUE_PEAK:--1.5}"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Each thump is a decaying 80 Hz tone with harmonics, so phone speakers, which
# cannot play deep bass, still render it; a compressor evens out its peak.
thump() {
  echo "exp(-16*($1))*(sin(2*PI*80*($1))+0.5*sin(2*PI*160*($1))+0.25*sin(2*PI*240*($1)))"
}
ffmpeg -hide_banner -loglevel error -y -f lavfi -i \
  "aevalsrc='$(thump t)+0.7*gte(t,0.28)*$(thump t-0.28)':s=44100:d=0.8" \
  -af "acompressor=threshold=-30dB:ratio=10:attack=1:release=60:makeup=8" \
  "$tmp/heartbeat.wav"

# Two-pass loudnorm, as in process.sh.
stats="$(ffmpeg -hide_banner -nostats -i "$tmp/heartbeat.wav" \
  -af "loudnorm=I=$effects_lufs:TP=$true_peak:LRA=11:print_format=json" \
  -f null - 2>&1 | sed -n '/^{/,/^}/p')"
get() { sed -n "s/.*\"$1\" : \"\([^\"]*\)\".*/\1/p" <<<"$stats"; }
mkdir -p "$out"
ffmpeg -hide_banner -loglevel error -y -i "$tmp/heartbeat.wav" -af \
  "loudnorm=I=$effects_lufs:TP=$true_peak:LRA=11:measured_I=$(get input_i):measured_TP=$(get input_tp):measured_LRA=$(get input_lra):measured_thresh=$(get input_thresh):offset=$(get target_offset):linear=true" \
  -ar 44100 -ac 1 -codec:a libmp3lame -b:a 128k "$out/heartbeat.mp3"

lufs="$(ffmpeg -hide_banner -nostats -i "$out/heartbeat.mp3" -af ebur128 -f null - 2>&1 |
  awk '/Integrated loudness:/ {getline; print $2; exit}')"
printf '%-22s %8s bytes  %s LUFS\n' heartbeat.mp3 "$(wc -c <"$out/heartbeat.mp3")" "$lufs"
