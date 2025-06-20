#!/bin/bash

#####################################################################
# 02-setup-vm-manager.sh  
# Purpose: Create VM management script and framework
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
error() { echo -e "${RED}✗${NC} $*"; exit 1; }

echo "========================================"
echo "Dell Rocky Linux - VM Manager Setup"
echo "========================================"

# Check root
[[ $EUID -eq 0 ]] || error "This script must be run as root"

# Create directories
log "Creating directory structure..."
directories=(
    "/var/lib/libvirt/isos"
    "/var/lib/libvirt/templates" 
    "/var/log/vm-test-manager"
    "/var/lock/vm-test-manager"
)

for dir in "${directories[@]}"; do
    mkdir -p "$dir" && success "Created: $dir"
    chmod 755 "$dir"
    case "$dir" in
        /var/lib/libvirt/*) chown root:qemu "$dir" 2>/dev/null || true ;;
    esac
done

# Create complete VM Manager script
log "Creating VM manager script..."

# Remove existing file/directory if it exists
rm -rf /opt/vm-test-manager

cat > /opt/vm-test-manager << 'VMSCRIPT'
#!/bin/bash
# VM Test Manager v1.0
set -euo pipefail

VM_BASE_DIR="/var/lib/libvirt/images"
ISO_DIR="/var/lib/libvirt/isos"
TEMPLATE_DIR="/var/lib/libvirt/templates"
LOG_DIR="/var/log/vm-test-manager"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

log() {
    local level=$1; shift
    case $level in
        "INFO") echo -e "${BLUE}[INFO]${NC} $*" ;;
        "SUCCESS") echo -e "${GREEN}[SUCCESS]${NC} $*" ;;
        "WARNING") echo -e "${YELLOW}[WARNING]${NC} $*" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} $*" ;;
    esac
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*" >> "${LOG_DIR}/vm-manager.log" 2>/dev/null || true
}

check_deps() {
    for dep in virsh virt-install qemu-img; do
        command -v "$dep" >/dev/null 2>&1 || { log "ERROR" "Missing: $dep"; return 1; }
    done
}

create_template() {
    local name=${1:-"standard"} memory=${2:-2048} vcpus=${3:-2}
    log "INFO" "Creating template: $name"
    mkdir -p "$TEMPLATE_DIR"
    
    cat > "${TEMPLATE_DIR}/${name}.xml" << EOF
<domain type='kvm'>
  <n>TEMPLATE_${name}</n>
  <memory unit='MiB'>${memory}</memory>
  <vcpu placement='static'>${vcpus}</vcpu>
  <os>
    <type arch='x86_64' machine='q35'>hvm</type>
    <boot dev='cdrom'/><boot dev='hd'/>
  </os>
  <features><acpi/><apic/><vmport state='off'/></features>
  <cpu mode='host-model' check='partial'/>
  <clock offset='utc'/>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>restart</on_crash>
  <devices>
    <emulator>/usr/libexec/qemu-kvm</emulator>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
      <source file='${VM_BASE_DIR}/VMNAME.qcow2'/>
      <target dev='vda' bus='virtio'/>
    </disk>
    <disk type='file' device='cdrom'>
      <driver name='qemu' type='raw'/>
      <source file='ISOPATH'/>
      <target dev='sda' bus='sata'/>
      <readonly/>
    </disk>
    <interface type='bridge'>
      <source bridge='virbr0'/>
      <model type='virtio'/>
    </interface>
    <console type='pty'><target type='serial' port='0'/></console>
    <graphics type='vnc' port='-1' autoport='yes' listen='0.0.0.0'/>
    <video><model type='cirrus' vram='16384' heads='1'/></video>
  </devices>
</domain>
EOF
    log "SUCCESS" "Template created: $name"
}

create_vm() {
    local vm_name=$1 template=${2:-"standard"} iso_path=${3:-""}
    log "INFO" "Creating VM: $vm_name"
    
    virsh list --all --name | grep -q "^${vm_name}$" && { log "ERROR" "VM exists: $vm_name"; return 1; }
    [[ ! -f "${TEMPLATE_DIR}/${template}.xml" ]] && { log "ERROR" "Template not found: $template"; return 1; }
    
    local disk_path="${VM_BASE_DIR}/${vm_name}.qcow2"
    qemu-img create -f qcow2 "$disk_path" 20G >/dev/null
    chown qemu:qemu "$disk_path" 2>/dev/null || true
    
    local vm_xml="/tmp/${vm_name}.xml"
    sed "s/TEMPLATE_${template}/${vm_name}/g; s|VMNAME|${vm_name}|g; s|ISOPATH|${iso_path}|g" \
        "${TEMPLATE_DIR}/${template}.xml" > "$vm_xml"
    
    virsh define "$vm_xml" && rm "$vm_xml"
    log "SUCCESS" "VM created: $vm_name"
}

start_vm() {
    local vm_name=$1 iso_path=${2:-""}
    log "INFO" "Starting VM: $vm_name"
    
    if [[ -n "$iso_path" ]]; then
        virsh detach-disk "$vm_name" sda --config 2>/dev/null || true
        virsh attach-disk "$vm_name" "$iso_path" sda --type cdrom --mode readonly --config
    fi
    
    virsh start "$vm_name"
    log "SUCCESS" "VM started: $vm_name"
}

stop_vm() {
    local vm_name=$1 force=${2:-false}
    log "INFO" "Stopping VM: $vm_name"
    
    if [[ "$force" == "true" ]]; then
        virsh destroy "$vm_name" 2>/dev/null || true
    else
        virsh shutdown "$vm_name" 2>/dev/null || true
        sleep 10
        virsh list --state-running --name | grep -q "^${vm_name}$" && virsh destroy "$vm_name" 2>/dev/null || true
    fi
    log "SUCCESS" "VM stopped: $vm_name"
}

delete_vm() {
    local vm_name=$1
    log "INFO" "Deleting VM: $vm_name"
    virsh destroy "$vm_name" 2>/dev/null || true
    virsh undefine "$vm_name" 2>/dev/null || true
    rm -f "${VM_BASE_DIR}/${vm_name}.qcow2"
    log "SUCCESS" "VM deleted: $vm_name"
}

list_vms() {
    echo "VM Status Summary:"
    echo "=================="
    printf "%-20s %-10s %-15s\n" "NAME" "STATE" "MEMORY"
    printf "%-20s %-10s %-15s\n" "----" "-----" "------"
    
    for vm in $(virsh list --all --name); do
        [[ -n "$vm" ]] || continue
        local state=$(virsh domstate "$vm" 2>/dev/null || echo "unknown")
        local memory=$(virsh dominfo "$vm" 2>/dev/null | awk '/Max memory:/ {print $3}' || echo "N/A")
        printf "%-20s %-10s %-15s\n" "$vm" "$state" "${memory}KB"
    done
}

get_vnc_port() {
    local vm_name=$1
    local port=$(virsh vncdisplay "$vm_name" 2>/dev/null | sed 's/://')
    [[ -n "$port" ]] && echo $((5900 + port)) || echo "N/A"
}

init_framework() {
    log "INFO" "Initializing VM framework"
    check_deps || return 1
    create_template "standard" 2048 2
    create_template "minimal" 1024 1  
    create_template "performance" 4096 4
    log "SUCCESS" "VM framework initialized"
}

case ${1:-""} in
    "init") init_framework ;;
    "create") create_vm "$2" "${3:-standard}" "${4:-}" ;;
    "start") start_vm "$2" "${3:-}" ;;
    "stop") stop_vm "$2" "${3:-false}" ;;
    "delete") delete_vm "$2" ;;
    "list") list_vms ;;
    "vnc") get_vnc_port "$2" ;;
    "status") echo "VM Manager: Ready" ;;
    *)
        echo "VM Test Manager v1.0"
        echo "Usage: $0 {init|create|start|stop|delete|list|vnc|status}"
        echo ""
        echo "Examples:"
        echo "  $0 init"
        echo "  $0 create test-vm standard /var/lib/libvirt/isos/test.iso"
        echo "  $0 start test-vm"
        echo "  $0 list"
        ;;
esac
VMSCRIPT

# Make executable and create symlink
chmod +x /opt/vm-test-manager
ln -sf /opt/vm-test-manager /usr/local/bin/vm-test-manager

success "VM manager script created and installed"
success "Available as: vm-test-manager"

echo
success "VM Manager setup completed!"
echo "Initialize with: vm-test-manager init"
