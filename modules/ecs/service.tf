resource "aws_ecs_task_definition" "hello_world" {
  family                   = "hello-world"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "hello-world"
      image     = "nginxdemos/hello"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "hello_world" {
  name            = "hello-world"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.hello_world.arn
  launch_type     = "EC2"
  desired_count   = 1
  network_configuration {
    subnets          = module.vpc.private_subnets
    security_groups  = [module.security_groups.ecs_sg_id]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = module.alb.target_group_arn
    container_name   = "hello-world"
    container_port   = 80
  }
  depends_on = [aws_autoscaling_group.ecs]
}
