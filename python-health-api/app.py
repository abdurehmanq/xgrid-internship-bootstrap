from flask import Flask, jsonify
import socket
import time
import os

app = Flask(__name__)

# Directory already created and chowned in Dockerfile
LOG_DIR = '/app/logs'

@app.route('/health')
def health_check():
    try:
        # Write a log entry to the persistent volume
        with open(f"{LOG_DIR}/api.log", 'a') as f:
            f.write(f"Health check accessed at {time.time()}\n")
            
        return jsonify({
            "status": "healthy",
            "container_id": socket.gethostname(),
            "message": "SRE Python API is running securely as a non-root user!"
        })
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
