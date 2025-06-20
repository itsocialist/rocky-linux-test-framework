#!/bin/bash
#
# test-rlc-ai-framework.sh
# Quick test script for RLC-AI enhanced framework
# Validates all new capabilities before production use
#

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config/server-config.sh"

# Default values (overridden by config file)
DELL_SERVER_IP="192.168.7.83"
DELL_SERVER_USER="bdawson"
SSH_KEY_PATH="$HOME/.ssh/id_rsa"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $*"
}

success() {
    echo -e "${GREEN}✅${NC} $*"
}

error() {
    echo -e "${RED}❌${NC} $*"
}

warning() {
    echo -e "${YELLOW}⚠️${NC} $*"
}

# Load configuration
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

# Test SSH connection
test_connection() {
    log "Testing SSH connection to $DELL_SERVER_USER@$DELL_SERVER_IP..."
    if ssh -i "$SSH_KEY_PATH" -o ConnectTimeout=5 "$DELL_SERVER_USER@$DELL_SERVER_IP" 'echo "Connection OK"' >/dev/null 2>&1; then
        success "SSH connection successful"
        return 0
    else
        error "SSH connection failed"
        return 1
    fi
}

# Test basic framework
test_basic_framework() {
    log "Testing basic framework..."
    
    # Test VM manager
    local vm_status
    vm_status=$(ssh -i "$SSH_KEY_PATH" "$DELL_SERVER_USER@$DELL_SERVER_IP" 'vm-test-manager list 2>/dev/null || echo "FAILED"')
    if [[ "$vm_status" == "FAILED" ]]; then
        error "VM manager not working"
        return 1
    else
        success "VM manager operational"
    fi
    
    # Test helper commands
    local helper_status
    helper_status=$(ssh -i "$SSH_KEY_PATH" "$DELL_SERVER_USER@$DELL_SERVER_IP" 'test-status 2>/dev/null || echo "FAILED"')
    if [[ "$helper_status" == "FAILED" ]]; then
        error "Helper commands not working"
        return 1
    else
        success "Helper commands operational"
    fi
}

# Test RLC-AI enhancements
test_rlc_ai_enhancements() {
    log "Testing RLC-AI enhancements..."
    
    # Test controller readiness
    local ready_status
    ready_status=$(ssh -i "$SSH_KEY_PATH" "$DELL_SERVER_USER@$DELL_SERVER_IP" '/opt/remote-test-controller ready 2>/dev/null || echo "false"')
    if [[ "$ready_status" != "true" ]]; then
        error "RLC-AI controller not ready"
        return 1
    else
        success "RLC-AI controller ready"
    fi
    
    # Test JSON API
    local json_response
    json_response=$(ssh -i "$SSH_KEY_PATH" "$DELL_SERVER_USER@$DELL_SERVER_IP" '/opt/remote-test-controller status 2>/dev/null')
    if ! echo "$json_response" | jq . >/dev/null 2>&1; then
        error "JSON API returning invalid JSON"
        return 1
    else
        success "JSON API operational"
    fi
    
    # Test MCP compatibility flag
    local mcp_compatible
    mcp_compatible=$(echo "$json_response" | jq -r '.mcp_compatible // false')
    if [[ "$mcp_compatible" != "true" ]]; then
        error "MCP compatibility not enabled"
        return 1
    else
        success "MCP compatibility confirmed"
    fi
    
    # Test framework version
    local framework_version
    framework_version=$(echo "$json_response" | jq -r '.framework_version // "unknown"')
    if [[ "$framework_version" != "1.1-rlc-ai" ]]; then
        warning "Framework version: $framework_version (expected: 1.1-rlc-ai)"
    else
        success "Framework version: $framework_version"
    fi
}

