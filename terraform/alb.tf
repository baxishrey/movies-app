resource "aws_lb" "main" {
  name            = var.app_name
  subnets         = aws_subnet.public_subnet.*.id
  security_groups = [aws_security_group.movies-app.id]
}

resource "aws_lb_target_group" "app_target_groups" {
  count       = length(var.service_names)
  protocol    = "HTTP"
  vpc_id      = aws_vpc.movies-app.id
  target_type = "ip"

  name = element(var.service_names, count.index)
  port = var.alb_port_mapping[var.service_names[count.index]]
}

resource "aws_lb_listener" "app_lb_listeners" {
  count             = length(var.service_names)
  load_balancer_arn = aws_lb.main.arn
  protocol          = "HTTP"
  port              = var.alb_port_mapping[var.service_names[count.index]]
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_target_groups[count.index].arn
  }
}
