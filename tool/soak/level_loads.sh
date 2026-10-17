#!/usr/bin/env bash
# Soak test: loads a level N times on an Android device or emulator and prints
# the app's memory after every batch, to catch leaks between level loads.
#
# Usage: tool/soak/level_loads.sh [loads=30] [batch=10]
#
# Start a development build on the device and open any level first. Each load
# replays TAPS, a space-separated list of "x,y" screen taps (physical pixels).
# The default leaves to the level selector and opens level 1, for a
# 1080x2400 screen; set TAPS for other screens or flows, for example the
# pause menu's restart button.
#
# Environment: SERIAL (adb device, default emulator-5554),
#              APP_ID (default com.grojof.ballodyssey.dev),
#              TAPS, TAP_DELAY (seconds between taps, default 1.5).
set -euo pipefail

loads="${1:-30}"
batch="${2:-10}"
serial="${SERIAL:-emulator-5554}"
app_id="${APP_ID:-com.grojof.ballodyssey.dev}"
taps="${TAPS:-126,126 154,438}"
tap_delay="${TAP_DELAY:-1.5}"

adb_() { adb -s "$serial" "$@"; }

pid="$(adb_ shell pidof "$app_id" | tr -d '\r')"
if [[ -z "$pid" ]]; then
  echo "$app_id is not running on $serial" >&2
  exit 1
fi

report() {
  local info pss native threads
  info="$(adb_ shell dumpsys meminfo "$pid")"
  pss="$(awk '/TOTAL PSS:/ {print $3; exit}' <<<"$info")"
  native="$(awk '$1 == "Native" && $2 == "Heap:" {print $3; exit}' <<<"$info")"
  threads="$(adb_ shell ls "/proc/$pid/task" | wc -l | tr -d ' ')"
  printf '%-14s PSS=%6d KB  native=%6d KB  threads=%s\n' \
    "$1" "$pss" "$native" "$threads"
}

report "start"
for ((i = 1; i <= loads; i++)); do
  for tap in $taps; do
    adb_ shell input tap "${tap%,*}" "${tap#*,}"
    sleep "$tap_delay"
  done
  if ((i % batch == 0)); then
    sleep 2
    report "after $i"
  fi
done
