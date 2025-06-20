#!/bin/bash
#
# install.sh - One-Command Rocky Linux Test Framework Installer
# Usage: curl -sSL https://raw.githubusercontent.com/user/rocky-linux-test-framework/main/install.sh | bash
#

set -euo pipefail

# Configuration
REPO_URL="https://github.com/itsocialist/rocky-linux-test-framework"
INSTALL_DIR="$HOME/rocky-linux-test-framework"
CONFIG_FILE="$INSTALL_DIR/config/server-config.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $*"
}

success() {
    echo -e "${GREEN}✅${NC} $*"
}

error() {
    echo -e "${RED}❌${NC} $*" >&2
    exit 1
}

warning() {
    echo -e "${YELLOW}⚠️${NC} $*"
}

# Banner
echo
echo -e "${BLUE}🚀 Rocky Linux Test Framework Installer${NC}"
echo -e "${BLUE}=======================================${NC}"
echo

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if git is installed
    if ! command -v git >/dev/null 2>&1; then
        error "Git is required but not installed. Please install git first."
    fi
    
    # Check if ssh is available
    if ! command -v ssh >/dev/null 2>&1; then
        error "SSH is required but not installed."
    fi
    
    # Check if we're on macOS (for SSH key handling)
    if [[ "$(uname)" == "Darwin" ]]; then
        log "Detected macOS environment"
    elif [[ "$(uname)" == "Linux" ]]; then
        log "Detected Linux environment"
    else
        warning "Unknown operating system. Proceeding with caution."
    fi
    
    success "Prerequisites check passed"
}

# Clone repository
clone_repository() {
    log "Cloning Rocky Linux Test Framework..."
    
    if [[ -d "$INSTALL_DIR" ]]; then
        warning "Directory $INSTALL_DIR already exists. Removing..."
        rm -rf "$INSTALL_DIR"
    fi
    
    git clone "$REPO_URL" "$INSTALL_DIR"
    cd "$INSTALL_DIR"
    
    success "Repository cloned to $INSTALL_DIR"
}

# Setup configuration
setup_configuration() {
    log "Setting up configuration..."
    
    # Copy example config if it doesn't exist
    if [[ ! -f "$CONFIG_FILE" ]]; then
        if [[ -f "$INSTALL_DIR/config/server-config.example.sh" ]]; then
            cp "$INSTALL_DIR/config/server-config.example.sh" "$CONFIG_FILE"
            success "Created configuration file from example"
        else
            error "No configuration example found"
        fi
    fi
    
    echo
    echo -e "${YELLOW}📝 Configuration Setup Required${NC}"
    echo "Please edit the server configuration file:"
    echo "  $CONFIG_FILE"
    echo
    echo "Update the following settings:"
    echo "  - DELL_SERVER_IP: Your Rocky Linux server IP"
    echo "  - DELL_SERVER_USER: Your username on the server"
    echo "  - SSH_KEY_PATH: Path to your SSH private key"
    echo
}

# Setup SSH key
setup_ssh_key() {
    log "Checking SSH key setup..."
    
    local ssh_key_path="$HOME/.ssh/id_rsa"
    
    if [[ ! -f "$ssh_key_path" ]]; then
        warning "SSH key not found at $ssh_key_path"
        echo
        echo "Would you like to generate an SSH key? (y/N)"
        read -r response
        
        if [[ "$response" =~ ^[Yy]$ ]]; then
            log "Generating SSH key..."
            ssh-keygen -t rsa -b 4096 -f "$ssh_key_path" -N ""
            success "SSH key generated at $ssh_key_path"
            
            echo
            echo -e "${YELLOW}📋 Next Steps for SSH Setup:${NC}"
            echo "1. Copy your public key to the server:"
            echo "   ssh-copy-id -i $ssh_key_path.pub user@server-ip"
            echo "2. Test SSH connection:"
            echo "   ssh -i $ssh_key_path user@server-ip"
            echo
        else
            echo
            echo -e "${YELLOW}📋 SSH Key Setup Required:${NC}"
            echo "1. Generate an SSH key: ssh-keygen -t rsa -b 4096"
            echo "2. Copy to server: ssh-copy-id user@server-ip"
            echo "3. Update config file with correct SSH_KEY_PATH"
            echo
        fi
    else
        success "SSH key found at $ssh_key_path"
    fi
}

