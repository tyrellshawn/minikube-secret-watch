Okay, this is a great little project to demonstrate several core cloud-native concepts! We'll build a monorepo with:

A Go application that watches a specific Kubernetes Secret.

Kubernetes manifests for the Go application and the Secret.

An ArgoCD Application manifest to deploy everything.

Monorepo Structure:

minikube-secret-watch/
├── go-app/
│   ├── main.go
│   ├── go.mod
│   ├── go.sum
│   └── Dockerfile
├── k8s/
│   ├── namespace.yaml
│   ├── secret.yaml
│   └── deployment.yaml
├── argocd/
│   └── application.yaml
└── README.md


Let's create the files.

1. go-app/main.go

This Go application will use the client-go library to watch for changes to a specific Kubernetes Secret.

package main

import (
	"context"
	"encoding/base64"
	"fmt"
	"log"
	"os"
	"time"

	v1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/fields"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
	"k8s.io/client-go/tools/cache"
)

func main() {
	secretNamespace := os.Getenv("SECRET_NAMESPACE")
	secretName := os.Getenv("SECRET_NAME")

	if secretNamespace == "" || secretName == "" {
		log.Fatalf("SECRET_NAMESPACE and SECRET_NAME environment variables must be set")
	}

	log.Printf("Starting secret watcher for secret '%s' in namespace '%s'", secretName, secretNamespace)

	// Creates the in-cluster config
	config, err := rest.InClusterConfig()
	if err != nil {
		log.Fatalf("Failed to get in-cluster config: %v", err)
	}
	// Creates the clientset
	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		log.Fatalf("Failed to create clientset: %v", err)
	}

	// Create a watch on the specific secret
	watchlist := cache.NewListWatchFromClient(
		clientset.CoreV1().RESTClient(),
		"secrets",
		secretNamespace,
		fields.OneTermEqualSelector("metadata.name", secretName),
	)

	_, controller := cache.NewInformer(
		watchlist,
		&v1.Secret{},
		0, // No resync period
		cache.ResourceEventHandlerFuncs{
			AddFunc: func(obj interface{}) {
				secret := obj.(*v1.Secret)
				log.Printf("Secret ADDED: %s/%s", secret.Namespace, secret.Name)
				printSecretData(secret)
			},
			UpdateFunc: func(oldObj, newObj interface{}) {
				oldSecret := oldObj.(*v1.Secret)
				newSecret := newObj.(*v1.Secret)
				log.Printf("Secret UPDATED: %s/%s", newSecret.Namespace, newSecret.Name)
				log.Println("Old Data:")
				printSecretData(oldSecret)
				log.Println("New Data:")
				printSecretData(newSecret)
			},
			DeleteFunc: func(obj interface{}) {
				secret := obj.(*v1.Secret)
				log.Printf("Secret DELETED: %s/%s", secret.Namespace, secret.Name)
			},
		},
	)

	stopCh := make(chan struct{})
	defer close(stopCh)

	go controller.Run(stopCh)

	log.Println("Secret watcher is running...")
	// Keep the main goroutine alive
	select {}
}

func printSecretData(secret *v1.Secret) {
	if secret.Data == nil {
		log.Println("  No data in secret.")
		return
	}
	for key, value := range secret.Data {
		// Assuming string data for simplicity, decode if necessary
		decodedValue, err := base64.StdEncoding.DecodeString(string(value))
        if err != nil {
             // If it's not base64, it might be opaque binary or already decoded by some controllers
             // For this demo, we'll just print the raw bytes if decode fails
             log.Printf("  %s: %s (raw, could not base64 decode)", key, string(value))
        } else {
		    log.Printf("  %s: %s", key, string(decodedValue))
        }
	}
}
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Go
IGNORE_WHEN_COPYING_END

2. go-app/go.mod

Initialize Go modules in the go-app directory:

