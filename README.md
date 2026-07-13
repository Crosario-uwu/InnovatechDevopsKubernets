# Proyecto Innovatech – Gestión de Proyectos y Avances con Infraestructura AWS (EC2 + EKS)

## Descripción

**Innovatech** es una aplicación web para la **gestión de proyectos y su seguimiento (avances)**. Permite:

* Crear, listar y eliminar **proyectos** (nombre, responsable, estado — por defecto `Planificado`).
* Registrar **avances** asociados a un proyecto (fecha, descripción, estado de completado), y listarlos globalmente o filtrados por proyecto.
* Consultar todo desde una interfaz **React** que consume dos APIs REST independientes (`/api/v1/proyectos` y `/api/v1/avances`).

Funcionalmente son 3 piezas:

* **Frontend** (React + Vite, servido por Nginx): UI para crear/ver proyectos y sus avances.
* **Backend Proyectos** (Spring Boot, puerto `8080`): CRUD de proyectos, persistido en MySQL.
* **Backend Avances** (Spring Boot, puerto `8081`): CRUD de avances, ligados a un proyecto por `proyectoId`, persistido en la misma base MySQL.

A nivel de infraestructura, el proyecto está gestionado con **Terraform** y se despliega de **dos formas en paralelo**, ambas desde un solo pipeline de GitHub Actions en cada push a la rama `deploy`:

* **EP2 – 3 capas en EC2**: Frontend público, Backend privado y Data privada, cada uno en su propia instancia EC2.
* **EP3 – Kubernetes (EKS)**: mismo set de servicios desplegado como Deployments/Services en un cluster EKS, con autoescalado horizontal (HPA), rolling updates controlados y logs enviados a CloudWatch Container Insights.

Recursos comunes a ambos destinos:

* **VPC** con subred pública y subred privada (más dos subredes adicionales en una segunda AZ, requeridas por EKS).
* **Internet Gateway** y **NAT Gateway**.
* **Security Groups** separados por capa.
* **Amazon ECR** para imágenes Docker, compartido por EC2 y EKS.
* **GitHub Actions** para CI/CD: test → build → push a ECR → deploy a EC2 (SSM) → deploy a EKS (kubectl), todo en un solo workflow.
* **AWS Systems Manager (SSM)** para el despliegue remoto en EC2, sin SSH manual.
* **CloudWatch Logs / Container Insights** (vía Fluent Bit en EKS) para centralizar logs.
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

## API — qué hace cada backend

### Backend Proyectos (`:8080`)

| Método | Endpoint | Descripción |
|---|---|---|
| `GET` | `/api/v1/proyectos` | Lista todos los proyectos |
| `POST` | `/api/v1/proyectos` | Crea un proyecto (`nombre`, `responsable`, `estado`) |
| `DELETE` | `/api/v1/proyectos/{id}` | Elimina un proyecto |
| `GET` | `/api/v1/ping` | Health check (usado por readiness/liveness probes) |

### Backend Avances (`:8081`)

| Método | Endpoint | Descripción |
|---|---|---|
| `GET` | `/api/v1/avances` | Lista todos los avances |
| `GET` | `/api/v1/proyectos/{proyectoId}/avances` | Lista avances de un proyecto |
| `POST` | `/api/v1/proyectos/{proyectoId}/avances` | Crea un avance (`fecha`, `descripcion`, `completado`) para ese proyecto |
| `DELETE` | `/api/v1/avances/{id}` | Elimina un avance |
| `GET` | `/api/v1/ping/avances` | Health check (usado por readiness/liveness probes) |

El **frontend** (`src/api/api.js`) consume ambas APIs vía Nginx como reverse proxy (`BACKEND_PROYECTOS_URL` / `BACKEND_AVANCES_URL`), por lo que nunca expone las URLs internas de los backends al navegador.

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

Flujo de despliegue (un solo workflow, dos jobs):

```text
Push a rama deploy
        ↓
Job "test": mvnw test en ambos backends (gate de calidad)
        ↓
Job "build-push-deploy":
Build de imágenes Docker → Push a Amazon ECR
        ↓
Deploy a EC2 vía AWS Systems Manager
   (Data → Backends → Frontend)
        ↓
Deploy a EKS vía kubectl
   (metrics-server → Fluent Bit/CloudWatch Container Insights
    → Secret/ConfigMap de MySQL → apply manifiestos
    → rollout restart con maxSurge:0 → esperar rollout → resumen)
```

El despliegue a EC2 se realiza mediante **SSM**, evitando conectarse manualmente por SSH a cada instancia. El despliegue a EKS requiere que el cluster ya exista (ver sección Terraform más abajo). Al final del job, el pipeline imprime en el log la **URL pública del frontend** (hostname del LoadBalancer de EKS).

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

## Buenas prácticas incluidas

* Separación en 3 capas: Frontend, Backend y Data.
* Frontend en subred pública; Backend y Data en subred privada.
* Security Groups separados por capa.
* Base de datos accesible solo desde Backend.
* NAT Gateway para salida a Internet desde recursos privados.
* Imágenes Docker almacenadas en ECR, reutilizadas tanto por EC2 como por EKS.
* Despliegue automatizado con GitHub Actions a ambos destinos, con job `test` como gate previo al build.
* Uso de SSM para ejecutar comandos remotos en EC2 (sin SSH manual).
* Credenciales de MySQL inyectadas vía Kubernetes Secret, no hardcodeadas en los manifiestos.
* Autoescalado horizontal (HPA, 2-10 réplicas al 50% CPU) para ambos backends en EKS.
* `readinessProbe`/`livenessProbe` en los backends contra sus endpoints `/api/v1/ping`, para que Kubernetes no enrute tráfico a pods aún no listos.
* `resources.requests`/`limits` de CPU y memoria definidos en cada Deployment, evitando que un pod acapare el nodo.
* Rolling updates con `maxSurge: 0` / `maxUnavailable: 1` en frontend y backends: evita necesitar un pod extra temporal durante el despliegue, ya que el cluster (2× t3.medium) no tiene CPU libre para ese pod momentáneo.
* Logs de aplicación centralizados en CloudWatch Container Insights vía Fluent Bit (DaemonSet).
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

**Innovatech** es una app de gestión de proyectos y avances (React + 2 APIs Spring Boot + MySQL), desplegada mediante una arquitectura AWS que la publica de **dos formas en paralelo**: **3 capas en EC2** y **Kubernetes (EKS)**, usando **Terraform, Docker, EC2, EKS, ECR, GitHub Actions, SSM, NAT Gateway, Security Groups, HPA y CloudWatch Container Insights**.

La solución mantiene el backend y la base de datos protegidos en una subred privada (EC2) o expuestos solo dentro del cluster (EKS), automatiza todo el ciclo de build-test-deploy con un solo pipeline de CI/CD, y en EKS agrega autoescalado horizontal y rolling updates ajustados a la capacidad real del cluster.
