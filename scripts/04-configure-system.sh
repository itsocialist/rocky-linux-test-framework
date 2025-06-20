#!/bin/bash

#####################################################################
# 04-configure-system.sh
# Purpose: Configure firewall, services, and helper scripts
# Usage: Run as root on Dell server
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
warning() { echo -e "${YELLOW}⚠${NC} $*"; }
error() { echo -e "${RED}✗${NC} $*"; exit 1; }

echo "========================================"
echo "Dell Rocky Linux - System Configuration"
echo "========================================"

# Check root
[[ $EUID -eq 0 ]] || error "This script must be run as root"

# Configure firewall
log "Configuring firewall..."

if ! systemctl is-active firewalld >/dev/null 2>&1; then
    log "Starting firewalld..."
    systemctl enable --now firewalld >/dev/null 2>&1 && success "firewalld started"
    sleep 2
else
    success "firewalld already running"
fi

# Add VNC ports for VM access (5900-5920)
if firewall-cmd --permanent --add-port=5900-5920/tcp >/dev/null 2>&1; then
    success "VNC ports (5900-5920) allowed"
else
    warning "Failed to add VNC ports"
fi

# Add libvirt service
if firewall-cmd --permanent --add-service=libvirt >/dev/null 2>&1; then
    success "libvirt service allowed"
else
    warning "Failed to add libvirt service"
fi

# Reload firewall
firewall-cmd --reload >/dev/null 2>&1 && success "Firewall rules reloaded"

# Configure SELinux
log "Configuring SELinux..."

if command -v getenforce >/dev/null 2>&1; then
    selinux_status=$(getenforce)
    log "SELinux status: $selinux_status"
    
    if [[ "$selinux_status" == "Enforcing" ]]; then
        # Set virtualization booleans
        for boolean in virt_use_nfs virt_use_samba virt_use_execmem; do
            if getsebool "$boolean" >/dev/null 2>&1; then
                setsebool -P "$boolean" 1 >/dev/null 2>&1 && success "SELinux boolean set: $boolean"
            fi
        done
    fi
else
    log "SELinux not installed"
fi

# Create systemd services
log "Creating systemd services..."

# VM Test Manager service
cat > /etc/systemd/system/vm-test-manager.service << 'EOF'
[Unit]
Description=VM Test Manager Service
After=libvirtd.service
Requires=libvirtd.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/true
ExecReload=/opt/vm-test-manager status

[Install]
WantedBy=multi-user.target
EOF

# Remote Test Controller service
cat > /etc/systemd/system/remote-test-controller.service << 'EOF'
[Unit]
Description=Remote Test Controller Service
After=vm-test-manager.service
Wants=vm-test-manager.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/true
ExecReload=/opt/remote-test-controller status

[Install]
WantedBy=multi-user.target
EOF

# Reload and enable services
systemctl daemon-reload >/dev/null 2>&1 && success "systemd configuration reloaded"
systemctl enable vm-test-manager.service >/dev/null 2>&1 && success "VM Test Manager enabled"
systemctl enable remote-test-controller.service >/dev/null 2>&1 && success "Remote Controller enabled"

# Create helper scripts
log "Creating helper scripts..."

# System status script
cat > /usr/local/bin/test-status << 'EOF'
#!/bin/bash
# VM Test Framework Status Display

echo "========================================="
echo "VM Test Framework Status"
echo "========================================="
echo

echo "System Information:"
echo "  Hostname: $(hostname)"
echo "  Uptime: $(uptime -p)"
echo "  Load: $(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')"
echo "  Memory: $(free -h | awk '/^Mem:/ {printf "%s / %s (%.1f%%)", $3, $2, $3/$2*100}')"
echo

echo "Virtualization Status:"
if systemctl is-active libvirtd >/dev/null 2>&1; then
    echo "  libvirtd: Running"
else
    echo "  libvirtd: Stopped"
fi

if virsh list >/dev/null 2>&1; then
    echo "  Connection: OK"
    echo "  VMs Total: $(virsh list --all --name | grep -v '^$' | wc -l)"
    echo "  VMs Running: $(virsh list --state-running --name | grep -v '^$' | wc -l)"
else
    echo "  Connection: Failed"
fi
echo

echo "Storage Information:"
echo "  VM Images: $(df -h /var/lib/libvirt/images 2>/dev/null | awk 'NR==2 {printf "%s / %s (%s used)", $3, $2, $5}' || echo "Not available")"
echo "  ISOs: $(du -sh /var/lib/libvirt/isos 2>/dev/null | awk '{print $1}' || echo "0B")"
echo

echo "Network Status:"
if virsh net-list | grep -q "default.*active"; then
    echo "  Default network: Active"
else
    echo "  Default network: Inactive"
fi
echo

echo "Framework Components:"
if [[ -x /opt/vm-test-manager ]]; then
    echo "  VM Manager: Installed"
else
    echo "  VM Manager: Not found"
fi

if [[ -x /opt/remote-test-controller ]]; then
    echo "  Remote Controller: Installed"
else
    echo "  Remote Controller: Not found"
fi
echo

