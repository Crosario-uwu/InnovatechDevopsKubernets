# ============================================================
# Innovatech Chile - EP2 DevOps
# Arquitectura de 3 capas basada en la entrega EP1:
# Frontend publico | Backend privado | Data privada
# Incluye: VPC, subnets, gateways, security groups, EC2, ECR y CloudWatch.
# ============================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ------------------------------------------------------------
# Data sources
# ------------------------------------------------------------

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# AWS Academy normalmente entrega este instance profile.
# Si tu laboratorio usa otro nombre, cambialo en terraform.tfvars.
data "aws_iam_instance_profile" "lab_profile" {
  name = var.iam_instance_profile_name
}

# ------------------------------------------------------------
# ECR - Registro de imagenes Docker
# ------------------------------------------------------------

resource "aws_ecr_repository" "frontend" {
  name                 = "${var.project_name}-frontend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name    = "${var.project_name}-frontend"
    Project = var.project_name
    Stage   = "EP2"
  }
}

resource "aws_ecr_repository" "proyectos_backend" {
  name                 = "${var.project_name}-proyectos-backend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name    = "${var.project_name}-proyectos-backend"
    Project = var.project_name
    Stage   = "EP2"
    Service = "Proyectos"
  }
}

resource "aws_ecr_repository" "avances_backend" {
  name                 = "${var.project_name}-avances-backend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name    = "${var.project_name}-avances-backend"
    Project = var.project_name
    Stage   = "EP2"
    Service = "Avances"
  }
}

# ------------------------------------------------------------
# VPC y subredes
# ------------------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "${var.project_name}-vpc"
    Project = var.project_name
    Stage   = "EP2"
  }
}

resource "aws_subnet" "public_frontend" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name    = "${var.project_name}-public-frontend"
    Tier    = "Frontend"
    Project = var.project_name
  }
}

resource "aws_subnet" "private_backend_data" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name    = "${var.project_name}-private-backend-data"
    Tier    = "Backend-Data"
    Project = var.project_name
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "${var.project_name}-igw"
    Project = var.project_name
  }
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name    = "${var.project_name}-nat-eip"
    Project = var.project_name
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_frontend.id

  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name    = "${var.project_name}-nat-gateway"
    Project = var.project_name
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name    = "${var.project_name}-public-rt"
    Project = var.project_name
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public_frontend.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name    = "${var.project_name}-private-rt"
    Project = var.project_name
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private_backend_data.id
  route_table_id = aws_route_table.private.id
}

# ------------------------------------------------------------
# Security Groups
# ------------------------------------------------------------

resource "aws_security_group" "frontend" {
  name        = "${var.project_name}-sg-frontend"
  description = "Frontend publico: HTTP/HTTPS desde Internet y SSH opcional"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP desde Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS desde Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH administracion desde IP permitida"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg-frontend"
    Tier = "Frontend"
  }
}

resource "aws_security_group" "backend" {
  name        = "${var.project_name}-sg-backend"
  description = "Backend privado: API solo desde Frontend"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "API 8080 Proyectos solo desde Frontend"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend.id]
  }

  ingress {
    description     = "API 8081 Avances solo desde Frontend"
    from_port       = 8081
    to_port         = 8081
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend.id]
  }

  ingress {
    description     = "SSH solo desde Frontend como bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg-backend"
    Tier = "Backend"
  }
}

resource "aws_security_group" "data" {
  name        = "${var.project_name}-sg-data"
  description = "Data privada: MySQL solo desde Backend"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL 3306 solo desde Backend"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.backend.id]
  }

  ingress {
    description     = "SSH solo desde Backend"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.backend.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg-data"
    Tier = "Data"
  }
}

# ------------------------------------------------------------
# CloudWatch Logs
# ------------------------------------------------------------

resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/${var.project_name}/frontend"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "backend" {
  name              = "/${var.project_name}/backend"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "data" {
  name              = "/${var.project_name}/data"
  retention_in_days = 7
}

# ------------------------------------------------------------
# User data comun: Docker + Compose + SSM + expansion de disco
# ------------------------------------------------------------

locals {
  common_user_data = <<-EOF
    #!/bin/bash
    set -eux

    dnf update -y
    dnf install -y docker git amazon-ssm-agent awscli cloud-utils-growpart xfsprogs

    # Expande la particion raiz si el volumen EBS fue aumentado.
    growpart /dev/xvda 1 || true
    xfs_growfs -d / || true

    systemctl enable docker
    systemctl start docker
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent

    usermod -aG docker ec2-user
    mkdir -p /opt/innovatech
    chown -R ec2-user:ec2-user /opt/innovatech

    # Instala Docker Compose plugin si no viene incluido en la AMI.
    if ! docker compose version >/dev/null 2>&1; then
      mkdir -p /usr/local/lib/docker/cli-plugins
      curl -SL https://github.com/docker/compose/releases/download/v2.29.7/docker-compose-linux-x86_64 -o /usr/local/lib/docker/cli-plugins/docker-compose
      chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
    fi
  EOF
}

# ------------------------------------------------------------
# EC2 - 3 capas
# ------------------------------------------------------------

resource "aws_instance" "frontend" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  key_name                    = var.key_pair_name
  subnet_id                   = aws_subnet.public_frontend.id
  vpc_security_group_ids      = [aws_security_group.frontend.id]
  iam_instance_profile        = data.aws_iam_instance_profile.lab_profile.name
  associate_public_ip_address = true
  user_data                   = local.common_user_data

  # Se asigna espacio suficiente para Docker, Nginx y la imagen del Frontend.
  # Mantiene un tamaño moderado para cuidar el presupuesto AWS Academy.
  root_block_device {
    volume_size = 12
    volume_type = "gp3"
  }

  tags = {
    Name    = "${var.project_name}-frontend"
    Tier    = "Frontend"
    Project = var.project_name
    Stage   = "EP2"
  }
}

resource "aws_instance" "backend" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  subnet_id              = aws_subnet.private_backend_data.id
  vpc_security_group_ids = [aws_security_group.backend.id]
  iam_instance_profile   = data.aws_iam_instance_profile.lab_profile.name
  user_data              = local.common_user_data

  # Se asigna espacio suficiente para descargar y ejecutar
  # dos imagenes Java: proyectos-backend y avances-backend.
  # Mantiene un tamaño moderado para cuidar el presupuesto AWS Academy.
  root_block_device {
    volume_size = 12
    volume_type = "gp3"
  }

  tags = {
    Name    = "${var.project_name}-backend"
    Tier    = "Backend"
    Project = var.project_name
    Stage   = "EP2"
  }
}

resource "aws_instance" "data" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  subnet_id              = aws_subnet.private_backend_data.id
  vpc_security_group_ids = [aws_security_group.data.id]
  iam_instance_profile   = data.aws_iam_instance_profile.lab_profile.name
  user_data              = local.common_user_data

  # Se asigna espacio suficiente para MySQL, volumenes Docker
  # y extraccion de la imagen mysql:8.0.
  # Mantiene un tamaño moderado para cuidar el presupuesto AWS Academy.
  root_block_device {
    volume_size = 12
    volume_type = "gp3"
  }

  tags = {
    Name    = "${var.project_name}-data"
    Tier    = "Data"
    Project = var.project_name
    Stage   = "EP2"
  }
}
