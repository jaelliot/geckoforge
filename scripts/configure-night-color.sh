#!/usr/bin/env bash
# @file configure-night-color.sh
# @description Interactive Night Color configurator for KDE Plasma
# @update-policy Update when KDE changes Night Color keys or workflow

set -euo pipefail

CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/kwinrc"
DEFAULT_DAY_TEMP=6500
DEFAULT_NIGHT_TEMP=4500
DEFAULT_MODE="automatic"
DEFAULT_TRANSITION=45
DEFAULT_EVENING="20:00"
DEFAULT_MORNING="07:00"

command -v kwriteconfig5 >/dev/null 2>&1 || {
  echo "[error] kwriteconfig5 is required but was not found. Confirm KDE Plasma is installed." >&2
  exit 1
}

prompt_temp() {
  local label=$1
  local default=$2
  local input
  while true; do
    read -r -p "${label} temperature in Kelvin [${default}]: " input || input=""
    input=${input// /}
    if [[ -z "$input" ]]; then
      echo "$default"
      return
    fi
    if [[ $input =~ ^[0-9]+$ ]] && (( input >= 1000 && input <= 10000 )); then
      echo "$input"
      return
    fi
    echo "Please enter an integer between 1000 and 10000." >&2
  done
}

prompt_time() {
  local label=$1
  local default=$2
  local input
  while true; do
    read -r -p "${label} time (HH:MM) [${default}]: " input || input=""
    input=${input// /}
    if [[ -z "$input" ]]; then
      echo "$default"
      return
    fi
    if [[ $input =~ ^([0-1][0-9]|2[0-3]):[0-5][0-9]$ ]]; then
      echo "$input"
      return
    fi
    echo "Time must be in 24h HH:MM format (e.g., 19:30)." >&2
  done
}

prompt_transition() {
  local default=$1
  local input
  while true; do
    read -r -p "Transition duration in minutes [${default}]: " input || input=""
    input=${input// /}
    if [[ -z "$input" ]]; then
      echo "$default"
      return
    fi
    if [[ $input =~ ^[0-9]+$ ]] && (( input >= 5 && input <= 180 )); then
      echo "$input"
      return
    fi
    echo "Enter a value between 5 and 180 minutes." >&2
  done
}

detect_location() {
  command -v curl >/dev/null 2>&1 || return 1
  local response
  if response=$(curl -fsSL --max-time 5 https://ipinfo.io/loc 2>/dev/null); then
    if [[ $response =~ ^-?[0-9]+\.?[0-9]*,-?[0-9]+\.?[0-9]*$ ]]; then
      IFS=',' read -r lat lon <<<"$response"
      echo "$lat" "$lon"
      return 0
    fi
  fi
  return 1
}

prompt_location() {
  local method
  echo "Location options:" \
    $'\n  1) Automatic detection (GeoIP)' \
    $'\n  2) Manual entry' \
    $'\n  3) Keep KDE auto-detect (GeoClue)'
  read -r -p "Select location method [1]: " method || method=""
  method=${method// /}
  case "$method" in
    ""|1)
      if coords=$(detect_location); then
        printf "%s" "$coords"
        return 0
      fi
      echo "Automatic detection failed; falling back to manual entry." >&2
      ;;&
    2)
      local lat lon
      while true; do
        read -r -p "Latitude (-90 to 90): " lat || lat=""
        read -r -p "Longitude (-180 to 180): " lon || lon=""
        if [[ $lat =~ ^-?[0-9]+(\.[0-9]+)?$ && $lon =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
          if (( $(awk "BEGIN{print ($lat >= -90 && $lat <= 90)}") )) && \
             (( $(awk "BEGIN{print ($lon >= -180 && $lon <= 180)}") )); then
            printf "%s %s" "$lat" "$lon"
            return 0
          fi
        fi
        echo "Coordinates must be numeric and within valid ranges." >&2
      done
      ;;
    3)
      echo "AUTO"
      return 0
      ;;
    *)
      echo "Invalid selection. Using option 1." >&2
      if coords=$(detect_location); then
        printf "%s" "$coords"
        return 0
      fi
      echo "Automatic detection failed; falling back to manual entry." >&2
      prompt_location "manual"
      return
      ;;
  esac
}

select_mode() {
  local input
  echo "Scheduling modes:" \
    $'\n  1) Automatic sunrise/sunset (recommended)' \
    $'\n  2) Custom times' \
    $'\n  3) Constant tint (always on)'
  read -r -p "Select scheduling mode [1]: " input || input=""
  case "${input// /}" in
    ""|1) echo "automatic" ;;
    2) echo "timed" ;;
    3) echo "constant" ;;
    *)
      echo "automatic"
      ;;
  esac
}

apply_setting() {
  local key=$1
  local value=$2
  kwriteconfig5 --file kwinrc --group NightColor --key "$key" "$value"
}

