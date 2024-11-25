resource "aws_service_discovery_http_namespace" "movies-app" {
  name = var.app_name
}

resource "aws_ecs_cluster" "main" {
  name = "${var.app_name}-cluster"
  service_connect_defaults {
    namespace = aws_service_discovery_http_namespace.movies-app.arn
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
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
    backend_app_url = aws_lb.main.dns_name
    port_mappings = jsonencode([{
      "containerPort" = var.app_port_mapping[element(var.service_names, count.index)]
      "name"          = element(var.service_names, count.index)
      "protocol"      = "tcp"
    }])
  }
}

data "template_file" "db_ecs_template" {
  template = file("./taskdefinitions/${var.app_name}.json.tpl")

  vars = {
    app_name        = "mongodb"
    app_image       = "mongo"
    fargate_cpu     = var.fargate_cpu
    fargate_memory  = var.fargate_memory
    aws_region      = local.aws_region
    backend_app_url = aws_lb.main.dns_name
    port_mappings = jsonencode([{
      "containerPort" = 27017
      "name"          = "mongodb"
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

resource "aws_ecs_task_definition" "db_task_definition" {
  family                   = "mongodb"
  requires_compatibilities = ["FARGATE"]
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  cpu                = var.fargate_cpu
  memory             = var.fargate_memory
  network_mode       = "awsvpc"
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = data.template_file.db_ecs_template.rendered
}

resource "aws_cloudwatch_log_group" "log_groups" {
  count = length(var.service_names)
  name = "/ecs/${var.service_names[count.index]}"
}

resource "aws_cloudwatch_log_group" "db_log_group" {
  name = "/ecs/mongodb"
}

resource "aws_ecs_service" "mongodb_service" {
  name            = "mongodb"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.db_task_definition.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private_subnet.*.id
    security_groups  = [aws_security_group.movies-app.id]
    assign_public_ip = false
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.movies-app.arn
    service {
      port_name = "mongodb"
      client_alias {
        port = 27017
      }
    }
  }
}

resource "aws_ecs_service" "app_service_definitions" {
  count = length(var.service_names)

  name            = element(var.service_names, count.index)
  cluster         = aws_ecs_cluster.main.id
  desired_count   = 1
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.task_definitions[count.index].arn

  network_configuration {
    subnets          = aws_subnet.private_subnet.*.id
    security_groups  = [aws_security_group.movies-app.id]
    assign_public_ip = false
  }
  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.movies-app.arn
    service {
      port_name = element(var.service_names, count.index)
      client_alias {
        port = 3000
      }
    }
  }
  load_balancer {
    container_name   = element(var.service_names, count.index)
    container_port   = 3000
    target_group_arn = aws_lb_target_group.app_target_groups[count.index].arn
  }

}
