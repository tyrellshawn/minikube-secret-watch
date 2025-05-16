#!/bin/bash
set -e

# Get the project root directory (parent of scripts directory)
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Check if Docker daemon is running
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        echo "Docker is not running. Please start Docker service with:"
        echo "sudo systemctl start docker"
        exit 1
    fi
}

# Check prerequisites
check_prerequisites() {
    echo "Checking prerequisites..."
    
    # Check Docker
    check_docker
    
    # Check if minikube is installed
    if ! command -v minikube >/dev/null 2>&1; then
        echo "Minikube is not installed. Please install it first."
        exit 1
    fi
    
    # Check if kubectl is installed
    if ! command -v kubectl >/dev/null 2>&1; then
        echo "kubectl is not installed. Please install it first."
        exit 1
    fi
    
    echo "All prerequisites checked."
}

# Run checks
check_prerequisites

# Start Minikube
echo "Starting Minikube..."
minikube start --driver=docker --cpus=4 --memory=4096

# Install ArgoCD
echo "Installing ArgoCD..."
kubectl create namespace argocd || true
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD pods to be ready
echo "Waiting for ArgoCD pods to be ready..."
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=180s

# Use Minikube Docker daemon
eval $(minikube -p minikube docker-env)

# Build and load Docker image
echo "Building Docker image..."
cd "${PROJECT_ROOT}/go-app"
docker build -t secret-watcher:latest .
cd "${PROJECT_ROOT}"

# Apply Kubernetes manifests
echo "Applying Kubernetes manifests..."
kubectl apply -f "${PROJECT_ROOT}/k8s/namespace.yaml"
kubectl apply -f "${PROJECT_ROOT}/k8s/secret.yaml"
kubectl apply -f "${PROJECT_ROOT}/k8s/deployment.yaml"

# Apply ArgoCD application
echo "Applying ArgoCD application..."
kubectl apply -f "${PROJECT_ROOT}/argocd/application.yaml" -n argocd

echo "Setup complete! Check ArgoCD UI or logs for status."
