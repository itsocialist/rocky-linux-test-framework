# Rocky Linux Test Framework - API Reference

## 🎯 Overview
Complete command reference for the Rocky Linux Test Framework JSON API.

## 🔧 Core Commands

### System Status & Readiness

#### `ready`
Check if the framework is ready for testing
```bash
/opt/remote-test-controller ready
```

**Response:**
```json
{
  "ready": true,
  "framework_version": "1.1-rlc-ai",
  "mcp_compatible": true
}
```

#### `status`
Get comprehensive system status
```bash
/opt/remote-test-controller status [test-id]
```

**Response (System):**
```json
{
  "ready": true,
  "current_tests": 0,
  "max_tests": 4,
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
    "uptime": "up 2 days, 5 hours",
    "memory_usage": "35.9%",
    "load_average": "0.15",
    "vm_storage": "15G available"
  }
}
```

**Response (Specific Test):**
```json
{
  "test_id": "test-20250620-143022-1234",
  "status": "running",
  "test_type": "rlc-ai-validation",
  "vm_name": "test-vm-20250620-143022-1234",
  "iso_path": "/var/lib/libvirt/isos/rlc-ai.iso",
  "start_time": "2025-06-20T14:30:22Z",
  "progress": {
    "boot_detection": "completed",
    "ai_workload": "running",
    "current_command": "nvidia-smi"
  },
  "results": {
    "boot_time": "45s",
    "gpu_detected": true,
    "cuda_available": true,
    "commands_executed": 3,
    "failed_commands": 0
  }
}
```

## 🧪 Test Management

### Basic VM Testing

#### `start-test`
Start basic VM test with ISO
```bash
/opt/remote-test-controller start-test <iso-path>
```

**Parameters:**
- `iso-path`: Full path to ISO file

**Response:**
```json
{
  "test_id": "test-20250620-143022-1234",
  "status": "started", 
  "vm_name": "test-vm-20250620-143022-1234",
  "iso_path": "/var/lib/libvirt/isos/test.iso"
}
```

### Enhanced AI Testing

#### `start-rlc-ai-test`
Start enhanced AI/GPU testing
```bash
/opt/remote-test-controller start-rlc-ai-test <iso-path> [test-type] [workload]
```

**Parameters:**
- `iso-path`: Full path to ISO file
- `test-type`: Test type (optional, default: `full`)
  - `minimal` - Basic boot + system validation
  - `gpu_detection` - GPU/CUDA detection only
  - `pytorch` - PyTorch framework validation  
  - `tensorflow` - TensorFlow framework validation
  - `container` - Container runtime validation
  - `full` - Complete AI stack validation
- `workload`: Specific workload name (optional)

**Response:**
```json
{
  "test_id": "rlc-ai-test-20250620-143022-1234",
  "status": "started",
  "test_type": "rlc-ai-validation", 
  "vm_name": "rlc-ai-vm-20250620-143022-1234",
  "iso_path": "/var/lib/libvirt/isos/rlc-ai.iso",
  "workload_type": "full"
}
```

#### `run-workload`
Execute command in running test VM
```bash
/opt/remote-test-controller run-workload <test-id> "<command>"
```

**Parameters:**
- `test-id`: Test identifier from start command
- `command`: Shell command to execute in VM

**Built-in Commands:**
- `nvidia-smi` - GPU detection and status
- `python3 -c "import torch; print(torch.cuda.is_available())"` - PyTorch CUDA test
- `python3 -c "import tensorflow as tf; print(tf.config.list_physical_devices())"` - TensorFlow test
- `podman run --rm hello-world` - Container runtime test
- `lscpu | grep -i virtual` - CPU virtualization check

**Response:**
```json
{
  "test_id": "rlc-ai-test-20250620-143022-1234",
  "command": "nvidia-smi",
  "status": "executed",
  "exit_code": 0,
  "output": "GPU information output...",
  "execution_time": "2.3s"
}
```

## 📋 Test Listing & Management

#### `list`
List current tests
```bash
/opt/remote-test-controller list [filter]
```

**Filters:**
- `running` - Show only running tests
- `completed` - Show only completed tests  
- `failed` - Show only failed tests
- (no filter) - Show all tests

**Response:**
```json
{
  "tests": [
    {
      "test_id": "test-20250620-143022-1234",
      "status": "running",
      "vm_name": "test-vm-20250620-143022-1234", 
      "start_time": "2025-06-20T14:30:22Z",
      "test_type": "basic"
    },
    {
      "test_id": "rlc-ai-test-20250620-120000-5678",
      "status": "completed",
      "vm_name": "rlc-ai-vm-20250620-120000-5678",
      "start_time": "2025-06-20T12:00:00Z", 
      "end_time": "2025-06-20T12:15:30Z",
      "test_type": "rlc-ai-validation"
    }
  ],
  "total_tests": 2,
  "running_tests": 1,
  "completed_tests": 1
}
```

