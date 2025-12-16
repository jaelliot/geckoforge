#!/usr/bin/env bash
# @file tools/verify-no-telemetry.sh
# @description Verify telemetry is disabled across GeckoForge system
# @usage: ./tools/verify-no-telemetry.sh
# @requires: Home Manager configuration applied, Firefox/VS Code/Thunderbird profiles exist

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
WARNINGS=0

echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     GeckoForge Telemetry Verification Report      ║${NC}"
echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo ""

# Function to check environment variables
check_env_var() {
    local var_name="$1"
    local expected_value="$2"
    local actual_value="${!var_name:-not set}"
    
    if [ "$actual_value" = "$expected_value" ]; then
        echo -e "  ${GREEN}✓${NC} $var_name = $expected_value"
        ((PASSED++))
    else
        echo -e "  ${RED}✗${NC} $var_name = $actual_value (expected: $expected_value)"
        ((FAILED++))
    fi
}

# Function to check file content
check_file_content() {
    local file_pattern="$1"
    local search_string="$2"
    local description="$3"
    
    local files=$(eval "ls $file_pattern 2>/dev/null" || echo "")
    
    if [ -z "$files" ]; then
        echo -e "  ${YELLOW}⚠${NC}  $description - File not found: $file_pattern"
        ((WARNINGS++))
        return
    fi
    
    if grep -q "$search_string" $files 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $description"
        ((PASSED++))
    else
        echo -e "  ${RED}✗${NC} $description - Pattern not found: $search_string"
        ((FAILED++))
    fi
}

# Function to check JSON file
check_json_setting() {
    local file_path="$1"
    local jq_query="$2"
    local expected_value="$3"
    local description="$4"
    
    if [ ! -f "$file_path" ]; then
        echo -e "  ${YELLOW}⚠${NC}  $description - File not found: $file_path"
        ((WARNINGS++))
        return
    fi
    
    local actual_value=$(jq -r "$jq_query" "$file_path" 2>/dev/null || echo "error")
    
    if [ "$actual_value" = "$expected_value" ]; then
        echo -e "  ${GREEN}✓${NC} $description"
        ((PASSED++))
    else
        echo -e "  ${RED}✗${NC} $description - Got: $actual_value (expected: $expected_value)"
        ((FAILED++))
    fi
}

echo -e "${BLUE}📊 Environment Variables:${NC}"
echo ""

# Development tool telemetry
check_env_var "GOTELEMETRY" "off"
check_env_var "GOTELEMETRYDIR" "/dev/null"
check_env_var "ELIXIR_CLI_TELEMETRY" "false"
check_env_var "MIX_TELEMETRY_DISABLED" "1"
check_env_var "NEXT_TELEMETRY_DISABLED" "1"
check_env_var "ASTRO_TELEMETRY_DISABLED" "1"
check_env_var "CARGO_TELEMETRY_DISABLED" "1"
check_env_var "DOTNET_CLI_TELEMETRY_OPTOUT" "1"
check_env_var "HOMEBREW_NO_ANALYTICS" "1"
check_env_var "AZURE_CORE_COLLECT_TELEMETRY" "false"
check_env_var "POWERSHELL_TELEMETRY_OPTOUT" "1"
check_env_var "DO_NOT_TRACK" "1"
check_env_var "CHECKPOINT_DISABLE" "1"
check_env_var "PYTHONDONTWRITEBYTECODE" "1"

echo ""
echo -e "${BLUE}🦊 Firefox Telemetry:${NC}"
echo ""

# Firefox prefs.js check
FIREFOX_PROFILE=$(find ~/.mozilla/firefox -maxdepth 1 -type d -name "*.default*" | head -1)
if [ -n "$FIREFOX_PROFILE" ]; then
    check_file_content "$FIREFOX_PROFILE/prefs.js" '"toolkit.telemetry.enabled", false' "Core telemetry disabled"
    check_file_content "$FIREFOX_PROFILE/prefs.js" '"datareporting.healthreport.uploadEnabled", false' "Health report disabled"
    check_file_content "$FIREFOX_PROFILE/prefs.js" '"browser.crashReports.unsubmittedCheck.autoSubmit2", false' "Crash auto-submit disabled"
    check_file_content "$FIREFOX_PROFILE/prefs.js" '"app.shield.optoutstudies.enabled", false' "Studies disabled"
    check_file_content "$FIREFOX_PROFILE/prefs.js" '"app.normandy.enabled", false' "Normandy (experiments) disabled"
    check_file_content "$FIREFOX_PROFILE/prefs.js" '"network.captive-portal-service.enabled", false' "Captive portal (phoning home) disabled"
else
    echo -e "  ${YELLOW}⚠${NC}  Firefox profile not found - launch Firefox to create profile"
    ((WARNINGS++))
fi

echo ""
echo -e "${BLUE}💻 VS Code Telemetry:${NC}"
echo ""

# VS Code settings.json check
VSCODE_SETTINGS="$HOME/.config/Code/User/settings.json"
if [ -f "$VSCODE_SETTINGS" ]; then
    check_json_setting "$VSCODE_SETTINGS" '.["telemetry.telemetryLevel"]' "off" "Telemetry level off"
    check_json_setting "$VSCODE_SETTINGS" '.["telemetry.enableCrashReporter"]' "false" "Crash reporter disabled"
    check_json_setting "$VSCODE_SETTINGS" '.["telemetry.enableTelemetry"]' "false" "Telemetry disabled"
    check_json_setting "$VSCODE_SETTINGS" '.["extensions.autoUpdate"]' "false" "Extension auto-update disabled"
    check_json_setting "$VSCODE_SETTINGS" '.["workbench.enableExperiments"]' "false" "Experiments disabled"
    check_json_setting "$VSCODE_SETTINGS" '.["redhat.telemetry.enabled"]' "false" "Red Hat telemetry disabled"
