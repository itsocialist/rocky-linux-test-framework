#!/bin/bash

# Dell Server Configuration
# Example configuration file - copy to server-config.sh and customize

# Server connection details
DELL_SERVER_IP="192.168.1.100"          # CHANGE: Your Rocky Linux server IP
DELL_SERVER_USER="your-username"         # CHANGE: Your username on the server
DELL_SERVER_PORT="22"                   # SSH port (usually 22)

# SSH key path
SSH_KEY_PATH="$HOME/.ssh/id_rsa"        # Path to your SSH private key

# Deployment directories (usually don't need to change)
REMOTE_TEMP_DIR="/tmp/vm-framework-deploy"
REMOTE_INSTALL_DIR="/opt"

# Framework settings
FRAMEWORK_VERSION="1.1-rlc-ai"
LOG_PREFIX="vm-framework"

# Colors for output (don't change)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    local level=$1; shift
    local message="$*"
    local timestamp=$(date '+%H:%M:%S')
    
    case $level in
        "INFO") echo -e "${BLUE}[${timestamp}]${NC} ${message}" ;;
        "SUCCESS") echo -e "${GREEN}[${timestamp}] ✓${NC} $message" ;;
        "WARNING") echo -e "${YELLOW}[${timestamp}] ⚠${NC} $message" ;;
        "ERROR") echo -e "${RED}[${timestamp}] ✗${NC} $message" ;;
    esac
}

# SSH connection test
test_connection() {
    log "INFO" "Testing connection to $DELL_SERVER_USER@$DELL_SERVER_IP..."
    
    if [[ -f "$SSH_KEY_PATH" ]]; then
        ssh -i "$SSH_KEY_PATH" -o ConnectTimeout=10 -o BatchMode=yes \
            "$DELL_SERVER_USER@$DELL_SERVER_IP" "echo 'Connection successful'" &>/dev/null
    else
        log "ERROR" "SSH key not found: $SSH_KEY_PATH"
        return 1
    fi
    
    if [[ $? -eq 0 ]]; then
        log "SUCCESS" "Connection to server established"
        return 0
    else
        log "ERROR" "Cannot connect to server"
        log "INFO" "Please check:"
        log "INFO" "  - Server IP: $DELL_SERVER_IP"
        log "INFO" "  - Username: $DELL_SERVER_USER" 
        log "INFO" "  - SSH key: $SSH_KEY_PATH"
        log "INFO" "  - Run: ssh-copy-id -i $SSH_KEY_PATH $DELL_SERVER_USER@$DELL_SERVER_IP"
        return 1
    fi
}

# Execute remote command (with sudo when needed)
remote_exec() {
    local command=$1
    local use_sudo=${2:-false}
    
    if [[ -f "$SSH_KEY_PATH" ]]; then
        if [[ "$use_sudo" == "true" ]]; then
            ssh -t -i "$SSH_KEY_PATH" "$DELL_SERVER_USER@$DELL_SERVER_IP" "sudo $command"
        else
            ssh -i "$SSH_KEY_PATH" "$DELL_SERVER_USER@$DELL_SERVER_IP" "$command"
        fi
    else
        log "ERROR" "SSH key not found: $SSH_KEY_PATH"
        return 1
    fi
}

# Copy file to remote server
remote_copy() {
    local local_file=$1
    local remote_path=$2
    
    if [[ -f "$SSH_KEY_PATH" ]]; then
        scp -i "$SSH_KEY_PATH" "$local_file" "$DELL_SERVER_USER@$DELL_SERVER_IP:$remote_path"
    else
        log "ERROR" "SSH key not found: $SSH_KEY_PATH"
        return 1
    fi
}

# Setup SSH key access to server
setup_ssh_access() {
    log "INFO" "Setting up SSH key access to server..."
    
    if [[ ! -f "$SSH_KEY_PATH" ]]; then
        log "ERROR" "SSH key not found: $SSH_KEY_PATH"
        log "INFO" "Generate one with: ssh-keygen -t rsa -b 4096 -f $SSH_KEY_PATH"
        return 1
    fi
    
    log "INFO" "Copying public key to server..."
    log "INFO" "You may need to enter the password for $DELL_SERVER_USER@$DELL_SERVER_IP"
    
    # Copy public key to server (will prompt for password)
    ssh-copy-id -i "$SSH_KEY_PATH" "$DELL_SERVER_USER@$DELL_SERVER_IP"
    
    if [[ $? -eq 0 ]]; then
        log "SUCCESS" "SSH key copied to server"
        
        if test_connection; then
            log "SUCCESS" "SSH key authentication working!"
            return 0
        else
            log "ERROR" "SSH key authentication failed"
            return 1
        fi
    else
        log "ERROR" "Failed to copy SSH key to server"
        return 1
    fi
}
