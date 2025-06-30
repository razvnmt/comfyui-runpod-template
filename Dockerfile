# ComfyUI Team Docker Template
FROM runpod/pytorch:2.8.0-py3.11-cuda12.4.1-devel-ubuntu22.04

# Set working directory
WORKDIR /workspace

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    wget \
    curl \
    vim \
    htop \
    && rm -rf /var/lib/apt/lists/*

# Copy startup script
COPY startup.sh /workspace/startup.sh
RUN chmod +x /workspace/startup.sh

# Create necessary directories
RUN mkdir -p /workspace/models /workspace/outputs

# Expose ports
EXPOSE 8188 8888 22

# Set the startup script as entrypoint
CMD ["/workspace/startup.sh"]
