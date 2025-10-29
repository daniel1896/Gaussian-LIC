#!/bin/bash
# Script to run the Gaussian-LIC Docker container with CUDA support

# IMPORTANT: Run this on your HOST machine ONCE before running the script:
# xhost +local:docker

# Detect CUDA installation path (adjust if needed)
CUDA_PATH=${CUDA_PATH:-/usr/local/cuda-12.6}

# Check if CUDA exists on host
if [ ! -d "$CUDA_PATH" ]; then
    echo "ERROR: CUDA not found at $CUDA_PATH"
    echo "Please set CUDA_PATH environment variable to your CUDA installation"
    echo "Example: export CUDA_PATH=/usr/local/cuda-11.4"
    exit 1
fi

echo "Using CUDA from: $CUDA_PATH"

# Get the current user's UID and GID
USER_UID=$(id -u)
USER_GID=$(id -g)

# Run the container
docker run -it --rm \
    --runtime nvidia \
    --network=host \
    --ipc=host \
    --privileged \
    -e DISPLAY=$DISPLAY \
    -e NVIDIA_VISIBLE_DEVICES=all \
    -e NVIDIA_DRIVER_CAPABILITIES=all \
    -e QT_X11_NO_MITSHM=1 \
    -e USER_UID=$USER_UID \
    -e USER_GID=$USER_GID \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    -v $CUDA_PATH:/usr/local/cuda-12.6:ro \
    -v $(pwd):/catkin_ws/src/gaussian-lic \
    -v $(pwd)/result:/catkin_ws/src/gaussian-lic/result \
    gaussian-lic-dev \
    "$@"