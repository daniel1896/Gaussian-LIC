#!/bin/bash
# Script to run the Docker container
# Relying on --runtime nvidia and environment variables

# --- IMPORTANT ---
# You MUST run this command on your HOST machine ONCE before running the script:
# xhost +local:docker
# -----------------

docker run -it --rm \
    --runtime nvidia \
    --network=host \
    --ipc=host \
    -e DISPLAY=$DISPLAY \
    -e NVIDIA_VISIBLE_DEVICES=all \
    -e NVIDIA_DRIVER_CAPABILITIES=all \
    -e QT_X11_NO_MITSHM=1 \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    -v $(pwd):/catkin_ws/src/gaussian-lic \
    gaussian-lic-dev