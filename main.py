import os
from flask import Flask, jsonify, request
from selenium.webdriver import Chrome, ChromeOptions
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import time
from functools import wraps

app = Flask(__name__)

def require_api_key(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        api_key = request.args.get('api_key')
        if not api_key:
            return jsonify({"error": "No API key provided"}), 401
        
        expected_api_key = os.environ.get("API_KEY")
        if not expected_api_key:
            return jsonify({"error": "API key not configured on server"}), 500
            
        if api_key != expected_api_key:
            return jsonify({"error": "Invalid API key"}), 401
            
        return f(*args, **kwargs)
    return decorated_function

def scrape_jwt():
    # Get credentials from Secret Manager or environment variables
    username = os.environ.get("USERNAME")
    password = os.environ.get("PASSWORD")
    url = os.environ.get("URL")
    
    if not all([username, password, url]):
        raise ValueError("Missing required credentials")

    # Configure Chrome options
    options = ChromeOptions()
    options.add_argument('--headless')
    options.add_argument('--disable-gpu')
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')
    
    driver = Chrome(options=options)
    wait = WebDriverWait(driver, 10)  # Add explicit wait
    
    try:
        # Navigate to the website
        driver.get(url)
        print("Opened the website...")

        # Click the "Login per SSO" button
        sso_button = wait.until(EC.element_to_be_clickable((By.LINK_TEXT, "Login via SSO")))
        sso_button.click()
        print("Clicked the 'Login per SSO' button...")

        # Enter "tum.de" in the input field
        domain_input = wait.until(EC.presence_of_element_located((By.TAG_NAME, "input")))
        domain_input.send_keys("tum.de")
        domain_input.send_keys(Keys.RETURN)
        print("Entered 'tum.de' and pressed Enter...")

        # Login with credentials
        username_field = wait.until(EC.presence_of_element_located((By.ID, "username")))
        username_field.send_keys(username)
        
        password_field = driver.find_element(By.ID, "password")
        password_field.send_keys(password)
        
        login_button = driver.find_element(By.ID, "btnLogin")
        login_button.click()
        print("Entered credentials and clicked the 'Login' button...")

        # Wait for the JWT cookie to be set
        time.sleep(5)  # You might want to replace this with a more robust wait condition

        # Get the jwt cookie
        jwt_cookie = driver.get_cookie("jwt")["value"]
        print("Got the JWT cookie...")

        return jwt_cookie

    finally:
        driver.quit()


@app.route('/get-jwt', methods=['GET'])
@require_api_key
def get_jwt():
    try:
        jwt = scrape_jwt()
        return jsonify({"jwt": jwt})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/health', methods=['GET'])
@require_api_key
def health_check():
    return jsonify({"status": "healthy"}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 8080)))