# Deployment with Google Cloud

This is a guide to deploy the JWT scraper to Google Cloud Run.

## Prerequisites

- Google Cloud account
- gcloud CLI installed
- Docker installed (for local testing)
- Access to Google Cloud Secret Manager

## Setup

1. Go to the [Google Cloud Console](https://console.cloud.google.com), create a new project and open this project.
  
2. Clone this repository:
```bash
git clone https://github.com/nilsreichardt/scrape-jwt-template jwt-scraper && cd jwt-scraper
```

3. Execute the `setup.sh` script to create the required resources:
```bash
./setup.sh john.doe@tum.de 'my_password'
```

Replace `john.doe@tum.de` with your username and `my_password` with your password.
