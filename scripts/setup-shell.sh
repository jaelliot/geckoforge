#!/usr/bin/env bash
# @file scripts/setup-shell.sh
# @description Change user's default shell to zsh and activate Home-Manager configuration
# @update-policy Update when shell configuration or onboarding process changes

set -euo pipefail

log() {
  printf '[shell] %s\n' "$1"
}

header() {
  echo ""
  echo "╔════════════════════════════════════════╗"
  printf "║ %38s ║\n" "$1"
  echo "╚════════════════════════════════════════╝"
  echo ""
}

header "Geckoforge Shell Setup"

log "Checking current shell..."
current_shell=$(getent passwd "$USER" | cut -d: -f7)
log "Current shell: $current_shell"

# Check if already using zsh
if [[ "$current_shell" == "/bin/zsh" ]] || [[ "$current_shell" == "/usr/bin/zsh" ]]; then
  log "✓ Shell already set to zsh"
  
  # Check if Home-Manager config is active
  if [[ -f "$HOME/.zshrc" ]] && grep -q "oh-my-zsh" "$HOME/.zshrc" 2>/dev/null; then
    log "✓ Oh My Zsh configuration appears active"
    log ""
    log "Run 'home-manager switch --flake ~/git/home' to update configuration"
    exit 0
  else
    log "⚠️  Zsh is default but Oh My Zsh not configured"
    log "    Run: cd ~/git/home && home-manager switch --flake ."
    exit 0
  fi
fi

# Verify zsh is installed
log "Checking zsh installation..."
if ! command -v zsh >/dev/null 2>&1; then
  log "✗ ERROR: zsh not installed"
  log ""
  log "Install zsh first:"
  log "  sudo zypper install zsh zsh-completions"
  log ""
  log "Or rebuild from geckoforge ISO (includes zsh in base system)"
  exit 1
fi

zsh_path=$(command -v zsh)
log "✓ Found zsh at: $zsh_path"

# Verify zsh is in /etc/shells
log "Verifying zsh is in /etc/shells..."
if ! grep -q "^${zsh_path}$" /etc/shells; then
  log "⚠️  Adding zsh to /etc/shells (requires sudo)..."
  echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
  log "✓ Added zsh to /etc/shells"
fi

# Change shell
log ""
log "Changing default shell to zsh..."
log "(You may be prompted for your password)"
chsh -s "$zsh_path"

log "✓ Shell changed to zsh"
log ""

header "Next Steps"

cat <<'EOF'
1. Log out and back in for shell change to take effect

2. After logging back in, activate Oh My Zsh configuration:
   cd ~/git/home
   home-manager switch --flake .

3. (Optional) Customize Powerlevel10k prompt:
   p10k configure

4. Start a new terminal session to see the new prompt!

═══════════════════════════════════════

DevOps Features:
• Use fzf with Ctrl+R for fuzzy history search
• Use autosuggestions by pressing → (right arrow)
• Prefix sensitive commands with space to exclude from history
• Your kubectl context shows in the right prompt
• Production contexts appear in RED (be careful!)
• 50,000 command history with deduplication
• DevOps plugins: docker, kubectl, terraform, aws

EOF