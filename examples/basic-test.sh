#!/bin/bash
# Basic VM testing example

# Configuration
SERVER="user@your-server"  # Change to your server
ISO_PATH="/var/lib/libvirt/isos/test.iso"

echo "🧪 Basic VM Testing Example"
echo "=========================="

# Upload ISO (optional - if you have one locally)
# scp local-test.iso $SERVER:/var/lib/libvirt/isos/

# Start basic VM test
echo "Starting VM test..."
TEST_RESULT=$(ssh $SERVER "/opt/remote-test-controller start-test $ISO_PATH")
TEST_ID=$(echo "$TEST_RESULT" | jq -r '.test_id')

echo "Test started with ID: $TEST_ID"

# Monitor test status
echo "Monitoring test progress..."
while true; do
    STATUS=$(ssh $SERVER "/opt/remote-test-controller status $TEST_ID" | jq -r '.status')
    echo "Status: $STATUS"
    
    if [[ "$STATUS" == "completed" || "$STATUS" == "failed" ]]; then
        break
    fi
    
    sleep 10
done

# Get final results
echo "Final results:"
ssh $SERVER "/opt/remote-test-controller status $TEST_ID" | jq .

echo "✅ Basic test completed!"
