#!/usr/bin/env bash
set -euo pipefail

print_step() {
  echo ""
  echo "--- $1 ---"
}

require_binary() {
  local bin="$1"
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "[ERROR] Missing required command: $bin"
    exit 1
  fi
}

check_kanata_package() {
  print_step "Checking Kanata availability"
  require_binary "kanata"
  kanata --version 2>/dev/null || echo "[warn] Unable to read kanata version"
}

check_config_files() {
  print_step "Verifying configuration files"
  local cfg="$HOME/.config/kanata/macos.kbd"
  local svc="$HOME/.config/systemd/user/kanata-macos.service"

  if [[ ! -f "$cfg" ]]; then
    echo "[ERROR] Kanata config missing: $cfg"
    exit 1
  fi
  echo "[ok] Found $cfg"

  if ! grep -q "deflayer macos" "$cfg"; then
    echo "[ERROR] Kanata config does not define macos layer"
    exit 1
  fi
  echo "[ok] macOS layer present"

  if [[ ! -f "$svc" ]]; then
    echo "[ERROR] Service file missing: $svc"
    exit 1
  fi
  echo "[ok] Found $svc"
}

check_systemd_service() {
  print_step "Inspecting systemd user service"
  require_binary "systemctl"

  systemctl --user daemon-reload >/dev/null 2>&1 || true

  if systemctl --user is-enabled kanata-macos.service >/dev/null 2>&1; then
    echo "[ok] kanata-macos.service is enabled"
  else
    echo "[WARN] kanata-macos.service is not enabled"
  fi

  if systemctl --user is-active kanata-macos.service >/dev/null 2>&1; then
    echo "[ok] kanata-macos.service is running"
  else
    echo "[WARN] kanata-macos.service is not active"
    echo "      Try: systemctl --user start kanata-macos.service"
  fi
}

check_kde_shortcuts() {
  print_step "Validating KDE shortcuts"
  local shortcuts_file="$HOME/.config/kglobalshortcutsrc"
  if [[ ! -f "$shortcuts_file" ]]; then
    echo "[WARN] kglobalshortcutsrc not found; KDE settings may not be initialized"
    return
  fi

  grep -q "Window Close=Meta+Q" "$shortcuts_file" && echo "[ok] Meta+Q close shortcut detected" || echo "[WARN] Meta+Q close shortcut missing"
  grep -q "Window Minimize=Meta+M" "$shortcuts_file" && echo "[ok] Meta+M minimize shortcut detected" || echo "[WARN] Meta+M minimize shortcut missing"
  grep -q "Walk Through Windows=Meta+Tab" "$shortcuts_file" && echo "[ok] Meta+Tab task switcher detected" || echo "[WARN] Meta+Tab task switcher missing"
}

check_application_configs() {
  print_step "Reviewing application overrides"

  local vscode_file="$HOME/.config/Code/User/keybindings.json"
  if [[ -f "$vscode_file" ]]; then
    if grep -q '"key": "cmd+c"' "$vscode_file"; then
      echo "[ok] VS Code keybindings configured"
    else
      echo "[WARN] VS Code keybindings.json missing cmd bindings"
    fi
  else
    echo "[WARN] VS Code keybindings.json not found"
  fi

  local katerc="$HOME/.config/katerc"
  if [[ -f "$katerc" ]]; then
    grep -q "copy=Meta+C" "$katerc" && echo "[ok] Kate shortcuts configured" || echo "[WARN] Kate shortcuts missing"
  else
    echo "[WARN] katerc not found"
  fi

  local profiles_ini="$HOME/.mozilla/firefox/profiles.ini"
  if [[ -f "$profiles_ini" ]]; then
    local default_profile
    default_profile=$(awk -F= '/^Default=/{print $2}' "$profiles_ini" | tail -n1)
    if [[ -n "$default_profile" ]]; then
      local user_js="$HOME/.mozilla/firefox/${default_profile}/user.js"
      if [[ -f "$user_js" ]] && grep -q 'ui.key.accelKey", 224' "$user_js"; then
        echo "[ok] Firefox accelKey override detected"
      else
        echo "[WARN] Firefox accelKey override missing"
      fi
    else
      echo "[WARN] Unable to determine default Firefox profile"
    fi
  else
    echo "[WARN] Firefox profiles.ini not found"
  fi
}

interactive_guidance() {
  print_step "Manual verification"
  cat <<'EOF'
1. Press Cmd+C / Cmd+V in a terminal to ensure copy/paste works.
2. Press Cmd+Q in a KDE application to confirm the window closes.
3. Use Cmd+Tab to cycle windows; verify behavior matches macOS expectations.
4. In Firefox, open about:config and confirm ui.key.accelKey = 224.
5. Open VS Code and confirm Cmd+, opens Settings.

If any test fails, rerun scripts/setup-macos-keyboard.sh or inspect
~/.config/kanata/macos.kbd for device path accuracy.
EOF
}

main() {
  check_kanata_package
  check_config_files
  check_systemd_service
  check_kde_shortcuts
  check_application_configs
  interactive_guidance
  echo ""
  echo "All automated checks completed."
}

main "$@"
