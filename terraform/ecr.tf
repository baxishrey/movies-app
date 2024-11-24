# resource "aws_ecr_repository" "ecr_repos" {
#   count = length(var.service_names)
#   name  = element(var.service_names, count.index)

# }

# output "images" {
#   value = { aws_ecr_repository.ecr_repos[*].name : aws_ecr_repository.ecr_repos[*].repository_url }
# }

locals {
  repositories = {
    "mongodb" : {
      name : "mongodb"
    }
    "backend" : {
      name : "backend"
    }
    "frontend" : {
      name : "frontend"
    }
  }
}

module "ecr" {
  source   = "./modules/ecr"
  for_each = local.repositories

  name = each.value.name
}
