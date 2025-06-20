# Troubleshooting Guide - Dell VM Testing Framework

## 🔧 Common Issues & Solutions

### 1. **Connection Issues**

#### Problem: "Cannot connect to Dell server"
```bash
# Test basic connectivity
ping dell-server-ip
ssh root@dell-server-ip "echo 'Connected'"

# Check SSH key
ssh-add -l
ssh-copy-id root@dell-server-ip

# Verify config
cat config/server-config.sh
```

#### Problem: "Permission denied"
```bash
# Ensure running with correct user
whoami
# Edit server config with correct username/key
nano config/server-config.sh
```

### 2. **Deployment Issues**

#### Problem: "Package installation failed"
```bash
# Manual verification on server
ssh root@server "dnf update -y"
ssh root@server "dnf install -y qemu-kvm libvirt"
```

#### Problem: "libvirtd not starting"
```bash
# Check virtualization support
ssh root@server "grep -E '(vmx|svm)' /proc/cpuinfo"
ssh root@server "lsmod | grep kvm"

# Start service manually
ssh root@server "systemctl enable --now libvirtd"
ssh root@server "systemctl status libvirtd"
```

### 3. **Framework Issues**

#### Problem: "VM Manager not working"
```bash
# Check script exists and is executable
ssh root@server "ls -la /opt/vm-test-manager"
ssh root@server "vm-test-manager status"

# Reinitialize if needed
ssh root@server "vm-test-manager init"
```

#### Problem: "Remote Controller not responding"
```bash
# Check controller status
ssh root@server "remote-test-controller ready"
ssh root@server "ls -la /opt/remote-test-controller"

# Check logs
ssh root@server "tail -f /var/log/remote-test-controller/controller.log"
```

### 4. **VM Issues**

#### Problem: "VM creation fails"
```bash
# Check storage space
ssh root@server "df -h /var/lib/libvirt/images"

# Check permissions
ssh root@server "ls -la /var/lib/libvirt/"
ssh root@server "chown qemu:qemu /var/lib/libvirt/images"

# Test manual creation
ssh root@server "qemu-img create -f qcow2 /tmp/test.qcow2 1G"
```

#### Problem: "VNC not accessible"
```bash
# Check firewall
ssh root@server "firewall-cmd --list-ports | grep 5900"
ssh root@server "firewall-cmd --permanent --add-port=5900-5920/tcp"
ssh root@server "firewall-cmd --reload"

# Check VM VNC settings
ssh root@server "vm-test-manager vnc vm-name"
ssh root@server "virsh vncdisplay vm-name"
```

### 5. **Network Issues**

#### Problem: "Default network not active"
```bash
# Check and restart network
ssh root@server "virsh net-list --all"
ssh root@server "virsh net-start default"
ssh root@server "virsh net-autostart default"
```

#### Problem: "VM has no network"
```bash
# Check bridge
ssh root@server "ip addr show virbr0"
ssh root@server "brctl show"

# Restart networking
ssh root@server "systemctl restart NetworkManager"
ssh root@server "systemctl restart libvirtd"
```

## 🔍 Diagnostic Commands

### Quick System Check:
```bash
ssh root@server 'test-status'
```

### Detailed Diagnostics:
```bash
# System resources
ssh root@server "free -h && df -h && uptime"

# Virtualization status
ssh root@server "systemctl status libvirtd"
ssh root@server "virsh list --all"
ssh root@server "virsh net-list --all"

# Framework status
ssh root@server "ls -la /opt/"
ssh root@server "vm-test-manager status"
ssh root@server "remote-test-controller ready"

# Logs
ssh root@server "tail -20 /var/log/vm-test-manager/vm-manager.log"
ssh root@server "tail -20 /var/log/remote-test-controller/controller.log"
```

## 🧪 Manual Testing

### Test VM Creation:
```bash
ssh root@server "vm-test-manager create test-manual standard"
ssh root@server "vm-test-manager start test-manual"
ssh root@server "vm-test-manager list"
ssh root@server "vm-test-manager vnc test-manual"
ssh root@server "vm-test-manager stop test-manual"
ssh root@server "vm-test-manager delete test-manual"
```

### Test Remote Controller:
```bash
# Upload test ISO
scp test.iso root@server:/var/lib/libvirt/isos/

# Start test
TEST_ID=$(ssh root@server 'remote-test-controller start-test /var/lib/libvirt/isos/test.iso' | jq -r '.test_id')

# Monitor
ssh root@server "remote-test-controller status $TEST_ID"
ssh root@server "remote-test-controller list running"

# Stop when done
ssh root@server "remote-test-controller stop $TEST_ID"
```

## 🔄 Recovery Procedures

### Complete Framework Reinstall:
```bash
# Clean installation
ssh root@server "rm -rf /opt/vm-test-manager /opt/remote-test-controller"
ssh root@server "systemctl stop vm-test-manager remote-test-controller"
ssh root@server "systemctl disable vm-test-manager remote-test-controller"

# Redeploy
./deploy.sh
```

### Reset VM Environment:
```bash
# Stop all VMs
ssh root@server "for vm in \$(virsh list --name); do virsh destroy \$vm 2>/dev/null; done"

# Clean VM storage
ssh root@server "rm -f /var/lib/libvirt/images/*.qcow2"

# Reinitialize
ssh root@server "vm-test-manager init"
```

### Reset Test Results:
```bash
# Clean test results
ssh root@server "rm -rf /opt/remote-test-controller/results/*"
ssh root@server "rm -f /var/lock/remote-test-controller/*.lock"

# Reinitialize
ssh root@server "remote-test-controller init"
```

## 📞 Getting Help

### Check Logs:
```bash
# Recent deployment logs (on Mac)
ls -la /Users/briandawson/dell-vm-framework/

# Framework logs (on server)
ssh root@server "find /var/log -name '*vm*' -o -name '*remote*' | xargs ls -la"
```

### System Information for Support:
```bash
# Collect system info
ssh root@server "
echo '=== System Info ==='
cat /etc/rocky-release
uname -a
free -h
df -h
echo '=== Virtualization ==='
grep -E '(vmx|svm)' /proc/cpuinfo | wc -l
lsmod | grep kvm
systemctl status libvirtd
echo '=== Network ==='
ip addr show
firewall-cmd --list-all
echo '=== Framework ==='
ls -la /opt/
test-status
"
```

### Emergency Contacts:
- **Project Location**: `/Users/briandawson/dell-vm-framework/`
- **Documentation**: `PROJECT-STATUS.md`, `README.md`
- **Configuration**: `config/server-config.sh`

---

**Remember**: Most issues can be resolved by checking logs and rerunning deployment scripts. The framework is designed to be idempotent - safe to run multiple times.
