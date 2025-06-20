#!/bin/bash

#####################################################################
# 01-install-packages.sh
# Purpose: Install virtualization packages on Rocky Linux
# Usage: Run as root on Dell server
#####################################################################

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging
log() {
    local level=$1; shift
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $level: $*"
}

success() { echo -e "${GREEN}✓${NC} $*"; }
warning() { echo -e "${YELLOW}⚠${NC} $*"; }
error() { echo -e "${RED}✗${NC} $*"; exit 1; }

echo "========================================"
echo "Dell Rocky Linux - Package Installation"
echo "========================================"

# Check if running as root
[[ $EUID -eq 0 ]] || error "This script must be run as root"

# Check Rocky Linux
if [[ -f /etc/rocky-release ]]; then
    version=$(cat /etc/rocky-release | grep -oP '(?<=release )\d+\.\d+')
    success "Rocky Linux $version detected"
else
    error "This script requires Rocky Linux"
fi

# Check hardware requirements
log "INFO" "Checking hardware requirements..."

# Memory check
total_memory=$(free -m | awk '/^Mem:/ {print $2}')
if [[ $total_memory -lt 4096 ]]; then
    warning "Recommended minimum memory is 4GB, found ${total_memory}MB"
else
    success "Memory: ${total_memory}MB"
fi

# CPU virtualization check
if grep -q -E '(vmx|svm)' /proc/cpuinfo; then
    success "CPU virtualization support detected"
else
    error "CPU virtualization support not found. Enable VT-x/AMD-V in BIOS"
fi

# Update system
log "INFO" "Updating system packages..."
dnf update -y >/dev/null 2>&1 && success "System updated"

# Define packages
packages=(
    "qemu-kvm" "libvirt" "libvirt-daemon-config-network"
    "libvirt-daemon-kvm" "virt-install" "virt-top"
    "virt-viewer" "bridge-utils" "libguestfs-tools"
    "guestfs-tools" "libvirt-client" "curl" "wget"
    "jq" "git" "htop" "tree"
)

# Install packages
log "INFO" "Installing virtualization packages..."
for package in "${packages[@]}"; do
    if rpm -q "$package" >/dev/null 2>&1; then
        success "Already installed: $package"
    else
        if dnf install -y "$package" >/dev/null 2>&1; then
            success "Installed: $package"
        else
            error "Failed to install: $package"
        fi
    fi
done

# Verify critical commands
critical_commands=("virsh" "virt-install" "qemu-img" "jq")
for cmd in "${critical_commands[@]}"; do
    if command -v "$cmd" >/dev/null 2>&1; then
        success "Command available: $cmd"
    else
        error "Critical command not found: $cmd"
    fi
done

# Configure and start libvirtd
log "INFO" "Configuring libvirt service..."

systemctl enable libvirtd >/dev/null 2>&1 && success "libvirtd enabled"
systemctl start libvirtd >/dev/null 2>&1 && success "libvirtd started"

# Wait for service to be ready
sleep 3

# Test connection
if virsh list >/dev/null 2>&1; then
    success "libvirt connection working"
else
    error "libvirt connection failed"
fi

# Configure default network
if ! virsh net-list | grep -q "default.*active"; then
    virsh net-start default >/dev/null 2>&1 && success "Default network started"
fi

virsh net-autostart default >/dev/null 2>&1 && success "Default network set to autostart"

echo
success "Package installation completed successfully!"
echo "Ready for VM framework installation..."
