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

# Feature flags for Task2
variable "enable_capacity_provider" {
  description = "Enable ECS Capacity Provider tied to the ASG"
  type        = bool
  default     = false
}

variable "cp_target_capacity" {
  description = "Managed scaling target capacity for Capacity Provider (percent)"
  type        = number
  default     = 100
}

variable "enable_service_autoscaling" {
  description = "Enable Application Auto Scaling for ECS service desired count"
  type        = bool
  default     = false
}

variable "service_min_capacity" {
  description = "Minimum ECS service desired count when autoscaling enabled"
  type        = number
  default     = 2
}

variable "service_max_capacity" {
  description = "Maximum ECS service desired count when autoscaling enabled"
  type        = number
  default     = 6
}

variable "scaleup_cpu_threshold" {
  description = "CPU percent to trigger scale up"
  type        = number
  default     = 60
}

variable "scaledown_cpu_threshold" {
  description = "CPU percent to trigger scale down"
  type        = number
  default     = 10
}
