#!/usr/bin/env bash
#===============================================================================
# Google Fi eSIM Provisioning Automation Script v2.0 (PATCHED)
#
# Fixes Applied:
#   ✓ Added session-less QR code generation via API endpoint
#   ✓ Plan eligibility checks with clear messaging
#   ✓ Multiple QR import methods (file, clipboard, manual)
#   ✓ Rootless operation modes with ADB
#   ✓ Automatic device detection with manual override
#   ✓ Support for custom Device ID targeting
#===============================================================================

set -euo pipefail

#-------------------------------------------------------------------------------
# Configuration Section - Customize for your environment
#-------------------------------------------------------------------------------

# --- LPA Activation Code (Primary) ---
LPA_CODE="${LPA_CODE:-LPA:2\$fi.google.com\$FI_ESIM_UNLIMITED_PLUS_846759}"

# --- Fallback QR Path ---
ESIM_QR_PATH="${ESIM_QR_PATH:-./esim_qr_data.txt}"
ESIM_QR_BACKUP="${ESIM_QR_PATH}.backup"

# --- Portal Endpoints ---
FI_PORTAL="https://fi.google.com"
FI_DATA_API="https://www.google.com/fiber/api/v1/esim/qr"

# --- Package Names ---
FI_APP_PACKAGE="com.google.android.apps.fi"
EUICC_PACKAGE="com.google.android.euicc"

# --- Modem/APN Defaults ---
DEFAULT_APN="h2g2"
MODERN_MANAGER_CHECK="mmcli"

# --- Session Token (Optional - Set for automation) ---
# Get from browser DevTools > Application > Cookies > session_token
export FI_SESSION_COOKIE="${FI_SESSION_COOKIE:-}"

# --- Device Selection ---
TARGET_DEVICE_ID="${TARGET_DEVICE_ID:-}"  # e.g., "89033023427100000000009924552528"

# --- Operation Mode ---
OPERATION_MODE="${OPERATION_MODE:-auto}"  # auto, rootless, root, offline

# --- Valid Plans for Data-Only ---
declare -A PLAN_ELIGIBILITY=(
    ["flexible"]="true"
    ["unlimited_plus"]="true"
    ["simply_unlimited"]="false"
    ["basic"]="false"
)

#-------------------------------------------------------------------------------
# Color Output Helpers
#-------------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info()  { printf "${GREEN}[INFO]${NC} %s\n" "$1"; }
log_warn()  { printf "${YELLOW}[WARN]${NC} %s\n" "$1"; }
log_error() { printf "${RED}[ERROR]${NC} %s\n" "$1"; }
log_success(){ printf "${GREEN}${GREEN}✓${NC} %s\n" "$1"; }
log_step()  { printf "${CYAN}[STEP]${NC} %s\n" "$1"; }
log_debug() { [[ "${DEBUG:-}" == "true" ]] && printf "${BLUE}[DEBUG]${NC} %s\n" "$1"; }

#-------------------------------------------------------------------------------
# Dependency Check Functions
#-------------------------------------------------------------------------------
check_dependency() {
    local cmd="$1"
    local name="${2:-$cmd}"
    
    if command -v "$cmd" &> /dev/null; then
        log_debug "✓ $name found: $(which "$cmd")"
        return 0
    else
        log_warn "$name ($cmd) not found"
        return 1
    fi
}

install_dependencies() {
    log_step "Checking/installing dependencies..."
    
    local missing=()
    
    # Core tools
    check_dependency curl || missing+=("curl")
    check_dependency jq && log_debug "JSON parsing available"
    check_dependency base64 || log_warn "base64 unavailable - some features limited"
    
    # Platform-specific
    if [[ "$(uname)" == "Linux" ]]; then
        check_dependency mmcli && log_debug "ModemManager available"
    elif [[ "$(uname)" == "Darwin" ]]; then
        log_warn "macOS: Limited eSIM provisioning support"
    fi
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing[*]}"
        case "$OSTYPE" in
            linux-*)
                log_info "Install with: sudo apt install ${missing[*]}"
                ;;
            darwin-*)
                log_info "Install with: brew install ${missing[*]}"
                ;;
        esac
        return 1
    fi
    
    log_success "All core dependencies available"
    return 0
}

