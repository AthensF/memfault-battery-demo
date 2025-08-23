FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      python3 python3-pip \
      gdb \
      gdb-multiarch \
      gcc-arm-none-eabi \
      git \
      curl \
      unzip \
      make \
      ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Install Memfault CLI (optional, but handy)
RUN pip3 install --no-cache-dir memfault-cli

WORKDIR /work

# Default command
CMD ["bash"]
