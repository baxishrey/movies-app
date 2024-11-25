locals {
  repositories = {
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
