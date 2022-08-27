# Nucamp Devops

* * * * *

## Week 1 - Django, Docker

### Workshop
##### 1. (local) directory setup

`requirements.txt` contents
```txt
django==3.2.2
gunicorn==20.0.4
djangorestframework==3.12.4
python-decouple==3.4
psycopg2-binary==2.9.1
```

run in terminal
```bash
# create workshop1 dir, from now on this is our workshop's root dir
mkdir workshop1
# cd into workshop1
cd workshop1
# create python3 virtual environment named venv in workshop1
python3 -m venv venv
# activate venv
source venv/bin/activate
# create app dir
mkdir app
# cd into app
cd app
# create empty file named requirements.txt
touch requirements.txt
# install packages from requirements.txt (after fleshing it out)
pip install -r requirements.txt
```

##### 2. (local) django setup

`app/nc_tutorials/settings.py` changes
```python
# comment out DATABASES under # Database

# DATABASES = {
#     'default': {
#         'ENGINE': 'django.db.backends.sqlite3',
#         'NAME': BASE_DIR / 'db.sqlite3',
#     }
# }
```

run in terminal
```bash
# create nc_tutorials with django-admin cli
django-admin startproject nc_tutorials .
# in app/nc_tutorials/settings.py, comment out DATABASES under # Database

# run server
python manage.py runserver 8000
# shutdown server with ctrl+C (not command for mac users)
```

##### 3. (local) Dockerfile setup; comment out CMD

`Dockerfile` contents
```Dockerfile
# Using base python3.8 image
FROM python:3.8-slim
# expose port 8080
EXPOSE 8000
# Keeps Python from generating .pyc files in the container
ENV PYTHONDONTWRITEBYTECODE=1
# Turns off buffering for easier container logging
ENV PYTHONUNBUFFERED=1
# Install pip requirements
COPY requirements.txt .
RUN python -m pip install -r requirements.txt
# set WORKDIR and copy contents of current dir (app) to WORKDIR
WORKDIR /app
COPY . /app
# Run CMD in container's terminal
#CMD ["gunicorn", "--bind", "0.0.0.0:8000", "nc_tutorials.wsgi"]
```

##### 4. (local) docker-compose.yml, data/misc/django_init.sql setup

`docker-compose.yml` contents
```yaml
version: "3.8"
services:
  web:
    build: ./app
    command: python manage.py runserver 0.0.0.0:8000
    volumes:
      - ./app/:/usr/src/app/
    ports:
      - 8000:8000
    environment:
      - DB_NAME=nc_tutorials_db
      - DB_USER=postgres
      - DB_PASSWORD=admin123
      - DB_HOST=pg
      - DB_PORT=5432
      - DATABASE=postgres
    depends_on:
      - pg
  pg:
    container_name: pg_container
    image: postgres:13.2-alpine
    restart: always
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: admin123
      POSTGRES_DB: nc_tutorials_db
      POSTGRES_HOST_AUTH_METHOD: trust
    ports:
      - "5432:5432"
    volumes:
      - ./data:/data
      - ./data/misc/django_init.sql:/docker-entrypoint-initdb.d/1-django-init.sql
  pgadmin:
    container_name: pgadmin_container
    image: dpage/pgadmin4:5.2
    restart: always
    environment:
      PGADMIN_DEFAULT_EMAIL: admin@example.com
      PGADMIN_DEFAULT_PASSWORD: admin123
      PGADMIN_LISTEN_PORT: 5433
      PGADMIN_CONFIG_SERVER_MODE: "False"
      PGADMIN_CONFIG_MASTER_PASSWORD_REQUIRED: "False"
    ports:
      - "5433:5433"
    depends_on:
      - pg
```

`django_init.sql` contents
```SQL
DROP DATABASE IF EXISTS nc_tutorials_db;
CREATE DATABASE nc_tutorials_db;

\c nc_tutorials_db

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET default_tablespace = '';
SET default_with_oids = false;
```