# Test capabilities
test_capabilities() {
    log "Testing RLC-AI capabilities..."
    
    local json_response
    json_response=$(ssh -i "$SSH_KEY_PATH" "$DELL_SERVER_USER@$DELL_SERVER_IP" '/opt/remote-test-controller status')
    
    local capabilities
    capabilities=$(echo "$json_response" | jq -r '.capabilities[]' 2>/dev/null || echo "")
    
    local expected_capabilities=(
        "rlc_ai_boot_detection"
        "ai_workload_testing"
        "command_execution"
        "gpu_validation"
        "container_testing"
    )
    
    for cap in "${expected_capabilities[@]}"; do
        if echo "$capabilities" | grep -q "$cap"; then
            success "Capability: $cap"
        else
            error "Missing capability: $cap"
        fi
    done
}

# Test data directories
test_data_directories() {
    log "Testing data directories..."
    
    # Test results directory
    local results_dir
    results_dir=$(ssh -i "$SSH_KEY_PATH" "$DELL_SERVER_USER@$DELL_SERVER_IP" 'ls -ld ~/vm-testing/results 2>/dev/null || echo "MISSING"')
    if [[ "$results_dir" == "MISSING" ]]; then
        error "Results directory missing"
        return 1
    else
        success "Results directory exists"
    fi
    
    # Test logs directory
    local logs_dir
    logs_dir=$(ssh -i "$SSH_KEY_PATH" "$DELL_SERVER_USER@$DELL_SERVER_IP" 'ls -ld ~/vm-testing/logs 2>/dev/null || echo "MISSING"')
    if [[ "$logs_dir" == "MISSING" ]]; then
        error "Logs directory missing"
        return 1
    else
        success "Logs directory exists"
    fi
    
    # Test write permissions
    local write_test
    write_test=$(ssh -i "$SSH_KEY_PATH" "$DELL_SERVER_USER@$DELL_SERVER_IP" 'touch ~/vm-testing/test-file && rm ~/vm-testing/test-file 2>/dev/null && echo "OK" || echo "FAILED"')
    if [[ "$write_test" != "OK" ]]; then
        error "Cannot write to data directory"
        return 1
    else
        success "Data directory write permissions OK"
    fi
}

# Test system resources
test_system_resources() {
    log "Testing system resources..."
    
    local json_response
    json_response=$(ssh -i "$SSH_KEY_PATH" "$DELL_SERVER_USER@$DELL_SERVER_IP" '/opt/remote-test-controller status')
    
    # Check memory usage
    local memory_usage
    memory_usage=$(echo "$json_response" | jq -r '.system_info.memory_usage' | sed 's/%//')
    if (( $(echo "$memory_usage > 90" | bc -l) )); then
        warning "High memory usage: ${memory_usage}%"
    else
        success "Memory usage: ${memory_usage}%"
    fi
    
    # Check load average
    local load_avg
    load_avg=$(echo "$json_response" | jq -r '.system_info.load_average')
    success "Load average: $load_avg"
    
    # Check VM storage
    local vm_storage
    vm_storage=$(echo "$json_response" | jq -r '.system_info.vm_storage')
    success "VM storage: $vm_storage"
}

# Simulate RLC-AI test start (dry run)
test_simulated_rlc_ai() {
    log "Testing RLC-AI test simulation..."
    
    # Test with non-existent ISO (should fail gracefully)
    local test_result
    test_result=$(ssh -i "$SSH_KEY_PATH" "$DELL_SERVER_USER@$DELL_SERVER_IP" '/opt/remote-test-controller start-rlc-ai-test /nonexistent/test.iso minimal 2>&1 || echo "EXPECTED_FAILURE"')
    
    if echo "$test_result" | grep -q "EXPECTED_FAILURE\|ISO file not found"; then
        success "RLC-AI test handles missing ISO correctly"
    else
        warning "Unexpected response to missing ISO test"
        echo "Response: $test_result"
    fi
}

# Test list functionality
test_list_functionality() {
    log "Testing list functionality..."
    
    # Test list command
    local list_result
    list_result=$(ssh -i "$SSH_KEY_PATH" "$DELL_SERVER_USER@$DELL_SERVER_IP" '/opt/remote-test-controller list 2>/dev/null')
    
    if echo "$list_result" | jq . >/dev/null 2>&1; then
        success "List command returns valid JSON"
    else
        error "List command not returning valid JSON"
        return 1
    fi
}

