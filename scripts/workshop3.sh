# Set env variables
REGION=us-central1
PGSERVER=workshop3-postgres
DBNAME=nc_tutorials_db
REPO=workshop3-repo
IMAGE=workshop3
PROJECT_ID=$(gcloud config get-value project)
PROJECT_NUM=$(gcloud projects describe $PROJECT_ID --format 'value(projectNumber)')

echo $REGION
echo $PGSERVER
echo $DBNAME
echo $REPO
echo $IMAGE
echo $PROJECT_ID
echo $PROJECT_NUM

# enable services
gcloud services enable \
  run.googleapis.com \
  sql-component.googleapis.com \
  sqladmin.googleapis.com \
  compute.googleapis.com \
  cloudbuild.googleapis.com \
  secretmanager.googleapis.com \
  artifactregistry.googleapis.com

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
CLOUDBUILD=${PROJECT_NUM}@cloudbuild.gserviceaccount.com
echo $CLOUDBUILD

gcloud projects add-iam-policy-binding $PROJECT_ID \
   --member serviceAccount:${CLOUDBUILD} \
   --role roles/cloudsql.client

# generate and set GS_BUCKET_NAME env variable and 
# create storage bucket named ${GS_BUCKET_NAME}
GS_BUCKET_NAME=${PROJECT_ID}-storage
echo $GS_BUCKET_NAME

gsutil mb -l us-central1 gs://${GS_BUCKET_NAME}

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

# do task 6 manually (create Dockerfile)
# -----------------------------------------------------------------
# FROM python:3.9-slim
# WORKDIR /app
# COPY requirements.txt .
# RUN pip install -U pip && pip install -r requirements.txt
# COPY . .
# ENV PORT 8080
# ENV PYTHONUNBUFFERED TRUE
# CMD exec gunicorn --bind 0.0.0.0:$PORT --workers 1 --threads 8 --timeout 0 nc_tutorials.wsgi:application
# -----------------------------------------------------------------

# create Artifact Registry repository:
gcloud artifacts repositories create $REPO --repository-format=docker --location=$REGION
				
# generate and set IMAGE_LOCATION env variable (where in the repository the image will be)
IMAGE_LOCATION=${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO}/${IMAGE}
echo $IMAGE_LOCATION

#  Submit for build/push
gcloud builds submit --tag ${IMAGE_LOCATION}

# generate and set SQL_SERVER env variable
SQL_SERVER=${PROJECT_ID}:${REGION}:${PGSERVER}
echo $SQL_SERVER

# do the manual part of task 8 (create cloudmigrate.yml)
# -----------------------------------------------------------------
# steps:

# - name: "gcr.io/google-appengine/exec-wrapper"
#   args: ["-i", "${_IMAGE_LOCATION}",
#          "-s", "${_SQL_SERVER}",
#          "--", "python", "manage.py", "migrate"]

# - name: "gcr.io/google-appengine/exec-wrapper"
#   args: ["-i", "${_IMAGE_LOCATION}",
#          "-s", "${_SQL_SERVER}",
#          "--", "python", "manage.py", "collectstatic", "--no-input"]
# ------------------------------------------------------------

# build the image
gcloud builds submit --config cloudmigrate.yml \
  --substitutions _IMAGE_LOCATION=$IMAGE_LOCATION,_SQL_SERVER=$SQL_SERVER

# deploy the image
gcloud run deploy $IMAGE \
  --platform managed \
  --region $REGION \
  --image $IMAGE_LOCATION \
  --set-cloudsql-instances $SQL_SERVER \
  --allow-unauthenticated

# How to rebuild if you make changes:
# gcloud builds submit --tag ${IMAGE_LOCATION}

# gcloud builds submit --config cloudmigrate.yml \
#   --substitutions _IMAGE_LOCATION=$IMAGE_LOCATION,_SQL_SERVER=$SQL_SERVER

# gcloud run services update $IMAGE \
#   --platform managed \
#   --region $REGION \
#   --image $IMAGE_LOCATION