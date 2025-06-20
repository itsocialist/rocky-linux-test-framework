# RLC-AI Testing Templates and Examples

## 🎯 RLC-AI Specific Test Commands

### GPU/CUDA Detection
```bash
# Basic GPU detection
ssh dell5280 '/opt/remote-test-controller run-workload <test-id> "nvidia-smi"'

# CUDA availability check
ssh dell5280 '/opt/remote-test-controller run-workload <test-id> "python3 -c \"import torch; print(torch.cuda.is_available())\""'

# GPU memory info
ssh dell5280 '/opt/remote-test-controller run-workload <test-id> "nvidia-smi --query-gpu=memory.total,memory.used --format=csv,noheader,nounits"'
```

### AI Framework Testing
```bash
# PyTorch validation
ssh dell5280 '/opt/remote-test-controller run-workload <test-id> "python3 -c \"import torch; print(f'PyTorch: {torch.__version__}'); print(f'CUDA: {torch.cuda.is_available()}')\""'

# TensorFlow validation
ssh dell5280 '/opt/remote-test-controller run-workload <test-id> "python3 -c \"import tensorflow as tf; print(f'TF: {tf.__version__}'); print(tf.config.list_physical_devices())\""'

# NumPy + SciPy stack
ssh dell5280 '/opt/remote-test-controller run-workload <test-id> "python3 -c \"import numpy as np; import scipy; print(f'NumPy: {np.__version__}'); print(f'SciPy: {scipy.__version__}')\""'
```

### Container Runtime Testing
```bash
# Podman version
ssh dell5280 '/opt/remote-test-controller run-workload <test-id> "podman --version"'

# Container hello world
ssh dell5280 '/opt/remote-test-controller run-workload <test-id> "podman run --rm hello-world"'

# AI container test
ssh dell5280 '/opt/remote-test-controller run-workload <test-id> "podman run --rm python:3.9 python -c \"print('Container AI test successful')\""'
```

### System Resource Validation
```bash
# Memory check
ssh dell5280 '/opt/remote-test-controller run-workload <test-id> "free -h"'

# CPU info
ssh dell5280 '/opt/remote-test-controller run-workload <test-id> "lscpu | grep -E \"Model name|CPU\(s\):\""'

# Disk space
ssh dell5280 '/opt/remote-test-controller run-workload <test-id> "df -h /"'

# Network connectivity
ssh dell5280 '/opt/remote-test-controller run-workload <test-id> "curl -s -o /dev/null -w \"%{http_code}\" https://pytorch.org || echo \"Network test\""'
```

## 🚀 Complete RLC-AI Test Workflows

### Quick Validation Test
```bash
# Start test
TEST_ID=$(ssh dell5280 '/opt/remote-test-controller start-rlc-ai-test /var/lib/libvirt/isos/rlc-ai-9.6.iso gpu_detection' | jq -r '.test_id')

# Wait for boot completion
while [[ "$(ssh dell5280 "/opt/remote-test-controller status $TEST_ID" | jq -r '.status')" == "detecting_boot" ]]; do
    echo "Waiting for boot..."
    sleep 10
done

# Run GPU test
ssh dell5280 "/opt/remote-test-controller run-workload $TEST_ID \"nvidia-smi\""
```

### Full AI Stack Validation
```bash
# Start comprehensive test
TEST_ID=$(ssh dell5280 '/opt/remote-test-controller start-rlc-ai-test /var/lib/libvirt/isos/rlc-ai-9.6.iso full' | jq -r '.test_id')

# Monitor progress
ssh dell5280 "/opt/remote-test-controller status $TEST_ID" | jq '.progress'

# Get final results
ssh dell5280 "/opt/remote-test-controller status $TEST_ID" | jq '.results'
```

### Custom Workload Test
```bash
# Start basic test
TEST_ID=$(ssh dell5280 '/opt/remote-test-controller start-rlc-ai-test /var/lib/libvirt/isos/rlc-ai-9.6.iso minimal' | jq -r '.test_id')

# Custom AI workloads
ssh dell5280 "/opt/remote-test-controller run-workload $TEST_ID \"python3 -c 'import transformers; print(transformers.__version__)'\""
ssh dell5280 "/opt/remote-test-controller run-workload $TEST_ID \"python3 -c 'from sklearn import __version__; print(f\"sklearn: {__version__}\")'\""
ssh dell5280 "/opt/remote-test-controller run-workload $TEST_ID \"python3 -c 'import pandas as pd; print(f\"pandas: {pd.__version__}\")'\""
```

