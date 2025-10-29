# Use NVIDIA's official L4T (Linux for Tegra) PyTorch image
# This is the latest available tag for Ubuntu 20.04 (L4T r35.x)
# It includes Ubuntu 20.04, CUDA 11.4, cuDNN, Python 3.8, and PyTorch 2.0
ARG L4T_TAG=r35.2.1-pth2.0-py3
FROM nvcr.io/nvidia/l4t-pytorch:${L4T_TAG}

# Set ROS distribution
ARG ROS_DISTRO=noetic

# Set non-interactive mode for apt-get to prevent prompts
ENV DEBIAN_FRONTEND=noninteractive
# Set NVIDIA variables
ENV NVIDIA_DRIVER_CAPABILITIES=all
ENV NVIDIA_VISIBLE_DEVICES=all

# Install basic system dependencies and GUI/OpenGL libraries for RViz/Pangolin
# The l4t-pytorch image is minimal, so we need many build tools.
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    git \
    wget \
    curl \
    unzip \
    pkg-config \
    lsb-release \
    # Python dev (for building python packages)
    python3-dev \
    # GUI/RViz/Pangolin dependencies
    libgl1-mesa-glx \
    libglew-dev \
    libglfw3-dev \
    libx11-dev \
    x11-apps \
    terminator \
    libglm-dev \
    # Project-specific C++ dependencies
    libeigen3-dev \
    libyaml-cpp-dev \
    # Cleanup
    && rm -rf /var/lib/apt/lists/*

# Install ROS Noetic (desktop-full includes RViz)
RUN sh -c 'echo "deb [signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list' \
    && curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg \
    && apt-get update \
    && apt-get -o Dpkg::Options::="--force-overwrite" install -y \
    ros-${ROS_DISTRO}-desktop-full \
    python3-rosdep \
    python3-rosinstall \
    python3-rosinstall-generator \
    python3-wstool \
    && rm -rf /var/lib/apt/lists/*

# Initialize rosdep
RUN rosdep init && rosdep update

# Install Pangolin (required by Gaussian-LIC) from source
# This ensures it's compiled with the correct dependencies
WORKDIR /opt
RUN git clone --depth 1 -b v0.8 https://github.com/stevenlovegrove/Pangolin.git \
    && cd Pangolin \
    && mkdir build && cd build \
    && cmake .. -DCMAKE_BUILD_TYPE=Release \
    && make -j$(nproc) \
    && make install \
    && cd / && rm -rf /opt/Pangolin

# --- LibTorch and PyTorch are pre-installed in the base image ---

# Create the Catkin Workspace
WORKDIR /catkin_ws
COPY . /catkin_ws/src/gaussian-lic

# Switch the default shell from /bin/sh to /bin/bash
SHELL ["/bin/bash", "-c"]

# Install all ROS dependencies from package.xml
RUN source /opt/ros/${ROS_DISTRO}/setup.bash \
    && rosdep install --from-paths src --ignore-src -r -y --rosdistro ${ROS_DISTRO}

# Build the workspace
# We no longer need to pass Torch_DIR, as it's set in CMakeLists.txt
RUN source /opt/ros/${ROS_DISTRO}/setup.bash \
    && catkin_make -DCMAKE_BUILD_TYPE=Release

# Set up the entrypoint to source the workspace (must be done as root)
COPY ./docker/docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

# Create a non-root user to match host user
# This prevents files created in mounted volumes from being owned by root
ARG UID=1000
ARG GID=1000
RUN groupadd -g $GID -o developer && \
    useradd -m -u $UID -g $GID -o -s /bin/bash developer
USER developer

# Set the entrypoint
ENTRYPOINT ["/docker-entrypoint.sh"]

# Default command to launch a bash shell
CMD ["bash"]