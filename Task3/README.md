# ECS on EC2 with Terraform (Modular)

This repository provisions a secure, scalable AWS ECS cluster on EC2 using Terraform modules, fronted by an Application Load Balancer (ALB). Remote state uses S3 with DynamoDB locking. A GitHub Actions workflow automates plan/apply.

## Architecture
- VPC with public and private subnets
- Internet Gateway for public subnets
- NAT Gateway for private subnets (egress)
- ALB in public subnets, HTTP listener on 80
- ECS Cluster on EC2 capacity (Auto Scaling Group)
- ECS Service running `nginxdemos/hello:latest` behind ALB
- Least-privilege Security Groups between ALB and ECS tasks
- Remote state: S3 backend + DynamoDB table for locking

## Module Structure
- `Super-repo-training/`
  - `main.tf` — root wiring (calls child modules)
  - `modules/vpc/` — VPC, subnets, IGW, NAT, routes
  - `modules/security/` — ALB + ECS security groups
  - `modules/alb/` — ALB, Target Group (IP mode), Listener
  - `modules/ecs/` — ECS Cluster, Launch Template, ASG, Task Definition, Service, IAM roles

## Prerequisites
- Terraform >= 1.3
- AWS CLI configured
- AWS credentials exported locally:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
  - `AWS_DEFAULT_REGION` (e.g., `us-east-1`)
- Create S3 bucket + DynamoDB table for backend (names referenced in root backend config)

## Getting Started
1. Initialize Terraform
```bash
terraform init
```
2. Review plan
```bash
terraform plan
```
3. Apply
```bash
terraform apply
```
4. Outputs include ALB DNS. Open the ALB DNS in a browser — you should see the NGINX Hello page with hostname.

## GitHub Actions CI/CD
Workflow at `.github/workflows/terraform.yml` runs plan/apply on pushes to `main`.
- Add these GitHub Secrets: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_DEFAULT_REGION`.

## Operations
- Force ECS service rollout (refresh tasks with same image):
```bash
aws ecs update-service \
  --cluster ecs-demo-cluster \
  --service hello-world \
  --force-new-deployment
```
- Scale ECS service tasks:
```bash
aws ecs update-service \
  --cluster ecs-demo-cluster \
  --service hello-world \
  --desired-count 2
```
- Replace an EC2 instance (let ASG relaunch with latest LT):
```bash
aws ec2 terminate-instances --instance-ids <instance-id>
```

## Task 2: Autoscaling (EC2 Cluster + ECS Service)

This task adds two layers of autoscaling:

- EC2 cluster autoscaling using an ECS Capacity Provider bound to the Auto Scaling Group.
- ECS service autoscaling of desired task count using CloudWatch CPU alarms and StepScaling policies.

### Files changed/added
- `Super-repo-training/modules/ecs/main.tf`: ASG `protect_from_scale_in = true` and ECS managed tag `AmazonECSManaged = true`.
- `Super-repo-training/modules/ecs/capacity_provider.tf`: `aws_ecs_capacity_provider` and `aws_ecs_cluster_capacity_providers`.
- `Super-repo-training/modules/ecs/service.tf`: split into CP (`hello_world_cp`) and LaunchType (`hello_world_lt`) variants, toggled by a flag.
- `Super-repo-training/modules/ecs/service_autoscaling.tf`: `aws_appautoscaling_target`, step policies, and CPU alarms.
- `Super-repo-training/modules/ecs/outputs.tf`: safe output of active service name.
- `Super-repo-training/main.tf`: feature flags enabled for the `ecs` module.

### How it works
- Capacity Provider attaches the ASG to the cluster and uses target tracking on reservation to scale EC2 instances.
- Instance protection from scale-in is enabled so ECS can drain tasks safely when scaling in.
- ECS service desired count is managed by Application Auto Scaling based on CPU:
  - Scale up by +2 tasks when CPU >= 60%.
  - Scale down by -1 task when CPU <= 10%.

### Toggle flags (in root `main.tf` under `module "ecs"`)
```hcl
enable_capacity_provider   = true   # use CP; when false, uses LaunchType EC2 service
enable_service_autoscaling = true   # enable CPU-based scaling of desired count
```

### Key variables (see `modules/ecs/variables.tf`)
- `cp_target_capacity` (default 100)
- `service_min_capacity` (default 2)
- `service_max_capacity` (default 6)
- `scaleup_cpu_threshold` (default 60)
- `scaledown_cpu_threshold` (default 10)

### Validate autoscaling
1) EC2 scaling (Capacity Provider):
   - Increase service `desired_count` or lower `cp_target_capacity` to push reservation > target.
   - Watch Capacity Provider target tracking alarms and ASG instance count grow.
2) ECS task scaling (CPU-based):
   - Generate load to drive CPU >= 60% for a few minutes (e.g., `ab -n 50000 -c 500 http://<alb-dns>/`).
   - Observe CloudWatch alarms `cpu-high/low` and Application Auto Scaling activities adjusting desired count.

### Troubleshooting specifics
- Capacity Provider creation requires:
  - ASG tag `AmazonECSManaged = true`.
  - ASG `protect_from_scale_in = true`.
  - Capacity Provider name not starting with `aws`, `ecs`, or `fargate`.
- Selecting the active service variant is done safely via `element(concat(...), 0)` to avoid indexing non-existent resources.

## Tuning & Defaults
- Target Group uses `target_type = "ip"` to support ECS awsvpc.
- ECS Service includes:
  - `deployment_minimum_healthy_percent = 50`
  - `deployment_maximum_percent = 200`
  - `health_check_grace_period_seconds = 60`
  - `deployment_circuit_breaker { enable = true, rollback = true }`
- ASG default min=1, max=3, desired=2 (adjust in `modules/ecs/main.tf`).

## Troubleshooting
- No ECS container instances (0 EC2) in cluster:
  - Ensure Launch Template has `iam_instance_profile` bound to `ecsInstanceRole`.
  - Confirm `user_data` sets `ECS_CLUSTER=<cluster-name>` in `/etc/ecs/ecs.config`.
  - Instance must be in private subnet with outbound via NAT Gateway.
- ALB shows no healthy targets:
  - Health check path `/`, matcher `200-399` (configured in `modules/alb/main.tf`).
  - ALB SG allows inbound 80 from Internet.
  - ECS SG allows inbound 80 from ALB SG; outbound 0.0.0.0/0.
- Tasks stuck in PROVISIONING/PENDING:
  - Verify sufficient EC2 capacity in ASG.
  - Check service events in ECS console.

## Clean Up
```bash
terraform destroy
```

## Notes
- Do not hardcode credentials into code. Use env vars locally and GitHub Secrets in CI.
- NAT Gateway incurs cost — destroy when done with demos.