remove_setting() {
  local key=$1
  kwriteconfig5 --file kwinrc --group NightColor --delete "$key" >/dev/null 2>&1 || true
}

refresh_kwin() {
  local bus=""
  if command -v qdbus6 >/dev/null 2>&1; then
    bus="qdbus6"
  elif command -v qdbus >/dev/null 2>&1; then
    bus="qdbus"
  fi

  if [[ -n "$bus" ]]; then
    "$bus" org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
    "$bus" org.kde.KWin.ColorCorrect /ColorCorrect reconfigure >/dev/null 2>&1 || true
  else
    echo "[info] qdbus not found; restart KWin manually if changes do not take effect." >&2
  fi
}

echo "=== KDE Night Color Configuration ==="
DAY_TEMP=$(prompt_temp "Day" "$DEFAULT_DAY_TEMP")
NIGHT_TEMP=$(prompt_temp "Night" "$DEFAULT_NIGHT_TEMP")
TRANSITION=$(prompt_transition "$DEFAULT_TRANSITION")
MODE=$(select_mode)

AUTO_LOCATION=true
LATITUDE=""
LONGITUDE=""
EVENING="$DEFAULT_EVENING"
MORNING="$DEFAULT_MORNING"

if [[ "$MODE" == "automatic" ]]; then
  coords=$(prompt_location) || coords="AUTO"
  if [[ "$coords" == "AUTO" ]]; then
    AUTO_LOCATION=true
  else
    AUTO_LOCATION=false
    LATITUDE=${coords%% *}
    LONGITUDE=${coords##* }
  fi
elif [[ "$MODE" == "timed" ]]; then
  AUTO_LOCATION=false
  EVENING=$(prompt_time "Evening begin" "$DEFAULT_EVENING")
  MORNING=$(prompt_time "Morning begin" "$DEFAULT_MORNING")
fi

echo "\nApplying Night Color settings..."
apply_setting Active true
apply_setting DayTemperature "$DAY_TEMP"
apply_setting NightTemperature "$NIGHT_TEMP"
apply_setting TransitionTime "$TRANSITION"
case "$MODE" in
  automatic)
    apply_setting Mode Automatic
    if $AUTO_LOCATION; then
      apply_setting LocationAuto true
      remove_setting LatitudeFixed
      remove_setting LongitudeFixed
    else
      apply_setting LocationAuto false
      apply_setting LatitudeFixed "$LATITUDE"
      apply_setting LongitudeFixed "$LONGITUDE"
    fi
    remove_setting EveningBeginFixed
    remove_setting MorningBeginFixed
    ;;
  timed)
    apply_setting Mode Timings
    apply_setting EveningBeginFixed "$EVENING"
    apply_setting MorningBeginFixed "$MORNING"
    apply_setting LocationAuto false
    remove_setting LatitudeFixed
    remove_setting LongitudeFixed
    ;;
  constant)
    apply_setting Mode Constant
    apply_setting LocationAuto false
    remove_setting LatitudeFixed
    remove_setting LongitudeFixed
    remove_setting EveningBeginFixed
    remove_setting MorningBeginFixed
    ;;
esac

refresh_kwin

echo "\nNight Color configuration updated. Current values:"
if command -v kreadconfig5 >/dev/null 2>&1; then
  kreadconfig5 --file kwinrc --group NightColor --key Active | xargs printf "  Active: %s\n"
  kreadconfig5 --file kwinrc --group NightColor --key Mode | xargs printf "  Mode: %s\n"
  kreadconfig5 --file kwinrc --group NightColor --key DayTemperature | xargs printf "  Day temperature: %s K\n"
  kreadconfig5 --file kwinrc --group NightColor --key NightTemperature | xargs printf "  Night temperature: %s K\n"
  kreadconfig5 --file kwinrc --group NightColor --key TransitionTime | xargs printf "  Transition: %s minutes\n"
  kreadconfig5 --file kwinrc --group NightColor --key LocationAuto | xargs printf "  Location auto-detect: %s\n"
  kreadconfig5 --file kwinrc --group NightColor --key LatitudeFixed | xargs printf "  Latitude: %s\n"
  kreadconfig5 --file kwinrc --group NightColor --key LongitudeFixed | xargs printf "  Longitude: %s\n"
  kreadconfig5 --file kwinrc --group NightColor --key EveningBeginFixed | xargs printf "  Evening begins: %s\n"
  kreadconfig5 --file kwinrc --group NightColor --key MorningBeginFixed | xargs printf "  Morning begins: %s\n"
else
  echo "  (Install kreadconfig5 for detailed status output.)"
fi

if [[ -f "$CONFIG_FILE" ]]; then
  echo "\nConfiguration file updated at: $CONFIG_FILE"
else
  echo "\nWarning: kwinrc not found; KDE will generate it on next login." >&2
fi

echo "Done."
