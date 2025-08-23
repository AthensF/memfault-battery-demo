#!/bin/bash
# Test Memfault upload with a simple test chunk

set -e

echo "🔋 Testing Memfault Upload"
echo "========================="

# Check project key
if [ -z "$MEMFAULT_PROJECT_KEY" ]; then
    echo "❌ MEMFAULT_PROJECT_KEY not set"
    exit 1
fi

echo "✅ Project key configured"

# Test with a minimal valid chunk (example from Memfault docs)
TEST_CHUNK="0802a702010301076a5445535453455249414c0a6d746573742d736f667477617265096a312e302e302d74657374066d746573742d686172647761726504a101a1726368756e6b5f746573745f737563636573730131e4"

echo "🧪 Testing with example chunk..."
export PATH="$HOME/.local/bin:$PATH"

memfault --project-key "$MEMFAULT_PROJECT_KEY" post-chunk --encoding hex "$TEST_CHUNK" --device-serial "DEMOSERIAL"

if [ $? -eq 0 ]; then
    echo "✅ Test upload successful! Project key is valid."
    echo "📊 Check your Memfault dashboard for the test data."
else
    echo "❌ Test upload failed. Please verify your project key."
fi
