# Gaussian-LIC Dockerfile for ARM64 (Jetson Orin/Xavier)
# USES CUDA 11.4 (JetPack 5.x)

FROM arm64v8/ubuntu:20.04

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
# Install CUDA Toolkit 11.4 and CUDNN for JetPack 5
# -------------------------------
# Add NVIDIA's L4T repository and fetch key
RUN apt-get update && apt-get install -y --no-install-recommends \
    gnupg2 \
    && rm -rf /var/lib/apt/lists/*
RUN apt-key adv --fetch-keys http://repo.download.nvidia.com/jetson/jetson-ota-public.asc && \
    echo 'deb https://repo.download.nvidia.com/jetson/common r35.3 main' > /etc/apt/sources.list.d/nvidia-l4t-apt-source.list && \
    echo 'deb https://repo.download.nvidia.com/jetson/t234 r35.3 main' >> /etc/apt/sources.list.d/nvidia-l4t-apt-source.list

# Install CUDA 11.4 Toolkit and CUDNN 8
RUN apt-get update && apt-get install -y \
    cuda-toolkit-11-4 \
    libcudnn8-dev \
    && rm -rf /var/lib/apt/lists/*

# -------------------------------
# CUDA Environment (switched to 11.4)
# -------------------------------
ENV CUDA_HOME=/usr/local/cuda-11.4
ENV PATH=${CUDA_HOME}/bin:${PATH}
ENV LD_LIBRARY_PATH=${CUDA_HOME}/lib64:${LD_LIBRARY_PATH:-}
ENV CUDA_TOOLKIT_ROOT_DIR=${CUDA_HOME}
ENV CUDA_INCLUDE_DIRS=${CUDA_HOME}/include
ENV CUDA_LIB_DIR=${CUDA_HOME}/lib64

# -------------------------------
# Python 3.8 and pip (Default for Ubuntu 20.04 and JP5)
# -------------------------------
RUN apt-get update && apt-get install -y \
    python3.8 \
    python3.8-dev \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Update pip
RUN python3.8 -m pip install --upgrade pip

# Install a modern version of CMake
RUN python3.8 -m pip install cmake

# -------------------------------
# PyTorch for ARM64/Jetson
# -------------------------------
# Install PyTorch 2.0.0 for Python 3.8 (cp38) and JetPack 5.1.1 (CUDA 11.4)
RUN python3.8 -m pip install --no-cache-dir \
    https://developer.download.nvidia.cn/compute/redist/jp/v511/pytorch/torch-2.0.0+nv23.05-cp38-cp38-linux_aarch64.whl

# Install torchvision (compatible version)
RUN apt-get update && apt-get install -y \
    libjpeg-dev \
    libpng-dev \
    && rm -rf /var/lib/apt/lists/*

# torchvision 0.15.0 is compatible with torch 2.0.0
RUN python3.8 -m pip install --no-cache-dir torchvision==0.15.0

# -------------------------------
# ROS Noetic
# -------------------------------
RUN sh -c 'echo "deb [arch=arm64] http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list' \
    && curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add -

RUN apt-get update && apt-get install -y \
    ros-noetic-desktop-full \
    python3-rosdep \
    python3-rosinstall \
    python3-rosinstall-generator \
    python3-wstool \
    python3-catkin-tools \
    && rm -rf /var/lib/apt/lists/*

# Initialize rosdep
RUN rosdep init || true
RUN rosdep update

ENV ROS_DISTRO=noetic

# -------------------------------
# OpenCV 4.7.0 with CUDA
# -------------------------------
# Added GStreamer dev libraries
RUN apt-get update && apt-get install -y \
    libgtk-3-dev \
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev \
    libv4l-dev \
    libxvidcore-dev \
    libx264-dev \
    libtbb2 \
    libtbb-dev \
    libjpeg-dev \
    libpng-dev \
    libtiff-dev \
    libdc1394-22-dev \
    gfortran \
    openexr \
    libopenexr-dev \
    libatlas-base-dev \
    libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev \
    && rm -rf /var/lib/apt/lists/*

# Build OpenCV from source with CUDA support
WORKDIR /tmp
# Use -O to specify output filenames and avoid conflicts
RUN wget -q https://github.com/opencv/opencv/archive/refs/tags/4.7.0.tar.gz -O opencv.tar.gz && \
    tar -zxf opencv.tar.gz && \
    wget -q https://github.com/opencv/opencv_contrib/archive/refs/tags/4.7.0.tar.gz -O opencv_contrib.tar.gz && \
    tar -zxf opencv_contrib.tar.gz && \
    rm -f *.tar.gz

RUN cd opencv-4.7.0 && mkdir build && cd build && \
    cmake \
    -DCMAKE_BUILD_TYPE=RELEASE \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DWITH_CUDA=ON \
    -DWITH_CUDNN=ON \
    -DOPENCV_DNN_CUDA=ON \
    -DENABLE_FAST_MATH=1 \
    -DCUDA_FAST_MATH=1 \
    -DWITH_CUBLAS=1 \
    -DOPENCV_EXTRA_MODULES_PATH=/tmp/opencv_contrib-4.7.0/modules \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_TESTS=OFF \
    -DBUILD_PERF_TESTS=OFF \
    -DWITH_FFMPEG=ON \
    -DWITH_GSTREAMER=ON \
    -DCUDA_TOOLKIT_ROOT_DIR=${CUDA_HOME} \
    .. && \
    make -j$(nproc) && \
    make install && \
    ldconfig && \
    cd / && rm -rf /tmp/opencv-4.7.0 /tmp/opencv_contrib-4.7.0

# -------------------------------
# Additional Dependencies
# -------------------------------
RUN apt-get update && apt-get install -y \
    libeigen3-dev \
    libyaml-cpp-dev \
    libpcl-dev \
    ros-noetic-cv-bridge \
    ros-noetic-image-transport \
    ros-noetic-pcl-conversions \
    ros-noetic-pcl-ros \
    ros-noetic-tf \
    ros-noetic-eigen-conversions \
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
# Create Catkin Workspace
# -------------------------------
WORKDIR /catkin_ws
RUN mkdir -p /catkin_ws/src

# Copy the Gaussian-LIC source code
COPY . /catkin_ws/src/gaussian-lic

# Install Livox ROS driver (dependency for Coco-LIC)
WORKDIR /catkin_ws/src
RUN git clone https://github.com/Livox-SDK/livox_ros_driver.git

# -------------------------------
# Set Torch Directory in CMakeLists
# -------------------------------
# Update the CMakeLists.txt to find PyTorch correctly
RUN TORCH_PATH=$(python3.8 -c "import torch; print(torch.__path__[0])") && \
    sed -i "s|set(Torch_DIR /usr/local/lib/python3.10/dist-packages/torch/share/cmake/Torch)|set(Torch_DIR ${TORCH_PATH}/share/cmake/Torch)|g" \
    /catkin_ws/src/gaussian-lic/CMakeLists.txt

# -------------------------------
# Build the Catkin Workspace
# -------------------------------
SHELL ["/bin/bash", "-c"]

# Source ROS and build
RUN source /opt/ros/${ROS_DISTRO}/setup.bash && \
    cd /catkin_ws && \
    rosdep install --from-paths src --ignore-src -r -y --rosdistro ${ROS_DISTRO} || true && \
    catkin_make -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    -DCMAKE_CUDA_STANDARD=17 \
    -DCUDA_TOOLKIT_ROOT_DIR=${CUDA_HOME} \
    -DCUDA_INCLUDE_DIRS=${CUDA_INCLUDE_DIRS}

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
    chown -R developer:developer /catkin_ws

USER developer

# Set working directory
WORKDIR /catkin_ws

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["bash"]