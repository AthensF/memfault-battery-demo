# Simple GDB script to debug the issue
target remote :3333

# Check current state
info registers pc
where

# Try to continue execution
continue

# If it stops, check where we are
where
info registers pc
