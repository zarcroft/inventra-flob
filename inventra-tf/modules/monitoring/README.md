# module monitoring — à créer par les étudiants
#
# Ressources attendues :
#   - aws_sns_topic + aws_sns_topic_subscription (e-mail)
#   - aws_cloudwatch_metric_alarm "ec2_cpu_backend"  : CPUUtilization > 80 %
#   - aws_cloudwatch_metric_alarm "ec2_cpu_frontend" : CPUUtilization > 80 %
#   - aws_cloudwatch_metric_alarm "rds_connections"  : DatabaseConnections > 50
#   - aws_cloudwatch_log_group "/inventra/backend"
#   - aws_cloudwatch_dashboard (optionnel — bonus)
#
# Variables d'entrée minimales :
#   name_prefix, alert_email,
#   backend_instance_id, frontend_instance_id, db_identifier
#
# Outputs attendus :
#   sns_topic_arn, log_group_name
