# Proyecto Innovatech EP2 – Infraestructura AWS con Terraform

## Descripción

Infraestructura gestionada con **Terraform** para desplegar una arquitectura de **3 capas en AWS**:

* **Frontend público** en EC2.
* **Backend privado** en EC2.
* **Base de datos MySQL** en EC2 privada.
* **VPC** con subred pública y subred privada.
* **Internet Gateway** para acceso al frontend.
* **NAT Gateway** para salida a Internet desde la subred privada.
* **Security Groups** separados por capa.
* **Amazon ECR** para imágenes Docker.
* **GitHub Actions** para CI/CD.
* **AWS Systems Manager (SSM)** para despliegue remoto.
* **CloudWatch Logs** para organización de logs por capa.

---

## Estructura del proyecto

```text
Proyecto-Innovatech-EP2/
├── .github/
│   └── workflows/
│       └── deploy.yml
├── backend-avances/
│   ├── Dockerfile
│   └── src/
├── backend-proyectos/
│   ├── Dockerfile
│   └── src/
├── frontend/
│   ├── Dockerfile
│   └── src/
├── deploy/
│   ├── frontend-compose.yml
│   ├── backend-compose.yml
│   └── data-compose.yml
├── infra/
│   └── ep2_tres_capas/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars.example
├── docker-compose.yml
├── .env.example
└── README.md
```

---

## Requisitos

* Cuenta AWS o AWS Academy activa.
* Terraform CLI `>= 1.5.0`.
* AWS CLI configurado.
* Docker Desktop.
* Git.
* Key Pair creado en AWS.
* Permisos para crear VPC, EC2, ECR, Security Groups, NAT Gateway, CloudWatch y SSM.

---

## ¿Qué despliega este proyecto?

### Red AWS

```text
Región: us-east-1
VPC: 10.0.0.0/16
Subred pública Frontend: 10.0.1.0/24
Subred privada Backend + Data: 10.0.2.0/24
```

La subred pública usa una ruta hacia el **Internet Gateway**.

```text
0.0.0.0/0 → Internet Gateway
```

La subred privada usa una ruta hacia el **NAT Gateway**.

```text
0.0.0.0/0 → NAT Gateway
```

---

### Capa Frontend

```text
EC2 Frontend
Subred pública
Contenedor: innovatech-frontend
Puerto público: 80
Puerto contenedor: 8080
```

Security Group:

```text
80  desde Internet
443 desde Internet
22  desde admin_cidr
```

---

### Capa Backend

```text
EC2 Backend
Subred privada
Contenedores:
- innovatech-proyectos-backend : 8080
- innovatech-avances-backend   : 8081
```

Security Group:

```text
8080 solo desde Frontend
8081 solo desde Frontend
22   solo desde Frontend
```

---

### Capa Data

```text
EC2 Data
Subred privada
Base de datos: MySQL 8.0
Puerto: 3306
Volumen: innovatech_mysql_data
Disco: gp3 de 12 GB
```

Security Group:

```text
3306 solo desde Backend
22   solo desde Backend
```

---

## Amazon ECR

Se crean tres repositorios para almacenar las imágenes Docker:

```text
innovatech-ep2-frontend
innovatech-ep2-proyectos-backend
innovatech-ep2-avances-backend
```

---

## GitHub Actions

El pipeline está ubicado en:

```text
.github/workflows/deploy.yml
```

Flujo de despliegue:

```text
Push a rama deploy
        ↓
GitHub Actions
        ↓
Build de imágenes Docker
        ↓
Push a Amazon ECR
        ↓
Deploy vía AWS Systems Manager
        ↓
EC2 Frontend, Backend y Data
```

El despliegue se realiza mediante **SSM**, evitando conectarse manualmente por SSH a cada instancia.

---

## Uso local con Docker

Levantar el proyecto completo:

```bash
docker compose up --build
```

Servicios locales:

```text
Frontend: http://localhost:3000
Backend Proyectos: http://localhost:8080
Backend Avances: http://localhost:8081
MySQL: localhost:3306
```

Detener los servicios:

```bash
docker compose down
```

---

## Uso con Terraform

Entrar a la carpeta de infraestructura:

```bash
cd infra/ep2_tres_capas
```

Inicializar Terraform:

```bash
terraform init
```

Validar configuración:

```bash
terraform validate
```

Revisar plan:

```bash
terraform plan
```

Crear infraestructura:

```bash
terraform apply
```

Ver outputs:

```bash
terraform output
```

Eliminar infraestructura:

```bash
terraform destroy
```

---

## Diagrama de arquitectura

El flujo general de la arquitectura es:

```text
Usuario / Navegador
        ↓
Internet Gateway
        ↓
EC2 Frontend pública
        ↓
EC2 Backend privada
        ↓
EC2 Data privada con MySQL
```

Flujo DevOps:

```text
GitHub Actions → Amazon ECR → AWS SSM → EC2
```

Para agregar el diagrama al README:

```markdown
![Diagrama de arquitectura](docs/arquitectura-aws-3-capas.png)
```

---

## Buenas prácticas incluidas

* Separación en 3 capas: Frontend, Backend y Data.
* Frontend en subred pública.
* Backend y Data en subred privada.
* Security Groups separados por capa.
* Base de datos accesible solo desde Backend.
* NAT Gateway para salida a Internet desde recursos privados.
* Imágenes Docker almacenadas en ECR.
* Despliegue automatizado con GitHub Actions.
* Uso de SSM para ejecutar comandos remotos en EC2.
* Variables y outputs organizados en Terraform.

---

## Mejoras futuras

* Separar Backend y Data en subredes privadas distintas.
* Agregar Application Load Balancer.
* Migrar de EC2 a ECS Fargate.
* Usar Amazon RDS en lugar de MySQL en EC2.
* Configurar envío real de logs de contenedores a CloudWatch.
* Agregar HTTPS con AWS Certificate Manager.
* Usar un backend remoto para el estado de Terraform.

---

## Resumen

Este proyecto implementa una arquitectura AWS de 3 capas usando **Terraform, Docker, EC2, ECR, GitHub Actions, SSM, NAT Gateway, Security Groups y CloudWatch Logs**.

La solución permite desplegar una aplicación web completa, manteniendo el backend y la base de datos protegidos en una subred privada y automatizando el despliegue mediante CI/CD.