## 📊 Expected JSON Responses

### Test Status Response
```json
{
    "test_id": "rlc-ai-test-20241219-143022-1234",
    "test_type": "rlc-ai-validation",
    "vm_name": "rlc-ai-vm-20241219-143022-1234",
    "iso_path": "/var/lib/libvirt/isos/rlc-ai-9.6.iso",
    "status": "testing_ai_workloads",
    "start_time": "2024-12-19T14:30:22Z",
    "progress": {
        "vm_creation": "completed",
        "boot_detection": "completed",
        "ai_workload": "running"
    },
    "results": {
        "boot_result": "gpu_detected",
        "boot_time": "45s"
    },
    "mcp_compatible": true
}
```

### Command Execution Response
```json
{
    "command": "nvidia-smi",
    "vm_name": "rlc-ai-vm-20241219-143022-1234",
    "timestamp": "2024-12-19T14:35:15Z",
    "execution_time_seconds": 3,
    "exit_code": 0,
    "output": "NVIDIA GPU detected: Tesla T4\nCUDA Version: 12.0",
    "success": true
}
```

### System Status Response
```json
{
    "ready": true,
    "framework_version": "1.1-rlc-ai",
    "mcp_compatible": true,
    "current_tests": 1,
    "max_tests": 4,
    "capabilities": [
        "rlc_ai_boot_detection",
        "ai_workload_testing",
        "command_execution",
        "gpu_validation",
        "container_testing"
    ],
    "system_info": {
        "hostname": "dell-server",
        "uptime": "7 hours",
        "memory_usage": "45.2%",
        "load_average": "0.10",
        "vm_storage": "15G available"
    },
    "timestamp": "2024-12-19T14:30:22Z"
}
```

## 🔍 Boot Detection Indicators

The enhanced controller looks for these RLC-AI specific boot signatures:

### AI System Indicators
- `rocky.*linux.*ai` or `ai.*rocky` - RLC-AI branding
- `artificial.*intelligence` - AI system identification

### Hardware Detection
- `nvidia` or `cuda` or `gpu` - GPU initialization
- `tesla` or `quadro` or `geforce` - Specific GPU models

### Software Stack
- `podman` or `docker` or `container` - Container runtime
- `python.*torch` or `tensorflow` - AI frameworks
- `jupyter` or `notebook` - AI development tools

### Standard Boot
- `login:` or `rocky.*login` - Standard login prompt

## 🎯 Test Types Available

### `gpu_detection`
- Basic GPU/CUDA detection
- Minimal resource usage
- Fast execution (~2 minutes)

### `pytorch`
- PyTorch installation validation
- CUDA integration testing
- Medium execution time (~5 minutes)

### `tensorflow`
- TensorFlow installation validation
- GPU acceleration testing
- Medium execution time (~5 minutes)

### `container`
- Container runtime validation
- AI container capability
- Fast execution (~3 minutes)

### `full` (default)
- Complete AI stack validation
- All frameworks + containers + GPU
- Comprehensive testing (~10 minutes)

### `minimal`
- Basic boot + system validation
- No AI framework testing
- Fastest execution (~1 minute)

## 🧪 Debugging and Troubleshooting

### Check Test Logs
```bash
# View test logs
ssh dell5280 'ls -la ~/vm-testing/logs/'
ssh dell5280 'tail -f ~/vm-testing/logs/controller.log'

# View specific test boot log
ssh dell5280 'cat ~/vm-testing/logs/<vm-name>-boot.log'

# View command execution log
ssh dell5280 'cat ~/vm-testing/logs/<vm-name>-commands.log'
```

### Check Test Results
```bash
# List all test results
ssh dell5280 'ls -la ~/vm-testing/results/'

# View test status
ssh dell5280 'cat ~/vm-testing/results/<test-id>-status.json | jq .'

# View AI workload summary
ssh dell5280 'cat ~/vm-testing/results/<test-id>-ai-workload-summary.json | jq .'
```

### Monitor Running VMs
```bash
# List all VMs
ssh dell5280 'virsh list --all'

# View VM console (for debugging)
ssh dell5280 'virsh console <vm-name>'

# Check VM status
ssh dell5280 'vm-test-manager status <vm-name>'
```

---

**🎯 Ready for RLC-AI Testing!**

These templates provide comprehensive testing capabilities for RLC-AI ISO validation with full MCP integration support.
