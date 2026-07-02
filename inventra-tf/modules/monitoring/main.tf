resource "aws_sns_topic" "alerts" {
  name = "${var.name_prefix}-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_cloudwatch_metric_alarm" "cpu_backend" {
  alarm_name          = "${var.name_prefix}-cpu-backend"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  period              = 60
  threshold           = 80
  statistic           = "Average"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"

  dimensions = {
    InstanceId = var.backend_instance_id
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "db_connections" {
  alarm_name          = "${var.name_prefix}-db-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  period              = 60
  threshold           = 50
  statistic           = "Average"
  namespace           = "AWS/RDS"
  metric_name         = "DatabaseConnections"

  dimensions = {
    DBInstanceIdentifier = var.db_identifier
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_log_group" "backend" {
  name              = "/inventra/backend"
  retention_in_days = 7
}
