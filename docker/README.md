# Gaussian-LIC Docker Setup for Jetson (ARM64)

This Docker setup allows you to run Gaussian-LIC on NVIDIA Jetson devices (Orin, Xavier, etc.) by mounting the host's CUDA installation.

## Prerequisites

### 1. Install NVIDIA Container Runtime

On your Jetson device, install the NVIDIA Container Toolkit:

```bash
# Add NVIDIA Docker repository
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
    sudo tee /etc/apt/sources.list.d/nvidia-docker.list

# Install nvidia-docker2
sudo apt-get update
sudo apt-get install -y nvidia-docker2

# Restart Docker
sudo systemctl restart docker
```

### 2. Verify CUDA Installation

Ensure CUDA is installed on your host:

```bash
ls -la /usr/local/cuda*
```

If CUDA is at a different location, note the path for later.

### 3. Install Docker

If Docker is not installed:

```bash
sudo apt-get update
sudo apt-get install -y docker.io
sudo usermod -aG docker $USER
# Log out and back in for group changes to take effect
```

## Build the Docker Image

1. **Make build script executable:**

```bash
chmod +x build.sh run.sh
```

2. **Build the image:**

```bash
./build.sh
```

This will take 30-60 minutes depending on your Jetson model.

## Run the Container

1. **Enable X11 forwarding (required once per boot):**

```bash
xhost +local:docker
```

2. **Start the container:**

```bash
./run.sh
```

3. **Inside the container, verify CUDA works:**

```bash
nvcc --version
python3.8 -c "import torch; print(f'PyTorch: {torch.__version__}'); print(f'CUDA available: {torch.cuda.is_available()}')"
```

## Running Gaussian-LIC

### 1. Prepare Your Dataset

Download one of the supported datasets:
- [FAST-LIVO Dataset](https://connecthkuhk-my.sharepoint.com/:f:/g/personal/zhengcr_connect_hku_hk/EokU3pbuZvFOsvpPfLEZXXEBGHYyUO7jYEZJ0RJjqgGqIQ?e=dAbccO)
- [R3LIVE Dataset](https://github.com/ziv-lin/r3live_dataset)
- [MCD Dataset](https://mcdviral.github.io/)

### 2. Install Coco-LIC (Odometry System)

Inside the container:

```bash
# Create workspace for Coco-LIC
mkdir -p ~/catkin_coco/src
cd ~/catkin_coco/src

# Clone dependencies
git clone https://github.com/Livox-SDK/livox_ros_driver.git

# Clone Coco-LIC
git clone https://github.com/APRIL-ZJU/Coco-LIC.git

# Build
cd ~/catkin_coco
source /opt/ros/noetic/setup.bash
catkin_make

# Configure dataset path
# Edit config/ct_odometry_fastlivo.yaml and set bag_path
nano ~/catkin_coco/src/Coco-LIC/config/ct_odometry_fastlivo.yaml
```

### 3. Run Gaussian-LIC

**Terminal 1 - Gaussian-LIC:**

```bash
cd /catkin_ws
source devel/setup.bash
roslaunch gaussian_lic fastlivo.launch
```

Wait for the message: `😋 Gaussian-LIC Ready!`

**Terminal 2 - Coco-LIC (in new container instance):**

```bash
# Start new terminal and run container
./run.sh

# Inside container
cd ~/catkin_coco
source devel/setup.bash
roslaunch cocolic odometry.launch config_path:=config/ct_odometry_fastlivo.yaml
```

### 4. View Results

Results will be saved in `/catkin_ws/src/gaussian-lic/result/` (visible on host as `./result/`)

## Troubleshooting

### CUDA Not Found

If you see CUDA errors, check your CUDA path:

```bash
# On host
ls -la /usr/local/cuda*
```

Update `run.sh` if your CUDA is at a different location:

```bash
export CUDA_PATH=/usr/local/cuda-11.4  # adjust as needed
./run.sh
```

### PyTorch CUDA Not Available

Inside container:

```bash
# Check CUDA libraries are accessible
ls -la /usr/local/cuda-12.6/lib64/

# Verify PyTorch installation
python3.8 -c "import torch; print(torch.version.cuda)"
```

### Build Failures

If build fails during OpenCV compilation (common on Jetson due to memory):

1. Reduce parallel jobs by editing Dockerfile line:
   ```dockerfile
   make -j2  # instead of -j$(nproc)
   ```

2. Or build with swap enabled on host:
   ```bash
   sudo fallocate -l 8G /swapfile
   sudo chmod 600 /swapfile
   sudo mkswap /swapfile
   sudo swapon /swapfile
   ```

### X11 Display Issues

If RViz doesn't display:

```bash
# On host, run:
xhost +local:docker
export DISPLAY=:0

# Try running with explicit display
docker run -it --rm \
    --runtime nvidia \
    -e DISPLAY=:0 \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    gaussian-lic-dev
```

## Performance Tips

1. **Use SSD for datasets** - Jetson eMMC can be slow
2. **Monitor thermals** - Use `tegrastats` on host
3. **Adjust point decimation** - Modify `select_every_k_frame` in config files
4. **Reduce Gaussian count** - Set `scaling_scale: 2` in config for fewer Gaussians

## Additional Notes

- The container runs as a non-root user matching your host UID/GID
- Source code is mounted from host, so edits persist
- Results directory is also mounted for easy access
- CUDA is read-only mounted from host to save space

## Support

For issues specific to:
- **Gaussian-LIC**: See [GitHub Issues](https://github.com/APRIL-ZJU/Gaussian-LIC/issues)
- **Docker setup**: Check this README and troubleshooting section
- **Coco-LIC**: See [Coco-LIC repository](https://github.com/APRIL-ZJU/Coco-LIC)