#### `stop`
Stop running test
```bash
/opt/remote-test-controller stop <test-id>
```

**Response:**
```json
{
  "test_id": "test-20250620-143022-1234",
  "status": "stopped",
  "cleanup": "completed"
}
```

## 🔧 VM Management Commands

### VM Lifecycle

#### `vm-test-manager create`
Create new VM
```bash
/opt/vm-test-manager create <vm-name> <template> [iso-path]
```

**Templates:**
- `standard` - 2GB RAM, 2 vCPU (default)
- `minimal` - 1GB RAM, 1 vCPU 
- `performance` - 4GB RAM, 4 vCPU

#### `vm-test-manager start`
Start existing VM
```bash
/opt/vm-test-manager start <vm-name> [iso-path]
```

#### `vm-test-manager stop`
Stop running VM
```bash
/opt/vm-test-manager stop <vm-name>
```

#### `vm-test-manager delete`
Delete VM and cleanup
```bash
/opt/vm-test-manager delete <vm-name>
```

#### `vm-test-manager list`
List all VMs
```bash
/opt/vm-test-manager list
```

#### `vm-test-manager vnc`
Get VNC port for VM console access
```bash
/opt/vm-test-manager vnc <vm-name>
```

#### `vm-test-manager status`
Get VM status information
```bash
/opt/vm-test-manager status [vm-name]
```

## 🤖 MCP Integration Examples

### Claude Automation Workflow

```javascript
// Example MCP integration for Claude
async function testRockyLinuxISO(isoPath) {
  // Start enhanced AI test
  const startResult = await ssh.exec(`/opt/remote-test-controller start-rlc-ai-test ${isoPath} full`);
  const testId = JSON.parse(startResult.stdout).test_id;
  
  // Monitor progress
  let status;
  do {
    await sleep(30000); // Wait 30 seconds
    const statusResult = await ssh.exec(`/opt/remote-test-controller status ${testId}`);
    status = JSON.parse(statusResult.stdout);
    console.log(`Test ${testId}: ${status.status}`);
  } while (status.status === 'running');
  
  // Return results
  return status;
}
```

### Test Result Processing

```javascript
// Process test results for analysis
function analyzeTestResults(testStatus) {
  const results = testStatus.results;
  
  return {
    bootSuccessful: results.boot_time < "60s",
    gpuAvailable: results.gpu_detected,
    cudaWorking: results.cuda_available,
    testsPassed: results.failed_commands === 0,
    recommendations: generateRecommendations(results)
  };
}
```

## 🔧 Helper Commands

### System Helpers

#### `test-status`
Quick system overview
```bash
test-status
```

#### `quick-vm`
Quick VM creation and start
```bash
quick-vm <vm-name> [iso-path]
```

## 🚨 Error Responses

### Common Error Format
```json
{
  "error": true,
  "message": "Error description",
  "code": "ERROR_CODE",
  "details": "Additional error information"
}
```

### Error Codes
- `TEST_NOT_FOUND` - Test ID does not exist
- `VM_CREATE_FAILED` - VM creation failed
- `ISO_NOT_FOUND` - ISO file not accessible
- `RESOURCES_EXHAUSTED` - System resources unavailable
- `COMMAND_FAILED` - Command execution failed
- `INVALID_PARAMETERS` - Invalid command parameters

## 📊 Status Values

### Test Status
- `starting` - Test initialization in progress
- `running` - Test execution in progress  
- `completed` - Test finished successfully
- `failed` - Test failed with errors
- `stopped` - Test manually stopped
- `timeout` - Test exceeded time limit

### VM Status  
- `creating` - VM creation in progress
- `running` - VM is running
- `stopped` - VM is stopped
- `error` - VM in error state
- `undefined` - VM does not exist

## 🔗 Related Documentation

- [Quick Start Guide](QUICK-START.md) - Getting started
- [AI Testing Guide](AI-TESTING.md) - RLC-AI specific testing
- [MCP Integration](MCP-INTEGRATION.md) - Claude automation
- [Troubleshooting](TROUBLESHOOTING.md) - Common issues

---

**Framework Version**: 1.1-rlc-ai  
**Last Updated**: June 20, 2025  
**MCP Compatible**: ✅ Yes