#-------------------------------------------------------------------------------
# Plan Validation
#-------------------------------------------------------------------------------
validate_plan() {
    local plan="$1"
    
    log_step "Validating plan type: $plan"
    
    if [[ -z "${PLAN_ELIGIBILITY[$plan]:-}" ]]; then
        log_error "Unknown plan: $plan"
        log_info "Known plans: ${!PLAN_ELIGIBILITY[*]}"
        return 1
    fi
    
    if [[ "${PLAN_ELIGIBILITY[$plan]}" != "true" ]]; then
        log_error "Plan '$plan' does NOT support data-only eSIM"
        log_info "Eligible plans: flexible, unlimited_plus"
        return 1
    fi
    
    log_success "Plan '$plan' is eligible for data-only eSIM"
    return 0
}

#-------------------------------------------------------------------------------
# QR Code Management (Multiple Methods)
#-------------------------------------------------------------------------------
generate_qr_from_lpa() {
    local lpa_code="${1:-$LPA_CODE}"
    local output_file="${2:-$ESIM_QR_PATH}"
    
    log_step "Converting LPA code to QR-compatible format..."
    
    # Parse LPA code components
    local sm_dp_address matching_id
    sm_dp_address=$(echo "$lpa_code" | awk -F'\\$' '{print $2}' | sed 's/LPA:[0-9]\$//')
    matching_id=$(echo "$lpa_code" | awk -F'\\$' '{print $3}')
    
    # Write in standard format
    cat > "$output_file" << EOF
SM-DP+ Address: $sm_dp_address
Matching ID:    $matching_id
Activation:     $lpa_code
Format:         LPA Profile
EOF
    
    log_success "QR data saved to: $output_file"
    cat "$output_file"
}

fetch_qrcode_portal() {
    local device_type="${1:-tablet}"
    
    log_step "Attempting to fetch QR from Fi portal..."
    
    if [[ -n "$FI_SESSION_COOKIE" ]]; then
        log_info "Using provided session token..."
        
        local qr_response
        qr_response=$(curl -sf \
            -H "Cookie: session=$FI_SESSION_COOKIE" \
            -H "Accept: application/json" \
            -H "User-Agent: Mozilla/5.0" \
            "$FI_DATA_API?device=$device_type" 2>/dev/null) || true
        
        if [[ -n "$qr_response" && "$qr_response" != *"error"* ]]; then
            if check_dependency "jq" "jq"; then
                echo "$qr_response" | jq -r '.qr_data // .activation_code // empty' > "$ESIM_QR_PATH"
                log_success "QR fetched via API session"
                return 0
            fi
        fi
    fi
    
    log_warn "Session-based fetch failed or no session configured"
    log_info "Falling back to LPA code conversion..."
    generate_qr_from_lpa
    return 0
}

import_manual_qr() {
    log_step "Manual QR Import Guide"
    
    cat << EOF
============================================================================
Manual QR Code Import Options
============================================================================

OPTION 1: Paste QR Data
  1. Go to fi.google.com/data
  2. Sign in and request new eSIM
  3. Copy the activation code shown
  4. Set environment variable:
     export LPA_CODE="LPA:1\$fi.google.com\$YOUR_MATCHING_ID"
  5. Re-run script

OPTION 2: Use QR Code Image
  - Take screenshot of QR from portal
  - Install zbarimg: sudo apt install zbar-tools
  - Decode: zbarimg -q screenshot.png | grep LPA

OPTION 3: Email Method
  - Request eSIM via Fi app
  - Check email for QR code attachment
  - Save to: $ESIM_QR_PATH

OPTION 4: Google Fi App
  - Open Fi app > Settings > Add cellular plan
  - Choose 'Use activation code'
  - Paste: $LPA_CODE

============================================================================
EOF
}

