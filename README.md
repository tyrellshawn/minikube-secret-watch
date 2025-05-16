# Minikube Secret Watcher with ArgoCD

This project demonstrates a Go application running in Minikube that watches for changes to a Kubernetes Secret. The deployment is managed by ArgoCD.

## Prerequisites

*   [Minikube](https://minikube.sigs.k8s.io/docs/start/)
*   [kubectl](https://kubernetes.io/docs/tasks/tools/)
*   [Docker](https://www.docker.com/get-started)
*   [Go](https://golang.org/doc/install) (for building the app)
*   [Git](https://git-scm.com/downloads)
*   [ArgoCD CLI](https://argo-cd.readthedocs.io/en/stable/cli_installation/) (optional, but helpful)

## Setup

### 1. Start Minikube

```bash
minikube start --cpus=4 --memory=4096
```

### 2. Install ArgoCD on Minikube

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Wait for ArgoCD pods to be ready:

```bash
kubectl get pods -n argocd -w
```

Access ArgoCD UI (optional):

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Open http://localhost:8080 in your browser.
# Username: admin
# Password:
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```

### 3. Build and Push Docker Image (or use Minikube's Docker daemon)

Option A: Push to a Docker Registry (e.g., Docker Hub)
Replace your-dockerhub-username in k8s/deployment.yaml and the command below.

```bash
cd go-app
docker build -t your-dockerhub-username/secret-watcher:latest .
docker push your-dockerhub-username/secret-watcher:latest
cd ..
```

Option B: Use Minikube's Docker daemon (no push needed)

```bash
eval $(minikube -p minikube docker-env)
cd go-app
docker build -t secret-watcher:latest .
# Ensure k8s/deployment.yaml image field matches this tag
# AND imagePullPolicy: IfNotPresent or Never
cd ..
# To undo: eval $(minikube -p minikube docker-env -u)
```

### 4. Create Git Repository and Push Files

```bash
git init
git add .
git commit -m "Initial commit of secret watcher app and k8s manifests"
git remote add origin https://github.com/your-github-username/minikube-secret-watch.git
git branch -M main
git push -u origin main
```

### 5. Create ArgoCD Application

```bash
kubectl apply -f argocd/application.yaml
```

Or, if you want ArgoCD to pick it up from its own namespace:

```bash
kubectl apply -f argocd/application.yaml -n argocd
```

Then check the status:

```bash
argocd app get secret-watcher-demo-app
argocd app sync secret-watcher-demo-app # Optional: to force an immediate sync
```

### 6. Testing the Secret Watcher

Check Application Logs:

```bash
kubectl get pods -n secret-watch-demo
kubectl logs -f <pod-name> -n secret-watch-demo
```

You should see a line like:

    Secret ADDED: secret-watch-demo/my-app-secret

And then the initial secret data.

Modify the Secret Declaratively (GitOps way):

Edit k8s/secret.yaml, change API_KEY, commit and push. ArgoCD will sync and the app logs will update.

Modify the Secret Imperatively (Directly in K8s):

```bash
kubectl edit secret my-app-secret -n secret-watch-demo
```

Check the Go application logs. You should see the Secret UPDATED message almost immediately.

### Cleanup

```bash
kubectl delete -f argocd/application.yaml
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl delete namespace argocd
kubectl delete namespace secret-watch-demo
minikube stop
minikube delete
```
