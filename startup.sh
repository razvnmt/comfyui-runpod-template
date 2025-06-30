#!/bin/bash

# ComfyUI Team Startup Script
# This script sets up ComfyUI from a shared network volume

set -e

echo "=== Starting ComfyUI Team Setup ==="

# Configuration
NETWORK_VOLUME="/runpod-volume"
WORKSPACE="/workspace"
COMFYUI_DIR="$WORKSPACE/ComfyUI"

# Function to setup network volume structure
setup_network_volume() {
    if [ -d "$NETWORK_VOLUME" ]; then
        echo "Setting up network volume structure..."
        
        # Create shared ComfyUI directory
        mkdir -p $NETWORK_VOLUME/ComfyUI
        
        # Create shared models directory
        mkdir -p $NETWORK_VOLUME/models
        
        # Create pod-specific output directory using artist name
        ARTIST_NAME=${ARTIST_NAME:-"unknown_artist"}
        POD_ID=${RUNPOD_POD_ID:-$(hostname)}
        OUTPUT_DIR="$ARTIST_NAME"
        
        mkdir -p $NETWORK_VOLUME/outputs/$OUTPUT_DIR
        
        echo "Network volume structure created"
        echo "Artist: $ARTIST_NAME"
        echo "Pod ID: $POD_ID"
    else
        echo "No network volume detected - using local storage"
        mkdir -p $WORKSPACE/models
    fi
}

# Function to setup ComfyUI from network volume
setup_comfyui() {
    if [ -d "$NETWORK_VOLUME" ] && [ -d "$NETWORK_VOLUME/ComfyUI" ]; then
        echo "Linking to existing ComfyUI installation..."
        
        # Create symlink to shared ComfyUI
        if [ -L "$COMFYUI_DIR" ]; then
            echo "ComfyUI symlink already exists"
        elif [ -d "$COMFYUI_DIR" ]; then
            rm -rf "$COMFYUI_DIR"
            ln -sf "$NETWORK_VOLUME/ComfyUI" "$COMFYUI_DIR"
        else
            ln -sf "$NETWORK_VOLUME/ComfyUI" "$COMFYUI_DIR"
        fi
        
        echo "Installing Python requirements for this pod..."
        cd "$COMFYUI_DIR"
        pip install -r requirements.txt
        
        echo "ComfyUI setup complete!"
        
    else
        echo "❌ ERROR: ComfyUI not found on network volume!"
        echo "Please ensure ComfyUI is installed at: $NETWORK_VOLUME/ComfyUI"
        echo "The network volume should be pre-configured with ComfyUI before using this launcher."
        exit 1
    fi
}

# Function to link network volume
link_network_volume() {
    if [ -d "$NETWORK_VOLUME" ]; then
        echo "Linking directories to network volume..."
        
        # Create the workspace models symlink (shared across pods)
        if [ -L "$WORKSPACE/models" ]; then
            echo "Models symlink already exists"
        elif [ -d "$WORKSPACE/models" ]; then
            echo "Moving existing models directory to network volume..."
            cp -r $WORKSPACE/models/* $NETWORK_VOLUME/models/ 2>/dev/null || true
            rm -rf $WORKSPACE/models
            ln -sf $NETWORK_VOLUME/models $WORKSPACE/models
        else
            echo "Creating models symlink..."
            ln -sf $NETWORK_VOLUME/models $WORKSPACE/models
        fi
        
        # ComfyUI is already symlinked from setup_comfyui function
        # Now link ComfyUI models directory to workspace models (shared)
        cd $COMFYUI_DIR
        if [ -L "models" ]; then
            echo "ComfyUI models symlink already exists"
        elif [ -d "models" ]; then
            echo "Moving ComfyUI models to workspace models..."
            cp -r models/* $WORKSPACE/models/ 2>/dev/null || true
            rm -rf models
            ln -sf $WORKSPACE/models models
        else
            echo "Creating ComfyUI models symlink..."
            ln -sf $WORKSPACE/models models
        fi
        
        # Link to artist-specific output directory
        ARTIST_NAME=${ARTIST_NAME:-"unknown_artist"}
        OUTPUT_DIR="$ARTIST_NAME"
        
        if [ -L "output" ]; then
            rm output
        elif [ -d "output" ]; then
            mv output output.bak
        fi
        ln -sf $NETWORK_VOLUME/outputs/$OUTPUT_DIR output
        
        echo "Network volume linking complete"
        echo "Shared: /workspace/ComfyUI -> /runpod-volume/ComfyUI"
        echo "Shared: /workspace/models -> /runpod-volume/models"
        echo "Shared: /workspace/ComfyUI/models -> /workspace/models"
        echo "Artist-specific: /workspace/ComfyUI/output -> /runpod-volume/outputs/$OUTPUT_DIR"
    fi
}

# Function to start services
start_services() {
    echo "Starting services..."
    
    # Start SSH (from original template)
    service ssh start
    
    # Start Jupyter (from original template) - but don't auto-launch browser
    cd /workspace
    nohup jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root --ServerApp.token="" --ServerApp.password="" > /workspace/jupyter.log 2>&1 &
    
    # Start ComfyUI
    echo "Starting ComfyUI..."
    cd $COMFYUI_DIR
    nohup python main.py --listen 0.0.0.0 --port 8188 > /workspace/comfyui.log 2>&1 &
    
    echo "All services started!"
    echo "ComfyUI: http://localhost:8188"
    echo "Jupyter: http://localhost:8888"
    echo "SSH: Port 22"
    
    # Keep container running
    tail -f /dev/null
}

# Main execution
main() {
    echo "ComfyUI Team Setup starting..."
    
    setup_network_volume
    setup_comfyui
    link_network_volume
    start_services
}

# Run main function
main