else
    echo -e "  ${YELLOW}⚠${NC}  VS Code settings not found: $VSCODE_SETTINGS"
    echo -e "  ${YELLOW}⚠${NC}  Launch VS Code to generate settings"
    ((WARNINGS++))
fi

echo ""
echo -e "${BLUE}📧 Thunderbird Telemetry:${NC}"
echo ""

# Thunderbird user.js check
THUNDERBIRD_PROFILE=$(find ~/.thunderbird -maxdepth 1 -type d -name "*.default*" | head -1)
if [ -n "$THUNDERBIRD_PROFILE" ]; then
    check_file_content "$THUNDERBIRD_PROFILE/user.js" '"toolkit.telemetry.enabled", false' "Telemetry disabled"
    check_file_content "$THUNDERBIRD_PROFILE/user.js" '"datareporting.healthreport.uploadEnabled", false' "Health report disabled"
    check_file_content "$THUNDERBIRD_PROFILE/user.js" '"datareporting.policy.dataSubmissionEnabled", false' "Data submission disabled"
else
    echo -e "  ${YELLOW}⚠${NC}  Thunderbird profile not found"
    echo -e "  ${YELLOW}⚠${NC}  Launch Thunderbird to create profile, then run: home-manager switch"
    ((WARNINGS++))
fi

echo ""
echo -e "${BLUE}🖥️  KDE Plasma Telemetry:${NC}"
echo ""

# KDE feedback config
check_file_content "$HOME/.config/PlasmaUserFeedback" "Enabled=false" "User feedback disabled"
check_file_content "$HOME/.config/drkonqirc" "AutoSubmit=false" "Dr. Konqi auto-submit disabled"

echo ""
echo -e "${BLUE}🐳 Docker Telemetry:${NC}"
echo ""

# Docker config.json
DOCKER_CONFIG="$HOME/.docker/config.json"
if [ -f "$DOCKER_CONFIG" ]; then
    check_json_setting "$DOCKER_CONFIG" '.analyticsEnabled' "false" "Analytics disabled"
    check_json_setting "$DOCKER_CONFIG" '.autoUpdate' "false" "Auto-update disabled"
else
    echo -e "  ${YELLOW}⚠${NC}  Docker config not found: $DOCKER_CONFIG"
    echo -e "  ${YELLOW}⚠${NC}  Will be created on next home-manager switch"
    ((WARNINGS++))
fi

echo ""
echo -e "${BLUE}📦 Package Manager Telemetry:${NC}"
echo ""

# npm config
NPMRC="$HOME/.npmrc"
if [ -f "$NPMRC" ]; then
    check_file_content "$NPMRC" "disable-telemetry=true" "npm telemetry disabled"
    check_file_content "$NPMRC" "fund=false" "npm funding messages disabled"
else
    echo -e "  ${YELLOW}⚠${NC}  npm config not found: $NPMRC"
    echo -e "  ${YELLOW}⚠${NC}  Will be created on next home-manager switch"
    ((WARNINGS++))
fi

echo ""
echo -e "${BLUE}🌐 Network Traffic Check:${NC}"
echo ""

# Optional: Check for known telemetry domains in /etc/hosts
TELEMETRY_DOMAINS=(
    "telemetry.mozilla.org"
    "incoming.telemetry.mozilla.org"
    "dc.services.visualstudio.com"
    "vortex.data.microsoft.com"
)

echo "  Checking for telemetry domain blocking in /etc/hosts..."
if [ -f "/etc/hosts" ]; then
    for domain in "${TELEMETRY_DOMAINS[@]}"; do
        if grep -q "$domain" /etc/hosts 2>/dev/null; then
            echo -e "  ${GREEN}✓${NC} $domain blocked in /etc/hosts"
            ((PASSED++))
        else
            echo -e "  ${YELLOW}⚠${NC}  $domain not blocked (optional - consider adding to /etc/hosts)"
            ((WARNINGS++))
        fi
    done
else
    echo -e "  ${YELLOW}⚠${NC}  Cannot read /etc/hosts (requires root)"
    ((WARNINGS++))
fi

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                   Summary Report                   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${GREEN}✓ Passed:${NC}   $PASSED checks"
echo -e "  ${RED}✗ Failed:${NC}   $FAILED checks"
echo -e "  ${YELLOW}⚠ Warnings:${NC} $WARNINGS checks"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All critical telemetry checks passed!${NC}"
    echo ""
    echo "Privacy Status: ✅ EXCELLENT"
    echo ""
    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}Note: Some optional checks showed warnings (missing configs or features).${NC}"
        echo -e "${YELLOW}These will be resolved once you launch the applications or run 'home-manager switch'.${NC}"
    fi
    exit 0
else
    echo -e "${RED}❌ Some telemetry checks failed!${NC}"
    echo ""
    echo "Privacy Status: ⚠️  NEEDS ATTENTION"
    echo ""
    echo "Action Required:"
    echo "  1. Run: home-manager switch --flake ~/Documents/Vaidya-Solutions-Code/geckoforge/home"
    echo "  2. Re-run this script to verify"
    echo "  3. If failures persist, check logs in ~/.xsession-errors"
    exit 1
fi
