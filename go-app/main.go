package main

import (
	"encoding/base64"
	"log"
	"os"

	v1 "k8s.io/api/core/v1"
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

	config, err := rest.InClusterConfig()
	if err != nil {
		log.Fatalf("Failed to get in-cluster config: %v", err)
	}
	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		log.Fatalf("Failed to create clientset: %v", err)
	}

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
	select {}
}

func printSecretData(secret *v1.Secret) {
	if secret.Data == nil {
		log.Println("  No data in secret.")
		return
	}
	for key, value := range secret.Data {
		decodedValue, err := base64.StdEncoding.DecodeString(string(value))
        if err != nil {
             log.Printf("  %s: %s (raw, could not base64 decode)", key, string(value))
        } else {
		    log.Printf("  %s: %s", key, string(decodedValue))
        }
	}
}