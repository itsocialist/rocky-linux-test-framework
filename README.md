# Rocky Linux Test Framework

**Comprehensive VM testing framework with AI/GPU validation and MCP integration for automated testing workflows**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Framework Version](https://img.shields.io/badge/Framework-1.1-blue.svg)](#)
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
- **Automated VM Management** - Complete KVM/libvirt virtualization
- **ISO Testing** - Boot validation and system testing
- **Remote Control** - SSH-based management from any machine
- **Console Access** - VNC support for visual debugging

### ✅ **Advanced Testing Capabilities**
- **Boot Detection** - Intelligent system startup monitoring
- **GPU/Hardware Validation** - NVIDIA/CUDA detection and testing
- **Software Framework Testing** - PyTorch, TensorFlow, container runtimes
- **Custom Workloads** - Execute arbitrary commands in test VMs

### ✅ **AI Assistant Integration**
- **JSON API** - Structured responses for AI/automation consumption
- **MCP Compatible** - Ready for Claude and other AI assistants
- **Real-time Monitoring** - Progress tracking and status reporting
- **Command Execution** - Remote workload testing and validation

### ✅ **Enterprise Ready**
- **Secure by Design** - User home directory data, SSH key authentication
- **Comprehensive Logging** - Detailed execution and audit trails
- **Scalable Testing** - Concurrent VM support with resource management
- **Robust Error Handling** - Graceful failure recovery and cleanup

## 📋 Requirements

### **Control Machine (Mac/Linux/Windows)**
- SSH client
- Git
- Bash 4.0+ (or compatible shell)

### **Target Server (Rocky Linux)**
- Rocky Linux 9.x (or compatible RHEL-based distribution)
- 4GB+ RAM, 20GB+ available disk space
- CPU virtualization support (Intel VT-x or AMD-V)
- User account with sudo privileges

## 🔧 Quick Configuration

Edit `config/server-config.sh`:
```bash
# Server connection details
DELL_SERVER_IP="192.168.1.100"        # Your Rocky Linux server IP
DELL_SERVER_USER="your-username"       # Your username on the server
SSH_KEY_PATH="$HOME/.ssh/id_rsa"      # Path to your SSH private key
```

## 🧪 Usage Examples

### **Deploy Framework**
```bash
./deploy.sh                    # Deploy complete framework to server
./test.sh                      # Validate installation and connectivity
```

### **Basic ISO Testing**
```bash
# Upload ISO to server
scp test.iso user@server:/var/lib/libvirt/isos/

# Start automated test
ssh server '/opt/remote-test-controller start-test /var/lib/libvirt/isos/test.iso'

# Monitor progress
ssh server '/opt/remote-test-controller status test-id'
```

### **Advanced AI/GPU Testing**
```bash
# Start comprehensive AI system test
ssh server '/opt/remote-test-controller start-rlc-ai-test /var/lib/libvirt/isos/ai-system.iso'

# Execute specific validation commands
ssh server '/opt/remote-test-controller run-workload test-id "nvidia-smi"'
ssh server '/opt/remote-test-controller run-workload test-id "python3 -c \"import torch; print(torch.cuda.is_available())\""'

# Get detailed status and results
ssh server '/opt/remote-test-controller status test-id'
```

### **Available Test Types**
- `minimal` - Basic boot and system validation
- `gpu_detection` - Hardware detection (GPU/CUDA)
- `pytorch` - PyTorch framework validation
- `tensorflow` - TensorFlow framework validation
- `container` - Container runtime testing (Podman/Docker)
- `full` - Complete system validation (default)

## 🤖 AI Assistant Integration

The framework provides a JSON API optimized for AI assistant integration:

### **System Status Response**
```json
{
  "ready": true,
  "framework_version": "1.1",
  "mcp_compatible": true,
  "capabilities": [
    "boot_detection",
    "ai_workload_testing",
    "command_execution", 
    "gpu_validation",
    "container_testing"
  ],
  "system_info": {
    "hostname": "test-server",
    "memory_usage": "45.2%",
    "vm_storage": "15G available"
  }
}
```

### **MCP Integration for Claude**
The framework is designed to work seamlessly with Claude and other AI assistants through the Model Context Protocol (MCP). See [docs/MCP-INTEGRATION.md](docs/MCP-INTEGRATION.md) for detailed integration examples.

## 📁 Project Structure

```
rocky-linux-test-framework/
├── deploy.sh                    # Main deployment script
├── test.sh                      # Framework validation
├── install.sh                   # One-command installer  
├── rltest                       # Convenient command wrapper
├── config/
│   ├── server-config.sh         # Your server configuration
│   └── server-config.example.sh # Configuration template
├── scripts/
│   ├── 01-install-packages.sh   # Package installation
│   ├── 02-setup-vm-manager.sh   # VM management setup
│   ├── 03-setup-remote-controller.sh # Enhanced API
│   └── 04-configure-system.sh   # System configuration
├── docs/
│   ├── QUICK-START.md           # Getting started guide
│   ├── AI-TESTING.md            # Advanced testing capabilities
│   ├── API-REFERENCE.md         # Complete API documentation
│   ├── MCP-INTEGRATION.md       # AI assistant integration
│   └── TROUBLESHOOTING.md       # Issue resolution
└── examples/
    ├── basic-test.sh            # Simple usage example
    ├── ai-workload-test.sh      # AI system testing
    └── mcp-integration/         # AI assistant examples
```

## 🎯 Use Cases

### **Software Testing**
- **Operating System Validation** - Test custom Linux distributions
- **Application Testing** - Validate software in clean environments
- **Hardware Compatibility** - Test drivers and hardware support

### **AI/ML Development**
- **GPU Validation** - Test NVIDIA/CUDA configurations
- **Framework Testing** - Validate PyTorch, TensorFlow installations
- **Container Platforms** - Test containerized AI workloads

### **Automation & CI/CD**
- **Automated Testing** - Integration with CI/CD pipelines
- **Quality Assurance** - Automated validation workflows
- **AI-Driven Testing** - Claude and other AI assistant integration

### **Education & Research**
- **Learning Environments** - Safe VM testing for students
- **Research Validation** - Reproducible testing environments
- **Proof of Concepts** - Rapid prototyping and validation

## 🔍 Troubleshooting

### **Quick Diagnostics**
```bash
# Test SSH connectivity
ssh -i ~/.ssh/id_rsa user@server 'echo "Connection working"'

# Verify framework status
ssh server '/opt/remote-test-controller ready'

# Check system resources
ssh server '/opt/remote-test-controller status'
```

### **Common Solutions**
- **SSH Issues**: Use `ssh-copy-id` to install your public key
- **Permission Errors**: Framework uses user home directory (`~/vm-testing/`)
- **Resource Limits**: Check available memory and disk space

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for comprehensive troubleshooting.

## 📖 Documentation

- **[Quick Start Guide](docs/QUICK-START.md)** - Get running in minutes
- **[AI Testing Guide](docs/AI-TESTING.md)** - Advanced testing capabilities
- **[API Reference](docs/API-REFERENCE.md)** - Complete command documentation
- **[MCP Integration](docs/MCP-INTEGRATION.md)** - AI assistant setup
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** - Common issues and solutions

## 🤝 Contributing

We welcome contributions! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Rocky Linux** community for excellent enterprise Linux distribution
- **KVM/QEMU** teams for robust virtualization technology
- **Anthropic** for MCP protocol and Claude integration capabilities

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/itsocialist/rocky-linux-test-framework/issues)
- **Discussions**: [GitHub Discussions](https://github.com/itsocialist/rocky-linux-test-framework/discussions)
- **Documentation**: Complete guides in [docs/](docs/) directory

---

**🎯 Ready for automated VM testing with AI assistant integration!** 🚀
