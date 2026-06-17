# Comandos EP2 tres capas

## Local

```powershell
copy .env.example .env
docker compose up --build -d
docker compose ps
```

Validar:

```text
http://localhost:3000
http://localhost:3000/api/v1/ping
http://localhost:3000/api/v1/ping/avances
```

## Terraform

```powershell
cd infra\ep2_tres_capas
copy terraform.tfvars.example terraform.tfvars
terraform init
terraform validate
terraform plan
terraform apply
terraform output
```

## GitHub ramas

```powershell
git checkout Develop
git merge feature/fix_backend
git push origin Develop

git checkout main
git merge Develop
git push origin main

git checkout deploy
git merge main
git push origin deploy
```

## Verificar EC2 con SSM

```powershell
aws ssm start-session --target ID_FRONTEND
aws ssm start-session --target ID_BACKEND
aws ssm start-session --target ID_DATA
```

Dentro de cada EC2:

```bash
docker ps
docker compose ps
docker volume ls
docker logs innovatech-frontend
docker logs innovatech-proyectos-backend
docker logs innovatech-avances-backend
docker logs innovatech-mysql
```

## Destruir infraestructura al terminar

```powershell
cd infra\ep2_tres_capas
terraform destroy
```
