# CloudWatch Log Group for application logs
resource "aws_cloudwatch_log_group" "jenkins_logs" {
  name              = "/aws/ec2/${var.project_name}"
  retention_in_days = 7  # Free tier: 5GB storage

  tags = {
    Name = "${var.project_name}-logs"
  }
}

# CloudWatch Alarm for High CPU
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "70"
  alarm_description   = "This metric monitors EC2 CPU utilization"
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.jenkins_server.id
  }

  tags = {
    Name = "${var.project_name}-high-cpu-alarm"
  }
}

# CloudWatch Alarm for Status Check Failed
resource "aws_cloudwatch_metric_alarm" "instance_status_check" {
  alarm_name          = "${var.project_name}-status-check"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "0"
  alarm_description   = "This metric monitors EC2 status checks"
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.jenkins_server.id
  }

  tags = {
    Name = "${var.project_name}-status-check-alarm"
  }
}
