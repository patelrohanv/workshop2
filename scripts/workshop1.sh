# TASK 1
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
# flesh it out with below:
# django==3.2.2
# gunicorn==20.0.4
# djangorestframework==3.12.4
# python-decouple==3.4
# psycopg2-binary==2.9.1

# install packages from requirements.txt
pip install -r requirements.txt

############################################

# TASK 2
# create nc_tutorials with django-admin cli
django-admin startproject nc_tutorials .

# in app/nc_tutorials/settings.py, comment out DATABASES under # Database

# run server
python manage.py runserver 8000

# shutdown server with ctrl+C (not command for mac users)

############################################

# TASK 3
# follow instructions for generating a Dockerfile using VS Code
# update the last command to `CMD ["gunicorn", "--bind", "0.0.0.0:8000", "nc_tutorials.wsgi"]`

# either use VS Code to build the docker image or use the terminal
# either use VS Code to run the docker image as a container or use the terminal

############################################

# TASK 4

# return to root (workshop1/)
cd ..
# create data/misc
mkdir data/misc

# cd into data/misc
cd data/misc

# create empty file named django_init.sql
touch django_init.sql
# flesh it out with below:
# DROP DATABASE IF EXISTS nc_tutorials_db;
# CREATE DATABASE nc_tutorials_db;

# \c nc_tutorials_db

# SET statement_timeout = 0;
# SET lock_timeout = 0;
# SET client_encoding = 'UTF8';
# SET standard_conforming_strings = on;
# SET check_function_bodies = false;
# SET client_min_messages = warning;
# SET default_tablespace = '';
# SET default_with_oids = false;

# return to root (workshop1/)
cd ..


# create empty file named docker-compose.yml
touch docker-compose.yml
# version: "3.8"
# services:
#   web:
#     build: ./app
#     command: python manage.py runserver 0.0.0.0:8000
#     volumes:
#       - ./app/:/usr/src/app/
#     ports:
#       - 8000:8000
#     environment:
#       - DB_NAME=nc_tutorials_db
#       - DB_USER=postgres
#       - DB_PASSWORD=admin123
#       - DB_HOST=pg
#       - DB_PORT=5432
#       - DATABASE=postgres
#     depends_on:
#       - pg
#  pg:
#       container_name: pg_container
#       image: postgres:13.2-alpine
#       restart: always
#       environment:
#           POSTGRES_USER: postgres
#           POSTGRES_PASSWORD: admin123
#           POSTGRES_DB: nc_tutorials_db
#           POSTGRES_HOST_AUTH_METHOD: trust
#       ports:
#           - "5432:5432"
#       volumes:
#           - ./data:/data
#           - ./data/misc/django_init.sql:/docker-entrypoint-initdb.d/1-django-init.sql
#   pgadmin:
#       container_name: pgadmin_container
#       image: dpage/pgadmin4:5.2
#       restart: always
#       environment:
#           PGADMIN_DEFAULT_EMAIL: admin@example.com
#           PGADMIN_DEFAULT_PASSWORD: admin123
#           PGADMIN_LISTEN_PORT: 5433
#           PGADMIN_CONFIG_SERVER_MODE: "False"
#           PGADMIN_CONFIG_MASTER_PASSWORD_REQUIRED: "False"
#       ports:
#           - "5433:5433"
#       depends_on:
#           - pg

# update app/Dockerfile
# comment out the three commands that begin with RUN adduser…, USER appuser, and CMD.

# run the containers from docker-compose (must be run from the same dir as docker-compose.yml)
docker-compose up -d

# look at instructions for pgAdmin stuff

# shut down containers
docker compose down --rmi all

############################################

# TASK 5

# cd into app
cd app

# create empty file named .env
touch .env
# flesh it out with below:
# # Database Settings
# DB_NAME=nc_tutorials_db
# DB_USER=postgres
# DB_PASSWORD=admin123
# DB_HOST=127.0.0.1
# DB_PORT=5432

# In the settings.py file, look for the line where Path is imported from pathlib. Beneath it, add this 
# `import: from decouple import config`

# In settings.py, scroll down to the DATABASES object, which you commented out in Task 1. Replace the commented-out object with:
# DATABASES = {
#     'default': {
#         'ENGINE': 'django.db.backends.postgresql_psycopg2',
#         'NAME': config('DB_NAME'),
#         'USER': config('DB_USER'),
#         'PASSWORD': config('DB_PASSWORD'),
#         'HOST': config('DB_HOST'),
#         'PORT': config('DB_PORT'),
#     }
# }

############################################

# TASK 6
# return to root
cd ..

# generate tables
docker compose exec web python manage.py migrate --noinput

# look at instructions for pgAdmin stuff

# shut down containers
docker compose down --rmi all

############################################

# TASK 7
# create tutorials sub app
python manage.py startapp tutorials

# create users sub app
python manage.py startapp users

# In the nc_tutorials/settings.py file, add these lines to the end of the INSTALLED_APPS object: 
    # 'tutorials',
    # 'users',

# download tutorials.zip
# https://learn.nucamp.co/pluginfile.php/72580/mod_assign/intro/tutorials.zip

# download users.zip
# https://learn.nucamp.co/pluginfile.php/72580/mod_assign/intro/users.zip

# unzip both archives and copy them into their respective sub apps

# in the nc_tutorials/urls.py file where path is being imported from django.urls.
# Update this line as follows:
# from django.urls import path, include
# and
# add these two items to the urlpatterns list:
#     path('', include('tutorials.urls')),
#     path('', include('users.urls')),


# run the containers from docker-compose (must be run from the same dir as docker-compose.yml)
docker-compose up -d

############################################

# TASK 8
# make migrations
docker compose exec web python manage.py makemigrations --noinput

# apply migrations
docker compose exec web python manage.py migrate --noinput

# look at instructions for pgAdmin stuff

############################################

# TASK 9
# look at instructions for insomnia stuff