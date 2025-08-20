#!/bin/bash

set -e

IMAGE="$1"

if [ -z "$IMAGE" ]; then
    echo "🔍 SGX Hash Extractor"
    echo "===================="
    echo ""
    read -p "Enter GSC Docker image name: " IMAGE
    
    if [ -z "$IMAGE" ]; then
        echo "❌ Error: Docker image name is required"
        echo "Usage: $0 <docker_image>"
        exit 1
    fi
    echo ""
fi

# Pull the image
echo "Pulling $IMAGE..."
docker pull --platform linux/amd64 "$IMAGE"

# Extract MRENCLAVE directly
MRENCLAVE=$(docker run --rm --platform linux/amd64 --entrypoint sh "$IMAGE" -c \
    "xxd -l 32 -s 960 /gramine/app_files/entrypoint.sig 2>/dev/null | cut -d' ' -f2-9 | tr -d ' \n'" 2>/dev/null || echo "")

if [ -z "$MRENCLAVE" ]; then
    echo "Error: Could not extract MRENCLAVE from $IMAGE"
    echo "This may not be a GSX image or signature file not found at /gramine/app_files/entrypoint.sig"
    exit 1
fi

echo "MRENCLAVE: $MRENCLAVE"