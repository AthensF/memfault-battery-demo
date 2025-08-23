# GDB script to extract Memfault chunks from Renode simulation
# Usage: arm-none-eabi-gdb build/battery_demo.elf -x extract_chunks.gdb

# Connect to Renode GDB server
target remote :3333

# Load Memfault GDB helper
source ../third_party/memfault/memfault-firmware-sdk/scripts/memfault_gdb.py

# Print some info
echo \n=== Memfault Chunk Extraction ===\n
info registers

# Install chunk handler (you'll need to set your actual project key)
# memfault install_chunk_handler -pk YOUR_PROJECT_KEY_HERE

# Alternative: dump chunks to file for manual upload
# memfault coredump
# memfault export_data --file memfault_data.bin

echo \nGDB connected to Renode simulation\n
echo Use: memfault install_chunk_handler -pk YOUR_PROJECT_KEY\n
echo Or:  memfault export_data --file chunks.bin\n
