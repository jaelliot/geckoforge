#!/usr/bin/env bash
# @file scripts/setup-rclone.sh
# @description Interactive rclone configuration wizard for encrypted cloud backups
# @update-policy Update when new cloud providers or best practices emerge

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
  printf "${GREEN}[rclone]${NC} %s\n" "$1"
}

warn() {
  printf "${YELLOW}[rclone]${NC} %s\n" "$1"
}

error() {
  printf "${RED}[rclone]${NC} %s\n" "$1"
}

header() {
  echo ""
  echo "╔════════════════════════════════════════════════════╗"
  printf "║ %-50s ║\n" "$1"
  echo "╚════════════════════════════════════════════════════╝"
  echo ""
}

header "Geckoforge Rclone Setup Wizard"

log "This wizard will help you configure encrypted cloud backups"
echo ""

# Check if rclone is installed
if ! command -v rclone >/dev/null 2>&1; then
  error "rclone not found"
  echo ""
  echo "Install rclone first:"
  echo "  cd ~/git/home"
  echo "  home-manager switch --flake ."
  exit 1
fi

log "rclone version: $(rclone version | head -n1)"
echo ""

# Check if already configured
if rclone listremotes 2>/dev/null | grep -q "."; then
  warn "Existing rclone remotes detected:"
  rclone listremotes
  echo ""
  read -p "Continue to add more remotes? (y/N): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log "Exiting"
    exit 0
  fi
fi

echo ""
header "Step 1: Choose Your Cloud Provider"
echo ""

cat <<EOF
Recommended providers for DevOps:

1. ${BLUE}Google Drive${NC} - 15 GB free, good for personal use
2. ${BLUE}AWS S3${NC} - Pay-as-you-go, best for professional use
3. ${BLUE}Backblaze B2${NC} - Cheaper than S3, good alternative
4. ${BLUE}Microsoft OneDrive${NC} - If you have O365 subscription
5. ${BLUE}Dropbox${NC} - Familiar interface, limited free tier

For complete list: https://rclone.org/#providers
EOF

echo ""
read -p "Ready to configure your cloud provider? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  log "Run this script again when ready"
  exit 0
fi

echo ""
log "Starting rclone configuration..."
log "Follow the prompts to add your cloud provider"
echo ""

# Run rclone config
rclone config

echo ""
header "Step 2: Verify Base Remote"
echo ""

log "Listing configured remotes..."
BASE_REMOTES=$(rclone listremotes)

if [ -z "$BASE_REMOTES" ]; then
  error "No remotes configured"
  echo "Run: rclone config"
  exit 1
fi

echo "$BASE_REMOTES"
echo ""

read -p "Enter the name of your base remote (without colon): " BASE_REMOTE

if ! echo "$BASE_REMOTES" | grep -q "^${BASE_REMOTE}:"; then
  error "Remote '$BASE_REMOTE' not found"
  exit 1
fi

log "Testing remote: $BASE_REMOTE"
if rclone lsf "${BASE_REMOTE}:" --max-depth 1 >/dev/null 2>&1; then
  log "✓ Remote '$BASE_REMOTE' is working"
else
  error "✗ Failed to access remote '$BASE_REMOTE'"
  error "Check your credentials and network connection"
  exit 1
fi

echo ""
header "Step 3: Create Encrypted Remote"
echo ""

log "Now we'll create an encrypted wrapper around '$BASE_REMOTE'"
echo ""

cat <<EOF
${YELLOW}Important:${NC} You'll need to generate two passwords:
1. ${BLUE}Encryption password${NC} - Encrypts your file contents
2. ${BLUE}Salt password${NC} - Adds additional security

Recommendations:
- Use ${GREEN}256-bit${NC} strength (rclone can generate this)
- Store both passwords in a ${GREEN}password manager${NC}
- ${RED}If you lose these passwords, your data is UNRECOVERABLE${NC}

EOF

