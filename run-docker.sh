#!/bin/bash

# Script to rebuild and run Docker container with .env file
# This ensures MEMFAULT_PROJECT_KEY is available in the container

echo "Building Docker container with environment variables..."
docker-compose build

echo "Starting Docker container..."
docker-compose up -d

echo "Docker container is running. To attach:"
echo "  docker-compose exec memfault-gdb bash"
echo ""
echo "Or to run GDB directly:"
echo "  docker-compose exec memfault-gdb gdb-multiarch build/battery_demo.elf"
echo ""
echo "Environment variables loaded from .env:"
docker-compose exec memfault-gdb env | grep MEMFAULT