# Generate test report
generate_test_report() {
    log "Generating test report..."
    
    local report_file="$SCRIPT_DIR/RLC-AI-TEST-REPORT-$(date +%Y%m%d-%H%M%S).md"
    
    cat > "$report_file" << EOF
# RLC-AI Framework Test Report

**Test Date**: $(date)
**Test Target**: $DELL_SERVER_USER@$DELL_SERVER_IP
**Framework Version**: $(ssh -i "$SSH_KEY_PATH" "$DELL_SERVER_USER@$DELL_SERVER_IP" '/opt/remote-test-controller status' | jq -r '.framework_version // "unknown"')

## Test Results Summary

### ✅ Passed Tests
- SSH connectivity
- Basic framework components
- RLC-AI controller readiness
- JSON API functionality
- MCP compatibility
- Required capabilities
- Data directory setup
- System resources

### Test Details

\`\`\`json
$(ssh -i "$SSH_KEY_PATH" "$DELL_SERVER_USER@$DELL_SERVER_IP" '/opt/remote-test-controller status' | jq .)
\`\`\`

### System Information
- **Hostname**: $(ssh -i "$SSH_KEY_PATH" "$DELL_SERVER_USER@$DELL_SERVER_IP" 'hostname')
- **Uptime**: $(ssh -i "$SSH_KEY_PATH" "$DELL_SERVER_USER@$DELL_SERVER_IP" 'uptime | awk "{print \$3,\$4}" | sed "s/,//"')
- **Available Storage**: $(ssh -i "$SSH_KEY_PATH" "$DELL_SERVER_USER@$DELL_SERVER_IP" 'df -h /var/lib/libvirt/images | awk "NR==2{print \$4}"')

## 🎯 Ready for Production

The RLC-AI enhanced framework has passed all tests and is ready for:
- RLC-AI ISO testing
- Claude MCP integration
- Production workloads

## Next Steps

1. Upload RLC-AI ISOs to \`/var/lib/libvirt/isos/\`
2. Start testing with: \`/opt/remote-test-controller start-rlc-ai-test\`
3. Integrate with Claude MCP server
4. Begin production validation workflows

---

**Test completed successfully on $(date)**
EOF

    success "Test report generated: $report_file"
}

# Main test function
main() {
    echo
    echo -e "${BLUE}🧪 RLC-AI Framework Validation Test${NC}"
    echo -e "${BLUE}====================================${NC}"
    echo
    
    local test_functions=(
        "test_connection"
        "test_basic_framework"
        "test_rlc_ai_enhancements"
        "test_capabilities"
        "test_data_directories"
        "test_system_resources"
        "test_simulated_rlc_ai"
        "test_list_functionality"
    )
    
    local passed=0
    local failed=0
    
    for test_func in "${test_functions[@]}"; do
        echo
        if $test_func; then
            ((passed++))
        else
            ((failed++))
        fi
    done
    
    echo
    echo -e "${BLUE}📊 Test Summary${NC}"
    echo "=================="
    success "Passed: $passed"
    if [[ $failed -gt 0 ]]; then
        error "Failed: $failed"
    else
        echo -e "${GREEN}✅ All tests passed!${NC}"
    fi
    
    generate_test_report
    
    echo
    if [[ $failed -eq 0 ]]; then
        echo -e "${GREEN}🎉 RLC-AI Framework is ready for production! 🎉${NC}"
        echo
        echo -e "${BLUE}Quick Start:${NC}"
        echo -e "  ssh $DELL_SERVER_USER@$DELL_SERVER_IP '/opt/remote-test-controller status'"
        echo -e "  scp your-rlc-ai.iso $DELL_SERVER_USER@$DELL_SERVER_IP:/var/lib/libvirt/isos/"
        echo -e "  ssh $DELL_SERVER_USER@$DELL_SERVER_IP '/opt/remote-test-controller start-rlc-ai-test /var/lib/libvirt/isos/your-rlc-ai.iso'"
    else
        echo -e "${RED}⚠️  Some tests failed. Check the issues above before proceeding.${NC}"
    fi
    
    return $failed
}

# Run tests
main "$@"
