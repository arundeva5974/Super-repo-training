locals {
  # Select the active service name safely (avoids evaluating non-existent indexes)
  service_name = element(
    concat(
      aws_ecs_service.hello_world_cp[*].name,
      aws_ecs_service.hello_world_lt[*].name
    ),
    0
  )
}

# Application Auto Scaling target for ECS service desired count
resource "aws_appautoscaling_target" "ecs_service" {
  count              = var.enable_service_autoscaling ? 1 : 0
  max_capacity       = var.service_max_capacity
  min_capacity       = var.service_min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${local.service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Scale Up policy: increase desired count by +2
resource "aws_appautoscaling_policy" "scale_up" {
  count              = var.enable_service_autoscaling ? 1 : 0
  name               = "ecs-service-scale-up"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.ecs_service[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_service[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_service[0].service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 2
    }
  }
}

# Scale Down policy: decrease desired count by -1
resource "aws_appautoscaling_policy" "scale_down" {
  count              = var.enable_service_autoscaling ? 1 : 0
  name               = "ecs-service-scale-down"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.ecs_service[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_service[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_service[0].service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
}

# High CPU alarm triggers scale up policy
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  count               = var.enable_service_autoscaling ? 1 : 0
  alarm_name          = "ecs-${aws_ecs_cluster.main.name}-${local.service_name}-cpu-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = var.scaleup_cpu_threshold

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = local.service_name
  }

  alarm_actions = [aws_appautoscaling_policy.scale_up[0].arn]
}

# Low CPU alarm triggers scale down policy
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_low" {
  count               = var.enable_service_autoscaling ? 1 : 0
  alarm_name          = "ecs-${aws_ecs_cluster.main.name}-${local.service_name}-cpu-low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = var.scaledown_cpu_threshold

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = local.service_name
  }

  alarm_actions = [aws_appautoscaling_policy.scale_down[0].arn]
}
