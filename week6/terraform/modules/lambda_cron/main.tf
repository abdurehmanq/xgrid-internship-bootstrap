variable "project_name" {}
variable "observability_ip" {}
variable "smtp_email" { default = "" }
variable "smtp_password" { default = "" }

data "archive_file" "reporter_payload" {
  type        = "zip"
  source_file = "${path.module}/../../../scripts/daily_reliability_report.py"
  output_path = "${path.module}/payload.zip"
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "${var.project_name}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

# Attach basic execution and CloudWatch logs read policy
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_cloudwatch" {
  name = "${var.project_name}-cloudwatch-read-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:StartQuery",
          "logs:GetQueryResults",
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_lambda_function" "reporter" {
  filename         = data.archive_file.reporter_payload.output_path
  function_name    = "${var.project_name}-daily-reporter"
  role             = aws_iam_role.lambda_role.arn
  handler          = "daily_reliability_report.lambda_handler"
  runtime          = "python3.10"
  timeout          = 45 # The script waits for CloudWatch Insights querying which takes ~10-15s

  source_code_hash = data.archive_file.reporter_payload.output_base64sha256

  environment {
    variables = {
      PROMETHEUS_URL = "http://${var.observability_ip}:9090"
      SMTP_EMAIL     = var.smtp_email
      SMTP_PASSWORD  = var.smtp_password
    }
  }
}

resource "aws_cloudwatch_event_rule" "daily_cron" {
  name                = "${var.project_name}-daily-cron"
  description         = "Fires every 24 hours to trigger SRE report"
  schedule_expression = "rate(1 day)"
}

resource "aws_cloudwatch_event_target" "trigger_lambda" {
  rule      = aws_cloudwatch_event_rule.daily_cron.name
  target_id = "lambda"
  arn       = aws_lambda_function.reporter.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.reporter.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_cron.arn
}

