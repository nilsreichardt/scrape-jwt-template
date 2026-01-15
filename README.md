# JWT Scraper

> [!NOTE]  
> This project is a personal project and not intended to work with any other service than the one it was built for.

This service scrapes JWT tokens from the hard-coded URL using Chrome automation.

The bot does the following:

1. Opens the hard-coded URL in a headless Chrome browser
2. Selects SSO login
3. Enters the provided `TUM_USERNAME` and `TUM_PASSWORD`
4. Waits for the JWT token to appear
5. Extracts the JWT token from the cookies
6. Returns the JWT token

## Prerequisites

- [Render.com](https://render.com) account

## Deployment

[![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy?repo=https://github.com/nilsreichardt/scrape-jwt-template)

1. Click the button above
2. Enter for "Blueprint Name" any name you want, e.g. `jwt-scraper`
3. For `TUM_USERNAME` and `TUM_PASSWORD` enter your TUM credentials
4. For `API_KEY` enter a random string
5. Click "Deploy"

## Local Testing

_Note:_ You don't need to do this if you are deploying to Render.com.

1. Set up environment variables:
```bash
export TUM_USERNAME=your_username
export TUM_PASSWORD=your_password
export API_KEY=your_api_key
```

### 1. Run locally using Docker:

_Note: The Docker image only works on x86 architecture. If you are using arm64, you can run the web server locally (see below)._

```bash
docker build -t jwt-scraper .
docker run -p 8080:8080 \
  -e TUM_USERNAME=${TUM_USERNAME} \
  -e TUM_PASSWORD=${TUM_PASSWORD} \
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

- `GET /get-jwt?api_key=YOUR_API_KEY`: Returns a JWT token using `TUM_USERNAME` and `TUM_PASSWORD`
- `GET /health?api_key=YOUR_API_KEY`: Health check endpoint 
