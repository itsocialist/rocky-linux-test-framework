#!/bin/bash

#####################################################################
# Enhanced Deploy Script - Rocky Linux Test Framework v1.2
# Purpose: Deploy framework with enhanced capabilities
# Usage: ./deploy.sh [--enhanced]
#####################################################################

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $*"; }
success() { echo -e "${GREEN}✓${NC} $*"; }
error() { echo -e "${RED}✗${NC} $*"; exit 1; }
warning() { echo -e "${YELLOW}⚠${NC} $*"; }

echo "========================================"
echo "Rocky Linux Test Framework Deployment"
echo "Enhanced v1.2 with Screenshot & SSH"
echo "========================================"

# Parse command line arguments
ENHANCED_MODE=false
if [[ "${1:-}" == "--enhanced" ]]; then
    ENHANCED_MODE=true
    log "Enhanced mode enabled - will deploy advanced capabilities"
fi

# Check configuration
config_file="config/server-config.sh"

if [[ ! -f "$config_file" ]]; then
    error "Configuration file not found: $config_file"
fi

# Load configuration
log "Loading configuration from $config_file"
source "$config_file"

# Validate configuration
if [[ -z "${DELL_SERVER_IP:-}" || -z "${DELL_SERVER_USER:-}" || -z "${SSH_KEY_PATH:-}" ]]; then
    error "Configuration incomplete. Please edit $config_file"
fi

if [[ ! -f "$SSH_KEY_PATH" ]]; then
    error "SSH key not found: $SSH_KEY_PATH"
fi

# Test SSH connection
log "Testing SSH connection to ${DELL_SERVER_USER}@${DELL_SERVER_IP}..."
if ! ssh -i "$SSH_KEY_PATH" -o ConnectTimeout=10 -o BatchMode=yes \
    "${DELL_SERVER_USER}@${DELL_SERVER_IP}" "echo 'SSH connection successful'" >/dev/null 2>&1; then
    error "SSH connection failed. Please check your configuration and SSH key setup."
fi

success "SSH connection verified"

# Determine which controller to use
CONTROLLER_SCRIPT="scripts/03-setup-remote-controller.sh"
if [[ "$ENHANCED_MODE" == "true" && -f "scripts/03-setup-remote-controller-enhanced.sh" ]]; then
    CONTROLLER_SCRIPT="scripts/03-setup-remote-controller-enhanced.sh"
    log "Using enhanced controller with screenshot and SSH capabilities"
fi

# Deploy framework
log "Deploying Rocky Linux Test Framework..."

# Upload and execute deployment scripts
scripts=(
    "scripts/01-install-packages.sh"
    "scripts/02-setup-vm-manager.sh"
    "$CONTROLLER_SCRIPT"
    "scripts/04-configure-system.sh"
)

for script in "${scripts[@]}"; do
    if [[ ! -f "$script" ]]; then
        warning "Script not found, skipping: $script"
        continue
    fi
    
    log "Uploading and executing: $script"
    
    # Upload script
    scp -i "$SSH_KEY_PATH" "$script" "${DELL_SERVER_USER}@${DELL_SERVER_IP}:/tmp/$(basename "$script")" || {
        error "Failed to upload $script"
    }
    
    # Execute script
    ssh -i "$SSH_KEY_PATH" "${DELL_SERVER_USER}@${DELL_SERVER_IP}" \
        "sudo bash /tmp/$(basename "$script")" || {
        error "Failed to execute $script"
    }
    
    success "Completed: $(basename "$script")"
done

# Post-deployment verification
log "Verifying deployment..."

# Test framework readiness
ssh -i "$SSH_KEY_PATH" "${DELL_SERVER_USER}@${DELL_SERVER_IP}" \
    "remote-test-controller ready" >/dev/null 2>&1 && {
    success "Framework is ready for testing"
} || {
    warning "Framework may not be fully ready - check logs"
}

# Test enhanced capabilities if deployed
if [[ "$ENHANCED_MODE" == "true" ]]; then
    log "Testing enhanced capabilities..."
    
    # Check enhanced status
    local enhanced_status
    enhanced_status=$(ssh -i "$SSH_KEY_PATH" "${DELL_SERVER_USER}@${DELL_SERVER_IP}" \
        "remote-test-controller status" 2>/dev/null || echo '{}')
    
    # Parse and verify enhanced features
    local framework_version
    framework_version=$(echo "$enhanced_status" | jq -r '.framework_version // "unknown"' 2>/dev/null || echo "unknown")
    
    if [[ "$framework_version" == "1.2-enhanced" ]]; then
        success "Enhanced framework v1.2 deployed successfully"
        
        # Display enhanced capabilities
        log "Enhanced capabilities available:"
        echo "  • Screenshot capture from VM consoles"
        echo "  • SSH tunneling to running VMs"
        echo "  • Arbitrary command execution in VMs"
        echo "  • Enhanced status reporting"
        
        # Test enhanced commands availability
        local enhanced_help
        enhanced_help=$(ssh -i "$SSH_KEY_PATH" "${DELL_SERVER_USER}@${DELL_SERVER_IP}" \
            "remote-test-controller" 2>/dev/null | grep -c "Enhanced Commands" || echo "0")
        
        if [[ "$enhanced_help" -gt 0 ]]; then
            success "Enhanced commands verified and available"
        else
            warning "Enhanced commands may not be fully available"
        fi
    else
        warning "Enhanced framework version not detected (got: $framework_version)"
    fi
