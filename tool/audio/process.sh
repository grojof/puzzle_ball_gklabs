#!/usr/bin/env bash
# Re-creates the shipped audio files from their source masters with ffmpeg.
#
# Usage: tool/audio/process.sh <source-dir> [output-dir=assets/audio]
#
# Effects are loudness-normalized to the same target, downmixed to mono and
# resampled to 44.1 kHz; the background track is normalized lower, so effects
# sit on top of it, and re-encoded at 128 kbps to keep the web download small.
# Normalization uses ffmpeg's two-pass EBU R128 `loudnorm` filter.
#
# The masters are the original files, kept in git history:
#   mkdir -p /tmp/audio-src && git archive efd3d1f assets/audio | tar -x -C /tmp/audio-src
#   tool/audio/process.sh /tmp/audio-src/assets/audio
#
# Targets can be tuned by ear: EFFECTS_LUFS (default -16), MUSIC_LUFS
# (default -20), TRUE_PEAK (dBTP, default -1.5).
set -euo pipefail

src="${1:?source directory with the master files}"
out="${2:-assets/audio}"
effects_lufs="${EFFECTS_LUFS:--16}"
music_lufs="${MUSIC_LUFS:--20}"
true_peak="${TRUE_PEAK:--1.5}"

# Two-pass loudnorm: measure, then apply with the measured values (linear).
normalize() {
  local in="$1" target="$2" outfile="$3"
  shift 3
  local stats
  stats="$(ffmpeg -hide_banner -nostats -i "$in" \
    -af "loudnorm=I=$target:TP=$true_peak:LRA=11:print_format=json" \
    -f null - 2>&1 | sed -n '/^{/,/^}/p')"
  get() { sed -n "s/.*\"$1\" : \"\([^\"]*\)\".*/\1/p" <<<"$stats"; }
  ffmpeg -hide_banner -loglevel error -y -i "$in" -af \
    "loudnorm=I=$target:TP=$true_peak:LRA=11:measured_I=$(get input_i):measured_TP=$(get input_tp):measured_LRA=$(get input_lra):measured_thresh=$(get input_thresh):offset=$(get target_offset):linear=true" \
    -ar 44100 "$@" -codec:a libmp3lame -b:a 128k "$outfile"
}

mkdir -p "$out"
for effect in jump boost_jump boost_speed boost_gravity; do
  normalize "$src/$effect.mp3" "$effects_lufs" "$out/$effect.mp3" -ac 1
done
normalize "$src/background.mp3" "$music_lufs" "$out/background.mp3" -ac 2

for f in "$out"/*.mp3; do
  lufs="$(ffmpeg -hide_banner -nostats -i "$f" -af ebur128 -f null - 2>&1 |
    awk '/Integrated loudness:/ {getline; print $2; exit}')"
  printf '%-22s %8s bytes  %s LUFS\n' "$(basename "$f")" "$(wc -c <"$f")" "$lufs"
done
