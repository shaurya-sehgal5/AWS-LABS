#!/bin/bash
set -e

CONTAINER_ID=$(docker ps -q | head -n 1)

if [ -n "$CONTAINER_ID" ]; then
    sudo docker rm -f "$CONTAINER_ID"
    echo "Container removed: $CONTAINER_ID"
else
    echo "No running container found"
fi
