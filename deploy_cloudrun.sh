#!/bin/bash
# Deploy ScreenGenie backend to Google Cloud Run
set -e

PROJECT_ID="${GCP_PROJECT_ID:-screengenie-hackathon}"
REGION="us-central1"
SERVICE_NAME="screengenie-api"

# Load API key from .env
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

if [ -z "$GEMINI_API_KEY" ]; then
  echo "Error: GEMINI_API_KEY not set in .env"
  exit 1
fi

echo "Deploying to Cloud Run: $SERVICE_NAME in $PROJECT_ID ($REGION)"

# Build and deploy from backend directory
cd backend

gcloud run deploy "$SERVICE_NAME" \
  --source . \
  --project "$PROJECT_ID" \
  --region "$REGION" \
  --platform managed \
  --allow-unauthenticated \
  --set-env-vars "GOOGLE_API_KEY=$GEMINI_API_KEY" \
  --memory 512Mi \
  --timeout 60

echo ""
echo "Deployed! Get the URL with:"
echo "  gcloud run services describe $SERVICE_NAME --region $REGION --format 'value(status.url)'"
