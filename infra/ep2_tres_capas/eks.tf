# ============================================================
# Innovatech Chile - EP3 DevOps
# Cluster EKS para desplegar los mismos servicios (frontend,
# backend-proyectos, backend-avances, mysql) con Kubernetes.
# Reutiliza la VPC, IGW y NAT Gateway creados en main.tf.
#
# AWS Academy no permite crear IAM Roles nuevos, por eso el
# cluster y el node group reutilizan el rol existente "LabRole"
# (var.lab_role_name) en lugar de crear roles dedicados. Ese rol
# debe tener adjuntas AmazonEKSClusterPolicy, AmazonEKSWorkerNodePolicy,
# AmazonEKS_CNI_Policy y AmazonEC2ContainerRegistryReadOnly, que ya
# vienen incluidas por defecto en el LabRole de los laboratorios que
# habilitan EKS.
# ============================================================

data "aws_iam_role" "lab_role" {
  name = var.lab_role_name
}

# ------------------------------------------------------------
# Segunda zona de disponibilidad: EKS exige subredes en al
# menos 2 AZ distintas para el control plane y los nodos.
# ------------------------------------------------------------

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_b_cidr
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name                                        = "${var.project_name}-public-b"
    Project                                     = var.project_name
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_b_cidr
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name                                        = "${var.project_name}-private-b"
    Project                                     = var.project_name
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}

# Las subredes originales (AZ1) tambien necesitan las tags de
# descubrimiento de subredes para que el Service type=LoadBalancer
# del frontend pueda crear el ELB automaticamente.
resource "aws_ec2_tag" "public_a_elb" {
  resource_id = aws_subnet.public_frontend.id
  key         = "kubernetes.io/role/elb"
  value       = "1"
}

resource "aws_ec2_tag" "public_a_cluster" {
  resource_id = aws_subnet.public_frontend.id
  key         = "kubernetes.io/cluster/${var.cluster_name}"
  value       = "shared"
}

resource "aws_ec2_tag" "private_a_elb" {
  resource_id = aws_subnet.private_backend_data.id
  key         = "kubernetes.io/role/internal-elb"
  value       = "1"
}

resource "aws_ec2_tag" "private_a_cluster" {
  resource_id = aws_subnet.private_backend_data.id
  key         = "kubernetes.io/cluster/${var.cluster_name}"
  value       = "shared"
}

# ------------------------------------------------------------
# Security Group del control plane EKS
# ------------------------------------------------------------

resource "aws_security_group" "eks_cluster" {
  name        = "${var.project_name}-sg-eks-cluster"
  description = "Trafico del cluster EKS (control plane y nodos)"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg-eks-cluster"
  }
}

resource "aws_security_group_rule" "eks_self_ingress" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.eks_cluster.id
  source_security_group_id = aws_security_group.eks_cluster.id
}

# ------------------------------------------------------------
# Cluster EKS
# ------------------------------------------------------------

resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = data.aws_iam_role.lab_role.arn
  version  = var.eks_version

  vpc_config {
    subnet_ids = [
      aws_subnet.public_frontend.id,
      aws_subnet.public_b.id,
      aws_subnet.private_backend_data.id,
      aws_subnet.private_b.id,
    ]
    security_group_ids      = [aws_security_group.eks_cluster.id]
    endpoint_public_access  = true
    endpoint_private_access = true
  }

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  tags = {
    Name    = var.cluster_name
    Project = var.project_name
    Stage   = "EP3"
  }
}

# ------------------------------------------------------------
# Node Group administrado (nodos worker en subredes privadas)
# ------------------------------------------------------------

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-nodes"
  node_role_arn   = data.aws_iam_role.lab_role.arn
  subnet_ids      = [aws_subnet.private_backend_data.id, aws_subnet.private_b.id]
  instance_types  = var.eks_node_instance_types

  scaling_config {
    desired_size = var.eks_node_desired_size
    min_size     = var.eks_node_min_size
    max_size     = var.eks_node_max_size
  }

  tags = {
    Name    = "${var.project_name}-eks-nodes"
    Project = var.project_name
    Stage   = "EP3"
  }

  depends_on = [aws_eks_cluster.main]
}
