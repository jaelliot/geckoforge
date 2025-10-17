#!/usr/bin/env bash
# @file test-night-color.sh
# @description Inspect and verify KDE Night Color configuration
# @update-policy Update when KDE changes Night Color DBus APIs or kwinrc keys

set -euo pipefail

CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/kwinrc"
GROUP="NightColor"
EXIT_CODE=0

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "[error] Night Color configuration not found at $CONFIG_FILE" >&2
  exit 1
fi

read_value() {
  local key=$1
  if command -v kreadconfig5 >/dev/null 2>&1; then
    kreadconfig5 --file kwinrc --group "$GROUP" --key "$key"
    return
  fi

  awk -F= -v key="$key" 'BEGIN { in_section=0 }
    match($0, /^\[(.*)\]$/, g) {
      in_section = (g[1] == "NightColor"); next
    }
    in_section {
      if ($1 == key) { gsub(/^ +| +$/, "", $2); print $2; exit }
    }
  ' "$CONFIG_FILE"
}

runtime_bus() {
  if command -v qdbus6 >/dev/null 2>&1; then
    echo "qdbus6"
  elif command -v qdbus >/dev/null 2>&1; then
    echo "qdbus"
  else
    echo ""
  fi
}

runtime_state() {
  local bus=$1
  [[ -z "$bus" ]] && return 1
  if state=$($bus org.kde.KWin /ColorCorrect isActive 2>/dev/null); then
    printf "%s" "$state"
    return 0
  fi
  if state=$($bus org.kde.KWin /ColorCorrect active 2>/dev/null); then
    printf "%s" "$state"
    return 0
  fi
  return 1
}

print_status() {
  local key label
  declare -A labels=(
    [Active]="Active"
    [Mode]="Mode"
    [DayTemperature]="Day temperature (K)"
    [NightTemperature]="Night temperature (K)"
    [TransitionTime]="Transition (minutes)"
    [LocationAuto]="Location auto-detect"
    [LatitudeFixed]="Latitude"
    [LongitudeFixed]="Longitude"
    [EveningBeginFixed]="Evening begins"
    [MorningBeginFixed]="Morning begins"
  )

  echo "=== Night Color Configuration Status ==="
  for key in "${!labels[@]}"; do
    value=$(read_value "$key" || true)
    if [[ -n "$value" ]]; then
      printf "%-24s %s\n" "${labels[$key]}:" "$value"
    fi
  done
}

validate_configuration() {
  local active mode day night auto lat lon
  active=$(read_value Active || echo "false")
  mode=$(read_value Mode || echo "Unknown")
  day=$(read_value DayTemperature || echo "0")
  night=$(read_value NightTemperature || echo "0")
  auto=$(read_value LocationAuto || echo "false")
  lat=$(read_value LatitudeFixed || echo "")
  lon=$(read_value LongitudeFixed || echo "")

  if [[ "$active" != "true" ]]; then
    echo "[warn] Night Color is not active (Active=$active)." >&2
    EXIT_CODE=2
  fi

  if ! [[ $day =~ ^[0-9]+$ ]] || (( day < 1000 || day > 10000 )); then
    echo "[warn] Day temperature appears out of range: $day" >&2
    EXIT_CODE=2
  fi

  if ! [[ $night =~ ^[0-9]+$ ]] || (( night < 1000 || night > 10000 )); then
    echo "[warn] Night temperature appears out of range: $night" >&2
    EXIT_CODE=2
  fi

  if [[ "$mode" == "Automatic" && "$auto" == "false" ]]; then
    echo "[warn] Mode is Automatic but LocationAuto is disabled." >&2
    EXIT_CODE=2
  fi

  if [[ "$auto" != "true" ]]; then
    if [[ -z "$lat" || -z "$lon" ]]; then
      echo "[warn] Manual location selected but coordinates are missing." >&2
      EXIT_CODE=2
    fi
  fi
}

prompt_toggle_test() {
  local bus=$1 original toggled restored reply
  [[ -z "$bus" ]] && return

  read -r -p $'Run Night Color runtime toggle test? (y/N): ' reply || reply=""
  if [[ ! $reply =~ ^[Yy]$ ]]; then
    echo "Skipping runtime toggle test."
    return
  fi

  if ! original=$(runtime_state "$bus"); then
    echo "[warn] Unable to query current Night Color runtime state." >&2
    return
  fi

  if ! $bus org.kde.KWin /ColorCorrect toggle >/dev/null 2>&1; then
    echo "[warn] DBus toggle call failed." >&2
    EXIT_CODE=3
    return
  fi

  sleep 1
  toggled=$(runtime_state "$bus" || echo "unknown")
  echo "Runtime state after toggle: $toggled"

  if ! $bus org.kde.KWin /ColorCorrect toggle >/dev/null 2>&1; then
    echo "[warn] Unable to restore Night Color state." >&2
    EXIT_CODE=3
    return
  fi

  sleep 1
  restored=$(runtime_state "$bus" || echo "unknown")
  echo "Runtime state restored: $restored"
}

print_status
validate_configuration

BUS=$(runtime_bus)
if [[ -n "$BUS" ]]; then
  if state=$(runtime_state "$BUS" 2>/dev/null); then
    echo "Runtime active state: $state"
  else
    echo "Runtime state unavailable (Night Color service may be inactive)."
  fi
else
  echo "qdbus not found; skipping runtime checks."
fi

prompt_toggle_test "$BUS"

if (( EXIT_CODE == 0 )); then
  echo "\nNight Color configuration looks healthy."
else
  echo "\nNight Color verification finished with warnings." >&2
fi

exit $EXIT_CODE
