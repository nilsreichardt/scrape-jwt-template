# JWT Scraper

> [!NOTE]  
> This project is a personal project and not intended to work with any other service than the one it was built for.

This service scrapes JWT tokens from the provided `URL` using Chrome automation. It runs as a [Cloud Run](https://cloud.google.com/run?hl=en) service and uses Google Cloud Secret Manager for secure credential storage.

The bot does the following:

1. Opens the provided `URL` in a headless Chrome browser
2. Selects SSO login
3. Enters the provided `USERNAME` and `PASSWORD`
4. Waits for the JWT token to appear
5. Extracts the JWT token from the cookies
6. Returns the JWT token

## Prerequisites

- Google Cloud account
- gcloud CLI installed
- Docker installed (for local testing)
- Access to Google Cloud Secret Manager

## Setup

1. Go to the [Google Cloud Console](https://console.cloud.google.com), create a new project and open this project.
  
2. Clone this repository:
```bash
git clone https://github.com/nilsreichardt/scrape-jwt-template jwt-scraper && cd jwt-scraper && chmod +x setup.sh
```

3. Execute the `setup.sh` script to create the required resources:
```bash
./setup.sh john.doe@tum.de 'my_password'
```

Replace `john.doe@tum.de` with your username and `my_password` with your password.

## Local Testing

1. Set up environment variables:
```bash
export USERNAME=your_username
export PASSWORD=your_password
export API_KEY=your_api_key
```

### 1. Run locally using Docker:

_Note: The Docker image only works on x86 architecture. If you are using arm64, you can run the web server locally (see below)._

```bash
docker build -t jwt-scraper .
docker run -p 8080:8080 \
  -e USERNAME=${USERNAME} \
  -e PASSWORD=${PASSWORD} \
  -e API_KEY=${API_KEY} \
  --shm-size="2g" \
  jwt-scraper
```

If you are using arm64, you can the web server locally:

1. Ensure [Chromedrive](https://googlechromelabs.github.io/chrome-for-testing/) is installed and in your PATH
2. Run the web server:
```bash
python3 main.py
```

### 2. Test the endpoint:
```bash
# Replace YOUR_API_KEY with your actual API key
curl "http://localhost:8080/get-jwt?api_key=YOUR_API_KEY"
```

## API Endpoints

All endpoints require an API key to be passed as a query parameter `api_key`.

- `GET /get-jwt?api_key=YOUR_API_KEY`: Returns a JWT token using `USERNAME` and `PASSWORD`
- `GET /health?api_key=YOUR_API_KEY`: Health check endpoint

## Deployment

To deploy manually using:

```bash
gcloud run deploy jwt-scraper \
  --source . \
  --platform managed \
  --region europe-west1 \
  --allow-unauthenticated \
  --memory 2Gi \
  --update-secrets=USERNAME=USERNAME:1 \
  --update-secrets=PASSWORD=PASSWORD:1 \
  --update-secrets=URL=URL:2 \
  --update-secrets=API_KEY=API_KEY:1 \
  --project anny-bot
```
 
