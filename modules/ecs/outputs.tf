output "ecs_cluster_id" {
  description = "The ID of the ECS cluster"
  value       = aws_ecs_cluster.main.id
}

output "ecs_service_name" {
  description = "The name of the ECS service"
  value       = element(concat(aws_ecs_service.hello_world_cp[*].name, aws_ecs_service.hello_world_lt[*].name), 0)
}
