variable "name" {
  description = "The name of the VPC"
  type        = string
}

variable "cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "azs" {
  description = "The availability zones to use"
  type        = list(string)
}

variable "public_subnets" {
  description = "The public subnet CIDRs"
  type        = list(string)
}

variable "private_subnets" {
  description = "The private subnet CIDRs"
  type        = list(string)
}