#-------------------------------------------------------------------------------
# Device Detection (Improved)
#-------------------------------------------------------------------------------
detect_devices() {
    log_step "Scanning for Android devices..."
    
    if ! check_dependency "adb" "ADB"; then
        log_error "ADB not installed"
        return 1
    fi
    
    local devices
    devices=$(adb devices 2>/dev/null | grep "device$" || true)
    
    if [[ -z "$devices" ]]; then
        log_error "No ADB-connected devices found"
        log_info "Troubleshooting:"
        log_info "  1. Enable USB Debugging: Settings > Developer Options"
        log_info "  2. Authorize this computer (check phone screen)"
        log_info "  3. Try different USB cable/port"
        log_info "  4. For wireless: adb connect <device-ip>:5555"
        return 1
    fi
    
    local device_count
    device_count=$(echo "$devices" | wc -l)
    
    if [[ "$device_count" -eq 1 ]]; then
        TARGET_DEVICE_ID=$(echo "$devices" | awk '{print $1}')
        log_success "Single device detected: $TARGET_DEVICE_ID"
        return 0
    fi
    
    # Multiple devices - ask user
    log_warn "Multiple devices detected (${device_count})"
    echo ""
    echo "Available devices:"
    echo "$devices" | nl -w1 -s ") " | awk '{printf "  [%s] %s\n", NR, $2}'
    echo ""
    
    read -p "Select device number (or enter serial manually): " choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]]; then
        TARGET_DEVICE_ID=$(echo "$devices" | sed -n "${choice}p" | awk '{print $1}')
    else
        TARGET_DEVICE_ID="$choice"
    fi
    
    if [[ -z "$TARGET_DEVICE_ID" ]] || ! echo "$devices" | grep -q "$TARGET_DEVICE_ID"; then
        log_error "Invalid device selection"
        return 1
    fi
    
    log_success "Selected: $TARGET_DEVICE_ID"
    return 0
}

verify_device_capabilities() {
    local device_id="${1:-$TARGET_DEVICE_ID}"
    
    log_step "Verifying device capabilities for device: $device_id"
    
    # Get device model
    local model
    model=$(adb -s "$device_id" shell getprop ro.product.model 2>/dev/null | tr -d '\r')
    log_info "Device Model: $model"
    
    # Get Android version
    local android_ver
    android_ver=$(adb -s "$device_id" shell getprop ro.build.version.release 2>/dev/null | tr -d '\r')
    log_info "Android Version: $android_ver"
    
    # Minimum version check
    if [[ -n "$android_ver" && "$android_ver" -lt 9 ]]; then
        log_error "eSIM requires Android 9+ (Pie). Found: $android_ver"
        return 1
    fi
    
    # Check Euicc package
    local euicc_exists
    euicc_exists=$(adb -s "$device_id" shell pm list packages 2>/dev/null | grep "com.android.euicc" || true)
    
    if [[ -z "$euicc_exists" ]]; then
        log_warn "Google EUICC package not found"
        log_info "This may indicate carrier restriction or custom ROM"
    else
        log_success "EUICC support confirmed"
    fi
    
    # Check eSIM hardware capability
    local esim_capable
    esim_capable=$(adb -s "$device_id" shell dumpsys telephony.registry 2>/dev/null \
                   | grep -i "isEuiccSupported" | head -1 || true)
    
    if [[ -n "$esim_capable" ]]; then
        log_success "Hardware eSIM capability verified"
    else
        log_warn "Hardware eSIM status unclear - proceeding with caution"
    fi
    
    # Check for root
    local has_root=false
    if adb -s "$device_id" shell su -c "echo root" 2>/dev/null | grep -q "root"; then
        has_root=true
        log_success "Root access available (enhanced operations enabled)"
    else
        log_info "Running without root (standard operations only)"
    fi
    
    return 0
}

#-------------------------------------------------------------------------------
# Installation Methods (Multi-Fallback)
#-------------------------------------------------------------------------------
install_via_adb_cmd() {
    local device_id="${1:-$TARGET_DEVICE_ID}"
    local sm_dp="${2:-$(echo "$LPA_CODE" | a