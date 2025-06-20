# Dell VM Testing Framework - Quick Reference

## 🚀 One-Time Setup
```bash
cd /Users/briandawson/dell-vm-framework
nano config/server-config.sh    # Edit server IP/credentials
./deploy.sh                     # Deploy to Dell server
```

## 📱 Daily Commands

### System Status
```bash
ssh dell5280 'test-status'
```

### Upload & Test ISO
```bash
# Upload ISO
scp your-test.iso bdawson@192.168.7.83:/var/lib/libvirt/isos/

# Start automated test
ssh dell5280 'remote-test-controller start-test /var/lib/libvirt/isos/your-test.iso'

# Monitor progress
ssh dell5280 'remote-test-controller list running'
```

### Manual VM Testing
```bash
# Create VM
ssh dell5280 'quick-vm test-vm /var/lib/libvirt/isos/test.iso'

# Get VNC port for visual access
ssh dell5280 'vm-test-manager vnc test-vm'

# List all VMs
ssh dell5280 'vm-test-manager list'

# Clean up
ssh dell5280 'vm-test-manager delete test-vm'
```

## 🔧 Framework Commands

### VM Manager
```bash
vm-test-manager init                           # Initialize (run once)
vm-test-manager create <n> [template] [iso]   # Create VM
vm-test-manager start <n> [iso]               # Start VM
vm-test-manager stop <n>                      # Stop VM
vm-test-manager delete <n>                    # Delete VM
vm-test-manager list                          # List all VMs
vm-test-manager vnc <n>                       # Get VNC port
```

### Remote Controller
```bash
remote-test-controller ready                  # Check if ready
remote-test-controller start-test <iso>       # Start automated test
remote-test-controller list [filter]          # List tests
remote-test-controller status [test-id]       # Get status
remote-test-controller stop <test-id>         # Stop test
```

### Helpers
```bash
test-status                    # System overview
quick-vm <n> [iso]            # Quick VM creation
```

## 📁 Key Paths

### On Mac Studio:
```
/Users/briandawson/dell-vm-framework/
├── deploy.sh                 # Main deployment script
├── PROJECT-STATUS.md         # Current project status
├── TROUBLESHOOTING.md        # Problem solutions
└── config/server-config.sh   # Server settings
```

### On Dell Server:
```
/opt/vm-test-manager          # VM management
/opt/remote-test-controller   # Remote testing API
~/vm-testing/results/         # Test results (user home)
~/vm-testing/logs/            # Test logs (user home)
/var/lib/libvirt/isos/        # Upload ISOs here
/var/lib/libvirt/images/      # VM disk storage
/opt/README.md                # Server documentation
```

## 🌐 Network Access

### SSH Connection:
```bash
ssh dell5280
# or
ssh bdawson@192.168.7.83
```

### VNC Access (for VM consoles):
```bash
# Get VNC port
PORT=$(ssh root@server 'vm-test-manager vnc vm-name')
# Connect with VNC client to: server-ip:$PORT
```

## 🚨 Quick Troubleshooting

### Framework Not Working?
```bash
ssh dell5280 'sudo systemctl status libvirtd'
ssh dell5280 'sudo vm-test-manager init'
ssh dell5280 'sudo remote-test-controller init'
```

### Can't Connect?
```bash
ping 192.168.7.83
ssh-copy-id -i ~/.ssh/id_rsa bdawson@192.168.7.83
# Check: ~/.ssh/config dell5280 entry
```

### VM Won't Start?
```bash
ssh dell5280 'virsh list --all'
ssh dell5280 'df -h /var/lib/libvirt'
# Check TROUBLESHOOTING.md
```

## 📊 JSON API Examples

### Start Test Response:
```json
{
  "test_id": "test-20241219-143022-1234",
  "status": "started",
  "vm_name": "test-vm-20241219-143022-1234"
}
```

### System Status Response:
```json
{
  "ready": true,
  "current_tests": 1,
  "max_tests": 4,
  "system_info": {
    "hostname": "dell-server",
    "memory_usage": "45.2%"
  }
}
```

---

**🎯 Success**: When `ssh dell5280 'remote-test-controller ready'` returns `true`

**📖 Full Docs**: `PROJECT-STATUS.md` | `TROUBLESHOOTING.md` | `README.md`
