# Use selenium/standalone-chrome as the base image
FROM selenium/standalone-chrome:latest

# Set working directory
WORKDIR /app

# Copy requirements and install dependencies
COPY requirements.txt .

# Install dependencies
USER root
RUN pip3 install --no-cache-dir --break-system-packages -r requirements.txt

# Copy application code
COPY . .

# Set environment variables
ENV PORT=8080

# Run the flask application
CMD ["python3", "main.py"] 