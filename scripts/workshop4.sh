CONTAINER_REGISTRY=rpnucampdjangoregistry

# To build the image (in workshop4/app)
cd app
docker build --platform linux/amd64 -t workshop4 .

# Log in to Azure CLI
az login

# To log in to the container registry (note, the name should be just the name, not the login server)
az acr login -n $CONTAINER_REGISTRY  

# Tag and push
LOGIN_SERVER=rpnucampdjangoregistry.azurecr.io
docker tag workshop4:latest $LOGIN_SERVER/workshop4:v1
docker push $LOGIN_SERVER/workshop4:v1

# To create a Postgres server
SQL_SERVER=rpnucamp-server
az postgres flexible-server create -g django-apps -n $SQL_SERVER -d nc_tutorials_db --public-access all

# To connect to the Kubernetes cluster
az aks get-credentials -g django-apps -n djangocluster

# TASK 5: update workshop4-deployment.yml

# Time to deploy and create a service (in workshop4 folder, NOT app):
cd ..
kubectl apply -f workshop4-deployment.yml

# Not required but use to check if deploy succeeded
kubectl get deployments

# Not required but easiest way to get the external IP
kubectl get services

# Get pod name
kubectl get pods

# Confirm ability to access container in pod
kubectl exec <pod_name> -- ls

# Make migrations
kubectl exec <pod_name> -- python manage.py makemigrations

# Apply migrations
kubectl exec <pod_name> -- python manage.py migrate
