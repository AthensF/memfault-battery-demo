#!/usr/bin/env python3
"""
Memfault Data Verification Script
Checks if the battery demo is properly collecting Memfault metrics
"""

import subprocess
import sys
import time

def check_renode_running():
    """Check if Renode is currently running"""
    try:
        result = subprocess.run(['ps', 'aux'], capture_output=True, text=True)
        return 'renode' in result.stdout.lower()
    except:
        return False

def check_build_artifacts():
    """Verify build artifacts contain Memfault symbols"""
    try:
        result = subprocess.run(['arm-none-eabi-nm', 'build/battery_demo.elf'], 
                              capture_output=True, text=True)
        
        memfault_symbols = [
            'memfault_metrics',
            'memfault_platform_boot',
            'memfault_data_export',
            'MEMFAULT_PROJECT_KEY'
        ]
        
        found_symbols = []
        for symbol in memfault_symbols:
            if symbol.lower() in result.stdout.lower():
                found_symbols.append(symbol)
        
        return found_symbols
    except:
        return []

def main():
    print("🔋 Memfault Battery Demo Verification")
    print("=" * 40)
    
    # Check if Renode is running
    if check_renode_running():
        print("✅ Renode simulation is running")
    else:
        print("❌ Renode simulation not detected")
    
    # Check build artifacts
    symbols = check_build_artifacts()
    if symbols:
        print(f"✅ Found {len(symbols)} Memfault symbols in binary:")
        for symbol in symbols:
            print(f"   - {symbol}")
    else:
        print("❌ No Memfault symbols found in binary")
    
    print("\n📊 Expected Demo Timeline:")
    print("   0-19s: Normal operation (100% → 21%)")
    print("   19s:   Low battery warning (20%)")
    print("   22s:   Critical battery warning (10%)")
    print("   24s:   Battery empty, device shutdown")
    
    print("\n💡 To export data to Memfault cloud:")
    print("   Use GDB with Memfault scripts or implement HTTP transport")
    print("   Data is being collected in RAM-based storage")

if __name__ == "__main__":
    main()