run in terminal
```bash
# return to root (workshop1/)
cd ..
# create data/misc
mkdir data/misc
# cd into data/misc
cd data/misc
# create empty file named django_init.sql
touch django_init.sql
# return to root (workshop1/)
cd ..
```

##### 5. (local) .env setup, `settings.py` changes

`.env` contents
```conf
DB_NAME=nc_tutorials_db
DB_USER=postgres
DB_PASSWORD=admin123
DB_HOST=127.0.0.1
DB_PORT=5432
```

`app/nc_tutorials/settings.py` changes
```python
# app/nc_tutorials/settings.py

# add import for config from decouple
from decouple import config


# Replace the commented-out object from TASK 1 with:
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql_psycopg2',
        'NAME': config('DB_NAME'),
        'USER': config('DB_USER'),
        'PASSWORD': config('DB_PASSWORD'),
        'HOST': config('DB_HOST'),
        'PORT': config('DB_PORT'),
    }
}
```

run in terminal
```bash
# cd into app
cd app
```

##### 6. (local) run migrations

run in terminal
```bash
# return to root
cd ..

# generate tables
docker compose exec web python manage.py migrate --noinput
```

##### 7. (local) create sub-apps; update `settings.py` and `urls.py`; download/extract zips and update the submodules

`app/nc_tutorials/settings.py` changes
```python
# add tutorials and users INSTALLED_APPS
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'tutorials',
    'users',
]
```

`app/nc_tutorials/urls.py` changes
```python
# update to also import include 
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
# include tutorials.urls
    path('', include('tutorials.urls')),
# include users.urls
    path('', include('users.urls')),
]
```

run in terminal
```bash
# create tutorials sub app
python manage.py startapp tutorials

# create users sub app
python manage.py startapp users

# update urls.py and settings.py
```

##### 8. (local) make new migrations and run migrations

run in terminal
```bash
# make migrations
docker compose exec web python manage.py makemigrations --noinput

# apply migrations
docker compose exec web python manage.py migrate --noinput
```

##### 9. (local) Test

* * * * *

## Week 2 - AWS

#### Environment
```conf
ECR_ADDR=293228169397.dkr.ecr.us-east-1.amazonaws.com/workshop2
EC2_ADDR=ec2-44-208-113-247.compute-1.amazonaws.com
ELASTIC_IP=44.208.113.247
RDS_ADDR=nctutorials1.cocp1s1hjzyg.us-east-1.rds.amazonaws.com
```

### Prework
##### 1. (web aws) EC2 setup -> `[Ubuntu Server 20.04 LTS (HVM), SSD Volume Type), t2.micro]`; create new security group `django_docker_aws` and add two rules for HTTP and HTTPS; create new keypair; save DNS addr to `$EC2_ADDR`

probably doesn't work, run in terminal
```bash
# might not work
# create security group
aws ec2 create-security-group --group-name django_docker_aws --description "django_docker_aws" 

# create keypair
aws ec2 create-key-pair --key-name django_docker_aws > django_docker_aws.pem
chmod 400 django_docker_aws.pem

# create launch ec2 instance
aws ec2 run-instances \
    --image-id ami-08d4ac5b634553e16 \
    --count 1 \
    --instance-type t2.micro \
    --key-name django_docker_aws \
    --security-group-ids django_docker_aws
```

##### 2. (web aws) allocate & associate elastic IP

##### 3. (web aws) security group -> add inbound rule `[Custom TCP, 8000, Anywhere-IPv4]`

##### 4. (web aws) IAM -> create new role `django_docker_aws` `[AWS service, EC2, AmazonEC2ContainerRegistryPowerUser policy]`; attach `django_docker_aws` to EC2 instance

```bash
# create IAM role
aws iam create-role --role-name role-example --assume-role-policy-document file://trust-policy.json
```
##### 5. (local) ssh into EC2 instance -> bootstrap

