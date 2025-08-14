# ECS Capacity Provider tied to the EC2 Auto Scaling Group

# Create Capacity Provider (conditional)
resource "aws_ecs_capacity_provider" "this" {
  count = var.enable_capacity_provider ? 1 : 0

  # Name cannot start with aws, ecs, or fargate; only letters, numbers, underscores, hyphens allowed
  name = "demo-ec2-cp"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs.arn
    managed_termination_protection = "ENABLED"

    managed_scaling {
      status          = "ENABLED"
      target_capacity = var.cp_target_capacity
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 2
    }
  }
}

# Attach capacity provider to cluster (conditional)
resource "aws_ecs_cluster_capacity_providers" "this" {
  count = var.enable_capacity_provider ? 1 : 0

  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = [aws_ecs_capacity_provider.this[0].name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.this[0].name
    base              = 1
    weight            = 1
  }
}
