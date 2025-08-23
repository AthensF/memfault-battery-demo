#!/usr/bin/env python3
"""
Test script to use GDB with Python support and Memfault's online script
Following the official documentation at:
https://docs.memfault.com/docs/mcu/test-data-collection-with-gdb
"""

import subprocess
import sys
import time
import os

def main():
    print("🔋 Memfault GDB Integration Test")
    print("================================")
    
    # Check if project key is set
    project_key = os.environ.get('MEMFAULT_PROJECT_KEY')
    if not project_key:
        print("❌ MEMFAULT_PROJECT_KEY environment variable not set")
        return 1
    
    print("✅ Project key configured")
    
    # Check if GDB server is accessible
    try:
        result = subprocess.run(['nc', '-z', 'localhost', '3333'], 
                              capture_output=True, timeout=5)
        if result.returncode != 0:
            print("❌ GDB server not accessible on port 3333")
            print("   Make sure Renode is running with GDB enabled")
            return 1
    except:
        print("❌ Cannot check GDB server connectivity")
        return 1
    
    print("✅ GDB server accessible")
    
    # Create GDB script following Memfault documentation
    gdb_script = f"""
# Connect to Renode
target remote :3333

# Load Memfault GDB script from online (as per documentation)
python exec('try:\\n from urllib2 import urlopen\\nexcept:\\n from urllib.request import urlopen'); exec(urlopen('https://app.memfault.com/static/scripts/memfault_gdb.py').read())

# Register the chunk handler with our project key
memfault install_chunk_handler --verbose --project-key {project_key}

# Continue execution to let the battery demo run
continue

# The handler will automatically post chunks when memfault_data_export_dump_chunks() is called
"""
    
    # Write the script to a temporary file
    with open('/tmp/memfault_gdb_test.gdb', 'w') as f:
        f.write(gdb_script)
    
    print("🔍 Starting GDB session with Memfault integration...")
    print("📊 The battery demo will automatically export chunks at critical events")
    print("⏱️  Expected timeline: ~5s low battery, ~6s critical, ~7s shutdown")
    print("🚀 Chunks will be automatically uploaded to Memfault cloud")
    print("")
    print("Press Ctrl+C to stop the session")
    
    try:
        # Run GDB with our script
        subprocess.run([
            'gdb', 
            'build/battery_demo.elf',
            '-x', '/tmp/memfault_gdb_test.gdb'
        ])
    except KeyboardInterrupt:
        print("\n🛑 Session stopped by user")
    finally:
        # Cleanup
        if os.path.exists('/tmp/memfault_gdb_test.gdb'):
            os.remove('/tmp/memfault_gdb_test.gdb')
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
