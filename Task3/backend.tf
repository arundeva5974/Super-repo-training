terraform {
  backend "s3" {
    bucket         = "yourcompany-ecs-terraform-state-arundeva-20250811"
    key            = "ecs-ec2/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock-table"
    encrypt        = true
  }
}