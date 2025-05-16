.PHONY: start build build-dockerhub clean logs port-forward check-docker

# Configuration
DOCKER_USERNAME ?= your-dockerhub-username
NAMESPACE = secret-watch-demo
APP_NAME = secret-watcher-app

# Check Docker status for WSL
check-docker:
	@echo "Checking Docker status..."
	@if ! docker info >/dev/null 2>&1; then \
		echo "Docker is not running. If you're using Docker Desktop:"; \
		echo "1. Please start Docker Desktop for Windows"; \
		echo "2. Wait a minute for it to fully start"; \
		echo "3. Try this command again"; \
		echo ""; \
		echo "If Docker Desktop is already running, try:"; \
		echo "wsl --shutdown"; \
		echo "then restart your WSL terminal."; \
		exit 1; \
	fi

# Start everything (Minikube, ArgoCD, build image, deploy)
start: check-docker
	@echo "Starting Minikube and deploying application..."
	./scripts/startup.sh

# Build for Minikube local registry
build:
	@echo "Building Docker image for Minikube..."
	./scripts/build_and_push.sh

# Build and push to Docker Hub
build-dockerhub:
	@echo "Building and pushing Docker image to Docker Hub..."
	./scripts/build_and_push.sh $(DOCKER_USERNAME)

# Clean up resources
clean:
	@echo "Cleaning up resources..."
	kubectl delete -f argocd/application.yaml -n argocd || true
	kubectl delete namespace $(NAMESPACE) || true
	minikube stop

# View application logs
logs:
	@POD=$$(kubectl get pods -n $(NAMESPACE) -l app=secret-watcher -o jsonpath='{.items[0].metadata.name}' 2>/dev/null); \
	if [ -n "$$POD" ]; then \
		kubectl logs -f -n $(NAMESPACE) $$POD; \
	else \
		echo "No pods found in namespace $(NAMESPACE)"; \
	fi

# Port forward ArgoCD UI
port-forward:
	@echo "Port forwarding ArgoCD UI to localhost:8082..."
	kubectl port-forward svc/argocd-server -n argocd 8082:443

# Get ArgoCD admin password
argocd-password:
	@echo "ArgoCD admin password:"
	@kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

# Help
help:
	@echo "Available targets:"
	@echo "  start            - Start Minikube and deploy everything"
	@echo "  build           - Build Docker image for Minikube"
	@echo "  build-dockerhub - Build and push to Docker Hub"
	@echo "  clean           - Clean up resources"
	@echo "  logs            - View application logs"
	@echo "  port-forward    - Port forward ArgoCD UI"
	@echo "  argocd-password - Get ArgoCD admin password"
	@echo "  help            - Show this help message"
