# Terraform EP2 - Arquitectura de tres capas

Esta carpeta adapta la entrega EP1 a la EP2. Crea VPC, subnet publica, subnet privada, Internet Gateway, NAT Gateway, Security Groups, EC2 Frontend, EC2 Backend, EC2 Data, repositorios ECR y Log Groups de CloudWatch.

## Comandos

```powershell
cd infra\ep2_tres_capas
copy terraform.tfvars.example terraform.tfvars
terraform init
terraform validate
terraform plan
terraform apply
terraform output
```

Los outputs indican los valores que debes copiar a GitHub Secrets para ejecutar el pipeline.

## Seguridad esperada

- Frontend queda en subnet publica y expone puerto 80.
- Backend queda en subnet privada y solo acepta puerto 8080 desde el Frontend.
- Data queda en subnet privada y solo acepta puerto 3306 desde Backend.
