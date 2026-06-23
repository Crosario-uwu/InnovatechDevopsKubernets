variable "aws_region" {
  description = "Region AWS del laboratorio"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre base para recursos AWS y ECR"
  type        = string
  default     = "innovatech-ep2"
}

variable "key_pair_name" {
  description = "Nombre del Key Pair creado en AWS. Debe existir antes del terraform apply."
  type        = string
  default     = "ep2-devops-key"
}

variable "iam_instance_profile_name" {
  description = "Instance profile usado por AWS Academy. Normalmente es LabInstanceProfile."
  type        = string
  default     = "LabInstanceProfile"
}

variable "instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t2.micro"
}

variable "vpc_cidr" {
  description = "CIDR de la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR subred publica Frontend"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR subred privada Backend/Data"
  type        = string
  default     = "10.0.2.0/24"
}

variable "admin_cidr" {
  description = "IP permitida para SSH al Frontend. Para laboratorio se puede usar 0.0.0.0/0."
  type        = string
  default     = "0.0.0.0/0"
}

# ------------------------------------------------------------
# EKS (EP3)
# ------------------------------------------------------------

variable "lab_role_name" {
  description = "Nombre del IAM Role existente de AWS Academy (LabRole) usado como rol del cluster EKS y de los nodos. AWS Academy no permite crear IAM roles nuevos, por eso se reutiliza este."
  type        = string
  default     = "LabRole"
}

variable "cluster_name" {
  description = "Nombre del cluster EKS"
  type        = string
  default     = "innovatech-cluster"
}

variable "eks_version" {
  description = "Version de Kubernetes para el cluster EKS"
  type        = string
  default     = "1.30"
}

variable "public_subnet_b_cidr" {
  description = "CIDR de la segunda subred publica (AZ2), requerida por EKS"
  type        = string
  default     = "10.0.3.0/24"
}

variable "private_subnet_b_cidr" {
  description = "CIDR de la segunda subred privada (AZ2), requerida por EKS"
  type        = string
  default     = "10.0.4.0/24"
}

variable "eks_node_instance_types" {
  description = "Tipos de instancia para el node group de EKS"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "eks_node_desired_size" {
  description = "Cantidad deseada de nodos worker en el cluster EKS"
  type        = number
  default     = 2
}

variable "eks_node_min_size" {
  description = "Cantidad minima de nodos worker en el cluster EKS"
  type        = number
  default     = 1
}

variable "eks_node_max_size" {
  description = "Cantidad maxima de nodos worker en el cluster EKS"
  type        = number
  default     = 3
}
