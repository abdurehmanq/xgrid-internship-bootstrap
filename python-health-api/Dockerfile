# 1. Use a lightweight base image
FROM python:3.9-slim

# 2. SRE SECURITY: Create a non-root user called 'sre-user'
RUN useradd -m sre-user

# 3. Set the working directory
WORKDIR /app

# 4. Copy requirements and install
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 5. Copy the application code
COPY app.py .

# 6. Create the logs directory and give ownership to sre-user
RUN mkdir /app/logs && chown -R sre-user:sre-user /app

# 7. SRE SECURITY: Switch to the non-root user
USER sre-user

# 8. Declare a volume for logs
VOLUME ["/app/logs"]

# 9. Expose the API port
EXPOSE 8080

# 10. Start the application
CMD ["python", "app.py"]
