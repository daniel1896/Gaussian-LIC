#!/bin/bash
# Basic entrypoint for ROS
set -e

# Source ROS setup
source "/opt/ros/humble/setup.bash"

# Source the workspace, *if it exists* (i.e., if colcon build has run)
if [ -f "/ros2_ws/install/setup.bash" ]; then
  source "/ros2_ws/install/setup.bash"
fi

# Execute the command passed to the container (e.g., "bash")
exec "$@"