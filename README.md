# ComfyUI Team RunPod Template 🎨

A Docker template for running ComfyUI with shared models and artist-specific workspaces on RunPod.

## Features

- ✅ **Shared ComfyUI installation** - Fast startup, no downloads
- ✅ **Shared models directory** - Team models synced from Google Drive  
- ✅ **Artist-specific outputs** - Personal folders for each team member
- ✅ **Network volume support** - Persistent storage across pod restarts
- ✅ **Auto-startup** - ComfyUI starts automatically when pod launches

## Architecture

```
Network Volume Structure:
/runpod-volume/
├── ComfyUI/              # Shared ComfyUI installation
├── models/               # Shared models (Google Drive synced)
│   ├── checkpoints/
│   ├── vae/
│   └── controlnet/
└── outputs/              # Artist-specific outputs
    ├── sarah/
    ├── mike/
    └── jessica/
```

## Setup Instructions

### 1. Create Network Volume
1. Go to RunPod → Storage → Network Volumes
2. Create a new volume (100GB+ recommended)
3. Note the volume ID

### 2. Pre-configure Network Volume
Before using this template, you need to setup ComfyUI on the network volume:

1. Deploy a temporary pod with the network volume
2. Install ComfyUI manually:
   ```bash
   cd /runpod-volume
   git clone https://github.com/comfyanonymous/ComfyUI.git
   cd ComfyUI
   pip install -r requirements.txt
   
   # Install ComfyUI Manager
   cd custom_nodes
   git clone https://github.com/ltdrdata/ComfyUI-Manager.git
   cd ComfyUI-Manager
   pip install -r requirements.txt
   ```
3. Set up your models directory and Google Drive sync
4. Install any custom nodes your team needs

### 3. Create RunPod Template
1. Go to RunPod → Templates → Create Template
2. Use these settings:
   - **Name**: ComfyUI Team Template
   - **Image**: `your-dockerhub-username/comfyui-team:latest`
   - **Ports**: `8188/http,8888/http,22/tcp`
   - **Volume Mount Path**: `/runpod-volume`
   - **Environment Variables**:
     - `ARTIST_NAME`: `artist1` (change per artist)

### 4. Deploy for Artists
Artists can either:
- Use the web interface with the template
- Use the Python launcher script for automated deployment

## Usage

### For Artists
1. Deploy pod using the team template
2. Set `ARTIST_NAME` environment variable to your name
3. Access ComfyUI at `http://[pod-ip]:8188`
4. Your outputs will be saved to `/runpod-volume/outputs/[your-name]/`

### Environment Variables
- `ARTIST_NAME`: Sets the artist's output folder name (required)

## Ports
- `8188`: ComfyUI web interface
- `8888`: Jupyter Lab (optional)
- `22`: SSH access

## File Structure
- `startup.sh`: Main startup script that configures the environment
- `Dockerfile`: Docker image definition
- `launcher/`: Python scripts for automated pod deployment

## Customization
Edit `startup.sh` to:
- Add additional software installations
- Modify the directory structure
- Add custom startup procedures

## Troubleshooting

**Pod fails to start**: Check that ComfyUI is properly installed on the network volume

**Models not found**: Ensure the models directory exists on the network volume

**Permission issues**: Make sure the startup script has execute permissions

## Support
For issues or questions, contact the team lead or check the RunPod documentation.
