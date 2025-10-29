#!/bin/bash
# Script to build the Docker image
docker build -t gaussian-lic-dev \
    -f docker/Dockerfile \
    .