run in terminal
```bash
ssh -i django_docker_aws.pem ubuntu@<your EC2 instance Elastic IP address>
```

run in ec2 instance; copy/paste it into a script
```bash
#/bin/bash
sudo apt update -y 
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - 
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
sudo apt update -y
sudo apt install -y docker-ce
sudo usermod -aG docker ${USER}
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo su $USER
docker -v
docker-compose -v 

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install -y unzip 
unzip awscliv2.zip 
sudo ./aws/install 
aws --version 
```

### Workshop
##### 1. (web aws) security group (`django_docker_aws`) -> add inbound rule [TCP, 5432, Anywhere-IPv4]; ECR -> create new registry `workshop2` & save URI to `$ECR_ADDR`

##### 2. (web aws) RDS -> `{version: PostgresSQL 12.8-R1; identifier: nctutorials; username: postgres; password: admin123; security groups: django_docker_aws; db_name: nc_tutorials_db }` & save endpoint to `$RDS_ADDR`

probably doesn't work, run in terminal
```bash
aws rds create-db-instance \
    --engine sqlserver-se \
    --db-instance-identifier mymsftsqlserver \
    --allocated-storage 250 \
    --db-instance-class db.t3.large \
    --vpc-security-group-ids django_docker_aws \
    --db-subnet-group mydbsubnetgroup \
    --master-username postgres \
    --master-user-password admin123 \
    --backup-retention-period 3
```

##### 3. (local) dev setup; download/extract zip

##### 4. (local) update `settings.py` and `urls.py`

`app/nc_tutorials/settings.py` changes
```python
# add import os
import os

# add [your-EC2-DNS-address, '0.0.0.0', 'localhost', '127.0.0.1'] to ALLOWED_HOSTS
ALLOWED_HOSTS = ['ec2-44-206-218-197.compute-1.amazonaws.com', '0.0.0.0', 'localhost', '127.0.0.1']

# add if/else before STATIC_URL declaration/assignment 
if DEBUG:
    STATICFILES_DIRS = [os.path.join(BASE_DIR, "static")]
else:
    STATIC_ROOT = [os.path.join(BASE_DIR, "static")]

STATIC_URL = '/static/'
```

`app/nc_tutorials/urls.py` changes
```python
# update to also import static and settings  
from django.conf.urls.static import static
from django.conf import settings

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', include('tutorials.urls')),
    path('', include('users.urls'))
# add static URL to patterns
] + static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
```

##### 5. (local) update the 'YOUR_SOMETHING_HERE' placeholders in `docker-compose.yml` and `.env`

`docker-compose.yml` to update
```yaml
version: "3.8"
services:
  web:
    build: ./app
    image: YOUR_REPO_HERE:workshop2_web
    command: gunicorn nc_tutorials.wsgi:application --bind 0.0.0.0:8000
    volumes:
      - ./app/:/usr/src/app/
      - static_volume:/usr/src/app/static
    expose:
      - 8000
    environment:
      - DB_NAME=nc_tutorials_db
      - DB_USER=postgres
      - DB_PASSWORD=admin123
      - DB_HOST=YOUR_DB_ENDPOINT_HERE
      - DB_PORT=5432
      - DATABASE=postgres
      - VIRTUAL_HOST=YOUR_EC2_INSTANCE_DNS_HERE
      - VIRTUAL_PORT=8000
  nginx:
    build: ./nginx
    image: YOUR_REPO_HERE:workshop2_nginx
    volumes:
      - static_volume:/usr/src/app/static
    ports:
      - 8000:80
    depends_on:
      - web
volumes:
  static_volume:
```

`.env` to update
```conf
# Database Settings
DB_NAME=nc_tutorials_db
DB_USER=postgres
DB_PASSWORD=admin123
DB_HOST=YOUR_DB_ENDPOINT_HERE
DB_PORT=5432
```

##### 6. (web gh) create new gh repo; (local) `git init` and set remote to new repo

##### 7. ssh into EC2 instance -> clone code; docker-compose up -d; make migrations; migrate