cd go-app
go mod init example.com/secret-watcher # Or your preferred module path
go get k8s.io/api/core/v1
go get k8s.io/apimachinery/pkg/apis/meta/v1
go get k8s.io/apimachinery/pkg/fields
go get k8s.io/client-go@v0.28.3 # Or latest stable
cd ..
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Bash
IGNORE_WHEN_COPYING_END

This will generate go.mod and go.sum.
go.mod will look something like:

module example.com/secret-watcher

go 1.21 // Or your Go version

require (
	k8s.io/api v0.28.3
	k8s.io/apimachinery v0.28.3
	k8s.io/client-go v0.28.3
)

// ... other indirect dependencies
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
IGNORE_WHEN_COPYING_END

3. go-app/Dockerfile

# Build stage
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o secret-watcher .

# Final stage
FROM alpine:latest
WORKDIR /root/
COPY --from=builder /app/secret-watcher .
ENV SECRET_NAMESPACE=""
ENV SECRET_NAME=""
CMD ["./secret-watcher"]
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Dockerfile
IGNORE_WHEN_COPYING_END

4. k8s/namespace.yaml

apiVersion: v1
kind: Namespace
metadata:
  name: secret-watch-demo
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Yaml
IGNORE_WHEN_COPYING_END

5. k8s/secret.yaml

This is the secret our application will watch.
Remember, data in Secrets must be base64 encoded.
echo -n "initial_api_key_value" | base64 -> aW5pdGlhbF9hcGlfa2V5X3ZhbHVl
echo -n "user123" | base64 -> dXNlcjEyMw==

apiVersion: v1
kind: Secret
metadata:
  name: my-app-secret
  namespace: secret-watch-demo
type: Opaque
data:
  API_KEY: aW5pdGlhbF9hcGlfa2V5X3ZhbHVl
  USERNAME: dXNlcjEyMw==
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Yaml
IGNORE_WHEN_COPYING_END

6. k8s/deployment.yaml

This deploys our Go application.

apiVersion: apps/v1
kind: Deployment
metadata:
  name: secret-watcher-app
  namespace: secret-watch-demo
  labels:
    app: secret-watcher
spec:
  replicas: 1
  selector:
    matchLabels:
      app: secret-watcher
  template:
    metadata:
      labels:
        app: secret-watcher
    spec:
      # serviceAccountName: <if you need specific permissions, create SA, Role, RoleBinding>
      # For watching secrets in its own namespace, default SA is often enough.
      containers:
      - name: watcher
        image: your-dockerhub-username/secret-watcher:latest # <-- CHANGE THIS
        imagePullPolicy: Always # For testing, change to IfNotPresent if using minikube docker-env
        env:
        - name: SECRET_NAMESPACE
          value: "secret-watch-demo"
        - name: SECRET_NAME
          value: "my-app-secret"
        resources:
          limits:
            memory: "128Mi"
            cpu: "100m"
          requests:
            memory: "64Mi"
            cpu: "50m"
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Yaml
IGNORE_WHEN_COPYING_END

Important:

Replace your-dockerhub-username/secret-watcher:latest with your Docker Hub username or another registry you can push to. If you're only using minikube locally, we can use minikube docker-env.

For simplicity, we're using the default service account. In a real scenario, you'd create a specific ServiceAccount, Role (with get, list, watch permissions on secrets), and RoleBinding.

7. argocd/application.yaml

This manifest tells ArgoCD about our application.

apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: secret-watcher-demo-app
  namespace: argocd # ArgoCD typically manages applications from its own namespace
spec:
  project: default
  source:
    repoURL: https://github.com/your-github-username/minikube-secret-watch.git # <-- CHANGE THIS
    targetRevision: HEAD # Or main/master branch
    path: k8s # Path within the repo where K8s manifests are
  destination:
    server: https://kubernetes.default.svc # Target K8s cluster (in-cluster for minikube)
    namespace: secret-watch-demo # Default namespace for resources if not specified in manifests
  syncPolicy:
    automated:
      prune: true    # Deletes resources removed from Git
      selfHeal: true # Reverts changes made outside of Git
    syncOptions:
    - CreateNamespace=true # Important: ArgoCD will create the 'secret-watch-demo' namespace if it doesn't exist
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Yaml
IGNORE_WHEN_COPYING_END

