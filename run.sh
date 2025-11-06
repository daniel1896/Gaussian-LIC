#!/bin/bash
# Script to run the Gaussian-LIC Docker container with CUDA support (JP6)

# IMPORTANT: Run this on your HOST machine ONCE before running the script:
# xhost +local:docker

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
    -v $(pwd):/ros2_ws/src/gaussian-lic \
    -v $(pwd)/result:/ros2_ws/src/gaussian-lic/result \
    gaussian-lic-dev \
    "$@"