run in terminal
```bash
ssh -i nucamp-private-key.pem ubuntu@<your EC2 instance Elastic IP address>
```

run in ec2 instance
```bash
# clone gh repo
git clone <GIT_REPO>
# cd into repo && docker-compose up -d
docker-compose up -d
# make migrations via docker-compose
docker-compose exec web python manage.py makemigrations --noinput
# apply migrations via docker-compose
docker-compose exec web python manage.py migrate --noinput
```

##### 8. Test

##### 9. (local) ssh into EC2 instance -> `docker-compose push`

run in terminal
```bash
ssh -i nucamp-private-key.pem ubuntu@<your EC2 instance Elastic IP address>
```

run in ec2 instance
```bash
docker-compose push
```

* * * * *

## Week 3 - GCP

#### Environment
```conf
REGION=us-central1
PGSERVER=workshop3-postgres
DBNAME=nc_tutorials_db
REPO=workshop3-repo
IMAGE=workshop3
PROJECT_ID=$(gcloud config get-value project)
PROJECT_NUM=$(gcloud projects describe $PROJECT_ID --format 'value(projectNumber)')
PGPASS="$(cat /dev/urandom | LC_ALL=C tr -dc 'a-zA-Z0-9' | fold -w 30 | head -n 1)"
CLOUDBUILD=${PROJECT_NUM}@cloudbuild.gserviceaccount.com
GS_BUCKET_NAME=${PROJECT_ID}-storage
CLOUDRUN=${PROJECT_NUM}-compute@developer.gserviceaccount.com
IMAGE_LOCATION=${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO}/${IMAGE}
SQL_SERVER=${PROJECT_ID}:${REGION}:${PGSERVER}
```

### Workshop
##### 1. (web gcp) Create GCP project

##### 2. (Cloud Shell) set environment variables

run in cloud shell
```bash
# Set env variables
REGION=
PGSERVER=
DBNAME=
REPO=
IMAGE=
PROJECT_ID=
PROJECT_NUM=

# Test that env vars are set with echo
echo $REGION
echo $PGSERVER
echo $DBNAME
echo $REPO
echo $IMAGE
echo $PROJECT_ID
echo $PROJECT_NUM
```

##### 3. (Cloud Shell) enable cloud services

run in cloud shell
```bash
# enable services
gcloud services enable \
  run.googleapis.com \
  sql-component.googleapis.com \
  sqladmin.googleapis.com \
  compute.googleapis.com \
  cloudbuild.googleapis.com \
  secretmanager.googleapis.com \
  artifactregistry.googleapis.com
```

##### 4. (Cloud Shell) create postgres instance, sql user, iam policy, and cloud bucket

run in cloud shell
```bash
# create sql instance named $PGSERVER, takes a while to run
gcloud sql instances create $PGSERVER \
  --project $PROJECT_ID \
  --database-version POSTGRES_13 \
  --tier db-f1-micro \
  --region $REGION

# create database named $DBNAME
gcloud sql databases create $DBNAME --instance $PGSERVER

# generate and set PGPASS env variable and 
# create a user for the instance we created earlier
PGPASS="$(cat /dev/urandom | LC_ALL=C tr -dc 'a-zA-Z0-9' | fold -w 30 | head -n 1)"
echo $PGPASS

gcloud sql users create pguser --instance $PGSERVER --password $PGPASS

# generate and set CLOUDBUILD env variable and 
# create iam policy
CLOUDBUILD=
echo $CLOUDBUILD

gcloud projects add-iam-policy-binding $PROJECT_ID \
   --member serviceAccount:${CLOUDBUILD} \
   --role roles/cloudsql.client

# generate and set GS_BUCKET_NAME env variable and 
# create storage bucket named ${GS_BUCKET_NAME}
GS_BUCKET_NAME=
echo $GS_BUCKET_NAME

gsutil mb -l us-central1 gs://${GS_BUCKET_NAME}
```

