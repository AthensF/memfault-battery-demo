#!/bin/bash
# Simple Memfault data extraction using memory dumps and CLI

set -e

echo "🔋 Simple Memfault Data Extraction"
echo "================================="

# Check if project key is set
if [ -z "$MEMFAULT_PROJECT_KEY" ]; then
    echo "❌ MEMFAULT_PROJECT_KEY environment variable not set"
    exit 1
fi

# Check if GDB server is accessible
if ! nc -z localhost 3333 2>/dev/null; then
    echo "❌ GDB server not accessible on port 3333"
    echo "   Make sure Renode is running with GDB enabled"
    exit 1
fi

echo "✅ Project key set"
echo "✅ GDB server accessible"

# Create a simple GDB script to dump the event storage
cat > /tmp/dump_storage.gdb << 'EOF'
target remote :3333
# Find the event storage buffer (from memfault_platform_port.c)
# It's a static 1024-byte buffer called s_event_storage
info variables s_event_storage
# Dump the storage buffer to a file
dump binary memory memfault_event_storage.bin &s_event_storage &s_event_storage+1024
echo \nEvent storage dumped to memfault_event_storage.bin\n
quit
EOF

echo "🔍 Extracting event storage buffer..."
arm-none-eabi-gdb build/battery_demo.elf -batch -x /tmp/dump_storage.gdb

if [ -f "memfault_event_storage.bin" ]; then
    echo "✅ Event storage extracted ($(wc -c < memfault_event_storage.bin) bytes)"
    
    # Check if memfault-cli is available
    if command -v memfault &> /dev/null; then
        echo "🚀 Uploading to Memfault cloud..."
        # Try to upload the raw storage buffer
        memfault --project-key "$MEMFAULT_PROJECT_KEY" post-chunk --encoding sdk_data_export memfault_event_storage.bin
        echo "✅ Upload attempt complete!"
    else
        echo "💡 Install memfault-cli to upload:"
        echo "   pip3 install memfault-cli"
        echo "   Then run:"
        echo "   memfault --project-key \$MEMFAULT_PROJECT_KEY post-chunk --encoding sdk_data_export memfault_event_storage.bin"
    fi
else
    echo "❌ Failed to extract event storage"
fi

# Cleanup
rm -f /tmp/dump_storage.gdb
