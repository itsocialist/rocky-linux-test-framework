#!/bin/bash

#####################################################################
# Rocky Linux Test Framework Deployment Script
# Deploy comprehensive VM testing framework with enhanced capabilities
# Usage: ./deploy.sh [command]
#####################################################################

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config/server-config.sh"

log() { echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $*"; }
success() { echo -e "${GREEN}✓${NC} $*"; }
error() { echo -e "${RED}✗${NC} $*"; exit 1; }
warning() { echo -e "${YELLOW}⚠${NC} $*"; }

show_help() {
    echo "Rocky Linux Test Framework Deployment Script"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  deploy         Deploy complete framework (default)"
    echo "  verify         Verify existing deployment"
    echo "  status         Get current framework status"
    echo "  help           Show this help message"
    echo ""
    echo "Framework Capabilities:"
    echo "  • VM management and testing"
    echo "  • Boot detection and validation"
    echo "  • AI/GPU workload testing"
    echo "  • Container runtime validation"
    echo "  • JSON API for automation"
    echo "  • MCP integration for Claude"
    echo ""
    echo "Configuration:"
    echo "  Edit config/server-config.sh for server details"
}

# Load configuration
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        log "Loading configuration from $CONFIG_FILE"
        source "$CONFIG_FILE"
    else
        error "Configuration file not found: $CONFIG_FILE. Please create it from config/server-config.example.sh"
    fi
    
    # Validate required variables
    if [[ -z "${DELL_SERVER_IP:-}" || -z "${DELL_SERVER_USER:-}" || -z "${SSH_KEY_PATH:-}" ]]; then
        error "Configuration incomplete. Please edit $CONFIG_FILE with server details."
    fi
    
    log "Target server: $DELL_SERVER_USER@$DELL_SERVER_IP"
    log "SSH key: $SSH_KEY_PATH"
}

# Verify prerequisites
verify_prerequisites() {
    log "Verifying prerequisites..."
    
    # Check SSH key
    if [[ ! -f "$SSH_KEY_PATH" ]]; then
        error "SSH key not found: $SSH_KEY_PATH"
    fi
    
    # Check required scripts
    local required_scripts=(
        "scripts/01-install-packages.sh"
        "scripts/02-setup-vm-manager.sh" 
        "scripts/03-setup-remote-controller.sh"
        "scripts/04-configure-system.sh"
    )
    
    for script in "${required_scripts[@]}"; do
        if [[ ! -f "$SCRIPT_DIR/$script" ]]; then
            error "Required script not found: $script"
        fi
    done
    
    # Test SSH connection
    log "Testing SSH connection..."
    if ! ssh -i "$SSH_KEY_PATH" -o ConnectTimeout=10 "$DELL_SERVER_USER@$DELL_SERVER_IP" 'echo "Connection successful"' >/dev/null 2>&1; then
        error "Cannot connect to server. Check SSH configuration."
    fi
    
    success "All prerequisites verified"
}

# Deploy script to server
deploy_script() {
    local script_name="$1"
    local script_path="$SCRIPT_DIR/$script_name"
    local script_basename="$(basename "$script_name")"
    
    log "Deploying $script_basename..."
    
    # Copy script to server
    scp -i "$SSH_KEY_PATH" "$script_path" "$DELL_SERVER_USER@$DELL_SERVER_IP:/tmp/$script_basename" || {
        error "Failed to upload $script_basename"
    }
    
    # Make executable and run with interactive sudo (preserves TTY for password prompt)
    log "Executing $script_basename (you may be prompted for sudo password)..."
    ssh -t -i "$SSH_KEY_PATH" "$DELL_SERVER_USER@$DELL_SERVER_IP" "
        chmod +x /tmp/$script_basename
        sudo /tmp/$script_basename
        rm -f /tmp/$script_basename
    " || {
        error "Failed to execute $script_basename"
    }
    
    success "$script_basename completed successfully"
}