##### 5. (Cloud Shell) create secret

run in cloud shell
```bash
# create .env file
echo DATABASE_URL=\"postgres://pguser:${PGPASS}@//cloudsql/${PROJECT_ID}:${REGION}:${PGSERVER}/${DBNAME}\" > .env
echo GS_BUCKET_NAME=\"${GS_BUCKET_NAME}\" >> .env
echo SECRET_KEY=\"$(cat /dev/urandom | LC_ALL=C tr -dc 'a-zA-Z0-9' | fold -w 50 | head -n 1)\" >> .env
echo DEBUG=\"True\" >> .env

# create application secrets named application_settings
gcloud secrets create application_settings --data-file .env

# generate and set GCLOUDRUN env variable and 
# Allow Cloud Run and Cloud Build service accounts on this project to access our secret
CLOUDRUN=${PROJECT_NUM}-compute@developer.gserviceaccount.com
echo $CLOUDRUN

gcloud secrets add-iam-policy-binding application_settings \
  --member serviceAccount:${CLOUDRUN} \
  --role roles/secretmanager.secretAccessor

gcloud secrets add-iam-policy-binding application_settings \
  --member serviceAccount:${CLOUDBUILD} \
  --role roles/secretmanager.secretAccessor

# delete .env
rm .env
```

##### 6. (Cloud Shell) upload files and create `Dockerfile`

`Dockerfile` contents
```dockerfile
# Dockerfile
# Use an official lightweight Python image.
FROM python:3.9-slim
# set container's working directory to /app
WORKDIR /app
# Install dependencies.
COPY requirements.txt .
RUN pip install -U pip && pip install -r requirements.txt
# Copy local code to WORKDIR to the container image.
COPY . .
# set env var $PORT to 8080
ENV PORT 8080
# Setting this ensures print statements and log messages promptly appear in Cloud Logging.
ENV PYTHONUNBUFFERED TRUE
# Run the web service on container startup. 
CMD exec gunicorn --bind 0.0.0.0:$PORT --workers 1 --threads 8 --timeout 0 nc_tutorials.wsgi:application
```

##### 7. (Cloud Shell) create artifact registry, build/push image

run in cloud shell
```bash
# create Artifact Registry repository:
gcloud artifacts repositories create $REPO --repository-format=docker --location=$REGION
				
# generate and set IMAGE_LOCATION env variable (where in the repository the image will be)
IMAGE_LOCATION=
echo $IMAGE_LOCATION

#  Submit for build/push
gcloud builds submit --tag ${IMAGE_LOCATION}
```

##### 8. (Cloud Shell) create `cloudmigrate.yml`, run, and run build
```yaml
# cloudmigrate.yml
steps:

- name: "gcr.io/google-appengine/exec-wrapper"
  args: ["-i", "${_IMAGE_LOCATION}",
         "-s", "${_SQL_SERVER}",
         "--", "python", "manage.py", "migrate"]

- name: "gcr.io/google-appengine/exec-wrapper"
  args: ["-i", "${_IMAGE_LOCATION}",
         "-s", "${_SQL_SERVER}",
         "--", "python", "manage.py", "collectstatic", "--no-input"]
```

run in cloud shell
```bash
# generate and set SQL_SERVER env variable
SQL_SERVER=
echo $SQL_SERVER

# build the image
gcloud builds submit --config cloudmigrate.yml \
  --substitutions _IMAGE_LOCATION=$IMAGE_LOCATION,_SQL_SERVER=$SQL_SERVER
```

##### 9. (Cloud Shell) deploy; test

run in cloud shell
```bash
gcloud run deploy $IMAGE \
  --platform managed \
  --region $REGION \
  --image $IMAGE_LOCATION \
  --set-cloudsql-instances $SQL_SERVER \
  --allow-unauthenticated
```

#### Troubleshooting
- If you make any changes to files after task 7 or 8 or 9

