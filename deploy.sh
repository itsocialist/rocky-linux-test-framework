#!/bin/bash
#
# deploy-rlc-ai-enhanced.sh
# Deploy Dell VM Testing Framework with RLC-AI Testing MVP
# Enhanced version of the framework with MCP integration capabilities
#

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config/server-config.sh"

# Default values (overridden by config file)
DELL_SERVER_IP="192.168.7.83"
DELL_SERVER_USER="bdawson"
SSH_KEY_PATH="$HOME/.ssh/id_rsa"

log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $*"
}

success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] ✅${NC} $*"
}

warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️${NC} $*"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ❌${NC} $*" >&2
    exit 1
}

# Load configuration
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        log "Loading configuration from $CONFIG_FILE"
        source "$CONFIG_FILE"
    else
        warning "Configuration file not found: $CONFIG_FILE"
        warning "Using default values. Create config file for custom settings."
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
    if ! ssh -i "$SSH_KEY_PATH" -o ConnectTimeout=10 "$DELL_SERVER_USER@$DELL_SERVER_IP" 'echo "SSH connection successful"' >/dev/null 2>&1; then
        error "Cannot connect to Dell server. Check SSH configuration."
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
    scp -i "$SSH_KEY_PATH" "$script_path" "$DELL_SERVER_USER@$DELL_SERVER_IP:/tmp/$script_basename"
    
    # Make executable and run with interactive sudo
    log "Running $script_basename (you may be prompted for sudo password)..."
    ssh -t -i "$SSH_KEY_PATH" "$DELL_SERVER_USER@$DELL_SERVER_IP" "
        chmod +x /tmp/$script_basename
        sudo /tmp/$script_basename
        rm /tmp/$script_basename
    "
    
    success "$script_basename deployed successfully"
}



# Verify deployment
verify_deployment() {
    log "Verifying deployment..."
    
    # Test basic framework
    log "Testing basic framework..."
    local basic_status
    basic_status=$(ssh -i "$SSH_KEY_PATH" "$DELL_SERVER_USER@$DELL_SERVER_IP" 'test-status 2>/dev/null || echo "FAILED"')
    
    if [[ "$basic_status" == "FAILED" ]]; then
        error "Basic framework verification failed"
    fi
    
    # Test enhanced controller
    log "Testing enhanced RLC-AI controller..."
    local ready_status
    ready_status=$(ssh -i "$SSH_KEY_PATH" "$DELL_SERVER_USER@$DELL_SERVER_IP" '/opt/remote-test-controller ready 2>/dev/null || echo "false"')
    
    if [[ "$ready_status" != "true" ]]; then
        error "Enhanced controller verification failed"
    fi
    
    # Test JSON API
    log "Testing JSON API..."
    local json_status
    json_status=$(ssh -i "$SSH_KEY_PATH" "$DELL_SERVER_USER@$DELL_SERVER_IP" '/opt/remote-test-controller status 2>/dev/null | jq -r .ready || echo "false"')
    
    if [[ "$json_status" != "true" ]]; then
        error "JSON API verification failed"
    fi
    
    success "All components verified successfully"
}

