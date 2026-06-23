# Proyecto Innovatech – Infraestructura AWS con Terraform (EC2 + EKS)

## Descripción

Infraestructura gestionada con **Terraform** que despliega la misma aplicación (frontend + 2 backends + MySQL) de **dos formas**, ambas desde un solo pipeline de GitHub Actions:

* **EP2 – 3 capas en EC2**: Frontend público, Backend privado y Data privada, cada uno en su propia instancia EC2.
* **EP3 – Kubernetes (EKS)**: mismo set de servicios desplegado como Deployments/Services en un cluster EKS, con autoescalado (HPA).

Recursos comunes a ambos:

* **VPC** con subred pública y subred privada (mas dos subredes adicionales en una segunda AZ, requeridas por EKS).
* **Internet Gateway** y **NAT Gateway**.
* **Security Groups** separados por capa.
* **Amazon ECR** para imágenes Docker.
* **GitHub Actions** para CI/CD (un solo workflow despliega a EC2 y a EKS).
* **AWS Systems Manager (SSM)** para el despliegue remoto en EC2.
* **CloudWatch Logs** para organización de logs por capa.
* **Cluster EKS + node group**, reutilizando el `LabRole` de AWS Academy.

---

## Estructura del proyecto

```text
InnovatechDevopsKubernets/
├── .github/
│   └── workflows/
│       └── deploy.yml          # build+push y deploy a EC2 y a EKS
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
│   ├── ep2_tres_capas/
│   │   ├── main.tf             # VPC, EC2, ECR, Security Groups
│   │   ├── eks.tf              # cluster EKS + node group
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars.example
│   └── k8s/
│       ├── mysql.yml
│       ├── backend-proyectos.yml
│       ├── backend-avances.yml
│       ├── frontend.yml
│       └── hpa.yml
├── mysql-init/
│   └── init.sql                # seed data, montado como ConfigMap en EKS
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

Flujo de despliegue (un solo workflow, un solo job):

```text
Push a rama deploy
        ↓
Build de imágenes Docker → Push a Amazon ECR
        ↓
Deploy a EC2 vía AWS Systems Manager
   (Data → Backends → Frontend)
        ↓
Deploy a EKS vía kubectl
   (Secret/ConfigMap de MySQL → apply manifiestos → rollout restart)
```

El despliegue a EC2 se realiza mediante **SSM**, evitando conectarse manualmente por SSH a cada instancia. El despliegue a EKS requiere que el cluster ya exista (ver sección Terraform más abajo).

---

## Uso local con Docker

Crea tu archivo de entorno (los valores de ejemplo ya funcionan en local):

```bash
cp .env.example .env
```

Levanta el proyecto completo:

```bash
docker compose up --build
```

Servicio accesible desde el host:

```text
Frontend: http://localhost:3000
```

Los backends (`proyectos-backend:8080`, `avances-backend:8081`) y MySQL (`3306`) **no se publican al host** — solo son alcanzables dentro de la red interna de Docker (`innovatech-net`); el frontend les llega vía Nginx como reverse proxy.

Detener los servicios:

```bash
docker compose down
```

---

## Uso con Terraform

Crea esta infraestructura (VPC, EC2, ECR, **y el cluster EKS + node group**) una sola vez, antes del primer push a la rama `deploy`:

Entrar a la carpeta de infraestructura:

```bash
cd infra/ep2_tres_capas
```

Exportar las credenciales de AWS Academy (Learner Lab → AWS Details):

```bash
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_SESSION_TOKEN=...
export AWS_DEFAULT_REGION=us-east-1
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

Crear infraestructura (la creación del cluster EKS demora ~10-15 min):

```bash
terraform apply
```

Ver outputs (incluye `eks_cluster_name`, `eks_cluster_endpoint` y la lista de secrets a configurar en GitHub):

```bash
terraform output
```

Eliminar infraestructura:

```bash
terraform destroy
```

---

## Uso con Kubernetes (EKS)

Una vez creado el cluster con Terraform, el pipeline se conecta y aplica los manifiestos de `infra/k8s/` automáticamente en cada push. Para operarlo a mano:

Conectarte al cluster:

```bash
aws eks update-kubeconfig --region us-east-1 --name innovatech-cluster
```

Instalar `metrics-server` (una sola vez, requerido para que el HPA escale):

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

Ver el estado del despliegue:

```bash
kubectl get pods
kubectl get svc frontend   # URL pública (LoadBalancer)
kubectl get hpa
```

Las credenciales de MySQL se inyectan vía un `Secret` (`mysql-credentials`) que el pipeline crea a partir de los GitHub Secrets `MYSQL_ROOT_PASSWORD`/`MYSQL_DATABASE` — no están hardcodeadas en los manifiestos.

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
                            └→ kubectl → EKS
```

Para agregar el diagrama al README:

```markdown
![Diagrama de arquitectura](docs/arquitectura-aws-3-capas.png)
```

---

## Buenas prácticas incluidas

* Separación en 3 capas: Frontend, Backend y Data.
* Frontend en subred pública; Backend y Data en subred privada.
* Security Groups separados por capa.
* Base de datos accesible solo desde Backend.
* NAT Gateway para salida a Internet desde recursos privados.
* Imágenes Docker almacenadas en ECR, reutilizadas tanto por EC2 como por EKS.
* Despliegue automatizado con GitHub Actions a ambos destinos.
* Uso de SSM para ejecutar comandos remotos en EC2 (sin SSH manual).
* Credenciales de MySQL inyectadas vía Kubernetes Secret, no hardcodeadas en los manifiestos.
* Autoescalado horizontal (HPA) para los backends en EKS.
* Variables y outputs organizados en Terraform.

---

## Mejoras futuras

* Separar Backend y Data en subredes privadas distintas.
* Agregar Application Load Balancer para la ruta EC2 (en EKS ya existe vía el Service `LoadBalancer`).
* Usar Amazon RDS en lugar de MySQL en EC2 o en un pod de Kubernetes.
* Configurar envío real de logs de contenedores a CloudWatch.
* Agregar HTTPS con AWS Certificate Manager.
* Usar un backend remoto para el estado de Terraform.
* Separar el job EC2 y el job EKS del pipeline para que sean independientes entre si.

---

## Resumen

Este proyecto implementa una arquitectura AWS que despliega la misma aplicación de dos formas: **3 capas en EC2** y **Kubernetes (EKS)**, usando **Terraform, Docker, EC2, EKS, ECR, GitHub Actions, SSM, NAT Gateway, Security Groups y CloudWatch Logs**.

La solución permite desplegar una aplicación web completa, manteniendo el backend y la base de datos protegidos en una subred privada y automatizando el despliegue mediante un solo pipeline de CI/CD.