# Verify deployment
verify_deployment() {
    log "Verifying deployment..."
    
    # Test framework readiness
    log "Testing framework readiness..."
    local ready_status
    ready_status=$(ssh -i "$SSH_KEY_PATH" "$DELL_SERVER_USER@$DELL_SERVER_IP" \
        'remote-test-controller ready 2>/dev/null || echo "false"')
    
    if [[ "$ready_status" != "true" ]]; then
        error "Framework readiness check failed"
    fi
    
    # Test JSON API
    log "Testing JSON API..."
    local api_test
    api_test=$(ssh -i "$SSH_KEY_PATH" "$DELL_SERVER_USER@$DELL_SERVER_IP" \
        'remote-test-controller status 2>/dev/null | jq -r .ready 2>/dev/null || echo "false"')
    
    if [[ "$api_test" != "true" ]]; then
        error "JSON API test failed"
    fi
    
    # Test helper commands
    log "Testing helper commands..."
    local helper_test
    helper_test=$(ssh -i "$SSH_KEY_PATH" "$DELL_SERVER_USER@$DELL_SERVER_IP" \
        'test-status >/dev/null 2>&1 && echo "true" || echo "false"')
    
    if [[ "$helper_test" != "true" ]]; then
        warning "Helper commands may not be fully functional"
    fi
    
    success "Framework verification completed"
}

# Get framework status
get_status() {
    log "Getting framework status..."
    
    local status_output
    status_output=$(ssh -i "$SSH_KEY_PATH" "$DELL_SERVER_USER@$DELL_SERVER_IP" \
        'remote-test-controller status 2>/dev/null' || echo '{"error": "Status unavailable"}')
    
    echo "$status_output" | jq . 2>/dev/null || echo "$status_output"
}

# Main deployment function
deploy_framework() {
    echo
    echo -e "${BLUE}🚀 Rocky Linux Test Framework Deployment${NC}"
    echo -e "${BLUE}===========================================${NC}"
    echo
    
    load_config
    verify_prerequisites
    
    echo
    log "Starting deployment sequence..."
    echo
    
    # Deploy framework components in order
    deploy_script "scripts/01-install-packages.sh"
    deploy_script "scripts/02-setup-vm-manager.sh"
    deploy_script "scripts/03-setup-remote-controller.sh"
    deploy_script "scripts/04-configure-system.sh"
    
    # Verify everything works
    verify_deployment
    
    echo
    echo -e "${GREEN}🎉 FRAMEWORK DEPLOYMENT COMPLETED! 🎉${NC}"
    echo
    success "Framework deployed with the following capabilities:"
    echo "   ✅ VM management and testing"
    echo "   ✅ Boot detection and validation" 
    echo "   ✅ AI/GPU workload testing"
    echo "   ✅ Container runtime validation"
    echo "   ✅ JSON API for automation"
    echo "   ✅ MCP integration ready for Claude"
    echo
    success "Framework is ready for testing!"
    echo
    echo -e "${YELLOW}Quick Test:${NC}"
    echo "   ssh $DELL_SERVER_USER@$DELL_SERVER_IP 'remote-test-controller status'"
    echo
    echo -e "${YELLOW}Upload ISO and Test:${NC}"
    echo "   scp your-test.iso $DELL_SERVER_USER@$DELL_SERVER_IP:/var/lib/libvirt/isos/"
    echo "   ssh $DELL_SERVER_USER@$DELL_SERVER_IP 'remote-test-controller start-test /var/lib/libvirt/isos/your-test.iso'"
    echo
    echo -e "${YELLOW}Documentation:${NC}"
    echo "   📖 docs/API-REFERENCE.md - Complete command reference"
    echo "   🤖 docs/MCP-INTEGRATION.md - Claude integration guide"
    echo "   🔧 docs/TROUBLESHOOTING.md - Problem resolution"
    echo
}

# Handle command line arguments
case "${1:-deploy}" in
    "deploy")
        deploy_framework
        ;;
    "verify")
        load_config
        verify_deployment
        success "Deployment verification completed"
        ;;
    "status")
        load_config
        get_status
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        error "Unknown command: $1. Use 'help' for usage information."
        ;;
esac
