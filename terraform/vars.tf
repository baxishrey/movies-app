data "aws_region" "current" {
}

data "aws_caller_identity" "current" {

}

locals {
  aws_region = data.aws_region.current.name  
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public subnet CIDRs"
  default     = ["10.0.0.0/20", "10.0.16.0/20"]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private subnet CIDRs"
  default     = ["10.0.128.0/20", "10.0.144.0/20"]
}

variable "app_name" {
  type    = string
  default = "movies-app"
}

variable "security_group_name" {
  type    = string
  default = "SG_Anjelina"
}

variable "service_names" {
  type    = list(string)
  default = ["backend", "frontend"]
}

variable "db_service_name" {
  type    = string
  default = "mongodb"
}

variable "backend_service_name" {
  type    = string
  default = "backend"
}

variable "frontend_service_name" {
  type    = string
  default = "frontend"
}

variable "fargate_cpu" {
  description = "Fargate instance CPU units to provision (1 vCPU = 1024 CPU units)"
  default     = "1024"
}

variable "fargate_memory" {
  description = "Fargate instance memory to provision (in MiB)"
  default     = "2048"
}


variable "ecs_task_execution_role_name" {
  description = "ECS task execution role name"
  default     = "myEcsTaskExecutionRole"
}

variable "app_port_mapping" {
  type = object({
    backend  = number
    frontend = number
    mongodb  = number
  })

  default = {
    backend  = 3000
    frontend = 3000
    mongodb  = 27017
  }
}

variable "alb_port_mapping" {
  type = object({
    backend  = number
    frontend = number
  })

  default = {
    backend  = 3000
    frontend = 80
  }
}

