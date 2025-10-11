#!/usr/bin/env bash
# @file scripts/check-backups.sh
# @description Health monitoring and verification for rclone encrypted backups
# @update-policy Update when backup strategies change or new health checks needed

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
RCLONE_CONFIG="$HOME/.config/rclone/rclone.conf"
LOG_DIR="$HOME/.local/share/rclone/logs"
STATUS_FILE="$HOME/.local/share/rclone/backup-status.json"
DEFAULT_REMOTE="gdrive-crypt"  # Override via environment: BACKUP_REMOTE
BACKUP_REMOTE="${BACKUP_REMOTE:-$DEFAULT_REMOTE}"

# Exit codes
EXIT_SUCCESS=0
EXIT_WARNING=1
EXIT_ERROR=2
EXIT_CRITICAL=3

log() {
  printf "${GREEN}[check-backups]${NC} %s\n" "$1"
}

warn() {
  printf "${YELLOW}[WARNING]${NC} %s\n" "$1"
}

error() {
  printf "${RED}[ERROR]${NC} %s\n" "$1"
}

critical() {
  printf "${RED}[CRITICAL]${NC} %s\n" "$1"
}

usage() {
  cat <<EOF
Usage: $0 [OPTIONS]

Health monitoring for rclone encrypted backups

OPTIONS:
  -r, --remote NAME    Override default remote ($DEFAULT_REMOTE)
  -v, --verbose        Verbose output
  -q, --quiet          Quiet mode (errors only)
  --fix               Attempt to fix common issues
  --test              Test backup/restore cycle
  -h, --help          Show this help

EXAMPLES:
  $0                  Basic health check
  $0 -v               Verbose health check
  $0 --test           Full backup/restore test
  $0 --fix            Fix permissions and missing directories

ENVIRONMENT:
  BACKUP_REMOTE       Override default remote name
  NO_COLOR           Disable colored output

EXIT CODES:
  0  Success          Everything healthy
  1  Warning          Minor issues found
  2  Error           Backup issues requiring attention
  3  Critical        Backup completely broken
EOF
}

# Parse arguments
VERBOSE=false
QUIET=false
FIX_MODE=false
TEST_MODE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    -r|--remote)
      BACKUP_REMOTE="$2"
      shift 2
      ;;
    -v|--verbose)
      VERBOSE=true
      shift
      ;;
    -q|--quiet)
      QUIET=true
      shift
      ;;
    --fix)
      FIX_MODE=true
      shift
      ;;
    --test)
      TEST_MODE=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      error "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

# Logging functions based on verbosity
vlog() {
  if [ "$VERBOSE" = true ] && [ "$QUIET" = false ]; then
    log "$1"
  fi
}

qlog() {
  if [ "$QUIET" = false ]; then
    log "$1"
  fi
}

# Track overall health
HEALTH_STATUS="HEALTHY"
HEALTH_SCORE=100
ISSUES_FOUND=0
WARNINGS_FOUND=0

update_health() {
  local severity="$1"
  local points="$2"
  
  case "$severity" in
    "WARNING")
      WARNINGS_FOUND=$((WARNINGS_FOUND + 1))
      HEALTH_SCORE=$((HEALTH_SCORE - points))
      if [ "$HEALTH_STATUS" = "HEALTHY" ]; then
        HEALTH_STATUS="WARNING"
      fi
      ;;
    "ERROR")
      ISSUES_FOUND=$((ISSUES_FOUND + 1))
      HEALTH_SCORE=$((HEALTH_SCORE - points))
      HEALTH_STATUS="ERROR"
      ;;
    "CRITICAL")
      ISSUES_FOUND=$((ISSUES_FOUND + 1))
      HEALTH_SCORE=$((HEALTH_SCORE - points))
      HEALTH_STATUS="CRITICAL"
      ;;
  esac
}

# Check if command exists
check_command() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    error "Required command '$cmd' not found"
    if [ "$FIX_MODE" = true ]; then
      warn "Run: home-manager switch --flake ~/git/home"
    fi
    update_health "ERROR" 20
    return 1
  fi
  return 0
}

