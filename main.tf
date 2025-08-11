provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source  = "./modules/vpc"
  # If using the community module, use: source  = "terraform-aws-modules/vpc/aws"
  # version = "~> 5.0"
  name = "ecs-demo-vpc"
  cidr = "10.0.0.0/16"
  azs             = ["us-east-1a", "us-east-1b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.101.0/24", "10.0.102.0/24"]
  enable_nat_gateway = true
  single_nat_gateway = true
  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

module "security" {
  source = "./modules/security"
  vpc_id = module.vpc.vpc_id
}

module "alb" {
  source         = "./modules/alb"
  vpc_id         = module.vpc.vpc_id
  public_subnets = module.vpc.public_subnets
  alb_sg_id      = module.security.alb_sg_id
}

module "ecs" {
  source          = "./modules/ecs"
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
  ecs_sg_id       = module.security.ecs_sg_id
  alb_sg_id       = module.security.alb_sg_id
  target_group_arn = module.alb.target_group_arn
}