read -p "Ready to create encrypted remote? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  log "Run this script again when ready"
  exit 0
fi

echo ""
log "Suggested encrypted remote name: ${BASE_REMOTE}-crypt"
read -p "Enter name for encrypted remote [${BASE_REMOTE}-crypt]: " CRYPT_REMOTE
CRYPT_REMOTE=${CRYPT_REMOTE:-${BASE_REMOTE}-crypt}

log "Creating encrypted remote: $CRYPT_REMOTE"
echo ""

# Create crypt remote non-interactively with prompts
rclone config create "$CRYPT_REMOTE" crypt \
  remote "${BASE_REMOTE}:encrypted-backup" \
  filename_encryption standard \
  directory_name_encryption true

echo ""
log "✓ Encrypted remote '$CRYPT_REMOTE' created"

echo ""
header "Step 4: Test Encrypted Remote"
echo ""

log "Creating test file..."
TEST_FILE="/tmp/rclone-test-$$.txt"
echo "Geckoforge encrypted backup test - $(date)" > "$TEST_FILE"

log "Uploading test file..."
if rclone copy "$TEST_FILE" "${CRYPT_REMOTE}:test/"; then
  log "✓ Upload successful"
else
  error "✗ Upload failed"
  rm -f "$TEST_FILE"
  exit 1
fi

log "Listing encrypted remote..."
if rclone ls "${CRYPT_REMOTE}:test/"; then
  log "✓ File visible in encrypted remote"
else
  error "✗ Failed to list remote"
  rm -f "$TEST_FILE"
  exit 1
fi

log "Verifying file contents..."
DOWNLOADED="/tmp/rclone-test-downloaded-$$.txt"
if rclone copy "${CRYPT_REMOTE}:test/$(basename "$TEST_FILE")" /tmp/ && \
   diff "$TEST_FILE" "$DOWNLOADED" >/dev/null 2>&1; then
  log "✓ Encryption/decryption working correctly"
else
  error "✗ File content mismatch"
  rm -f "$TEST_FILE" "$DOWNLOADED"
  exit 1
fi

# Cleanup
log "Cleaning up test files..."
rclone delete "${CRYPT_REMOTE}:test/" >/dev/null 2>&1 || true
rm -f "$TEST_FILE" "$DOWNLOADED"

echo ""
header "Step 5: Enable Automated Backups"
echo ""

cat <<EOF
Your encrypted remote is ready: ${GREEN}$CRYPT_REMOTE${NC}

Automated backups are configured but ${YELLOW}not enabled yet${NC}.

To enable:

${BLUE}1. Update backup module${NC} (if remote name differs):
   Edit: ~/git/home/modules/backup.nix
   Change: REMOTE="gdrive-crypt"
   To:     REMOTE="$CRYPT_REMOTE"
   Run:    home-manager switch --flake ~/git/home

${BLUE}2. Enable backup timers:${NC}
   systemctl --user enable --now rclone-backup-critical.timer
   systemctl --user enable --now rclone-backup-projects.timer

${BLUE}3. Check timer status:${NC}
   systemctl --user list-timers

${BLUE}4. Manual backup test:${NC}
   systemctl --user start rclone-backup-critical.service
   journalctl --user -u rclone-backup-critical.service -f

${BLUE}5. View backup logs:${NC}
   ls ~/.local/share/rclone/logs/
   tail -f ~/.local/share/rclone/logs/critical-*.log

EOF

echo ""
log "✓ Rclone setup complete!"
echo ""

cat <<EOF
${GREEN}Next steps:${NC}
1. Configure what to backup (edit filters in ~/.config/rclone/)
2. Test manual backup: systemctl --user start rclone-backup-critical
3. Enable automatic backups (see commands above)
4. Document your encryption passwords securely

${YELLOW}Security reminders:${NC}
- Store encryption passwords in a password manager
- Test restoring from backup regularly
- Keep at least one backup offline (external HDD)
- Never share your rclone.conf file (contains credentials)

EOF