# Make scripts executable
setup_scripts() {
    log "Setting up scripts..."
    
    # Make main scripts executable
    chmod +x "$INSTALL_DIR/deploy.sh"
    chmod +x "$INSTALL_DIR/test.sh"
    chmod +x "$INSTALL_DIR/scripts/"*.sh
    
    success "Scripts made executable"
}

# Create convenient aliases
create_aliases() {
    log "Creating convenient command aliases..."
    
    # Create a simple launcher script
    cat > "$INSTALL_DIR/rltest" << 'EOF'
#!/bin/bash
# Rocky Linux Test Framework Launcher

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "${1:-help}" in
    "deploy")
        "$SCRIPT_DIR/deploy.sh"
        ;;
    "test")
        "$SCRIPT_DIR/test.sh"
        ;;
    "status")
        "$SCRIPT_DIR/deploy.sh" status
        ;;
    "config")
        if command -v nano >/dev/null 2>&1; then
            nano "$SCRIPT_DIR/config/server-config.sh"
        elif command -v vim >/dev/null 2>&1; then
            vim "$SCRIPT_DIR/config/server-config.sh"
        else
            echo "Please edit: $SCRIPT_DIR/config/server-config.sh"
        fi
        ;;
    "help"|*)
        echo "Rocky Linux Test Framework"
        echo ""
        echo "Usage: $0 {deploy|test|status|config|help}"
        echo ""
        echo "Commands:"
        echo "  deploy  - Deploy framework to Rocky Linux server"
        echo "  test    - Run validation tests"
        echo "  status  - Get framework status"
        echo "  config  - Edit server configuration"
        echo "  help    - Show this help"
        echo ""
        echo "Files:"
        echo "  Configuration: $SCRIPT_DIR/config/server-config.sh"
        echo "  Documentation: $SCRIPT_DIR/docs/"
        echo ""
        ;;
esac
EOF
    
    chmod +x "$INSTALL_DIR/rltest"
    
    success "Created launcher script: $INSTALL_DIR/rltest"
}

# Show next steps
show_next_steps() {
    echo
    echo -e "${GREEN}🎉 Installation Complete!${NC}"
    echo
    echo -e "${BLUE}📋 Next Steps:${NC}"
    echo
    echo "1. Configure server settings:"
    echo "   cd $INSTALL_DIR"
    echo "   ./rltest config"
    echo
    echo "2. Ensure SSH access to your Rocky Linux server"
    echo
    echo "3. Deploy the framework:"
    echo "   ./rltest deploy"
    echo
    echo "4. Validate installation:"
    echo "   ./rltest test"
    echo
    echo -e "${BLUE}📖 Documentation:${NC}"
    echo "   Quick Start: $INSTALL_DIR/docs/QUICK-START.md"
    echo "   AI Testing: $INSTALL_DIR/docs/AI-TESTING.md"
    echo "   MCP Integration: $INSTALL_DIR/docs/MCP-INTEGRATION.md"
    echo
    echo -e "${BLUE}🎯 Framework Features:${NC}"
    echo "   ✅ VM Testing and Management"
    echo "   ✅ RLC-AI Boot Detection"
    echo "   ✅ AI Workload Testing (GPU, PyTorch, TensorFlow)"
    echo "   ✅ Container Runtime Validation"
    echo "   ✅ MCP Integration for Claude"
    echo "   ✅ Remote SSH-based Control"
    echo
}

# Main installation flow
main() {
    check_prerequisites
    clone_repository
    setup_scripts
    setup_configuration
    setup_ssh_key
    create_aliases
    show_next_steps
}

# Run installation
main "$@"
