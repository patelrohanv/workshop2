CONTAINER_REGISTRY=rpnucampdjangoregistry

# Create AKS Kubernetes cluster
az login
az group create --name django-apps --location eastus
az aks create --resource-group django-apps --name djangocluster --node-count 1 --generate-ssh-keys
az aks get-credentials --resource-group django-apps --name djangocluster
kubectl get nodes

# Create Container Registry
az acr create --resource-group django-apps --name $CONTAINER_REGISTRY --sku Basic
LOGIN_SERVER=rpnucampdjangoregistry.azurecr.io

# To log in to the container registry (note, the name should be just the name, not the login server)
az acr login --name $CONTAINER_REGISTRY
az aks update -n djangocluster -g django-apps --attach-acr $CONTAINER_REGISTRY