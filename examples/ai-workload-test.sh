#!/bin/bash
# RLC-AI testing example with GPU and AI framework validation

# Configuration
SERVER="user@your-server"  # Change to your server
RLC_AI_ISO="/var/lib/libvirt/isos/rlc-ai-9.6.iso"

echo "🤖 RLC-AI Testing Example"
echo "========================="

# Start RLC-AI test
echo "Starting RLC-AI test..."
TEST_RESULT=$(ssh $SERVER "/opt/remote-test-controller start-rlc-ai-test $RLC_AI_ISO full")
TEST_ID=$(echo "$TEST_RESULT" | jq -r '.test_id')

echo "RLC-AI test started with ID: $TEST_ID"

# Wait for boot detection
echo "Waiting for boot detection..."
while true; do
    STATUS=$(ssh $SERVER "/opt/remote-test-controller status $TEST_ID" | jq -r '.status')
    echo "Status: $STATUS"
    
    if [[ "$STATUS" == "boot_completed" || "$STATUS" == "failed" ]]; then
        break
    fi
    
    sleep 15
done

if [[ "$STATUS" == "failed" ]]; then
    echo "❌ Boot detection failed"
    exit 1
fi

echo "✅ Boot detection completed"

# Run AI workload tests
echo "Running AI workload tests..."

# GPU Detection
echo "Testing GPU detection..."
GPU_RESULT=$(ssh $SERVER "/opt/remote-test-controller run-workload $TEST_ID 'nvidia-smi'")
echo "GPU Test Result: $(echo "$GPU_RESULT" | jq -r '.output')"

# PyTorch Test
echo "Testing PyTorch..."
PYTORCH_RESULT=$(ssh $SERVER "/opt/remote-test-controller run-workload $TEST_ID 'python3 -c \"import torch; print(torch.cuda.is_available())\"'")
echo "PyTorch CUDA: $(echo "$PYTORCH_RESULT" | jq -r '.output')"

# TensorFlow Test
echo "Testing TensorFlow..."
TF_RESULT=$(ssh $SERVER "/opt/remote-test-controller run-workload $TEST_ID 'python3 -c \"import tensorflow as tf; print(tf.config.list_physical_devices())\"'")
echo "TensorFlow Devices: $(echo "$TF_RESULT" | jq -r '.output')"

# Container Test
echo "Testing container runtime..."
CONTAINER_RESULT=$(ssh $SERVER "/opt/remote-test-controller run-workload $TEST_ID 'podman run --rm hello-world'")
echo "Container Test: $(echo "$CONTAINER_RESULT" | jq -r '.output')"

# Get final comprehensive status
echo "Getting final test status..."
FINAL_STATUS=$(ssh $SERVER "/opt/remote-test-controller status $TEST_ID")
echo "$FINAL_STATUS" | jq .

# Summary
echo ""
echo "🎯 AI Testing Summary"
echo "===================="
echo "Test ID: $TEST_ID"
echo "GPU Available: $(echo "$GPU_RESULT" | jq -r '.success')"
echo "PyTorch Working: $(echo "$PYTORCH_RESULT" | jq -r '.success')"
echo "TensorFlow Working: $(echo "$TF_RESULT" | jq -r '.success')"
echo "Containers Working: $(echo "$CONTAINER_RESULT" | jq -r '.success')"

echo "✅ RLC-AI testing completed!"