run in cloud shell
```bash
# rebuild and push the image
gcloud builds submit --tag ${IMAGE_LOCATION}

# run migrations and collect static files again
gcloud builds submit --config cloudmigrate.yml \
  --substitutions _IMAGE_LOCATION=$IMAGE_LOCATION,_SQL_SERVER=$SQL_SERVER

# deploy update to running service
gcloud run services update $IMAGE \
  --platform managed \
  --region $REGION \
  --image $IMAGE_LOCATION
```

* * * * *

## Week 4 - Azure

#### Environment
```conf
CONTAINER_REGISTRY=rpnucampdjangoregistry
LOGIN_SERVER=rpnucampdjangoregistry.azurecr.io
SQL_SERVER=rpnucamp-server
```

### Prework
##### 1. (local) log into the Azure cli

run in terminal
```bash
az login
```

##### 2. (local) Create resource group named *django-apps* in the *eastus* region

run in terminal
```bash
az group create --name django-apps --location eastus
```

##### 3. (local) Create AKS cluster 

run in terminal
```bash
az aks create --resource-group django-apps --name djangocluster --node-count 1 --generate-ssh-keys
```

##### 4. (local) Create container registry; save login server to `$LOGIN_SERVER` 

run in terminal
```bash
az acr create --resource-group django-apps --name $CONTAINER_REGISTRY --sku Basic
```

### Workshop
##### 1. (local) dev setup; download/extract zip

run in terminal
```bash
cd app

# To build the image (in workshop4/app)
docker build --platform linux/amd64 -t workshop4 .
```

##### 2. (local) azure setup

run in terminal
```bash
# Log in to Azure CLI
az login

# To log in to the container registry (note, the name should be just the name, not the login server)
az acr login -n $CONTAINER_REGISTRY  

# Tag and push
docker tag workshop4:latest $LOGIN_SERVER/workshop4:v1
docker push $LOGIN_SERVER/workshop4:v1
```

##### 3. (local) azure postgres setup

run in terminal
```bash
az postgres flexible-server create -g django-apps -n $SQL_SERVER -d nc_tutorials_db --public-access all
```

##### 4. (local) connect to azure cluster

run in terminal
```bash
az aks get-credentials -g django-apps -n djangocluster
```

##### 5. (local) update `workshop4-deployment.yml`

`workshop4-deployment.yml` to update
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: workshop4
spec:
  replicas: 1
  selector:
    matchLabels:
      app: workshop4
  template:
    metadata:
      labels:
        app: workshop4
    spec:
      containers:
        - args:
            - python
            - manage.py
            - runserver
            - 0.0.0.0:8000
          name: workshop4
          image: <CHANGE TO YOUR REGISTRY LOGIN SERVER>/workshop4:v1
          imagePullPolicy: Always
          ports:
            - containerPort: 8000
          env:
            - name: DATABASE_HOST
              value: "<CHANGE TO YOUR DATABASE HOST>"
            - name: DATABASE_USER
              value: "<CHANGE TO YOUR DATABASE USER>"
            - name: DATABASE_PASSWORD
              value: "<CHANGE TO YOUR DATABASE PASSWORD>"
            - name: DATABASE_NAME
              value: "nc_tutorials_db"
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            - labelSelector:
                matchExpressions:
                  - key: "app"
                    operator: In
                    values:
                      - workshop4
              topologyKey: "kubernetes.io/hostname"
---
apiVersion: v1
kind: Service
metadata:
  name: workshop4-service
spec:
  type: LoadBalancer
  ports:
    - port: 8000
  selector:
    app: workshop4

```

##### 6. (local) deploy and create a service (in workshop4 folder, NOT app)

run in terminal
```bash
cd ..
kubectl apply -f workshop4-deployment.yml
```

##### 7. (local) make migrations, migrate

run in terminal
```bash
# Make migrations
kubectl exec <pod_name> -- python manage.py makemigrations

# Apply migrations
kubectl exec <pod_name> -- python manage.py migrate
```

##### 8. Test