fi

# Display usage information
echo
success "Deployment completed successfully!"
echo
echo "========================================"
echo "Framework Usage Information"
echo "========================================"
echo

if [[ "$ENHANCED_MODE" == "true" ]]; then
    echo "🚀 Enhanced Framework v1.2 Ready"
    echo
    echo "Standard Commands:"
    echo "  ssh ${DELL_SERVER_USER}@${DELL_SERVER_IP} 'remote-test-controller ready'"
    echo "  ssh ${DELL_SERVER_USER}@${DELL_SERVER_IP} 'remote-test-controller status'"
    echo "  ssh ${DELL_SERVER_USER}@${DELL_SERVER_IP} 'remote-test-controller start-test /path/to/iso'"
    echo
    echo "Enhanced Commands:"
    echo "  ssh ${DELL_SERVER_USER}@${DELL_SERVER_IP} 'remote-test-controller screenshot vm-name'"
    echo "  ssh ${DELL_SERVER_USER}@${DELL_SERVER_IP} 'remote-test-controller ssh-tunnel vm-name 2222'"
    echo "  ssh ${DELL_SERVER_USER}@${DELL_SERVER_IP} 'remote-test-controller execute vm-name \"nvidia-smi\"'"
    echo
    echo "Screenshots saved to: ~/vm-testing/screenshots/"
    echo "SSH tunnel usage: ssh -p 2222 root@${DELL_SERVER_IP}"
else
    echo "🎯 Standard Framework Ready"
    echo
    echo "Basic Commands:"
    echo "  ssh ${DELL_SERVER_USER}@${DELL_SERVER_IP} 'remote-test-controller ready'"
    echo "  ssh ${DELL_SERVER_USER}@${DELL_SERVER_IP} 'remote-test-controller status'"
    echo "  ssh ${DELL_SERVER_USER}@${DELL_SERVER_IP} 'remote-test-controller start-test /path/to/iso'"
    echo
    echo "To deploy enhanced capabilities, run: ./deploy.sh --enhanced"
fi

echo
echo "Quick Test:"
echo "  1. Upload ISO: scp test.iso ${DELL_SERVER_USER}@${DELL_SERVER_IP}:/var/lib/libvirt/isos/"
echo "  2. Start test: ssh ${DELL_SERVER_USER}@${DELL_SERVER_IP} 'remote-test-controller start-test /var/lib/libvirt/isos/test.iso'"
echo "  3. Check status: ssh ${DELL_SERVER_USER}@${DELL_SERVER_IP} 'remote-test-controller status'"
echo
echo "📖 Documentation: docs/ directory"
echo "🐛 Troubleshooting: docs/TROUBLESHOOTING.md"
echo "🤖 API Reference: docs/API-REFERENCE.md"
echo

# Save connection info for convenience
cat > .connection-info << EOF
# Rocky Linux Test Framework Connection Info
# Generated: $(date)

# SSH Connection
SERVER_IP="$DELL_SERVER_IP"
SERVER_USER="$DELL_SERVER_USER"
SSH_KEY="$SSH_KEY_PATH"

# Quick Connect
alias rocky-ssh="ssh -i $SSH_KEY_PATH $DELL_SERVER_USER@$DELL_SERVER_IP"
alias rocky-status="ssh -i $SSH_KEY_PATH $DELL_SERVER_USER@$DELL_SERVER_IP 'remote-test-controller status'"
alias rocky-ready="ssh -i $SSH_KEY_PATH $DELL_SERVER_USER@$DELL_SERVER_IP 'remote-test-controller ready'"

# Enhanced Commands (if deployed)
EOF

if [[ "$ENHANCED_MODE" == "true" ]]; then
    cat >> .connection-info << EOF
alias rocky-screenshot="ssh -i $SSH_KEY_PATH $DELL_SERVER_USER@$DELL_SERVER_IP 'remote-test-controller screenshot"
alias rocky-tunnel="ssh -i $SSH_KEY_PATH $DELL_SERVER_USER@$DELL_SERVER_IP 'remote-test-controller ssh-tunnel"
alias rocky-execute="ssh -i $SSH_KEY_PATH $DELL_SERVER_USER@$DELL_SERVER_IP 'remote-test-controller execute"
EOF
fi

echo "💡 Connection aliases saved to .connection-info"
echo "   Source it with: source .connection-info"

echo
success "🎉 Rocky Linux Test Framework is ready for use!"

if [[ "$ENHANCED_MODE" == "true" ]]; then
    echo
    echo "✨ Enhanced features deployed:"
    echo "   • VM console screenshots"
    echo "   • SSH access to running VMs"
    echo "   • Remote command execution"
    echo "   • Advanced debugging capabilities"
fi
