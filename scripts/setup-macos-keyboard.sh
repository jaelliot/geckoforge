#!/usr/bin/env bash
set -euo pipefail

print_section() {
  local title="$1"
  echo ""
  echo "========================================"
  echo "${title}"
  echo "========================================"
}

require_binary() {
  local bin="$1"
  local pkg_hint="$2"
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "[ERROR] Missing required command: $bin"
    if [[ -n "$pkg_hint" ]]; then
      echo "        Install via: sudo zypper install -y $pkg_hint"
    fi
    exit 1
  fi
}

backup_file() {
  local target="$1"
  if [[ -f "$target" ]]; then
    local backup="${target}.bak.$(date +%Y%m%d%H%M%S)"
    cp "$target" "$backup"
    echo "[backup] Created ${backup}"
  fi
}

select_keyboard_device() {
  local devices=()
  local idx=0
  if command -v kanata >/dev/null 2>&1; then
    if kanata --list-devices >/dev/null 2>&1; then
      while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        devices+=("$line")
      done < <(kanata --list-devices | grep -E '/dev/input/.+-event-(kbd|keyboard)')
    fi
  fi

  if [[ ${#devices[@]} -eq 0 ]]; then
    while IFS= read -r path; do
      devices+=("$path")
    done < <(find /dev/input/by-path -maxdepth 1 -type l -name '*-event-kbd' 2>/dev/null | sort)
  fi

  if [[ ${#devices[@]} -eq 0 ]]; then
    echo "[WARN] Unable to auto-detect keyboard device."
    read -rp "Enter the full /dev/input path for your keyboard: " manual_path
    if [[ -z "$manual_path" ]]; then
      echo "[ERROR] No device selected. Aborting."
      exit 1
    fi
    echo "$manual_path"
    return
  fi

  if [[ ${#devices[@]} -eq 1 ]]; then
    echo "[info] Using detected keyboard device: ${devices[0]}"
    echo "${devices[0]}"
    return
  fi

  echo "Select the keyboard device Kanata should capture:"
  for device in "${devices[@]}"; do
    idx=$((idx + 1))
    echo "  [$idx] $device"
  done

  local selection
  while true; do
    read -rp "Choose device number: " selection
    if [[ "$selection" =~ ^[0-9]+$ ]] && (( selection >= 1 && selection <= ${#devices[@]} )); then
      echo "${devices[selection-1]}"
      return
    fi
    echo "Invalid selection."
  done
}

write_kanata_config() {
  local device_path="$1"
  local config_dir="$HOME/.config/kanata"
  local config_file="${config_dir}/macos.kbd"

  mkdir -p "$config_dir"
  backup_file "$config_file"

  cat >"$config_file" <<EOF
(defcfg
  input  (device-file "${device_path}")
  output (uinput-sink "kanata-macos-virtual")
  fallthrough true
  allow-cmd true
)

(defsrc
  esc      f1    f2    f3    f4    f5    f6    f7    f8    f9    f10   f11   f12
  grv      1     2     3     4     5     6     7     8     9     0     minus equal bspc
  tab      q     w     e     r     t     y     u     i     o     p     lbrc rbrc bslash
  capslock a     s     d     f     g     h     j     k     l     semicolon apostrophe ret
  lsft     z     x     c     v     b     n     m     comma dot   slash rsft
  lctl     lmet  lalt  spc   ralt  rmet  menu  rctl
)

(deflayer macos
  esc      f1    f2    f3    f4    f5    f6    f7    f8    f9    f10   f11   f12
  grv      1     2     3     4     5     6     7     8     9     0     minus equal bspc
  tab      q     w     e     r     t     y     u     i     o     p     lbrc rbrc bslash
  capslock a     s     d     f     g     h     j     k     l     semicolon apostrophe ret
  lsft     z     x     c     v     b     n     m     comma dot   slash rsft
  lmet     lctl  lalt  spc   ralt  rctl  menu  rmet
)
EOF

  echo "[ok] Wrote Kanata configuration to $config_file"
}

create_systemd_service() {
  local service_dir="$HOME/.config/systemd/user"
  local service_file="${service_dir}/kanata-macos.service"

  mkdir -p "$service_dir"
  backup_file "$service_file"

  cat >"$service_file" <<EOF
[Unit]
Description=Kanata macOS-style keyboard remapping
After=graphical-session.target
ConditionPathExists=%h/.config/kanata/macos.kbd

[Service]
Type=simple
ExecStart=/usr/bin/env bash -c 'exec kanata --cfg %h/.config/kanata/macos.kbd'
Restart=on-failure
RestartSec=2

[Install]
WantedBy=default.target
EOF

  systemctl --user daemon-reload
  systemctl --user enable --now kanata-macos.service
  echo "[ok] Enabled kanata-macos.service (user)"
}

configure_kde_shortcuts() {
  local shortcuts_file="$HOME/.config/kglobalshortcutsrc"
  backup_file "$shortcuts_file"

  kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Window Close" "Meta+Q\tAlt+F4,Meta+Q,Close Window"
  kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Window Minimize" "Meta+M,Meta+M,Minimize Window"
  kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Walk Through Windows" "Meta+Tab,Alt+Tab,Walk Through Windows"
  kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Walk Through Windows (Reverse)" "Meta+Shift+Tab,Alt+Shift+Tab,Walk Through Windows (Reverse)"
  kwriteconfig5 --file ksmserver --group logout --key "Lock Session" "Meta+L\tCtrl+Alt+L,Meta+L,Lock Screen"

  qdbus org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
  echo "[ok] Applied KDE global shortcuts"
}

configure_vscode() {
  local vscode_dir="$HOME/.config/Code/User"
  local keybindings_file="${vscode_dir}/keybindings.json"

  mkdir -p "$vscode_dir"
  backup_file "$keybindings_file"

  cat >"$keybindings_file" <<'EOF'
[
  { "key": "cmd+c", "command": "editor.action.clipboardCopyAction" },
  { "key": "cmd+v", "command": "editor.action.clipboardPasteAction" },
  { "key": "cmd+x", "command": "editor.action.clipboardCutAction" },
  { "key": "cmd+s", "command": "workbench.action.files.save" },
  { "key": "cmd+shift+s", "command": "workbench.action.files.saveAs" },
  { "key": "cmd+q", "command": "workbench.action.quit" },
  { "key": "cmd+w", "command": "workbench.action.closeActiveEditor" },
  { "key": "cmd+t", "command": "workbench.action.showAllSymbols" },
  { "key": "cmd+,", "command": "workbench.action.openSettings" }
]
EOF

  echo "[ok] Updated VS Code keybindings"
}

configure_kate() {
  kwriteconfig5 --file katerc --group Shortcuts --key copy "Meta+C"
  kwriteconfig5 --file katerc --group Shortcuts --key paste "Meta+V"
  kwriteconfig5 --file katerc --group Shortcuts --key cut "Meta+X"
  kwriteconfig5 --file katerc --group Shortcuts --key save "Meta+S"
  kwriteconfig5 --file katerc --group Shortcuts --key close "Meta+W"
  echo "[ok] Applied Kate shortcut overrides"
}

configure_firefox() {
  local profiles_ini="$HOME/.mozilla/firefox/profiles.ini"
  if [[ ! -f "$profiles_ini" ]]; then
    echo "[warn] Firefox profiles.ini not found; skipping Firefox configuration."
    return
  fi

  local default_profile
  default_profile=$(awk -F= '/^Default=/{print $2}' "$profiles_ini" | tail -n1)

  if [[ -z "$default_profile" ]]; then
    echo "[warn] Unable to determine default Firefox profile; skipping."
    return
  fi

  local profile_dir="$HOME/.mozilla/firefox/${default_profile}"
  local user_js="${profile_dir}/user.js"
  mkdir -p "$profile_dir"
  backup_file "$user_js"

  cat >>"$user_js" <<'EOF'
user_pref("ui.key.accelKey", 224);
EOF

  echo "[ok] Set Firefox accelKey to Meta in ${default_profile}"
}

main() {
  if [[ "$(uname -s)" != "Linux" ]]; then
    echo "[ERROR] This script must run on Linux."
    exit 1
  fi

  require_binary "sudo" "sudo"
  require_binary "zypper" "zypper"
  require_binary "systemctl" "systemd"
  require_binary "kwriteconfig5" "plasma5-workspace"

  print_section "Installing Kanata"
  if ! zypper search --match-exact kanata 2>/dev/null | grep -q "kanata"; then
    echo "[warn] 'kanata' package not listed in repositories. Attempting installation anyway."
  fi
  sudo zypper install -y kanata

  print_section "Detecting keyboard device"
  local device_path
  device_path=$(select_keyboard_device)
  echo "[info] Selected device: $device_path"

  print_section "Writing Kanata configuration"
  write_kanata_config "$device_path"

  print_section "Configuring systemd user service"
  create_systemd_service

  print_section "Applying KDE shortcuts"
  configure_kde_shortcuts

  print_section "Configuring applications"
  configure_vscode
  configure_kate
  configure_firefox

  print_section "Setup complete"
  cat <<'EOF'
Next steps:
1. Log out and back in to ensure the uinput device is active.
2. Test shortcuts using scripts/test-macos-keyboard.sh.
3. If you use multiple keyboards, rerun this script when plugging a new device.
EOF
}

main "$@"
