#!/bin/bash
# Basic entrypoint for ROS
set -e

# Source ROS and workspace setup
source "/opt/ros/noetic/setup.bash"
source "/catkin_ws/devel/setup.bash"

# Execute the command passed to the container (e.g., "bash")
exec "$@"