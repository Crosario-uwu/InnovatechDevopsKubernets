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