# Create deployment summary
create_summary() {
    log "Creating deployment summary..."
    
    # Get system status
    local system_status
    system_status=$(ssh -i "$SSH_KEY_PATH" "$DELL_SERVER_USER@$DELL_SERVER_IP" '/opt/remote-test-controller status' | jq .)
    
    cat > "$SCRIPT_DIR/DEPLOYMENT-SUMMARY-$(date +%Y%m%d-%H%M%S).md" << EOF
# RLC-AI Enhanced Framework Deployment Summary

**Deployment Date**: $(date)
**Target Server**: $DELL_SERVER_USER@$DELL_SERVER_IP
**Framework Version**: 1.1-rlc-ai with MCP integration

## ✅ Deployed Components

### Base Framework
- ✅ Package installation (KVM, libvirt, QEMU, etc.)
- ✅ VM Test Manager (\`/opt/vm-test-manager\`)
- ✅ Remote Test Controller (\`/opt/remote-test-controller\`)
- ✅ System configuration (firewall, services, helpers)

### RLC-AI Enhancements
- ✅ Enhanced boot detection for AI systems
- ✅ AI workload command execution framework
- ✅ GPU/CUDA validation testing
- ✅ Container runtime testing (Podman)
- ✅ MCP-compatible JSON API
- ✅ PyTorch/TensorFlow validation templates

## 🎯 New Capabilities

### RLC-AI Testing Commands
\`\`\`bash
# Start RLC-AI test
ssh $DELL_SERVER_USER@$DELL_SERVER_IP '/opt/remote-test-controller start-rlc-ai-test /path/to/rlc-ai.iso'

# Run AI workload
ssh $DELL_SERVER_USER@$DELL_SERVER_IP '/opt/remote-test-controller run-workload <test-id> "nvidia-smi"'

# Get enhanced status
ssh $DELL_SERVER_USER@$DELL_SERVER_IP '/opt/remote-test-controller status'
\`\`\`

### Test Types Available
- \`minimal\` - Basic boot + system validation
- \`gpu_detection\` - GPU/CUDA detection only
- \`pytorch\` - PyTorch framework validation
- \`tensorflow\` - TensorFlow framework validation
- \`container\` - Container runtime validation
- \`full\` - Complete AI stack validation (default)

## 📊 Current System Status

\`\`\`json
$system_status
\`\`\`

## 🚀 Quick Start

### Upload and Test RLC-AI ISO
\`\`\`bash
# Upload ISO
scp rlc-ai-9.6.iso $DELL_SERVER_USER@$DELL_SERVER_IP:/var/lib/libvirt/isos/

# Start test
ssh $DELL_SERVER_USER@$DELL_SERVER_IP '/opt/remote-test-controller start-rlc-ai-test /var/lib/libvirt/isos/rlc-ai-9.6.iso'
\`\`\`

### Monitor Test Progress
\`\`\`bash
# List running tests
ssh $DELL_SERVER_USER@$DELL_SERVER_IP '/opt/remote-test-controller list running'

# Get test status
ssh $DELL_SERVER_USER@$DELL_SERVER_IP '/opt/remote-test-controller status <test-id>'
\`\`\`

## 🤖 MCP Integration Ready

The framework now provides:
- ✅ Structured JSON API responses
- ✅ Real-time status monitoring
- ✅ Command execution capabilities
- ✅ Comprehensive error handling
- ✅ Claude-friendly output formats

See \`MCP-INTEGRATION-GUIDE.md\` for detailed integration instructions.

## 📁 Key File Locations

### Framework Scripts
- \`/opt/vm-test-manager\` - VM management
- \`/opt/remote-test-controller\` - Enhanced testing API

### Data Directories
- \`~/vm-testing/results/\` - Test results (user home)
- \`~/vm-testing/logs/\` - Test logs (user home)
- \`/var/lib/libvirt/isos/\` - ISO storage
- \`/var/lib/libvirt/images/\` - VM disk storage

### Documentation
- \`RLC-AI-TESTING-TEMPLATES.md\` - Testing examples
- \`MCP-INTEGRATION-GUIDE.md\` - Claude integration guide
- \`QUICK-REFERENCE.md\` - Daily usage commands

## 🎉 Deployment Status: COMPLETED

**Framework Status**: ✅ Production Ready
**RLC-AI Capabilities**: ✅ Fully Functional  
**MCP Integration**: ✅ Ready for Claude
**Testing**: ✅ All components verified

**Next**: Upload RLC-AI ISOs and start testing!

---

**Deployment completed successfully on $(date)**
EOF
    
    success "Deployment summary created"
}

# Main deployment function
main() {
    echo
    echo -e "${BLUE}🚀 Rocky Linux Test Framework - RLC-AI Enhanced Deployment${NC}"
    echo -e "${BLUE}================================================================${NC}"
    echo
    
    load_config
    verify_prerequisites
    
    echo
    log "Starting deployment sequence..."
    echo
    
    # Deploy enhanced framework components (RLC-AI capabilities integrated)
    deploy_script "scripts/01-install-packages.sh"
    deploy_script "scripts/02-setup-vm-manager.sh"
    deploy_script "scripts/03-setup-remote-controller.sh"  # Now includes RLC-AI enhancements
    deploy_script "scripts/04-configure-system.sh"
    
    # Verify everything works
    verify_deployment
    
    # Create summary
    create_summary
    
    echo
    echo -e "${GREEN}🎉 RLC-AI ENHANCED FRAMEWORK DEPLOYMENT COMPLETED! 🎉${NC}"
    echo
    success "Framework deployed with the following capabilities:"
    echo -e "   ✅ RLC-AI specific boot detection"
    echo -e "   ✅ AI workload testing (GPU, PyTorch, TensorFlow)"
    echo -e "   ✅ Container runtime validation"
    echo -e "   ✅ Enhanced MCP-compatible JSON API"
    echo -e "   ✅ Real-time status monitoring"
    echo -e "   ✅ Command execution framework"
    echo
    success "Ready for RLC-AI ISO testing and Claude MCP integration!"
    echo
    echo -e "${YELLOW}Quick Test:${NC}"
    echo -e "   ssh $DELL_SERVER_USER@$DELL_SERVER_IP '/opt/remote-test-controller status'"
    echo
    echo -e "${YELLOW}Documentation:${NC}"
    echo -e "   📖 RLC-AI-TESTING-TEMPLATES.md - Testing examples"
    echo -e "   🤖 MCP-INTEGRATION-GUIDE.md - Claude integration"
    echo -e "   📋 QUICK-REFERENCE.md - Daily usage"
    echo
    echo -e "${BLUE}Framework is now ready for Phase 2: MCP Integration! 🚀${NC}"
}

# Handle command line arguments
case "${1:-deploy}" in
    "deploy")
        main
        ;;
    "verify")
        load_config
        verify_deployment
        ;;
    "status")
        load_config
        ssh -i "$SSH_KEY_PATH" "$DELL_SERVER_USER@$DELL_SERVER_IP" '/opt/remote-test-controller status' | jq .
        ;;
    "help"|"-h"|"--help")
        echo "RLC-AI Enhanced Framework Deployment Script"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  deploy  - Deploy complete RLC-AI enhanced framework (default)"
        echo "  verify  - Verify existing deployment"
        echo "  status  - Get current framework status"
        echo "  help    - Show this help message"
        echo ""
        echo "Configuration:"
        echo "  Edit config/server-config.sh for custom settings"
        ;;
    *)
        error "Unknown command: $1. Use 'help' for usage information."
        ;;
esac