echo "Quick Commands:"
echo "  vm-test-manager init"
echo "  remote-test-controller ready" 
echo "  virsh list --all"
EOF

# Quick VM creation script
cat > /usr/local/bin/quick-vm << 'EOF'
#!/bin/bash
# Quick VM Creation Helper

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <vm-name> [iso-path]"
    echo "Example: $0 test-vm /var/lib/libvirt/isos/test.iso"
    exit 1
fi

VM_NAME="$1"
ISO_PATH="${2:-}"

echo "Creating VM: $VM_NAME"
if [[ -n "$ISO_PATH" ]]; then
    echo "ISO: $ISO_PATH"
fi

vm-test-manager create "$VM_NAME" standard "$ISO_PATH"
EOF

# Make helper scripts executable
chmod +x /usr/local/bin/test-status
chmod +x /usr/local/bin/quick-vm

success "Helper scripts created: test-status, quick-vm"

# Apply performance optimizations
log "Applying performance optimizations..."

# System limits for virtualization
if [[ ! -f /etc/security/limits.d/99-vm-testing.conf ]]; then
    cat > /etc/security/limits.d/99-vm-testing.conf << 'EOF'
# VM Testing Performance Limits
* soft nofile 65536
* hard nofile 65536
* soft nproc 32768
* hard nproc 32768

# Specific limits for qemu user
qemu soft nofile 65536
qemu hard nofile 65536
qemu soft nproc 4096
qemu hard nproc 4096
EOF
    success "System limits configured for VM testing"
else
    success "System limits already configured"
fi

# Optimize libvirt configuration
libvirt_conf="/etc/libvirt/libvirtd.conf"
config_updated=false

if ! grep -q "^max_clients" "$libvirt_conf"; then
    echo "max_clients = 1000" >> "$libvirt_conf"
    config_updated=true
fi

if ! grep -q "^max_workers" "$libvirt_conf"; then
    echo "max_workers = 20" >> "$libvirt_conf"
    config_updated=true
fi

if [[ "$config_updated" == "true" ]]; then
    systemctl restart libvirtd >/dev/null 2>&1 && success "libvirt configuration optimized"
else
    success "libvirt configuration already optimized"
fi

# Create documentation
log "Creating documentation..."

cat > /opt/README.md << 'EOF'
# Dell Rocky Linux VM Testing Framework

## Quick Start Guide

### Check System Status
```bash
sudo test-status
```

### Initialize Framework
```bash
sudo vm-test-manager init
sudo remote-test-controller init
```

### Create and Test VM
```bash
# Create a test VM
sudo quick-vm test-vm /var/lib/libvirt/isos/test.iso

# Start VM
sudo vm-test-manager start test-vm

# Get VNC port for remote access
sudo vm-test-manager vnc test-vm

# List all VMs
sudo vm-test-manager list
```

### Remote Testing (from Mac)
```bash
# Check if system is ready
ssh root@server 'remote-test-controller ready'

# Start automated test
ssh root@server 'remote-test-controller start-test /var/lib/libvirt/isos/test.iso'

# Monitor tests
ssh root@server 'remote-test-controller list'

# Get detailed status
ssh root@server 'remote-test-controller status test-id'
```

## Key Directories
- Framework: `/opt/`
- VM Images: `/var/lib/libvirt/images/`
- ISOs: `/var/lib/libvirt/isos/`
- Test Results: `/opt/remote-test-controller/results/`
- Logs: `/var/log/vm-test-manager/` and `/var/log/remote-test-controller/`

## Available Commands
- `test-status` - System overview
- `quick-vm <n> [iso]` - Quick VM creation
- `vm-test-manager` - VM management
- `remote-test-controller` - Remote testing API

## Remote Access
- SSH: Port 22
- VNC for VMs: Ports 5900-5920
- Use `vm-test-manager vnc <vm-name>` to get specific port

## Framework Components
- **VM Manager**: Creates and manages virtual machines
- **Remote Controller**: Provides JSON API for remote testing
- **Test Results**: Automated collection and reporting
- **VNC Access**: Visual access to VM consoles

---
Installation completed: $(date)
Server: $(hostname)
Framework Version: 1.0
EOF

success "Documentation created at /opt/README.md"

# Final verification
log "Running final verification..."

# Test VM manager
if /opt/vm-test-manager status >/dev/null 2>&1; then
    success "VM manager working"
else
    warning "VM manager test failed"
fi

# Test remote controller  
if /opt/remote-test-controller ready >/dev/null 2>&1; then
    success "Remote controller working"
else
    warning "Remote controller test failed"
fi

# Test libvirt
if virsh list >/dev/null 2>&1; then
    success "libvirt working"
else
    warning "libvirt test failed"
fi

echo
success "System configuration completed!"
echo
echo "Framework is ready for use:"
echo "  - Run 'test-status' for system overview"
echo "  - Upload ISOs to /var/lib/libvirt/isos/"
echo "  - Initialize with: vm-test-manager init && remote-test-controller init"
echo "  - Test from Mac: ssh root@$(hostname) 'remote-test-controller ready'"
