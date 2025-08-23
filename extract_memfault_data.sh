#!/bin/bash
# Script to extract Memfault chunks from Renode simulation

set -e

echo "🔋 Memfault Chunk Extraction Script"
echo "=================================="

# Check if project key is set
if [ -z "$MEMFAULT_PROJECT_KEY" ]; then
    echo "❌ MEMFAULT_PROJECT_KEY environment variable not set"
    echo "   Run: export MEMFAULT_PROJECT_KEY=your_key_here"
    exit 1
fi

# Check if Renode is running with GDB server
if ! nc -z localhost 3333 2>/dev/null; then
    echo "❌ GDB server not accessible on port 3333"
    echo "   Make sure Renode is running with: include @battery_demo_gdb.resc"
    exit 1
fi

echo "✅ Project key set"
echo "✅ GDB server accessible"

# Create GDB commands file
cat > /tmp/memfault_extract.gdb << EOF
target remote :3333
source ../third_party/memfault/memfault-firmware-sdk/scripts/memfault_gdb.py
echo \n=== Extracting Memfault Data ===\n
memfault export_data --file memfault_chunks.bin
echo \nData exported to memfault_chunks.bin\n
quit
EOF

echo "🔍 Connecting to GDB and extracting chunks..."

# Run GDB with our script
arm-none-eabi-gdb build/battery_demo.elf -batch -x /tmp/memfault_extract.gdb

# Check if data was extracted
if [ -f "memfault_chunks.bin" ]; then
    echo "✅ Chunks extracted to memfault_chunks.bin"
    echo "📊 File size: $(wc -c < memfault_chunks.bin) bytes"
    
    # Install memfault-cli if not present
    if ! command -v memfault &> /dev/null; then
        echo "💡 Install memfault-cli to upload chunks:"
        echo "   pip install memfault-cli"
    else
        echo "🚀 Uploading chunks to Memfault..."
        memfault --project-key "$MEMFAULT_PROJECT_KEY" post-chunk --encoding sdk_data_export memfault_chunks.bin
        echo "✅ Upload complete!"
    fi
else
    echo "❌ No chunks extracted"
fi

# Cleanup
rm -f /tmp/memfault_extract.gdb
