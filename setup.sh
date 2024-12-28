#!/bin/bash

# Usage: ./setup.sh <username> <password> <url> <api_key>

echo "Setting up secrets..."

printf $0 | gcloud secrets create USERNAME --data-file=- # Enter your username
printf $1 | gcloud secrets create PASSWORD --data-file=- # Enter your password
printf $2 | gcloud secrets create URL --data-file=- # Enter the URL
printf $3 | gcloud secrets create API_KEY --data-file=- # Enter a secure random API key

echo "Setting up IAM permissions..."

PROJECT_ID=$(gcloud config get-value project)
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
SERVICE_ACCOUNT="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"
gcloud secrets add-iam-policy-binding USERNAME --member="serviceAccount:${SERVICE_ACCOUNT}" --role="roles/secretmanager.secretAccessor"
gcloud secrets add-iam-policy-binding PASSWORD --member="serviceAccount:${SERVICE_ACCOUNT}" --role="roles/secretmanager.secretAccessor"
gcloud secrets add-iam-policy-binding URL --member="serviceAccount:${SERVICE_ACCOUNT}" --role="roles/secretmanager.secretAccessor"
gcloud secrets add-iam-policy-binding API_KEY --member="serviceAccount:${SERVICE_ACCOUNT}" --role="roles/secretmanager.secretAccessor"

echo "Starting to deploy the Cloud Run service..."

gcloud run deploy jwt-scraper \
  --source . \
  --platform managed \
  --region europe-west1 \
  --allow-unauthenticated \
  --update-secrets=USERNAME=USERNAME:1 \
  --update-secrets=PASSWORD=PASSWORD:1 \
  --update-secrets=URL=URL:1 \
  --update-secrets=API_KEY=API_KEY:1
