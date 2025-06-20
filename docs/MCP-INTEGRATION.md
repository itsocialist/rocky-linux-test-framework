# MCP Integration Guide for Rocky Linux Test Framework

## 🤖 Overview

This guide explains how to integrate the Rocky Linux Test Framework with Claude via MCP (Model Context Protocol). The enhanced framework provides MCP-compatible JSON APIs perfect for Claude-driven testing workflows.

## 🔄 MCP Architecture

```
Claude ←→ MCP Server ←→ SSH Commands ←→ Dell Server Framework
                ↓
        Structured JSON API
        Real-time Status
        Detailed Logging
```

## 📡 MCP-Compatible API Commands

### Core Status Commands
```javascript
// Check framework readiness
const ready = await ssh.exec('dell5280', '/opt/remote-test-controller ready');
// Returns: "true" or "false"

// Get system status
const status = await ssh.exec('dell5280', '/opt/remote-test-controller status');
// Returns: JSON object with system info
```

### RLC-AI Testing Commands
```javascript
// Start RLC-AI test
const testResult = await ssh.exec('dell5280', '/opt/remote-test-controller start-rlc-ai-test /var/lib/libvirt/isos/rlc-ai-9.6.iso');
// Returns: JSON with test_id and initial status

// Get test progress
const progress = await ssh.exec('dell5280', `/opt/remote-test-controller status ${testId}`);
// Returns: JSON with detailed progress and results

// Run AI workload
const workloadResult = await ssh.exec('dell5280', `/opt/remote-test-controller run-workload ${testId} "nvidia-smi"`);
// Returns: JSON with command execution results
```

### Test Management Commands
```javascript
// List all tests
const tests = await ssh.exec('dell5280', '/opt/remote-test-controller list');
// Returns: JSON array of test IDs

// List running tests
const runningTests = await ssh.exec('dell5280', '/opt/remote-test-controller list running');
// Returns: JSON array of currently running test IDs

// List completed tests
const completedTests = await ssh.exec('dell5280', '/opt/remote-test-controller list completed');
// Returns: JSON array of completed test IDs
```

## 🎯 Claude Workflow Examples

### Example 1: Basic RLC-AI Validation
```markdown
User: "Test the RLC-AI ISO on the Dell server"

Claude workflow:
1. Check framework readiness
2. Start RLC-AI test
3. Monitor boot detection
4. Run GPU validation
5. Report results with recommendations
```

### Example 2: Comprehensive AI Stack Testing
```markdown
User: "Run a full AI validation suite on the latest RLC-AI build"

Claude workflow:
1. Upload ISO (if needed)
2. Start full RLC-AI test
3. Monitor all test phases
4. Run custom AI workloads
5. Analyze results and provide summary
6. Generate test report
```

### Example 3: Custom Workload Testing
```markdown
User: "Test PyTorch and TensorFlow on RLC-AI"

Claude workflow:
1. Start minimal RLC-AI test
2. Wait for boot completion
3. Run PyTorch validation commands
4. Run TensorFlow validation commands
5. Compare framework performance
6. Provide optimization recommendations
```

## 📊 JSON API Responses for MCP

### System Status Response
```json
{
    "ready": true,
    "framework_version": "1.1-rlc-ai",
    "mcp_compatible": true,
    "current_tests": 0,
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

### Test Progress Response
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
        "boot_time": "45s",
        "gpu_detected": true,
        "cuda_available": true
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

## 🛠️ MCP Server Implementation Example

### Basic MCP Tool Definition
```typescript
interface RLCAITestTool {
    name: "rlc_ai_test";
    description: "Test RLC-AI ISO on Dell server";
    parameters: {
        iso_path: string;
        test_type?: "minimal" | "gpu_detection" | "pytorch" | "tensorflow" | "container" | "full";
        ai_workload?: "minimal" | "gpu_detection" | "pytorch" | "tensorflow" | "container" | "full";
    };
}

interface RunWorkloadTool {
    name: "run_ai_workload";
    description: "Run AI workload command on test VM";
    parameters: {
        test_id: string;
        command: string;
        timeout?: number;
    };
}

interface GetTestStatusTool {
    name: "get_test_status";
    description: "Get status of RLC-AI test";
    parameters: {
        test_id?: string;
    };
}
```

### MCP Tool Implementation
```typescript
async function handleRLCAITest(params: RLCAITestParameters): Promise<any> {
    const command = `/opt/remote-test-controller start-rlc-ai-test ${params.iso_path} ${params.test_type || 'full'} ${params.ai_workload || 'full'}`;
    const result = await ssh.exec('dell5280', command);
    return JSON.parse(result);
}

async function handleRunWorkload(params: RunWorkloadParameters): Promise<any> {
    const command = `/opt/remote-test-controller run-workload ${params.test_id} "${params.command}"`;
    const result = await ssh.exec('dell5280', command);
    return JSON.parse(result);
}

