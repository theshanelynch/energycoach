#!/usr/bin/env bash
set -euo pipefail

# Data directory management script
# This script helps manage shared data between integrations

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Load configuration
if [[ -f "${SCRIPT_DIR}/env.example" ]]; then
  source "${SCRIPT_DIR}/env.example"
fi

# Default data directory
DATA_DIR="${DATA_DIR:-${SCRIPT_DIR}}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Ensure data directory structure exists
ensure_structure() {
  log_info "Ensuring data directory structure..."
  
  mkdir -p "${DATA_DIR}/esb"
  mkdir -p "${DATA_DIR}/homeassistant/sensors"
  mkdir -p "${DATA_DIR}/homeassistant/states"
  mkdir -p "${DATA_DIR}/solix"
  mkdir -p "${DATA_DIR}/shared/forecasts"
  
  log_success "Data directory structure created"
}

# Check data freshness
check_freshness() {
  log_info "Checking data freshness..."
  
  echo "ESB Usage Data:"
  if [[ -f "${DATA_DIR}/esb/usage_raw.json" ]]; then
    ls -la "${DATA_DIR}/esb/usage_raw.json"
    # Check if data contains errors
    if grep -q "\[FAILED\]\|Unable to get full set of required cookies\|captcha\|too many retries" "${DATA_DIR}/esb/usage_raw.json" 2>/dev/null; then
      log_warning "ESB data contains error messages - may be stale"
    fi
  else
    log_warning "ESB usage data not found"
  fi
  
  echo -e "\nSolix Battery Data:"
  if [[ -f "${DATA_DIR}/solix/battery.json" ]]; then
    ls -la "${DATA_DIR}/solix/battery.json"
  else
    log_warning "Solix battery data not found"
  fi
  
  echo -e "\nEnergy Plan:"
  if [[ -f "${DATA_DIR}/shared/energy_plan.json" ]]; then
    ls -la "${DATA_DIR}/shared/energy_plan.json"
  else
    log_warning "Energy plan not found"
  fi
}

# Clean old data
cleanup() {
  log_info "Cleaning up old data..."
  
  # Remove files older than 7 days
  find "${DATA_DIR}" -name "*.json" -mtime +7 -delete 2>/dev/null || true
  
  log_success "Cleanup completed"
}

# Clean failed/error data
clean_failed() {
  log_info "Cleaning failed/error data..."
  
  # Remove failed ESB data
  if [[ -f "${DATA_DIR}/esb/usage_raw.json" ]]; then
    if grep -q "\[FAILED\]\|Unable to get full set of required cookies\|captcha\|too many retries" "${DATA_DIR}/esb/usage_raw.json" 2>/dev/null; then
      log_warning "Removing failed ESB data"
      rm -f "${DATA_DIR}/esb/usage_raw.json"
      log_success "Failed ESB data removed"
    else
      log_info "ESB data appears valid"
    fi
  else
    log_info "No ESB data file found"
  fi
  
  # Check for other failed data patterns
  local failed_count=0
  for file in $(find "${DATA_DIR}" -name "*.json" -type f 2>/dev/null); do
    if grep -l "ERROR\|FAILED\|Exception\|Traceback" "$file" > /dev/null 2>&1; then
      log_warning "Found failed data in: $file"
      failed_count=$((failed_count + 1))
    fi
  done
  
  if [[ $failed_count -eq 0 ]]; then
    log_success "No failed data found"
  else
    log_warning "Found $failed_count files with error indicators"
  fi
  
  log_success "Failed data cleanup completed"
}

# Show data directory size
show_size() {
  log_info "Data directory sizes:"
  du -sh "${DATA_DIR}"/* 2>/dev/null || true
}

# Export data for other services
export_data() {
  local service="$1"
  local target_dir="$2"
  
  if [[ -z "$service" || -z "$target_dir" ]]; then
    log_error "Usage: export_data <service> <target_directory>"
    return 1
  fi
  
  log_info "Exporting $service data to $target_dir..."
  
  case "$service" in
    "esb")
      if [[ -f "${DATA_DIR}/esb/usage_raw.json" ]]; then
        mkdir -p "$target_dir"
        cp "${DATA_DIR}/esb/usage_raw.json" "$target_dir/"
        log_success "ESB data exported"
      else
        log_warning "ESB data not available"
      fi
      ;;
    "solix")
      if [[ -f "${DATA_DIR}/solix/battery.json" ]]; then
        mkdir -p "$target_dir"
        cp "${DATA_DIR}/solix/"*.json "$target_dir/"
        log_success "Solix data exported"
      else
        log_warning "Solix data not available"
      fi
      ;;
    *)
      log_error "Unknown service: $service"
      return 1
      ;;
  esac
}

# Show help
show_help() {
  cat << EOF
Data Directory Management Script

Usage: $0 [COMMAND]

Commands:
  ensure      Create data directory structure
  check       Check data freshness
  cleanup     Remove old data files
  clean-failed Remove failed/error data files
  size        Show directory sizes
  export      Export data to another location
  help        Show this help message

Examples:
  $0 ensure                    # Create directory structure
  $0 check                    # Check data freshness
  $0 cleanup                  # Clean old data
  $0 clean-failed             # Remove failed data
  $0 export esb /tmp/esb      # Export ESB data to /tmp/esb
  $0 export solix /tmp/solix  # Export Solix data to /tmp/solix

Environment Variables:
  DATA_DIR                    # Base data directory (default: ./data)
  ESB_DATA_DIR               # ESB data directory
  HA_DATA_DIR                # Home Assistant data directory
  SOLIX_DATA_DIR             # Solix data directory
  SHARED_DATA_DIR            # Shared data directory
EOF
}

# Main script logic
main() {
  case "${1:-help}" in
    "ensure")
      ensure_structure
      ;;
    "check")
      check_freshness
      ;;
    "cleanup")
      cleanup
      ;;
    "clean-failed")
      clean_failed
      ;;
    "size")
      show_size
      ;;
    "export")
      export_data "$2" "$3"
      ;;
    "help"|*)
      show_help
      ;;
  esac
}

# Run main function with all arguments
main "$@"
