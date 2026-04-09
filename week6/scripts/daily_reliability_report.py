import os
import urllib.request
import urllib.parse
import json
import smtplib
import boto3
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from datetime import datetime, timedelta

# Configuration variables
PROMETHEUS_URL = os.getenv("PROMETHEUS_URL", "http://localhost:9090")
SMTP_EMAIL = os.getenv("SMTP_EMAIL")
SMTP_PASSWORD = os.getenv("SMTP_PASSWORD")
DESTINATION_EMAIL = os.getenv("DESTINATION_EMAIL", SMTP_EMAIL)
SMTP_SERVER = "smtp.gmail.com"
SMTP_PORT = 465 # SSL Port

# AWS CloudWatch configuration
AWS_REGION = os.getenv("AWS_REGION", "us-east-1")
LOG_GROUP_NAME = "/ecs/sre-wp" 

def query_prometheus(query):
    """Executes a PromQL query using native urllib and returns the scalar value."""
    try:
        url = f"{PROMETHEUS_URL}/api/v1/query?query={urllib.parse.quote(query)}"
        req = urllib.request.Request(url)
        with urllib.request.urlopen(req) as response:
            res_data = json.loads(response.read().decode('utf-8'))
            data = res_data['data']['result']
            if data:
                return float(data[0]['value'][1])
        return 0.0
    except Exception as e:
        print(f"Error querying Prometheus for {query}: {e}")
        return 0.0

def fetch_cloudwatch_error_logs():
    """Uses Boto3 to query CloudWatch logs for critical errors over the last 24h."""
    try:
        client = boto3.client('logs', region_name=AWS_REGION)
        start_time = int((datetime.now() - timedelta(days=1)).timestamp() * 1000)
        end_time = int(datetime.now().timestamp() * 1000)

        query = "fields @timestamp, @message | filter @message like /(?i)(error|exception|fail|oom)/ | sort @timestamp desc | limit 50"
        
        response = client.start_query(
            logGroupName=LOG_GROUP_NAME,
            startTime=start_time,
            endTime=end_time,
            queryString=query,
        )
        query_id = response['queryId']
        
        import time
        response = None
        while response == None or response['status'] == 'Running':
            time.sleep(1)
            response = client.get_query_results(queryId=query_id)
            
        return len(response['results'])
    except Exception as e:
        print(f"Boto3 CloudWatch Error: {e}")
        return "N/A"

def generate_report():
    print("Collecting SRE Metrics from Prometheus & CloudWatch...")
    
    uptime_query = 'sum(up)'
    nodes_up = query_prometheus(uptime_query)
    
    cpu_query = '100 - (avg by (instance) (avg_over_time(node_cpu_seconds_total{mode="idle"}[24h])) * 100)'
    cpu_avg = query_prometheus(cpu_query)
    
    disk_query = '100 - ((node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100)'
    disk_usage = query_prometheus(disk_query)

    restarts_query = 'sum(changes(process_start_time_seconds[24h]))'
    restarts = query_prometheus(restarts_query)

    cw_errors = fetch_cloudwatch_error_logs()
    
    recommendations = []
    if cpu_avg > 80:
        recommendations.append("Scale out ECS task instances or provision higher CPU allocation.")
    if disk_usage > 75:
        recommendations.append("Clear unused docker assets or expand EBS storage limits soon.")
    if restarts > 2:
        recommendations.append("Investigate high container turnover. Check logs via Boto3.")
    if isinstance(cw_errors, int) and cw_errors > 20:
        recommendations.append("High volume of CloudWatch text errors detected! Investigate application logic.")
    if not recommendations:
        recommendations.append("System health looks stable. No immediate actions required.")

    html_content = f"""
    <html>
      <body style="font-family: Arial, sans-serif; color: #333;">
        <h2>Daily System Reliability Scorecard</h2>
        <p><strong>Date:</strong> {datetime.now().strftime('%Y-%m-%d %H:%M')}</p>
        
        <table border="1" cellpadding="10" cellspacing="0" style="border-collapse: collapse; width: 60%;">
            <tr style="background-color: #f2f2f2;"><th>Metric</th><th>Value</th></tr>
            <tr><td><strong>System Nodes Up</strong></td><td>{int(nodes_up)} Instances</td></tr>
            <tr><td><strong>CPU Average (24h)</strong></td><td>{cpu_avg:.2f}%</td></tr>
            <tr><td><strong>Disk Storage Consumed</strong></td><td>{disk_usage:.2f}%</td></tr>
            <tr><td><strong>Failures / Restarts (24h)</strong></td><td>{int(restarts)} Restart(s)</td></tr>
            <tr><td><strong>CloudWatch Errors Logged</strong></td><td>{cw_errors} Alert(s)</td></tr>
        </table>
        
        <h3>Recommendations:</h3>
        <ul>
            {''.join([f'<li>{rec}</li>' for rec in recommendations])}
        </ul>
        <br>
        <i>Generated automatically by AWS Lambda & SRE-STACK-ONE</i>
      </body>
    </html>
    """
    return html_content

def send_email(html_content):
    if not SMTP_EMAIL or not SMTP_PASSWORD:
        print("WARNING: SMTP_EMAIL or SMTP_PASSWORD not set. Skipping email dispatch.")
        print(html_content)
        return

    msg = MIMEMultipart('alternative')
    msg['Subject'] = f"SRE Daily Report - {datetime.now().strftime('%Y-%m-%d')}"
    msg['From'] = SMTP_EMAIL
    msg['To'] = DESTINATION_EMAIL

    part = MIMEText(html_content, 'html')
    msg.attach(part)

    try:
        with smtplib.SMTP_SSL(SMTP_SERVER, SMTP_PORT) as server:
            server.login(SMTP_EMAIL, SMTP_PASSWORD)
            server.sendmail(SMTP_EMAIL, DESTINATION_EMAIL, msg.as_string())
        print("Daily Reliability Report sent successfully via Lambda!")
    except Exception as e:
        print(f"Failed to send email: {e}")

# AWS Lambda Entrypoint
def lambda_handler(event, context):
    report_html = generate_report()
    send_email(report_html)
    return {
        'statusCode': 200,
        'body': 'Report executed successfully'
    }

# Local Testing Entrypoint
if __name__ == "__main__":
    lambda_handler({}, None)