async function handleGetTestStatus(params: GetTestStatusParameters): Promise<any> {
    const command = `/opt/remote-test-controller status ${params.test_id || ''}`;
    const result = await ssh.exec('dell5280', command);
    return JSON.parse(result);
}
```

## 🔍 Claude Integration Patterns

### Pattern 1: Polling for Completion
```javascript
async function waitForTestCompletion(testId) {
    let status = 'running';
    while (status === 'running' || status === 'detecting_boot' || status === 'testing_ai_workloads') {
        const result = await ssh.exec('dell5280', `/opt/remote-test-controller status ${testId}`);
        const testStatus = JSON.parse(result);
        status = testStatus.status;
        
        // Report progress to user
        claude.updateUser(`Test progress: ${testStatus.progress}`);
        
        // Wait before next check
        await sleep(10000); // 10 seconds
    }
    return status;
}
```

### Pattern 2: Progressive Enhancement
```javascript
async function comprehensiveRLCAITest(isoPath) {
    // Start basic test
    const testResult = await ssh.exec('dell5280', `/opt/remote-test-controller start-rlc-ai-test ${isoPath} minimal`);
    const testId = JSON.parse(testResult).test_id;
    
    // Wait for boot
    await waitForBootComplete(testId);
    
    // Progressive AI testing
    const tests = [
        'nvidia-smi',
        'python3 -c "import torch; print(torch.cuda.is_available())"',
        'python3 -c "import tensorflow as tf; print(tf.config.list_physical_devices())"',
        'podman run --rm hello-world'
    ];
    
    for (const test of tests) {
        const result = await ssh.exec('dell5280', `/opt/remote-test-controller run-workload ${testId} "${test}"`);
        const testResult = JSON.parse(result);
        claude.reportProgress(testResult);
    }
}
```

### Pattern 3: Error Handling and Recovery
```javascript
async function robustRLCAITest(isoPath) {
    try {
        const testResult = await ssh.exec('dell5280', `/opt/remote-test-controller start-rlc-ai-test ${isoPath}`);
        const testStatus = JSON.parse(testResult);
        
        if (!testStatus.test_id) {
            throw new Error('Test failed to start');
        }
        
        // Monitor with timeout
        const completed = await waitForTestCompletion(testStatus.test_id, 600); // 10 minute timeout
        
        if (completed === 'failed') {
            // Get detailed error info
            const status = await ssh.exec('dell5280', `/opt/remote-test-controller status ${testStatus.test_id}`);
            const errorInfo = JSON.parse(status);
            claude.reportError('Test failed', errorInfo);
        }
        
    } catch (error) {
        claude.reportError('Test execution error', error);
        // Attempt cleanup
        await ssh.exec('dell5280', '/opt/remote-test-controller list running').then(cleanup);
    }
}
```

## 📈 Claude Reporting Templates

### Progress Updates
```markdown
🔄 **RLC-AI Test Progress Update**

**Test ID**: `rlc-ai-test-20241219-143022-1234`
**Status**: Testing AI workloads
**Progress**: 
- ✅ VM Creation (completed)
- ✅ Boot Detection (45s - GPU detected)
- 🔄 AI Workload Testing (running)

**Next**: PyTorch validation
```

### Success Report
```markdown
✅ **RLC-AI Test Completed Successfully**

**Test Summary**:
- **Boot Time**: 45 seconds
- **GPU Status**: ✅ NVIDIA Tesla T4 detected
- **CUDA**: ✅ Version 12.0 available
- **PyTorch**: ✅ GPU acceleration working
- **TensorFlow**: ✅ GPU devices detected
- **Containers**: ✅ Podman functional

**Recommendations**:
- System is ready for AI workloads
- GPU performance optimal
- Container stack fully functional
```

### Error Report
```markdown
❌ **RLC-AI Test Failed**

**Error**: Boot timeout after 300 seconds
**Possible Causes**:
- ISO corruption or incomplete download
- Insufficient VM resources
- Hardware compatibility issues

**Recommended Actions**:
1. Verify ISO integrity
2. Check VM resource allocation
3. Review boot logs for specific errors

**Logs Available**: `~/vm-testing/logs/rlc-ai-vm-*-boot.log`
```

## 🎯 MCP Best Practices

### 1. Stateless Operations
- Each MCP call should be independent
- Use test IDs for stateful operations
- Always check system readiness before starting tests

### 2. Error Handling
- Parse JSON responses safely
- Handle SSH connection failures gracefully
- Provide meaningful error messages to users

### 3. Resource Management
- Check current test count before starting new tests
- Monitor system resources
- Clean up failed tests automatically

### 4. User Experience
- Provide real-time progress updates
- Break long operations into steps
- Give clear next actions for failures

### 5. Security
- Use SSH key authentication
- Validate all input parameters
- Sanitize commands for shell injection

## 🚀 Deployment for MCP Integration

### Prerequisites
1. Enhanced framework deployed on Dell server
2. SSH key authentication configured
3. MCP server with SSH execution capability

### Testing MCP Integration
```bash
# Verify framework readiness
ssh dell5280 '/opt/remote-test-controller ready'
# Should return: true

# Test JSON API
ssh dell5280 '/opt/remote-test-controller status' | jq .
# Should return valid JSON

# Test RLC-AI capabilities  
ssh dell5280 '/opt/remote-test-controller start-rlc-ai-test /var/lib/libvirt/isos/test.iso minimal' | jq .test_id
# Should return test ID
```

### MCP Configuration Example
```json
{
    "servers": {
        "dell-vm-testing": {
            "command": "node",
            "args": ["dell-vm-mcp-server.js"],
            "env": {
                "DELL_SERVER": "dell5280",
                "SSH_KEY": "/path/to/ssh/key"
            }
        }
    }
}
```

---

**🎯 Ready for Claude Integration!**

The Rocky Linux Test Framework now provides full MCP compatibility with structured JSON APIs, real-time status updates, and comprehensive error handling - perfect for Claude-driven testing workflows.
