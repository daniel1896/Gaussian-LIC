# Gaussian-LIC Dockerfile for ARM64 (Jetson Orin/Xavier)
# USES HOST CUDA (JetPack 6.x)

# 1. Base Image (Ubuntu 22.04 for JetPack 6)
FROM arm64v8/ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# -------------------------------
# System Dependencies
# -------------------------------
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    gnupg2 \
    lsb-release \
    ca-certificates \
    software-properties-common \
    build-essential \
    git \
    pkg-config \
    libgomp1 \
    libnuma1 \
    && rm -rf /var/lib/apt/lists/*

# -------------------------------
# Python 3.10 (Default for Ubuntu 22.04)
# -------------------------------
RUN apt-get update && apt-get install -y \
    python3.10 \
    python3.10-dev \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install a modern CMake via pip
RUN python3.10 -m pip install --upgrade pip
RUN python3.10 -m pip install cmake

# -------------------------------
# PyTorch for ARM64/Jetson (JetPack 6.0)
# -------------------------------
# Install PyTorch for Python 3.10 and JetPack 6.0 (CUDA 12.x)
# Find new wheels here: https://developer.download.nvidia.com/compute/redist/jp/v60/pytorch/
RUN python3.10 -m pip install --no-cache-dir \
    https://developer.download.nvidia.com/compute/redist/jp/v60/pytorch/torch-2.3.0a0+eb1a57b15d.nv24.05-cp310-cp310-linux_aarch64.whl

# Install torchvision (compatible with torch 2.3)
RUN apt-get update && apt-get install -y \
    libjpeg-dev \
    libpng-dev \
    && rm -rf /var/lib/apt/lists/*
RUN python3.10 -m pip install --no-cache-dir torchvision==0.18.0

# -------------------------------
# ROS 2 Humble (for Ubuntu 22.04)
# -------------------------------
RUN apt-get update && apt-get install -y \
    software-properties-common \
    && add-apt-repository universe \
    && rm -rf /var/lib/apt/lists/*

RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null

RUN apt-get update && apt-get install -y \
    ros-humble-desktop-full \
    python3-rosdep \
    python3-colcon-common-extensions \
    && rm -rf /var/lib/apt/lists/*

# Initialize rosdep
RUN rosdep init || true
RUN rosdep update

ENV ROS_DISTRO=humble

# -------------------------------
# OpenCV (from ROS) and Additional Dependencies
# -------------------------------
# We will use the OpenCV that comes with ROS Humble, not build from source.
RUN apt-get update && apt-get install -y \
    libopencv-dev \
    libeigen3-dev \
    libyaml-cpp-dev \
    libpcl-dev \
    ros-humble-cv-bridge \
    ros-humble-image-transport \
    ros-humble-pcl-conversions \
    ros-humble-pcl-ros \
    ros-humble-tf2-ros \
    ros-humble-eigen-conversions \
    libglew-dev \
    libglfw3-dev \
    libx11-dev \
    libglm-dev \
    libffi-dev \
    libopenblas-base \
    && rm -rf /var/lib/apt/lists/*

# -------------------------------
# Pangolin (for visualization)
# -------------------------------
WORKDIR /tmp
RUN git clone --depth 1 -b v0.8 https://github.com/stevenlovegrove/Pangolin.git && \
    cd Pangolin && mkdir build && cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release && \
    make -j$(nproc) && \
    make install && \
    cd / && rm -rf /tmp/Pangolin

# -------------------------------
# Livox SDK (Dependency for livox_ros_driver)
# -------------------------------
WORKDIR /tmp
RUN git clone https://github.com/Livox-SDK/Livox-SDK.git && \
    cd Livox-SDK && cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_POLICY_VERSION_MINIMUM=3.5 && \
    make -j$(nproc) && \
    make install && \
    cd / && rm -rf /tmp/Livox-SDK

# -------------------------------
# Create ROS 2 Workspace (renamed from catkin_ws)
# -------------------------------
WORKDIR /ros2_ws
RUN mkdir -p /ros2_ws/src

# Copy the Gaussian-LIC source code
COPY . /ros2_ws/src/gaussian-lic

# Install Livox ROS 2 driver
WORKDIR /ros2_ws/src
RUN git clone -b ros2 https://github.com/Livox-SDK/livox_ros_driver.git

# -------------------------------
# Set Torch Directory in CMakeLists
# -------------------------------
# Update the CMakeLists.txt to find PyTorch correctly
# NOTE: This may fail if the old path isn't in the file.
RUN TORCH_PATH=$(python3.10 -c "import torch; print(torch.__path__[0])") && \
    sed -i "s|set(Torch_DIR /usr/local/lib/python3.10/dist-packages/torch/share/cmake/Torch)|set(Torch_DIR ${TORCH_PATH}/share/cmake/Torch)|g" \
    /ros2_ws/src/gaussian-lic/CMakeLists.txt || echo "sed command failed, but continuing build."

# -------------------------------
# Build the ROS 2 Workspace (with colcon)
# -------------------------------
SHELL ["/bin/bash", "-c"]

# Source ROS 2 and build
RUN source /opt/ros/${ROS_DISTRO}/setup.bash && \
    cd /ros2_ws && \
    rosdep install --from-paths src --ignore-src -r -y --rosdistro ${ROS_DISTRO} || true

# !!! WARNING !!!
# The following build WILL FAIL. The Gaussian-LIC code is for ROS 1 (Noetic)
# and must be manually ported to ROS 2 (Humble) to compile.
# This step is included as a placeholder for when the code is ported.
# -------------------------------------------------------------------------
# RUN source /opt/ros/${ROS_DISTRO}/setup.bash && \
#     cd /ros2_ws && \
#     colcon build --symlink-install --cmake-args \
#     -DCMAKE_BUILD_TYPE=Release \
#     -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
#     -DCMAKE_CUDA_STANDARD=17
# -------------------------------------------------------------------------

# -------------------------------
# Setup Entrypoint
# -------------------------------
COPY ./docker/docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Create non-root user
ARG UID=1000
ARG GID=1000
RUN groupadd -g $GID -o developer && \
    useradd -m -u $UID -g $GID -o -s /bin/bash developer && \
    chown -R developer:developer /ros2_ws

USER developer

# Set working directory
WORKDIR /ros2_ws

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["bash"]