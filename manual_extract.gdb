# Manual Memfault data extraction using standard GDB commands
# Usage: arm-none-eabi-gdb build/battery_demo.elf -x manual_extract.gdb

target remote :3333

echo \n=== Manual Memfault Data Extraction ===\n

# Find Memfault event storage buffer
info variables s_event_storage
info variables g_memfault_event_storage

# Check if we can find the storage info
info variables memfault_event_storage

# Print some memory regions where Memfault data might be stored
# Look for the event storage buffer (defined in memfault_platform_port.c)
x/64x &s_event_storage

# Also check for any coredump storage
info variables s_coredump_storage

echo \nMemfault symbols in binary:\n
info functions memfault
info variables memfault

echo \nTo manually inspect data:\n
echo "1. Find storage buffers with 'info variables s_event_storage'\n"
echo "2. Examine memory with 'x/NNx address'\n"
echo "3. Save to file with 'dump binary memory filename start_addr end_addr'\n"

# Keep connection open for manual inspection
echo \nGDB session ready for manual inspection...\n
