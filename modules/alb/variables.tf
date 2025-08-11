variable "vpc_id" {
  description = "The VPC ID for the ALB"
  type        = string
}

variable "public_subnets" {
  description = "The public subnet IDs for the ALB"
  type        = list(string)
}

variable "alb_sg_id" {
  description = "The security group ID for the ALB"
  type        = string
}
