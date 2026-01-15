#!/bin/bash

# Usage: ./setup.sh <username> <password>

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Error: Missing required arguments."
  echo "Usage: ./setup.sh <username> <password>"
  exit 1
fi

# Disable all interactive prompts when running gcloud commands. If input is
# required, defaults will be used, or an error will be raised.
#
# Is needed because when running the script the first time, the user is prompted
# to enable the Cloud Run API, and the user needs to confirm by entering 'y'.
export CLOUDSDK_CORE_DISABLE_PROMPTS=1

echo "Setting up secrets..."

gcloud services enable secretmanager.googleapis.com
# Wait for the Secret Manager API to be enabled. Sometimes it takes a few
# seconds.
sleep 10

if ! gcloud secrets describe TUM_USERNAME &>/dev/null; then
  printf $1 | gcloud secrets create TUM_USERNAME --data-file=-
fi

if ! gcloud secrets describe TUM_PASSWORD &>/dev/null; then
  printf $2 | gcloud secrets create TUM_PASSWORD --data-file=-
fi

if ! gcloud secrets describe API_KEY &>/dev/null; then
  API_KEY=$(openssl rand -hex 16)
  printf $API_KEY | gcloud secrets create API_KEY --data-file=-
else
  API_KEY=$(gcloud secrets versions access latest --secret="API_KEY")
fi

echo "Setting up IAM permissions..."
gcloud services enable iam.googleapis.com

PROJECT_ID=$(gcloud config get-value project)
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")

# Create a new service account
SERVICE_ACCOUNT_NAME="jwt-scraper-sa"
if ! gcloud iam service-accounts describe "${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" &>/dev/null; then
  gcloud iam service-accounts create $SERVICE_ACCOUNT_NAME --display-name "JWT Scraper Service Account"
fi

# Wait for the creation of the service account. Sometimes it takes a few
# seconds.
sleep 10

# Assign the editor role to the new service account
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/editor"

# Update the SERVICE_ACCOUNT variable to use the new service account
SERVICE_ACCOUNT="${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

gcloud secrets add-iam-policy-binding TUM_USERNAME --member="serviceAccount:${SERVICE_ACCOUNT}" --role="roles/secretmanager.secretAccessor"
gcloud secrets add-iam-policy-binding TUM_PASSWORD --member="serviceAccount:${SERVICE_ACCOUNT}" --role="roles/secretmanager.secretAccessor"
gcloud secrets add-iam-policy-binding API_KEY --member="serviceAccount:${SERVICE_ACCOUNT}" --role="roles/secretmanager.secretAccessor"

echo "Starting to deploy the Cloud Run service..."
# Function to deploy the Cloud Run service
deploy_cloud_run() {
  gcloud run deploy jwt-scraper \
    --source . \
    --platform managed \
    --region europe-west1 \
    --allow-unauthenticated \
    --memory 2Gi \
    --update-secrets=TUM_USERNAME=TUM_USERNAME:1 \
    --update-secrets=TUM_PASSWORD=TUM_PASSWORD:1 \
    --update-secrets=API_KEY=API_KEY:1 \
    --project $PROJECT_ID \
    --service-account $SERVICE_ACCOUNT
}

# Loop to retry the deployment up to 5 times if it fails
#
# The deployment typically fails with the first attempt because the Cloud Build
# isn't created yet. The second attempt usually succeeds.
MAX_RETRIES=5
retry_count=0

until deploy_cloud_run || [ $retry_count -eq $MAX_RETRIES ]; do
  echo "Retrying deployment... ($((retry_count+1))/$MAX_RETRIES)"
  retry_count=$((retry_count+1))
  sleep 10
done

if [ $retry_count -eq $MAX_RETRIES ]; then
  echo "Deployment failed after $MAX_RETRIES attempts."
  exit 1
fi

SERVICE_URL=$(gcloud run services describe jwt-scraper --platform managed --region europe-west1 --format "value(status.url)")
echo "⬇️ Copy the following URL ⬇️"
echo "${SERVICE_URL}/get-jwt?api_key=$API_KEY"
echo "⬆️ ⬆️ ⬆️ ⬆️ ⬆️ ⬆️"