# Check rclone installation and version
check_rclone() {
  qlog "Checking rclone installation..."
  
  if ! check_command "rclone"; then
    return 1
  fi
  
  local version
  version=$(rclone version --check=false | head -n1 | cut -d' ' -f2)
  vlog "rclone version: $version"
  
  # Check for recent version (warn if older than 1 year)
  local version_date
  version_date=$(rclone version --check=false | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+' | head -n1)
  if [ -n "$version_date" ]; then
    vlog "Version string: $version_date"
  fi
  
  return 0
}

# Check rclone configuration
check_config() {
  qlog "Checking rclone configuration..."
  
  if [ ! -f "$RCLONE_CONFIG" ]; then
    error "rclone config not found: $RCLONE_CONFIG"
    if [ "$FIX_MODE" = true ]; then
      warn "Run: rclone config"
    fi
    update_health "CRITICAL" 50
    return 1
  fi
  
  # Check config permissions (should be 600)
  local perms
  perms=$(stat -c "%a" "$RCLONE_CONFIG")
  if [ "$perms" != "600" ]; then
    warn "Config permissions are $perms (should be 600)"
    if [ "$FIX_MODE" = true ]; then
      log "Fixing config permissions..."
      chmod 600 "$RCLONE_CONFIG"
      qlog "✓ Fixed config permissions"
    fi
    update_health "WARNING" 5
  fi
  
  # Check if backup remote exists
  if ! rclone listremotes | grep -q "^${BACKUP_REMOTE}:"; then
    error "Backup remote '$BACKUP_REMOTE' not configured"
    error "Available remotes:"
    rclone listremotes | sed 's/^/  /'
    update_health "CRITICAL" 50
    return 1
  fi
  
  vlog "✓ Backup remote '$BACKUP_REMOTE' configured"
  return 0
}

# Check remote connectivity
check_connectivity() {
  qlog "Checking remote connectivity..."
  
  if ! rclone lsf "${BACKUP_REMOTE}:" --max-depth 1 >/dev/null 2>&1; then
    error "Cannot connect to remote '$BACKUP_REMOTE'"
    error "Check network connection and credentials"
    update_health "ERROR" 30
    return 1
  fi
  
  vlog "✓ Remote '$BACKUP_REMOTE' accessible"
  return 0
}

# Check systemd services
check_services() {
  qlog "Checking systemd backup services..."
  
  local services=("rclone-backup-critical" "rclone-backup-projects" "rclone-backup-infra")
  local service_issues=0
  
  for service in "${services[@]}"; do
    # Check if service file exists
    if ! systemctl --user cat "${service}.service" >/dev/null 2>&1; then
      warn "Service not found: ${service}.service"
      if [ "$FIX_MODE" = true ]; then
        warn "Run: home-manager switch --flake ~/git/home"
      fi
      update_health "WARNING" 10
      service_issues=$((service_issues + 1))
      continue
    fi
    
    # Check if timer exists and is enabled
    if ! systemctl --user is-enabled "${service}.timer" >/dev/null 2>&1; then
      warn "Timer not enabled: ${service}.timer"
      if [ "$FIX_MODE" = true ]; then
        log "Enabling timer: ${service}.timer"
        systemctl --user enable "${service}.timer"
      fi
      update_health "WARNING" 5
    fi
    
    # Check last run status
    if systemctl --user is-failed "${service}.service" >/dev/null 2>&1; then
      error "Service failed: ${service}.service"
      if [ "$VERBOSE" = true ]; then
        echo "Last 5 lines of service log:"
        systemctl --user status "${service}.service" -n 5 --no-pager | tail -n 5
      fi
      update_health "ERROR" 15
      service_issues=$((service_issues + 1))
    fi
    
    vlog "✓ Service OK: ${service}"
  done
  
  if [ $service_issues -eq 0 ]; then
    vlog "✓ All systemd services configured"
  fi
  
  return 0
}

# Check backup directories and permissions
check_directories() {
  qlog "Checking backup directories..."
  
  local dirs=(
    "$HOME/.local/share/rclone"
    "$HOME/.local/share/rclone/logs"
    "$HOME/.config/rclone"
  )
  
  for dir in "${dirs[@]}"; do
    if [ ! -d "$dir" ]; then
      warn "Directory missing: $dir"
      if [ "$FIX_MODE" = true ]; then
        log "Creating directory: $dir"
        mkdir -p "$dir"
        chmod 700 "$dir"
        qlog "✓ Created directory: $dir"
      fi
      update_health "WARNING" 5
    else
      vlog "✓ Directory exists: $dir"
    fi
  done
  
  return 0
}

# Check recent backup logs
check_logs() {
  qlog "Checking recent backup logs..."
  
  if [ ! -d "$LOG_DIR" ]; then
    warn "Log directory missing: $LOG_DIR"
    update_health "WARNING" 10
    return 1
  fi
  
  # Check for recent critical backup
  local critical_log
  critical_log=$(find "$LOG_DIR" -name "critical-*.log" -mtime -1 | head -n1)
  
  if [ -z "$critical_log" ]; then
    warn "No recent critical backup logs (last 24h)"
    update_health "WARNING" 10
  else
    # Check if last backup was successful
    if tail -n 20 "$critical_log" | grep -q "ERROR\|Failed\|failed"; then
      error "Recent critical backup had errors"
      if [ "$VERBOSE" = true ]; then
        echo "Last 5 lines of critical backup log:"
        tail -n 5 "$critical_log"
      fi
      update_health "ERROR" 20
    else
      vlog "✓ Recent critical backup successful"
    fi
  fi
  
  return 0
}

# Test backup/restore cycle
test_backup_restore() {
  qlog "Running backup/restore test..."
  
  local test_dir="/tmp/rclone-test-$$"
  local test_file="$test_dir/test-backup-$(date +%s).txt"
  local remote_test_dir="test-$(date +%s)"
  
  # Create test data
  mkdir -p "$test_dir"
  echo "Backup test data - $(date)" > "$test_file"
  echo "Hostname: $(hostname)" >> "$test_file"
  echo "User: $(whoami)" >> "$test_file"
  
  # Test upload
  log "Testing backup upload..."
  if ! rclone copy "$test_dir" "${BACKUP_REMOTE}:${remote_test_dir}/"; then
    error "Backup upload failed"
    rm -rf "$test_dir"
    update_health "ERROR" 25
    return 1
  fi
  
  # Verify upload
  log "Verifying upload..."
  local remote_files
  remote_files=$(rclone ls "${BACKUP_REMOTE}:${remote_test_dir}/" | wc -l)
  if [ "$remote_files" -eq 0 ]; then
    error "No files found in remote backup"
    rm -rf "$test_dir"
    update_health "ERROR" 25
    return 1
  fi
  
  # Test download
  log "Testing backup restore..."
  local restore_dir="/tmp/rclone-restore-$$"
  if ! rclone copy "${BACKUP_REMOTE}:${remote_test_dir}/" "$restore_dir"; then
    error "Backup restore failed"
    rm -rf "$test_dir" "$restore_dir"
    update_health "ERROR" 25
    return 1
  fi
  
  # Verify restore
  log "Verifying restore..."
  if ! diff "$test_file" "$restore_dir/$(basename "$test_file")" >/dev/null 2>&1; then
    error "Restored file differs from original"
    rm -rf "$test_dir" "$restore_dir"
    update_health "ERROR" 25
    return 1
  fi
  
  # Cleanup
  rclone delete "${BACKUP_REMOTE}:${remote_test_dir}/" >/dev/null 2>&1 || true
  rm -rf "$test_dir" "$restore_dir"
  
  qlog "✓ Backup/restore test successful"
  return 0
}

# Generate status report
generate_report() {
  local timestamp
  timestamp=$(date -Iseconds)
  
  # Create JSON status file
  cat > "$STATUS_FILE" <<EOF
{
  "timestamp": "$timestamp",
  "health_status": "$HEALTH_STATUS",
  "health_score": $HEALTH_SCORE,
  "remote": "$BACKUP_REMOTE",
  "issues_found": $ISSUES_FOUND,
  "warnings_found": $WARNINGS_FOUND,
  "last_check": "$timestamp"
}
EOF
  
  # Console summary
  echo ""
  echo "╔════════════════════════════════════════════════════╗"
  printf "║ %-50s ║\n" "BACKUP HEALTH REPORT"
  echo "╠════════════════════════════════════════════════════╣"
  
  local status_color="$GREEN"
  case "$HEALTH_STATUS" in
    "WARNING") status_color="$YELLOW" ;;
    "ERROR") status_color="$RED" ;;
    "CRITICAL") status_color="$RED" ;;
  esac
  
  printf "║ Status: ${status_color}%-43s${NC} ║\n" "$HEALTH_STATUS"
  printf "║ Score:  %-43s ║\n" "$HEALTH_SCORE/100"
  printf "║ Remote: %-43s ║\n" "$BACKUP_REMOTE"
  printf "║ Issues: %-43s ║\n" "$ISSUES_FOUND errors, $WARNINGS_FOUND warnings"
  printf "║ Time:   %-43s ║\n" "$(date)"
  echo "╚════════════════════════════════════════════════════╝"
  echo ""
  
  if [ "$HEALTH_STATUS" != "HEALTHY" ]; then
    echo "Recommendations:"
    if [ $ISSUES_FOUND -gt 0 ] || [ $WARNINGS_FOUND -gt 0 ]; then
      echo "  • Run with --fix to attempt automatic repairs"
      echo "  • Check systemd service logs: journalctl --user -u rclone-backup-critical"
      echo "  • Verify rclone configuration: rclone config"
    fi
    if [ "$HEALTH_STATUS" = "CRITICAL" ]; then
      echo "  • URGENT: Backup system is not functional"
      echo "  • Run setup script: ~/git/geckoforge/scripts/setup-rclone.sh"
    fi
    echo ""
  fi
}

# Main execution
main() {
  if [ "$QUIET" = false ]; then
    echo "Geckoforge Backup Health Check"
    echo "Remote: $BACKUP_REMOTE"
    echo ""
  fi
  
  # Run checks
  check_rclone
  check_config
  check_connectivity
  check_services
  check_directories
  check_logs
  
  # Optional full test
  if [ "$TEST_MODE" = true ]; then
    test_backup_restore
  fi
  
  # Generate report
  generate_report
  
  # Exit with appropriate code
  case "$HEALTH_STATUS" in
    "HEALTHY")
      exit $EXIT_SUCCESS
      ;;
    "WARNING")
      exit $EXIT_WARNING
      ;;
    "ERROR")
      exit $EXIT_ERROR
      ;;
    "CRITICAL")
      exit $EXIT_CRITICAL
      ;;
  esac
}

# Handle Ctrl+C
trap 'error "Health check interrupted"; exit 130' INT

# Run main function
main "$@"