# Rocky Linux Test Framework

**Enhanced VM testing framework with AI/GPU validation capabilities and Claude MCP integration**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Framework Version](https://img.shields.io/badge/Framework-1.1--rlc--ai-blue.svg)](#)
[![MCP Compatible](https://img.shields.io/badge/MCP-Compatible-green.svg)](#)

## 🚀 Quick Start

### One-Command Installation
```bash
curl -sSL https://raw.githubusercontent.com/itsocialist/rocky-linux-test-framework/main/install.sh | bash
```

### Manual Installation
```bash
git clone https://github.com/itsocialist/rocky-linux-test-framework.git
cd rocky-linux-test-framework
cp config/server-config.example.sh config/server-config.sh
# Edit config/server-config.sh with your server details
./deploy.sh
```

## 🎯 Features

### ✅ **Core VM Testing**
- **Automated VM Creation** - KVM/libvirt based virtualization
- **ISO Boot Testing** - Automated boot validation and monitoring
- **Remote Control** - SSH-based management from Mac/Linux
- **VNC Access** - Visual console access for debugging

### ✅ **Enhanced AI/GPU Testing**
- **RLC-AI Boot Detection** - AI-specific system recognition
- **GPU Validation** - NVIDIA/CUDA detection and testing
- **AI Framework Testing** - PyTorch, TensorFlow validation
- **Container Runtime** - Podman/Docker functionality testing

### ✅ **Claude MCP Integration**
- **JSON API** - Structured responses for AI consumption
- **Real-time Status** - Progress monitoring and reporting
- **Command Execution** - Remote AI workload testing
- **MCP Compatible** - Ready for Claude automation

### ✅ **Security & Reliability**
- **User Home Data** - No system-wide permission changes needed
- **SSH Key Authentication** - Secure key-based access
- **Comprehensive Logging** - Detailed test execution logs
- **Graceful Error Handling** - Robust failure recovery

## 📋 Requirements

### **Control Machine (Mac/Linux)**
- SSH client
- Git
- Bash 4.0+

### **Target Server (Rocky Linux)**
- Rocky Linux 9.x
- 4GB+ RAM, 20GB+ disk space
- CPU virtualization support (VT-x/AMD-V)
- Sudo access for user account

## 🔧 Configuration

Edit `config/server-config.sh`:
```bash
# Server connection details
DELL_SERVER_IP="192.168.1.100"        # Your Rocky Linux server IP
DELL_SERVER_USER="your-username"       # Your username on the server
SSH_KEY_PATH="$HOME/.ssh/id_rsa"      # Path to your SSH private key
```

## 🧪 Usage

### **Deploy Framework**
```bash
./deploy.sh                    # Deploy complete framework
./test.sh                      # Validate installation
```

### **Basic VM Testing**
```bash
# Upload ISO
scp test.iso user@server:/var/lib/libvirt/isos/

# Start test
ssh server '/opt/remote-test-controller start-test /var/lib/libvirt/isos/test.iso'

# Monitor progress
ssh server '/opt/remote-test-controller status test-id'
```

### **AI/RLC-AI Testing**
```bash
# Start RLC-AI test
ssh server '/opt/remote-test-controller start-rlc-ai-test /var/lib/libvirt/isos/rlc-ai.iso'

# Run AI workloads
ssh server '/opt/remote-test-controller run-workload test-id "nvidia-smi"'
ssh server '/opt/remote-test-controller run-workload test-id "python3 -c \"import torch; print(torch.cuda.is_available())\""'

# Enhanced status
ssh server '/opt/remote-test-controller status'
```

### **Test Types Available**
- `minimal` - Basic boot + system validation
- `gpu_detection` - GPU/CUDA detection only  
- `pytorch` - PyTorch framework validation
- `tensorflow` - TensorFlow framework validation
- `container` - Container runtime validation
- `full` - Complete AI stack validation (default)

## 🤖 Claude MCP Integration

### **JSON API Example**
```json
{
    "ready": true,
    "framework_version": "1.1-rlc-ai",
    "mcp_compatible": true,
    "capabilities": [
        "rlc_ai_boot_detection",
        "ai_workload_testing",
        "command_execution",
        "gpu_validation",
        "container_testing"
    ],
    "system_info": {
        "hostname": "rocky-server",
        "memory_usage": "45.2%",
        "vm_storage": "15G available"
    }
}
```

### **MCP Integration**
See [docs/MCP-INTEGRATION.md](docs/MCP-INTEGRATION.md) for detailed Claude integration guide.

## 📁 Project Structure

```
rocky-linux-test-framework/
├── deploy.sh                    # Main deployment script
├── test.sh                      # Validation testing
├── install.sh                   # One-command installer
├── rltest                       # Convenient launcher
├── config/
│   ├── server-config.sh         # Server configuration
│   └── server-config.example.sh # Configuration template
├── scripts/
│   ├── 01-install-packages.sh   # Package installation
│   ├── 02-setup-vm-manager.sh   # VM management setup
│   ├── 03-setup-remote-controller.sh # Enhanced API with RLC-AI
│   └── 04-configure-system.sh   # System configuration
├── docs/
│   ├── QUICK-START.md           # Getting started guide
│   ├── AI-TESTING.md            # AI/RLC-AI testing guide
│   ├── MCP-INTEGRATION.md       # Claude integration
│   └── TROUBLESHOOTING.md       # Common issues
└── examples/
    ├── basic-test.sh            # Simple usage example
    ├── ai-workload-test.sh      # AI testing example
    └── mcp-integration/         # MCP code examples
```

## 🔍 Troubleshooting

### **Common Issues**

**SSH Connection Failed**
```bash
# Test SSH access
ssh -i ~/.ssh/id_rsa user@server

# Copy SSH key if needed
ssh-copy-id -i ~/.ssh/id_rsa user@server
```

**Sudo Password Required**
- The framework uses interactive sudo prompts for security
- You'll be prompted for your password during deployment

**Permission Denied**
- Framework stores data in `~/vm-testing/` (user home)
- No system-wide permission changes required

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for complete troubleshooting guide.

## 📖 Documentation

- **[Quick Start Guide](docs/QUICK-START.md)** - Get up and running quickly
- **[AI Testing Guide](docs/AI-TESTING.md)** - RLC-AI and GPU testing
- **[MCP Integration](docs/MCP-INTEGRATION.md)** - Claude automation setup
- **[API Reference](docs/API-REFERENCE.md)** - Complete command reference
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** - Common issues and solutions

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Rocky Linux** community for the excellent AI-focused distribution
- **CIQ** for RLC-AI development and testing requirements
- **Anthropic** for Claude MCP integration capabilities

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/itsocialist/rocky-linux-test-framework/issues)
- **Discussions**: [GitHub Discussions](https://github.com/itsocialist/rocky-linux-test-framework/discussions)
- **Documentation**: [docs/](docs/) directory

---

**🎯 Ready for production VM testing with AI/GPU validation and Claude integration!** 🚀
