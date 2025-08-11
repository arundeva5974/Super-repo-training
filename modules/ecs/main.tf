resource "aws_ecs_cluster" "main" {
  name = "ecs-demo-cluster"
}

resource "aws_launch_template" "ecs" {
  name_prefix   = "ecs-demo-lt"
  image_id      = data.aws_ami.ecs_optimized.id
  instance_type = "t3.micro"

  user_data = base64encode(<<EOF
#!/bin/bash
echo ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config
EOF
  )

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.ecs_sg_id]
    subnet_id                   = var.private_subnets[0]
  }
}


resource "aws_autoscaling_group" "ecs" {
  name                      = "ecs-demo-asg"
  max_size                  = 1
  min_size                  = 1
  desired_capacity          = 1
  vpc_zone_identifier       = var.private_subnets
  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = "ecs-demo-instance"
    propagate_at_launch = true
  }
}