Important: Replace https://github.com/your-github-username/minikube-secret-watch.git with the actual URL of your Git repository once you create it.

8. README.md (Instructions to set up and run)

# Minikube Secret Watcher with ArgoCD

This project demonstrates a Go application running in Minikube that watches for changes
to a Kubernetes Secret. The deployment is managed by ArgoCD.

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
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Markdown
IGNORE_WHEN_COPYING_END
2. Install ArgoCD on Minikube
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Bash
IGNORE_WHEN_COPYING_END

Wait for ArgoCD pods to be ready:

kubectl get pods -n argocd -w
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Bash
IGNORE_WHEN_COPYING_END

Access ArgoCD UI (optional):

kubectl port-forward svc/argocd-server -n argocd 8080:443
# Open http://localhost:8080 in your browser.
# Username: admin
# Password:
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Bash
IGNORE_WHEN_COPYING_END
3. Build and Push Docker Image (or use Minikube's Docker daemon)

Option A: Push to a Docker Registry (e.g., Docker Hub)
Replace your-dockerhub-username in k8s/deployment.yaml and the command below.

cd go-app
docker build -t your-dockerhub-username/secret-watcher:latest .
docker push your-dockerhub-username/secret-watcher:latest
cd ..
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Bash
IGNORE_WHEN_COPYING_END

Option B: Use Minikube's Docker daemon (no push needed)
This builds the image directly into Minikube's Docker environment.
Make sure imagePullPolicy: IfNotPresent or Never is set in k8s/deployment.yaml for this to work reliably without a registry.
(Our deployment.yaml currently has Always, so change it if you use this option).

eval $(minikube -p minikube docker-env)
cd go-app
docker build -t your-local-registry/secret-watcher:latest . # Name it anything, e.g., secret-watcher:latest
# Important: Ensure k8s/deployment.yaml `image:` field matches this tag
# AND `imagePullPolicy: IfNotPresent` or `Never`
cd ..
# To undo: eval $(minikube -p minikube docker-env -u)
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Bash
IGNORE_WHEN_COPYING_END

For simplicity with ArgoCD, pushing to a public or accessible private registry (Option A) is often easier. If using minikube docker-env, ensure the image name in k8s/deployment.yaml matches what you built, and set imagePullPolicy: IfNotPresent. For this guide, we'll assume you pushed to a registry.

4. Create Git Repository and Push Files

Initialize a Git repository in the minikube-secret-watch directory.
Replace your-github-username in argocd/application.yaml.

git init
git add .
git commit -m "Initial commit of secret watcher app and k8s manifests"
# Create a new repository on GitHub (e.g., minikube-secret-watch)
git remote add origin https://github.com/your-github-username/minikube-secret-watch.git
git branch -M main
git push -u origin main
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Bash
IGNORE_WHEN_COPYING_END
5. Create ArgoCD Application

You can do this via the ArgoCD UI or CLI.

Using CLI:

kubectl apply -f argocd/application.yaml
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Bash
IGNORE_WHEN_COPYING_END

Or, if you want ArgoCD to pick it up from its own namespace:

kubectl apply -f argocd/application.yaml -n argocd
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Bash
IGNORE_WHEN_COPYING_END

Then check the status:

argocd app get secret-watcher-demo-app
argocd app sync secret-watcher-demo-app # Optional: to force an immediate sync
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Bash
IGNORE_WHEN_COPYING_END

Using UI:

Navigate to the ArgoCD UI (localhost:8080 from port-forward).

Click "NEW APP".

Application Name: secret-watcher-demo-app

Project: default

Sync Policy: Automatic (Enable Prune Resources and Self Heal)

Repository URL: https://github.com/your-github-username/minikube-secret-watch.git (your repo URL)

Revision: HEAD

Path: k8s

Cluster URL: https://kubernetes.default.svc

Namespace: secret-watch-demo

Check "Create Namespace" under Sync Options directory.

Click "CREATE".

ArgoCD will now sync the manifests from your k8s directory.

Testing the Secret Watcher
1. Check Application Logs

Find the pod name:

kubectl get pods -n secret-watch-demo
# e.g., secret-watcher-app-xxxxxxxxx-yyyyy
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Bash
IGNORE_WHEN_COPYING_END

View logs:

kubectl logs -f <pod-name> -n secret-watch-demo
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Bash
IGNORE_WHEN_COPYING_END

You should see a line like:
... Secret ADDED: secret-watch-demo/my-app-secret
And then the initial secret data.

2. Modify the Secret Declaratively (GitOps way)

Edit k8s/secret.yaml. For example, change API_KEY.
Original: aW5pdGlhbF9hcGlfa2V5X3ZhbHVl (initial_api_key_value)
New value: echo -n "new_secret_value_woohoo" | base64 -> bmV3X3NlY3JldF92YWx1ZV93b29ob28=
Update k8s/secret.yaml:

# ...
data:
  API_KEY: bmV3X3NlY3JldF92YWx1ZV93b29ob28= # new_secret_value_woohoo
  USERNAME: dXNlcjEyMw== # admin
# ...
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Yaml
IGNORE_WHEN_COPYING_END

Commit and push the changes to your Git repository:

git add k8s/secret.yaml
git commit -m "Update API_KEY in my-app-secret"
git push origin main
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Bash
IGNORE_WHEN_COPYING_END

ArgoCD will detect the change in Git (usually within 3 minutes, or you can force a refresh/sync in the UI) and apply the updated Secret to the cluster.

Check the Go application logs again. You should see:
... Secret UPDATED: secret-watch-demo/my-app-secret
Followed by the old and new secret data.

3. Modify the Secret Imperatively (Directly in K8s)

You can also edit the secret directly in Kubernetes (though ArgoCD with selfHeal will revert this if it's not also changed in Git).

Edit the secret:

kubectl edit secret my-app-secret -n secret-watch-demo
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Bash
IGNORE_WHEN_COPYING_END

Your editor will open. Modify one of the base64 encoded values. Save and exit.

Check the Go application logs. You should see the Secret UPDATED message almost immediately.

Note: If selfHeal is enabled in ArgoCD, ArgoCD will soon detect this manual change as "out of sync" and revert it to match the state in Git. This demonstrates the power of GitOps!

Cleanup
# Delete the ArgoCD application (this will delete the K8s resources it manages)
kubectl delete -f argocd/application.yaml # or use argocd app delete secret-watcher-demo-app
# Or delete via UI

# Uninstall ArgoCD
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl delete namespace argocd
kubectl delete namespace secret-watch-demo

# Stop Minikube
minikube stop
minikube delete # If you want to remove the cluster entirely
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Bash
IGNORE_WHEN_COPYING_END
---

**To summarize the steps after creating all files:**

1.  **Initialize Git:** `git init`, `git add .`, `git commit ...`
2.  **Create GitHub repo:** Create it on GitHub.
3.  **Push to GitHub:** `git remote add ...`, `git push ...` (Update `repoURL` in `argocd/application.yaml` *before* this if you haven't already, then commit that change too).
4.  **Start Minikube:** `minikube start`
5.  **Build/Push Docker Image:** (Use `minikube docker-env` or push to Docker Hub). Ensure `k8s/deployment.yaml` points to the correct image.
6.  **Install ArgoCD:** As per `README.md`.
7.  **Apply ArgoCD Application:** `kubectl apply -f argocd/application.yaml` (or via UI).
8.  **Test:** Check logs, modify `k8s/secret.yaml`, push to Git, observe ArgoCD syncing and app logs changing.

This comprehensive setup gives you a working monorepo for your mini Kubernetes cluster, a Go app watching secrets, and ArgoCD for visualization and GitOps-based management.
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
IGNORE_WHEN_COPYING_END