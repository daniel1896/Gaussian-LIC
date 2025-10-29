#!/bin/bash
# Script to build the Docker image for Gaussian-LIC

# Get the current user's UID and GID to create matching user in container
USER_UID=$(id -u)
USER_GID=$(id -g)

echo "Building Gaussian-LIC Docker image..."
echo "User UID: $USER_UID"
echo "User GID: $USER_GID"

docker build \
    --build-arg UID=$USER_UID \
    --build-arg GID=$USER_GID \
    -t gaussian-lic-dev \
    -f docker/Dockerfile \
    .

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Docker image 'gaussian-lic-dev' built successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Enable X11 forwarding (run once):"
    echo "   xhost +local:docker"
    echo ""
    echo "2. Run the container:"
    echo "   ./run.sh"
    echo ""
else
    echo ""
    echo "❌ Docker build failed!"
    exit 1
fi