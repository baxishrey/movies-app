resource "aws_ecs_cluster" "main" {
  name = "${var.app_name}-cluster"
}

data "template_file" "ecs_templates" {
  count    = length(var.service_names)
  template = file("./taskdefinitions/${var.app_name}.json.tpl")

  vars = {
    app_name        = element(var.service_names, count.index)
    app_image       = module.ecr[element(var.service_names, count.index)].repository_url
    fargate_cpu     = var.fargate_cpu
    fargate_memory  = var.fargate_memory
    aws_region      = local.aws_region
    backend_app_url = "http://${aws_lb.main.dns_name}:3000"
    port_mappings = jsonencode([{
      "containerPort" = var.app_port_mapping[element(var.service_names, count.index)]
      "name"          = element(var.service_names, count.index)
      "protocol"      = "tcp"
    }])
  }
}


resource "aws_ecs_task_definition" "task_definitions" {
  count = length(var.service_names)

  family                   = element(var.service_names, count.index)
  requires_compatibilities = ["FARGATE"]
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  cpu                = var.fargate_cpu
  memory             = var.fargate_memory
  network_mode       = "awsvpc"
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = data.template_file.ecs_templates[count.index].rendered
}
