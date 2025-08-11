resource "aws_ecs_cluster" "main" {
  name = "ecs-demo-cluster"
}

resource "aws_launch_template" "ecs" {
  name_prefix   = "ecs-demo-lt"
  image_id      = data.aws_ami.ecs_optimized.id
  instance_type = "t3.micro"

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [module.security_groups.ecs_sg_id]
    subnet_id                   = module.vpc.private_subnets[0]
  }
}

data "aws_ami" "ecs_optimized" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}

resource "aws_autoscaling_group" "ecs" {
  name                      = "ecs-demo-asg"
  max_size                  = 1
  min_size                  = 1
  desired_capacity          = 1
  vpc_zone_identifier       = module.vpc.private_subnets
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
