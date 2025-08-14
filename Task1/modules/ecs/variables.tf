variable "vpc_id" {
  description = "The VPC ID for ECS resources"
  type        = string
}

variable "private_subnets" {
  description = "The private subnet IDs for ECS instances"
  type        = list(string)
}

variable "ecs_sg_id" {
  description = "The security group ID for ECS instances"
  type        = string
}

variable "alb_sg_id" {
  description = "The security group ID for ALB"
  type        = string
}

variable "target_group_arn" {
  description = "The ARN of the ALB target group"
  type        = string
}
