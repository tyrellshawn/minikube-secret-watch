#!/bin/bash
set -e

# Get the project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Usage: ./build_and_push.sh [dockerhub-username]
# If no username is given, builds for Minikube local registry only.

cd "${PROJECT_ROOT}/go-app"

if [ -n "$1" ]; then
    IMAGE="$1/secret-watcher:latest"
    echo "Building and pushing Docker image to Docker Hub: $IMAGE"
    docker build -t $IMAGE .
    docker push $IMAGE
else
    IMAGE="secret-watcher:latest"
    echo "Building Docker image for Minikube local registry: $IMAGE"
    eval $(minikube -p minikube docker-env)
    docker build -t $IMAGE .
    echo "Image built for Minikube."
fi

cd "${PROJECT_ROOT}"
