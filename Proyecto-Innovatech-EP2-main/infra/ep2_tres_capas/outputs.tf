output "frontend_public_ip" {
  description = "IP publica del Frontend. Esta es la URL que se muestra en la defensa."
  value       = aws_instance.frontend.public_ip
}

output "frontend_url" {
  description = "URL publica del Frontend"
  value       = "http://${aws_instance.frontend.public_ip}"
}

output "frontend_instance_id" {
  value = aws_instance.frontend.id
}

output "backend_instance_id" {
  value = aws_instance.backend.id
}

output "data_instance_id" {
  value = aws_instance.data.id
}

output "frontend_private_ip" {
  value = aws_instance.frontend.private_ip
}

output "backend_private_ip" {
  value = aws_instance.backend.private_ip
}

output "data_private_ip" {
  value = aws_instance.data.private_ip
}

output "frontend_ecr_url" {
  value = aws_ecr_repository.frontend.repository_url
}

output "proyectos_backend_ecr_url" {
  value = aws_ecr_repository.proyectos_backend.repository_url
}

output "avances_backend_ecr_url" {
  value = aws_ecr_repository.avances_backend.repository_url
}

output "security_summary" {
  value = <<-EOT
  Frontend: publico por HTTP/HTTPS. SSH solo desde admin_cidr.
  Backend privado: puerto 8080 para Proyectos y 8081 para Avances, ambos solo desde el Security Group del Frontend.
  Data privada: puerto 3306 solo desde el Security Group del Backend.
  EOT
}

output "github_secrets_to_create" {
  value = <<-EOT
  Crear estos secrets en GitHub Actions:
  AWS_ACCESS_KEY_ID
  AWS_SECRET_ACCESS_KEY
  AWS_SESSION_TOKEN
  AWS_REGION=${var.aws_region}
  FRONTEND_INSTANCE_ID=${aws_instance.frontend.id}
  BACKEND_INSTANCE_ID=${aws_instance.backend.id}
  DATA_INSTANCE_ID=${aws_instance.data.id}
  BACKEND_PRIVATE_IP=${aws_instance.backend.private_ip}
  DATA_PRIVATE_IP=${aws_instance.data.private_ip}
  MYSQL_DATABASE=innovatech_db
  MYSQL_ROOT_PASSWORD=una_clave_segura
  EOT
}

output "ssm_commands" {
  value = <<-EOT
  aws ssm start-session --target ${aws_instance.frontend.id}
  aws ssm start-session --target ${aws_instance.backend.id}
  aws ssm start-session --target ${aws_instance.data.id}
  EOT
}
