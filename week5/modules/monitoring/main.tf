# SNS Topic for Alarms
resource "aws_sns_topic" "alerts" {
  name = "wp-cloudwatch-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.sns_email
}

# -----------------------------------------------------------------------------
# SLO 1: EC2 Target CPU < 80% (Latency/Capacity)
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "wp-slo-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "SLO Violation: ASG average CPU utilization > 80% for 4 minutes"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  
  dimensions = {
    AutoScalingGroupName = var.asg_name
  }
}

# -----------------------------------------------------------------------------
# SLO 2: RDS Database Connections (Capacity/Availability)
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "high_db_connections" {
  alarm_name          = "wp-slo-db-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 120
  statistic           = "Average"
  threshold           = 50
  alarm_description   = "SLO Violation: Database connections > 50"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = var.db_instance_id
  }
}

# -----------------------------------------------------------------------------
# SLO 3: ALB 5xx Error Rate (Availability/Error Rate)
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "high_5xx_errors" {
  alarm_name          = "wp-slo-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "SLO Violation: More than 5 5xx errors from Target Group in 2 minutes"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }
}

# -----------------------------------------------------------------------------
# Composite SLO: Web Latency + DB Latency
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "high_web_latency" {
  alarm_name          = "wp-slo-web-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 2.0 # 2 seconds
  alarm_description   = "ALB Target Response Time > 2s"
}

resource "aws_cloudwatch_metric_alarm" "high_db_latency" {
  alarm_name          = "wp-slo-db-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ReadLatency"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 0.1 # 100ms
  alarm_description   = "RDS Read Latency > 100ms"
  
  dimensions = {
    DBInstanceIdentifier = var.db_instance_id
  }
}

resource "aws_cloudwatch_composite_alarm" "system_degraded" {
  alarm_name        = "wp-slo-composite-system-degraded"
  alarm_description = "SLO Violation: Both Web and DB latency are high"
  alarm_actions     = [aws_sns_topic.alerts.arn]

  alarm_rule = trimspace(<<-EOF
    ALARM(${aws_cloudwatch_metric_alarm.high_web_latency.alarm_name}) AND 
    ALARM(${aws_cloudwatch_metric_alarm.high_db_latency.alarm_name})
  EOF
  )
}
